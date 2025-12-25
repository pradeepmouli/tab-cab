//
//  TabGroupRepositoryTests.swift
//  TabOrganizerStorageTests
//
//  Tests for TabGroupRepository implementations.
//  Verifies CRUD operations, duplicate name prevention, and reactive observation.
//

import Testing
import Foundation
import TabOrganizerCore
@testable import TabOrganizerStorage

/// Tests for TabGroupRepository protocol implementations.
@Suite("TabGroupRepository Tests")
@MainActor
struct TabGroupRepositoryTests {

    // MARK: - Test Fixtures

    func makeSampleGroup(name: String = "Work", tabIDs: [String] = ["tab-1", "tab-2"]) -> TabGroup {
        TabGroup(
            id: UUID(),
            name: name,
            color: "#0066CC",
            collapsed: false,
            createdAt: Date(),
            updatedAt: Date(),
            tabIDs: tabIDs,
            metadata: [:]
        )
    }

    // MARK: - Save Tests

    @Test("Save creates new group")
    func saveCreatesNewGroup() async throws {
        let repo = MockGroupRepository()
        let group = makeSampleGroup(name: "Work")
        let windowID = "window-1"

        try await repo.save(group, windowID: windowID)

        let groups = try await repo.getAllGroups(windowID: windowID)
        #expect(groups.count == 1)
        #expect(groups.first?.id == group.id)
        #expect(groups.first?.name == "Work")
    }

    @Test("Save prevents duplicate names (FR-006)")
    func savePreventsduplicateNames() async throws {
        let repo = MockGroupRepository()
        let windowID = "window-1"

        let group1 = makeSampleGroup(name: "Work")
        try await repo.save(group1, windowID: windowID)

        let group2 = makeSampleGroup(name: "Work") // Different ID, same name

        await #expect(throws: StorageError.self) {
            try await repo.save(group2, windowID: windowID)
        }
    }

    @Test("Save allows same name in different windows")
    func saveAllowsSameNameDifferentWindows() async throws {
        let repo = MockGroupRepository()

        let group1 = makeSampleGroup(name: "Work")
        try await repo.save(group1, windowID: "window-1")

        let group2 = makeSampleGroup(name: "Work")
        try await repo.save(group2, windowID: "window-2")

        let window1Groups = try await repo.getAllGroups(windowID: "window-1")
        let window2Groups = try await repo.getAllGroups(windowID: "window-2")

        #expect(window1Groups.count == 1)
        #expect(window2Groups.count == 1)
    }

    @Test("Save updates existing group")
    func saveUpdatesExistingGroup() async throws {
        let repo = MockGroupRepository()
        let windowID = "window-1"

        let group = makeSampleGroup(name: "Work", tabIDs: ["tab-1"])
        try await repo.save(group, windowID: windowID)

        // Update with more tabs
        let updatedGroup = try group.withTabAdded("tab-2")
        try await repo.save(updatedGroup, windowID: windowID)

        let groups = try await repo.getAllGroups(windowID: windowID)
        #expect(groups.count == 1) // Should be updated, not duplicated
        #expect(groups.first?.tabIDs.count == 2)
    }

    // MARK: - Delete Tests

    @Test("Delete removes group")
    func deleteRemovesGroup() async throws {
        let repo = MockGroupRepository()
        let windowID = "window-1"

        let group = makeSampleGroup(name: "Work")
        try await repo.save(group, windowID: windowID)

        try await repo.delete(groupID: group.id)

        let groups = try await repo.getAllGroups(windowID: windowID)
        #expect(groups.isEmpty)
    }

    @Test("Delete throws on non-existent group")
    func deleteThrowsOnNonExistentGroup() async throws {
        let repo = MockGroupRepository()

        await #expect(throws: StorageError.self) {
            try await repo.delete(groupID: UUID())
        }
    }

    @Test("Delete only affects target group")
    func deleteOnlyAffectsTargetGroup() async throws {
        let repo = MockGroupRepository()
        let windowID = "window-1"

        let group1 = makeSampleGroup(name: "Work")
        let group2 = makeSampleGroup(name: "Research")

        try await repo.save(group1, windowID: windowID)
        try await repo.save(group2, windowID: windowID)

        try await repo.delete(groupID: group1.id)

        let groups = try await repo.getAllGroups(windowID: windowID)
        #expect(groups.count == 1)
        #expect(groups.first?.name == "Research")
    }

    // MARK: - GetAllGroups Tests

    @Test("GetAllGroups returns empty for new window")
    func getAllGroupsReturnsEmptyForNewWindow() async throws {
        let repo = MockGroupRepository()

        let groups = try await repo.getAllGroups(windowID: "window-1")
        #expect(groups.isEmpty)
    }

    @Test("GetAllGroups returns all groups for window")
    func getAllGroupsReturnsAllGroupsForWindow() async throws {
        let repo = MockGroupRepository()
        let windowID = "window-1"

        let group1 = makeSampleGroup(name: "Work")
        let group2 = makeSampleGroup(name: "Research")
        let group3 = makeSampleGroup(name: "Shopping")

        try await repo.save(group1, windowID: windowID)
        try await repo.save(group2, windowID: windowID)
        try await repo.save(group3, windowID: windowID)

        let groups = try await repo.getAllGroups(windowID: windowID)
        #expect(groups.count == 3)
    }

    @Test("GetAllGroups isolates windows")
    func getAllGroupsIsolatesWindows() async throws {
        let repo = MockGroupRepository()

        let group1 = makeSampleGroup(name: "Work")
        try await repo.save(group1, windowID: "window-1")

        let group2 = makeSampleGroup(name: "Research")
        try await repo.save(group2, windowID: "window-2")

        let window1Groups = try await repo.getAllGroups(windowID: "window-1")
        let window2Groups = try await repo.getAllGroups(windowID: "window-2")

        #expect(window1Groups.count == 1)
        #expect(window2Groups.count == 1)
        #expect(window1Groups.first?.name == "Work")
        #expect(window2Groups.first?.name == "Research")
    }

    // MARK: - GetGroup Tests

    @Test("GetGroup returns group by ID")
    func getGroupReturnsGroupByID() async throws {
        let repo = MockGroupRepository()
        let windowID = "window-1"

        let group = makeSampleGroup(name: "Work")
        try await repo.save(group, windowID: windowID)

        let retrieved = try await repo.getGroup(groupID: group.id)
        #expect(retrieved?.id == group.id)
        #expect(retrieved?.name == "Work")
    }

    @Test("GetGroup returns nil for non-existent ID")
    func getGroupReturnsNilForNonExistentID() async throws {
        let repo = MockGroupRepository()

        let retrieved = try await repo.getGroup(groupID: UUID())
        #expect(retrieved == nil)
    }

    // MARK: - Update Tests

    @Test("Update modifies existing group")
    func updateModifiesExistingGroup() async throws {
        let repo = MockGroupRepository()
        let windowID = "window-1"

        let group = makeSampleGroup(name: "Work", tabIDs: ["tab-1"])
        try await repo.save(group, windowID: windowID)

        let updatedGroup = try group.withName("Work Projects")
        try await repo.update(updatedGroup, windowID: windowID)

        let retrieved = try await repo.getGroup(groupID: group.id)
        #expect(retrieved?.name == "Work Projects")
    }

    @Test("Update throws on non-existent group")
    func updateThrowsOnNonExistentGroup() async throws {
        let repo = MockGroupRepository()
        let windowID = "window-1"

        let group = makeSampleGroup(name: "Work")

        await #expect(throws: StorageError.self) {
            try await repo.update(group, windowID: windowID)
        }
    }

    @Test("Update prevents duplicate names (FR-006)")
    func updatePreventsDuplicateNames() async throws {
        let repo = MockGroupRepository()
        let windowID = "window-1"

        let group1 = makeSampleGroup(name: "Work")
        let group2 = makeSampleGroup(name: "Research")

        try await repo.save(group1, windowID: windowID)
        try await repo.save(group2, windowID: windowID)

        // Try to rename group2 to "Work" (duplicate)
        let renamedGroup = try group2.withName("Work")

        await #expect(throws: StorageError.self) {
            try await repo.update(renamedGroup, windowID: windowID)
        }
    }

    // MARK: - ObserveGroups Tests

    @Test("ObserveGroups emits initial state")
    func observeGroupsEmitsInitialState() async throws {
        let repo = MockGroupRepository()
        let windowID = "window-1"

        let group = makeSampleGroup(name: "Work")
        try await repo.save(group, windowID: windowID)

        var receivedGroups: [TabGroup] = []
        let stream = repo.observeGroups(windowID: windowID)

        for await groups in stream {
            receivedGroups = groups
            break // Get first emission
        }

        #expect(receivedGroups.count == 1)
        #expect(receivedGroups.first?.name == "Work")
    }

    @Test("ObserveGroups emits on save")
    func observeGroupsEmitsOnSave() async throws {
        let repo = MockGroupRepository()
        let windowID = "window-1"

        var emissionCount = 0
        let stream = repo.observeGroups(windowID: windowID)

        Task {
            for await groups in stream {
                emissionCount += 1
                if emissionCount == 2 {
                    break
                }
            }
        }

        // Wait for initial emission
        try await Task.sleep(for: .milliseconds(100))

        // Trigger change
        let group = makeSampleGroup(name: "Work")
        try await repo.save(group, windowID: windowID)

        // Wait for second emission
        try await Task.sleep(for: .milliseconds(100))

        #expect(emissionCount == 2)
    }

    @Test("ObserveGroups emits on delete")
    func observeGroupsEmitsOnDelete() async throws {
        let repo = MockGroupRepository()
        let windowID = "window-1"

        let group = makeSampleGroup(name: "Work")
        try await repo.save(group, windowID: windowID)

        var latestGroups: [TabGroup] = []
        let stream = repo.observeGroups(windowID: windowID)

        Task {
            for await groups in stream {
                latestGroups = groups
            }
        }

        // Wait for initial emission
        try await Task.sleep(for: .milliseconds(100))

        // Delete group
        try await repo.delete(groupID: group.id)

        // Wait for emission
        try await Task.sleep(for: .milliseconds(100))

        #expect(latestGroups.isEmpty)
    }

    // MARK: - Bulk Operations Tests

    @Test("DeleteAllGroups removes all groups for window")
    func deleteAllGroupsRemovesAllGroupsForWindow() async throws {
        let repo = MockGroupRepository()
        let windowID = "window-1"

        let group1 = makeSampleGroup(name: "Work")
        let group2 = makeSampleGroup(name: "Research")

        try await repo.save(group1, windowID: windowID)
        try await repo.save(group2, windowID: windowID)

        try await repo.deleteAllGroups(windowID: windowID)

        let groups = try await repo.getAllGroups(windowID: windowID)
        #expect(groups.isEmpty)
    }

    @Test("DeleteAllGroups only affects target window")
    func deleteAllGroupsOnlyAffectsTargetWindow() async throws {
        let repo = MockGroupRepository()

        let group1 = makeSampleGroup(name: "Work")
        try await repo.save(group1, windowID: "window-1")

        let group2 = makeSampleGroup(name: "Research")
        try await repo.save(group2, windowID: "window-2")

        try await repo.deleteAllGroups(windowID: "window-1")

        let window1Groups = try await repo.getAllGroups(windowID: "window-1")
        let window2Groups = try await repo.getAllGroups(windowID: "window-2")

        #expect(window1Groups.isEmpty)
        #expect(window2Groups.count == 1)
    }

    @Test("GetGroupCount returns correct count")
    func getGroupCountReturnsCorrectCount() async throws {
        let repo = MockGroupRepository()
        let windowID = "window-1"

        let count1 = try await repo.getGroupCount(windowID: windowID)
        #expect(count1 == 0)

        let group1 = makeSampleGroup(name: "Work")
        try await repo.save(group1, windowID: windowID)

        let count2 = try await repo.getGroupCount(windowID: windowID)
        #expect(count2 == 1)

        let group2 = makeSampleGroup(name: "Research")
        try await repo.save(group2, windowID: windowID)

        let count3 = try await repo.getGroupCount(windowID: windowID)
        #expect(count3 == 2)
    }
}
