//
//  GroupListViewTests.swift
//  TabOrganizerUITests
//
//  Tests for GroupListView SwiftUI component.
//  Verifies UI state, user interactions, and accessibility.
//

import Testing
import SwiftUI
@testable import TabOrganizerUI
@testable import TabOrganizerCore
@testable import TabOrganizerStorage
@testable import TabOrganizerSafariAPI

/// Tests for GroupListView component.
///
/// **Note**: These are logic tests for the view's state management.
/// Visual testing is done via SwiftUI Previews (TDD approach).
@Suite("GroupListView Tests")
@MainActor
struct GroupListViewTests {

    // MARK: - Test Fixtures

    func makeTestState() -> ExtensionState {
        let repo = MockGroupRepository()
        let tabManager = MockTabManager.withSampleTabs()
        let storage = MockStorageAdapter()

        let groupService = TabGroupService(repository: repo, tabManager: tabManager)
        let trackingService = TabTrackingService(storage: storage)

        return ExtensionState(
            groupService: groupService,
            trackingService: trackingService
        )
    }

    // MARK: - State Management Tests

    @Test("ExtensionState initializes with empty groups")
    func stateInitializesWithEmptyGroups() {
        let state = makeTestState()

        #expect(state.groupService.groups.isEmpty)
        #expect(state.currentTabs.isEmpty)
        #expect(!state.isLoading)
    }

    @Test("ExtensionState loads initial state")
    func stateLoadsInitialState() async throws {
        let state = makeTestState()

        // Add sample group
        _ = try await state.groupService.createGroup(
            name: "Work",
            color: "#0066CC",
            windowID: state.currentWindowID
        )

        await state.loadInitialState()

        #expect(state.groupService.groups.count == 1)
        #expect(state.groupService.groups.first?.name == "Work")
    }

    @Test("ExtensionState handles group creation")
    func stateHandlesGroupCreation() async throws {
        let state = makeTestState()

        state.showCreateGroup()

        #expect(state.isPresentingGroupEditor)
        #expect(state.groupBeingEdited == nil) // nil = create mode
    }

    @Test("ExtensionState handles group editing")
    func stateHandlesGroupEditing() async throws {
        let state = makeTestState()

        let group = try await state.groupService.createGroup(
            name: "Work",
            color: "#0066CC",
            windowID: state.currentWindowID
        )

        state.showEditGroup(group)

        #expect(state.isPresentingGroupEditor)
        #expect(state.groupBeingEdited?.id == group.id)
    }

    @Test("ExtensionState filters groups by search text")
    func stateFiltersGroupsBySearchText() async throws {
        let state = makeTestState()

        _ = try await state.groupService.createGroup(name: "Work", color: "#0066CC", windowID: state.currentWindowID)
        _ = try await state.groupService.createGroup(name: "Research", color: "#00CC66", windowID: state.currentWindowID)
        _ = try await state.groupService.createGroup(name: "Shopping", color: "#FF6600", windowID: state.currentWindowID)

        await state.loadInitialState()

        // No filter
        #expect(state.filteredGroups.count == 3)

        // Filter by "work"
        state.searchText = "work"
        #expect(state.filteredGroups.count == 1)
        #expect(state.filteredGroups.first?.name == "Work")

        // Filter by "re" (matches Research)
        state.searchText = "re"
        #expect(state.filteredGroups.count == 1)
        #expect(state.filteredGroups.first?.name == "Research")

        // Clear filter
        state.searchText = ""
        #expect(state.filteredGroups.count == 3)
    }

    @Test("ExtensionState tracks tab selection")
    func stateTracksTabSelection() {
        let state = makeTestState()

        #expect(state.selectedTabIDs.isEmpty)
        #expect(!state.hasSelection)

        state.toggleTabSelection("tab-1")
        #expect(state.selectedTabIDs.contains("tab-1"))
        #expect(state.hasSelection)
        #expect(state.selectedCount == 1)

        state.toggleTabSelection("tab-2")
        #expect(state.selectedCount == 2)

        state.toggleTabSelection("tab-1") // Deselect
        #expect(state.selectedCount == 1)
        #expect(!state.selectedTabIDs.contains("tab-1"))

        state.clearSelection()
        #expect(state.selectedTabIDs.isEmpty)
        #expect(!state.hasSelection)
    }

    @Test("ExtensionState identifies ungrouped tabs")
    func stateIdentifiesUngroupedTabs() async throws {
        let state = makeTestState()

        // Set up current tabs
        state.currentTabs = [
            TabInfo(id: "tab-1", url: URL(string: "https://github.com")!, title: "GitHub", windowID: "window-1", index: 0),
            TabInfo(id: "tab-2", url: URL(string: "https://stackoverflow.com")!, title: "Stack Overflow", windowID: "window-1", index: 1),
            TabInfo(id: "tab-3", url: URL(string: "https://apple.com")!, title: "Apple", windowID: "window-1", index: 2)
        ]

        // All tabs ungrouped initially
        #expect(state.ungroupedTabs.count == 3)

        // Create group with tab-1
        _ = try await state.groupService.createGroup(
            name: "Work",
            color: "#0066CC",
            tabIDs: ["tab-1"],
            windowID: state.currentWindowID
        )
        await state.loadInitialState()

        // Now only tab-2 and tab-3 are ungrouped
        #expect(state.ungroupedTabs.count == 2)
        #expect(state.ungroupedTabs.contains { $0.id == "tab-2" })
        #expect(state.ungroupedTabs.contains { $0.id == "tab-3" })
        #expect(!state.ungroupedTabs.contains { $0.id == "tab-1" })
    }

    @Test("ExtensionState handles errors")
    func stateHandlesErrors() {
        let state = makeTestState()

        #expect(state.errorMessage == nil)
        #expect(!state.showError)

        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        state.handleError(testError)

        #expect(state.errorMessage == "Test error")
        #expect(state.showError)

        state.clearError()
        #expect(state.errorMessage == nil)
        #expect(!state.showError)
    }

    // MARK: - View Mode Tests

    @Test("ViewMode provides correct icons")
    func viewModeIconsAreCorrect() {
        #expect(ViewMode.grouped.icon == "square.stack.3d.up.fill")
        #expect(ViewMode.list.icon == "list.bullet")
        #expect(ViewMode.grid.icon == "square.grid.2x2")
    }

    @Test("ViewMode raw values are human readable")
    func viewModeRawValuesAreReadable() {
        #expect(ViewMode.grouped.rawValue == "Grouped")
        #expect(ViewMode.list.rawValue == "List")
        #expect(ViewMode.grid.rawValue == "Grid")
    }

    // MARK: - Integration Tests

    @Test("State coordinates create-load-display flow")
    func stateCoordinatesFullFlow() async throws {
        let state = makeTestState()

        // 1. Create group via service
        let group = try await state.groupService.createGroup(
            name: "Work",
            color: "#0066CC",
            tabIDs: ["tab-1", "tab-2"],
            windowID: state.currentWindowID
        )

        // 2. Load into state
        await state.loadInitialState()

        // 3. Verify state reflects creation
        #expect(state.groupService.groups.count == 1)
        #expect(state.groupService.groups.first?.id == group.id)

        // 4. Filter should work
        state.searchText = "Work"
        #expect(state.filteredGroups.count == 1)

        // 5. Selection should work
        state.toggleTabSelection("tab-1")
        #expect(state.selectedCount == 1)
    }

    @Test("State handles multiple groups correctly")
    func stateHandlesMultipleGroups() async throws {
        let state = makeTestState()

        _ = try await state.groupService.createGroup(name: "Work", color: "#0066CC", windowID: state.currentWindowID)
        _ = try await state.groupService.createGroup(name: "Research", color: "#00CC66", windowID: state.currentWindowID)
        _ = try await state.groupService.createGroup(name: "Shopping", color: "#FF6600", windowID: state.currentWindowID)

        await state.loadInitialState()

        #expect(state.groupService.groups.count == 3)

        // Search for specific group
        state.searchText = "shop"
        #expect(state.filteredGroups.count == 1)
        #expect(state.filteredGroups.first?.name == "Shopping")
    }

    @Test("State refresh reloads data")
    func stateRefreshReloadsData() async throws {
        let state = makeTestState()

        // Initial load
        await state.loadInitialState()
        #expect(state.groupService.groups.isEmpty)

        // Create group externally
        _ = try await state.groupService.createGroup(
            name: "Work",
            color: "#0066CC",
            windowID: state.currentWindowID
        )

        // Refresh
        await state.refresh()

        // Should see new group
        #expect(state.groupService.groups.count == 1)
    }
}
