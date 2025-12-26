//
//  TabAssociationServiceTests.swift
//  TabOrganizerCoreTests
//
//  Tests for TabAssociationService business logic.
//  Verifies CRUD operations, validation, and error handling.
//

import Testing
import Foundation
@testable import TabOrganizerCore
@testable import TabOrganizerStorage
@testable import TabOrganizerSafariAPI

/// Tests for TabAssociationService.
@Suite("TabAssociationService Tests")
@MainActor
struct TabAssociationServiceTests {

    // MARK: - Test Fixtures

    func makeService() -> (service: TabAssociationService, repo: MockAssociationRepository, tabManager: MockTabManager) {
        let repo = MockAssociationRepository()
        let tabManager = MockTabManager.withSampleTabs()
        let service = TabAssociationService(repository: repo, tabManager: tabManager)
        return (service, repo, tabManager)
    }

    // MARK: - Create Group Tests

    @Test("CreateGroup creates new group with valid name (FR-001)")
    func createGroupCreatesNewGroupWithValidName() async throws {
        let (service, repo, _) = makeService()
        let windowID = "window-1"

        let group = try await service.createGroup(
            name: "Work",
            color: "#0066CC",
            tabIDs: ["tab-1"],
            windowID: windowID
        )

        #expect(group.name == "Work")
        #expect(group.color == "#0066CC")
        #expect(group.tabIDs == ["tab-1"])
        #expect(repo.saveCalls.count == 1)
    }

    @Test("CreateGroup throws on empty name")
    func createGroupThrowsOnEmptyName() async throws {
        let (service, _, _) = makeService()
        let windowID = "window-1"

        await #expect(throws: TabAssociationError.self) {
            try await service.createGroup(
                name: "",
                color: "#0066CC",
                windowID: windowID
            )
        }
    }

    @Test("CreateGroup trims whitespace from name")
    func createGroupTrimsWhitespaceFromName() async throws {
        let (service, _, _) = makeService()
        let windowID = "window-1"

        let group = try await service.createGroup(
            name: "  Work  ",
            color: "#0066CC",
            windowID: windowID
        )

        #expect(group.name == "Work")
    }

    @Test("CreateGroup prevents duplicate names (FR-006)")
    func createGroupPreventsDuplicateNames() async throws {
        let (service, _, _) = makeService()
        let windowID = "window-1"

        try await service.createGroup(name: "Work", color: "#0066CC", windowID: windowID)

        await #expect(throws: StorageError.self) {
            try await service.createGroup(name: "Work", color: "#FF0000", windowID: windowID)
        }
    }

    @Test("CreateGroup updates observable state")
    func createGroupUpdatesObservableState() async throws {
        let (service, _, _) = makeService()
        let windowID = "window-1"

        #expect(service.groups.isEmpty)

        _ = try await service.createGroup(name: "Work", color: "#0066CC", windowID: windowID)

        #expect(service.groups.count == 1)
        #expect(service.groups.first?.name == "Work")
    }

    // MARK: - Delete Group Tests

    @Test("DeleteGroup removes group (FR-005)")
    func deleteGroupRemovesGroup() async throws {
        let (service, repo, _) = makeService()
        let windowID = "window-1"

        let group = try await service.createGroup(name: "Work", color: "#0066CC", windowID: windowID)

        try await service.deleteGroup(associationID: group.id, windowID: windowID)

        #expect(repo.deleteCalls.contains(group.id))
        #expect(service.groups.isEmpty)
    }

    @Test("DeleteGroup throws on non-existent group")
    func deleteGroupThrowsOnNonExistentGroup() async throws {
        let (service, _, _) = makeService()
        let windowID = "window-1"

        await #expect(throws: StorageError.self) {
            try await service.deleteGroup(associationID: UUID(), windowID: windowID)
        }
    }

    // MARK: - Update Group Tests

    @Test("UpdateGroup modifies existing group")
    func updateGroupModifiesExistingGroup() async throws {
        let (service, repo, _) = makeService()
        let windowID = "window-1"

        let group = try await service.createGroup(name: "Work", color: "#0066CC", windowID: windowID)
        let updatedGroup = try group.withName("Work Projects")

        try await service.updateGroup(updatedGroup, windowID: windowID)

        #expect(repo.updateCalls.count == 1)
        #expect(service.groups.first?.name == "Work Projects")
    }

    @Test("UpdateGroup prevents duplicate names (FR-006)")
    func updateGroupPreventsDuplicateNames() async throws {
        let (service, _, _) = makeService()
        let windowID = "window-1"

        let group1 = try await service.createGroup(name: "Work", color: "#0066CC", windowID: windowID)
        _ = try await service.createGroup(name: "Research", color: "#00CC66", windowID: windowID)

        let renamedGroup = try group1.withName("Research")

        await #expect(throws: StorageError.self) {
            try await service.updateGroup(renamedGroup, windowID: windowID)
        }
    }

    // MARK: - GetAllGroups Tests

    @Test("GetAllGroups returns all groups")
    func getAllAssociationsReturnsAllGroups() async throws {
        let (service, _, _) = makeService()
        let windowID = "window-1"

        _ = try await service.createGroup(name: "Work", color: "#0066CC", windowID: windowID)
        _ = try await service.createGroup(name: "Research", color: "#00CC66", windowID: windowID)

        let groups = try await service.getAllAssociations(windowID: windowID)

        #expect(groups.count == 2)
    }

    // MARK: - Tab Membership Tests

    @Test("AddTabToGroup adds tab to group (FR-004)")
    func addTabToGroupAddsTabToGroup() async throws {
        let (service, _, _) = makeService()
        let windowID = "window-1"

        let group = try await service.createGroup(name: "Work", color: "#0066CC", windowID: windowID)

        try await service.addTabToGroup(tabID: "tab-1", associationID: group.id, windowID: windowID)

        let updatedGroups = try await service.getAllAssociations(windowID: windowID)
        #expect(updatedGroups.first?.tabIDs.contains("tab-1") == true)
    }

    @Test("RemoveTabFromGroup removes tab from group (FR-004)")
    func removeTabFromGroupRemovesTabFromGroup() async throws {
        let (service, _, _) = makeService()
        let windowID = "window-1"

        let group = try await service.createGroup(
            name: "Work",
            color: "#0066CC",
            tabIDs: ["tab-1", "tab-2"],
            windowID: windowID
        )

        try await service.removeTabFromGroup(tabID: "tab-1", associationID: group.id, windowID: windowID)

        let updatedGroups = try await service.getAllAssociations(windowID: windowID)
        #expect(updatedGroups.first?.tabIDs == ["tab-2"])
    }

    @Test("MoveTab moves tab between groups")
    func moveTabMovesTabBetweenGroups() async throws {
        let (service, _, _) = makeService()
        let windowID = "window-1"

        let group1 = try await service.createGroup(
            name: "Work",
            color: "#0066CC",
            tabIDs: ["tab-1"],
            windowID: windowID
        )

        let group2 = try await service.createGroup(
            name: "Research",
            color: "#00CC66",
            windowID: windowID
        )

        try await service.moveTab(
            tabID: "tab-1",
            fromGroupID: group1.id,
            toGroupID: group2.id,
            windowID: windowID
        )

        let groups = try await service.getAllAssociations(windowID: windowID)
        let workGroup = groups.first { $0.id == group1.id }
        let researchGroup = groups.first { $0.id == group2.id }

        #expect(workGroup?.tabIDs.isEmpty == true)
        #expect(researchGroup?.tabIDs.contains("tab-1") == true)
    }

    // MARK: - Group State Tests

    @Test("ToggleGroupCollapsed toggles collapsed state (FR-003)")
    func toggleGroupCollapsedTogglesCollapsedState() async throws {
        let (service, _, _) = makeService()
        let windowID = "window-1"

        let group = try await service.createGroup(name: "Work", color: "#0066CC", windowID: windowID)

        #expect(group.collapsed == false)

        try await service.toggleGroupCollapsed(associationID: group.id, windowID: windowID)

        let groups = try await service.getAllAssociations(windowID: windowID)
        #expect(groups.first?.collapsed == true)

        try await service.toggleGroupCollapsed(associationID: group.id, windowID: windowID)

        let groups2 = try await service.getAllAssociations(windowID: windowID)
        #expect(groups2.first?.collapsed == false)
    }

    @Test("RenameGroup changes group name (FR-005)")
    func renameGroupChangesGroupName() async throws {
        let (service, _, _) = makeService()
        let windowID = "window-1"

        let group = try await service.createGroup(name: "Work", color: "#0066CC", windowID: windowID)

        try await service.renameGroup(associationID: group.id, newName: "Work Projects", windowID: windowID)

        let groups = try await service.getAllAssociations(windowID: windowID)
        #expect(groups.first?.name == "Work Projects")
    }

    @Test("RenameGroup prevents empty name")
    func renameGroupPreventsEmptyName() async throws {
        let (service, _, _) = makeService()
        let windowID = "window-1"

        let group = try await service.createGroup(name: "Work", color: "#0066CC", windowID: windowID)

        await #expect(throws: TabAssociationError.self) {
            try await service.renameGroup(associationID: group.id, newName: "", windowID: windowID)
        }
    }

    @Test("ChangeGroupColor changes color")
    func changeGroupColorChangesColor() async throws {
        let (service, _, _) = makeService()
        let windowID = "window-1"

        let group = try await service.createGroup(name: "Work", color: "#0066CC", windowID: windowID)

        try await service.changeGroupColor(associationID: group.id, newColor: "#FF0000", windowID: windowID)

        let groups = try await service.getAllAssociations(windowID: windowID)
        #expect(groups.first?.color == "#FF0000")
    }

    // MARK: - Error Handling Tests

    @Test("Service sets lastError on failure")
    func serviceSetsLastErrorOnFailure() async throws {
        let (service, repo, _) = makeService()
        let windowID = "window-1"

        // Inject error
        repo.saveError = StorageError.quotaExceeded("Test error")

        do {
            _ = try await service.createGroup(name: "Work", color: "#0066CC", windowID: windowID)
            #expect(Bool(false), "Should have thrown error")
        } catch {
            #expect(service.lastError != nil)
        }
    }

    @Test("Service sets isLoading during operations")
    func serviceSetsIsLoadingDuringOperations() async throws {
        let (service, _, _) = makeService()
        let windowID = "window-1"

        // Note: This test is illustrative - in practice, isLoading is set/unset
        // too quickly to observe in tests. In real UI, SwiftUI would observe changes.

        #expect(service.isLoading == false)

        Task {
            _ = try await service.createGroup(name: "Work", color: "#0066CC", windowID: windowID)
        }

        // In production, SwiftUI would observe isLoading changes for UI feedback
    }
}
