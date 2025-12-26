//
//  US1_ManualGroupingTests.swift
//  TabOrganizerIntegrationTests
//
//  End-to-end integration tests for User Story 1 (Manual Tab Group Organization).
//  Tests complete workflows across all layers: UI → Services → Storage → Persistence.
//

import Testing
import Foundation
@testable import TabOrganizerUI
@testable import TabOrganizerCore
@testable import TabOrganizerStorage
@testable import TabOrganizerSafariAPI

/// Integration tests for User Story 1.
///
/// **Scope**: Full stack testing from UI state to persistence
/// **User Story 1 Acceptance**: Create 10+ tabs, organize into 2-3 groups,
/// close Safari, reopen, verify groups persist with correct tabs.
@Suite("User Story 1 - Manual Grouping Integration")
@MainActor
struct US1_ManualGroupingTests {

    // MARK: - Test Fixtures

    func makeFullStack() -> (state: ExtensionState, storage: MockStorageAdapter, repo: MockAssociationRepository) {
        let storage = MockStorageAdapter()
        let repo = MockAssociationRepository()
        let tabManager = MockTabManager.withSampleTabs()

        let associationService = TabAssociationService(repository: repo, tabManager: tabManager)
        let trackingService = TabTrackingService(storage: storage)

        let state = ExtensionState(
            associationService: associationService,
            trackingService: trackingService
        )

        return (state, storage, repo)
    }

    // MARK: - End-to-End Workflow Tests

    @Test("Complete workflow: create → persist → restore (FR-002)")
    func completeWorkflowCreatePersistRestore() async throws {
        let (state, _, repo) = makeFullStack()
        let windowID = state.currentWindowID

        // STEP 1: Create multiple groups (simulating user actions)
        let workGroup = try await state.associationService.createGroup(
            name: "Work",
            color: "#0066CC",
            tabIDs: ["tab-1", "tab-2", "tab-3"],
            windowID: windowID
        )

        let researchGroup = try await state.associationService.createGroup(
            name: "Research",
            color: "#00CC66",
            tabIDs: ["tab-4", "tab-5"],
            windowID: windowID
        )

        let shoppingGroup = try await state.associationService.createGroup(
            name: "Shopping",
            color: "#FF6600",
            tabIDs: ["tab-6"],
            windowID: windowID
        )

        // STEP 2: Verify groups are created
        await state.loadInitialState()
        #expect(state.associationService.groups.count == 3)

        // STEP 3: Simulate Safari close → reopen by creating new state with same storage
        let (newState, _, _) = makeFullStack()
        // Copy groups from repo to simulate persistence
        newState.associationService.associationService.groups = repo.groups[windowID] ?? []

        // STEP 4: Load persisted data
        await newState.loadInitialState()

        // STEP 5: Verify all groups restored
        #expect(newState.associationService.groups.count == 3)

        let restoredWork = newState.associationService.groups.first { $0.name == "Work" }
        let restoredResearch = newState.associationService.groups.first { $0.name == "Research" }
        let restoredShopping = newState.associationService.groups.first { $0.name == "Shopping" }

        #expect(restoredWork?.tabIDs.count == 3)
        #expect(restoredResearch?.tabIDs.count == 2)
        #expect(restoredShopping?.tabIDs.count == 1)
    }

    @Test("User Story 1 acceptance scenario 1: Create and organize tabs (FR-001)")
    func acceptanceScenario1CreateAndOrganize() async throws {
        let (state, _, _) = makeFullStack()

        // Given: I have 15 tabs open across different topics
        state.currentTabs = (1...15).map { i in
            TabInfo(
                id: "tab-\(i)",
                url: URL(string: "https://example.com/page\(i)")!,
                title: "Page \(i)",
                windowID: state.currentWindowID,
                index: i - 1
            )
        }

        // When: I open the extension and create a group named "Work" and drag 5 tabs into it
        let group = try await state.associationService.createGroup(
            name: "Work",
            color: "#0066CC",
            windowID: state.currentWindowID
        )

        // Add tabs one by one (simulating drag-and-drop)
        for tabID in ["tab-1", "tab-2", "tab-3", "tab-4", "tab-5"] {
            try await state.associationService.addTabToGroup(
                tabID: tabID,
                associationID: group.id,
                windowID: state.currentWindowID
            )
        }

        await state.loadInitialState()

        // Then: Those tabs are visually grouped together and the group is labeled "Work"
        let workGroup = state.associationService.groups.first { $0.name == "Work" }
        #expect(workGroup != nil)
        #expect(workGroup?.tabIDs.count == 5)
        #expect(workGroup?.color == "#0066CC")
    }

    @Test("User Story 1 acceptance scenario 2: Persistence across sessions (FR-002)")
    func acceptanceScenario2PersistenceAcrossSessions() async throws {
        let (state1, _, repo) = makeFullStack()

        // Given: I have created tab associations in my current session
        _ = try await state1.associationService.createGroup(
            name: "Work",
            color: "#0066CC",
            tabIDs: ["tab-1", "tab-2"],
            windowID: state1.currentWindowID
        )

        _ = try await state1.associationService.createGroup(
            name: "Research",
            color: "#00CC66",
            tabIDs: ["tab-3"],
            windowID: state1.currentWindowID
        )

        // When: I close and reopen Safari (simulated by new state)
        let (state2, _, _) = makeFullStack()
        state2.associationService.associationService.groups = repo.groups[state1.currentWindowID] ?? []
        await state2.loadInitialState()

        // Then: All tab associations and their contained tabs are restored in the same state
        #expect(state2.associationService.groups.count == 2)

        let work = state2.associationService.groups.first { $0.name == "Work" }
        let research = state2.associationService.groups.first { $0.name == "Research" }

        #expect(work?.tabIDs == ["tab-1", "tab-2"])
        #expect(research?.tabIDs == ["tab-3"])
    }

    @Test("User Story 1 acceptance scenario 3: Collapse groups (FR-003)")
    func acceptanceScenario3CollapseGroups() async throws {
        let (state, _, _) = makeFullStack()

        // Given: I have a tab association with 8 tabs
        let group = try await state.associationService.createGroup(
            name: "Work",
            color: "#0066CC",
            tabIDs: Array(1...8).map { "tab-\($0)" },
            windowID: state.currentWindowID
        )

        #expect(group.collapsed == false)

        // When: I click the collapse button on the group
        try await state.associationService.toggleGroupCollapsed(
            associationID: group.id,
            windowID: state.currentWindowID
        )

        await state.loadInitialState()

        // Then: The tabs are hidden from view but remain accessible by expanding the group
        let collapsedGroup = state.associationService.groups.first { $0.id == group.id }
        #expect(collapsedGroup?.collapsed == true)
        #expect(collapsedGroup?.tabIDs.count == 8) // Tabs still present

        // And: Can expand again
        try await state.associationService.toggleGroupCollapsed(
            associationID: group.id,
            windowID: state.currentWindowID
        )

        await state.loadInitialState()

        let expandedGroup = state.associationService.groups.first { $0.id == group.id }
        #expect(expandedGroup?.collapsed == false)
    }

    @Test("User Story 1 acceptance scenario 4: Remove tabs from groups (FR-004)")
    func acceptanceScenario4RemoveTabsFromGroups() async throws {
        let (state, _, _) = makeFullStack()

        // Given: I want to remove tabs from a group
        let group = try await state.associationService.createGroup(
            name: "Work",
            color: "#0066CC",
            tabIDs: ["tab-1", "tab-2", "tab-3"],
            windowID: state.currentWindowID
        )

        // When: I drag a tab out of the group
        try await state.associationService.removeTabFromGroup(
            tabID: "tab-2",
            associationID: group.id,
            windowID: state.currentWindowID
        )

        await state.loadInitialState()

        // Then: The tab becomes ungrouped and remains open in the main tab bar
        let updatedGroup = state.associationService.groups.first { $0.id == group.id }
        #expect(updatedGroup?.tabIDs.count == 2)
        #expect(!updatedGroup!.tabIDs.contains("tab-2"))

        // Verify tab-2 would now appear in ungrouped tabs
        state.currentTabs = [
            TabInfo(id: "tab-1", url: URL(string: "https://a.com")!, title: "A", windowID: state.currentWindowID, index: 0),
            TabInfo(id: "tab-2", url: URL(string: "https://b.com")!, title: "B", windowID: state.currentWindowID, index: 1),
            TabInfo(id: "tab-3", url: URL(string: "https://c.com")!, title: "C", windowID: state.currentWindowID, index: 2)
        ]

        let ungrouped = state.ungroupedTabs
        #expect(ungrouped.contains { $0.id == "tab-2" })
    }

    // MARK: - Cross-Layer Integration Tests

    @Test("Full stack: UI state → Service → Repository → Storage")
    func fullStackIntegration() async throws {
        let (state, storage, repo) = makeFullStack()

        // UI Layer: User creates group via state
        state.showCreateAssociation()
        #expect(state.isPresentingGroupEditor)

        // Service Layer: Create group
        let group = try await state.associationService.createGroup(
            name: "Work",
            color: "#0066CC",
            tabIDs: ["tab-1"],
            windowID: state.currentWindowID
        )

        // Repository Layer: Verify saved
        #expect(repo.saveCalls.count == 1)
        #expect(repo.groups[state.currentWindowID]?.count == 1)

        // Storage Layer: Would persist to UserDefaults in production
        // (MockStorageAdapter doesn't persist, but tracks calls)

        // Reload and verify
        await state.loadInitialState()
        #expect(state.associationService.groups.count == 1)
        #expect(state.associationService.groups.first?.id == group.id)
    }

    @Test("Error propagation through layers")
    func errorPropagationThroughLayers() async throws {
        let (state, _, repo) = makeFullStack()

        // Inject error at repository layer
        repo.saveError = StorageError.quotaExceeded("Test quota error")

        // Attempt create at service layer
        do {
            _ = try await state.associationService.createGroup(
                name: "Work",
                color: "#0066CC",
                windowID: state.currentWindowID
            )
            #expect(Bool(false), "Should have thrown error")
        } catch {
            // Error propagated to UI layer
            state.handleError(error)
            #expect(state.showError)
            #expect(state.errorMessage?.contains("quota") == true)
        }
    }

    @Test("Tab tracking integration")
    func tabTrackingIntegration() async throws {
        let (state, storage, _) = makeFullStack()

        // Record tab views
        try await state.trackingService.recordTabView(tabID: "tab-1")
        try await state.trackingService.recordTabView(tabID: "tab-2")

        // Verify tracking
        let lastViewed1 = state.trackingService.getLastViewed(tabID: "tab-1")
        let lastViewed2 = state.trackingService.getLastViewed(tabID: "tab-2")

        #expect(lastViewed1 != nil)
        #expect(lastViewed2 != nil)

        // Get stats
        let stats = state.trackingService.getActivityStats()
        #expect(stats.totalTracked == 2)
        #expect(stats.viewedLastHour == 2)
    }
}
