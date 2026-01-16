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
        let repo = MockAssociationRepository()
        let tabManager = MockTabManager.withSampleTabs()
        let storage = MockStorageAdapter()

        let associationService = TabAssociationService(repository: repo, tabManager: tabManager)
        let trackingService = TabTrackingService(storage: storage)

        return ExtensionState(
            associationService: associationService,
            trackingService: trackingService
        )
    }

    // MARK: - State Management Tests

    @Test("ExtensionState initializes with empty groups")
    func stateInitializesWithEmptyGroups() {
        let state = makeTestState()

        #expect(state.associationService.groups.isEmpty)
        #expect(state.currentTabs.isEmpty)
        #expect(!state.isLoading)
    }

    @Test("ExtensionState loads initial state")
    func stateLoadsInitialState() async throws {
        let state = makeTestState()

        // Add sample group
        _ = try await state.associationService.createGroup(
            name: "Work",
            color: "#0066CC",
            windowID: state.currentWindowID
        )

        await state.loadInitialState()

        #expect(state.associationService.groups.count == 1)
        #expect(state.associationService.groups.first?.name == "Work")
    }

    @Test("ExtensionState handles group creation")
    func stateHandlesGroupCreation() async throws {
        let state = makeTestState()

        state.showCreateAssociation()

        #expect(state.isPresentingGroupEditor)
        #expect(state.associationBeingEdited == nil) // nil = create mode
    }

    @Test("ExtensionState handles group editing")
    func stateHandlesGroupEditing() async throws {
        let state = makeTestState()

        let group = try await state.associationService.createGroup(
            name: "Work",
            color: "#0066CC",
            windowID: state.currentWindowID
        )

        state.showEditAssociation(group)

        #expect(state.isPresentingGroupEditor)
        #expect(state.associationBeingEdited?.id == group.id)
    }

    @Test("ExtensionState filters groups by search text")
    func stateFiltersGroupsBySearchText() async throws {
        let state = makeTestState()

        _ = try await state.associationService.createGroup(name: "Work", color: "#0066CC", windowID: state.currentWindowID)
        _ = try await state.associationService.createGroup(name: "Research", color: "#00CC66", windowID: state.currentWindowID)
        _ = try await state.associationService.createGroup(name: "Shopping", color: "#FF6600", windowID: state.currentWindowID)

        await state.loadInitialState()

        // No filter
        #expect(state.filteredAssociations.count == 3)

        // Filter by "work"
        state.searchText = "work"
        #expect(state.filteredAssociations.count == 1)
        #expect(state.filteredAssociations.first?.name == "Work")

        // Filter by "re" (matches Research)
        state.searchText = "re"
        #expect(state.filteredAssociations.count == 1)
        #expect(state.filteredAssociations.first?.name == "Research")

        // Clear filter
        state.searchText = ""
        #expect(state.filteredAssociations.count == 3)
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
        _ = try await state.associationService.createGroup(
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
        let group = try await state.associationService.createGroup(
            name: "Work",
            color: "#0066CC",
            tabIDs: ["tab-1", "tab-2"],
            windowID: state.currentWindowID
        )

        // 2. Load into state
        await state.loadInitialState()

        // 3. Verify state reflects creation
        #expect(state.associationService.groups.count == 1)
        #expect(state.associationService.groups.first?.id == group.id)

        // 4. Filter should work
        state.searchText = "Work"
        #expect(state.filteredAssociations.count == 1)

        // 5. Selection should work
        state.toggleTabSelection("tab-1")
        #expect(state.selectedCount == 1)
    }

    @Test("State handles multiple groups correctly")
    func stateHandlesMultipleGroups() async throws {
        let state = makeTestState()

        _ = try await state.associationService.createGroup(name: "Work", color: "#0066CC", windowID: state.currentWindowID)
        _ = try await state.associationService.createGroup(name: "Research", color: "#00CC66", windowID: state.currentWindowID)
        _ = try await state.associationService.createGroup(name: "Shopping", color: "#FF6600", windowID: state.currentWindowID)

        await state.loadInitialState()

        #expect(state.associationService.groups.count == 3)

        // Search for specific group
        state.searchText = "shop"
        #expect(state.filteredAssociations.count == 1)
        #expect(state.filteredAssociations.first?.name == "Shopping")
    }

    @Test("State refresh reloads data")
    func stateRefreshReloadsData() async throws {
        let state = makeTestState()

        // Initial load
        await state.loadInitialState()
        #expect(state.associationService.groups.isEmpty)

        // Create group externally
        _ = try await state.associationService.createGroup(
            name: "Work",
            color: "#0066CC",
            windowID: state.currentWindowID
        )

        // Refresh
        await state.refresh()

        // Should see new group
        #expect(state.associationService.groups.count == 1)
    }

    // MARK: - Drag-and-Drop Tests (T044)

    @Test("DragDropManager handles tab-onto-tab drop for new association creation")
    func dragDropManagerCreatesNewAssociation() {
        let manager = DragDropManager()

        // Drag ungrouped tab onto another ungrouped tab
        manager.beginDragTab(tabID: "tab-1", fromAssociationID: nil)
        let result = manager.handleDrop(on: .tab(id: "tab-2", inAssociationID: nil))

        // Should create new association
        #expect(result == .createNewAssociation(tab1: "tab-1", tab2: "tab-2"))
    }

    @Test("DragDropManager handles tab-onto-association-member drop")
    func dragDropManagerAddsToExistingAssociation() {
        let manager = DragDropManager()
        let associationID = UUID()

        // Drag ungrouped tab onto a tab that's in an association
        manager.beginDragTab(tabID: "tab-1", fromAssociationID: nil)
        let result = manager.handleDrop(on: .tab(id: "tab-2", inAssociationID: associationID))

        // Should add to existing association
        #expect(result == .addToAssociation(tabID: "tab-1", associationID: associationID, fromAssociationID: nil))
    }

    @Test("DragDropManager handles tab-onto-association-header drop")
    func dragDropManagerAddsToAssociationViaHeader() {
        let manager = DragDropManager()
        let associationID = UUID()

        // Drag ungrouped tab onto association header
        manager.beginDragTab(tabID: "tab-1", fromAssociationID: nil)
        let result = manager.handleDrop(on: .association(id: associationID))

        // Should add to association
        #expect(result == .addToAssociation(tabID: "tab-1", associationID: associationID, fromAssociationID: nil))
    }

    @Test("DragDropManager handles tab-to-empty-area drop")
    func dragDropManagerRemovesFromAssociation() {
        let manager = DragDropManager()
        let associationID = UUID()

        // Drag grouped tab to empty area
        manager.beginDragTab(tabID: "tab-1", fromAssociationID: associationID)
        let result = manager.handleDrop(on: .emptyArea)

        // Should remove from association
        #expect(result == .removeFromAssociation(tabID: "tab-1", fromAssociationID: associationID))
    }

    @Test("DragDropManager handles association merge via header drag")
    func dragDropManagerMergesAssociations() {
        let manager = DragDropManager()
        let sourceID = UUID()
        let targetID = UUID()

        // Drag association header onto another association header
        manager.beginDragAssociation(associationID: sourceID)
        let result = manager.handleDrop(on: .association(id: targetID))

        // Should merge associations
        #expect(result == .mergeAssociations(source: sourceID, target: targetID))
    }

    @Test("DragDropManager prevents self-merge of associations")
    func dragDropManagerPreventsSelfMerge() {
        let manager = DragDropManager()
        let associationID = UUID()

        // Drag association header onto itself
        manager.beginDragAssociation(associationID: associationID)
        let result = manager.handleDrop(on: .association(id: associationID))

        // Should be no-op
        #expect(result == .noAction)
    }

    @Test("DragDropManager validates drop targets")
    func dragDropManagerValidatesDropTargets() {
        let manager = DragDropManager()
        let associationID = UUID()

        // Tab can be dropped on other tabs
        manager.beginDragTab(tabID: "tab-1", fromAssociationID: nil)
        #expect(manager.isValidDropTarget(.tab(id: "tab-2", inAssociationID: nil)))
        #expect(manager.isValidDropTarget(.association(id: associationID)))
        #expect(manager.isValidDropTarget(.emptyArea))

        // Association can only be dropped on other associations
        manager.beginDragAssociation(associationID: associationID)
        let otherAssocID = UUID()
        #expect(manager.isValidDropTarget(.association(id: otherAssocID)))
        #expect(!manager.isValidDropTarget(.tab(id: "tab-1", inAssociationID: nil)))
        #expect(!manager.isValidDropTarget(.emptyArea))

        // Self-drop is invalid
        #expect(!manager.isValidDropTarget(.association(id: associationID)))
    }

    @Test("DragDropManager tracks drag state")
    func dragDropManagerTracksDragState() {
        let manager = DragDropManager()

        // No drag initially
        #expect(!manager.isDragging)
        #expect(manager.currentDragItem == nil)

        // Begin dragging tab
        manager.beginDragTab(tabID: "tab-1", fromAssociationID: nil)
        #expect(manager.isDragging)

        // End drag
        manager.endDrag()
        #expect(!manager.isDragging)
        #expect(manager.currentDragItem == nil)
    }

    @Test("DragDropManager handles tab movement between associations")
    func dragDropManagerMovesTabBetweenAssociations() {
        let manager = DragDropManager()
        let fromAssocID = UUID()
        let toAssocID = UUID()

        // Drag tab from one association to another
        manager.beginDragTab(tabID: "tab-1", fromAssociationID: fromAssocID)
        let result = manager.handleDrop(on: .association(id: toAssocID))

        // Should add to target, with source tracked for removal
        #expect(result == .addToAssociation(tabID: "tab-1", associationID: toAssocID, fromAssociationID: fromAssocID))
    }

    @Test("DragDropManager handles complex tab-onto-tab scenarios")
    func dragDropManagerHandlesComplexTabScenarios() {
        let manager = DragDropManager()
        let fromAssocID = UUID()
        let targetAssocID = UUID()

        // Case 1: Grouped tab onto ungrouped tab
        // Should add the ungrouped tab to the association
        manager.beginDragTab(tabID: "tab-1", fromAssociationID: fromAssocID)
        let result1 = manager.handleDrop(on: .tab(id: "tab-2", inAssociationID: nil))
        #expect(result1 == .addToAssociation(tabID: "tab-2", associationID: fromAssocID, fromAssociationID: nil))

        // Case 2: Ungrouped tab onto grouped tab
        // Should add the dragged tab to the target's association
        manager.beginDragTab(tabID: "tab-1", fromAssociationID: nil)
        let result2 = manager.handleDrop(on: .tab(id: "tab-2", inAssociationID: targetAssocID))
        #expect(result2 == .addToAssociation(tabID: "tab-1", associationID: targetAssocID, fromAssociationID: nil))

        // Case 3: Both tabs ungrouped
        // Should create new association
        manager.beginDragTab(tabID: "tab-1", fromAssociationID: nil)
        let result3 = manager.handleDrop(on: .tab(id: "tab-2", inAssociationID: nil))
        #expect(result3 == .createNewAssociation(tab1: "tab-1", tab2: "tab-2"))
    }

    @Test("DragDropManager ends drag after handling drop")
    func dragDropManagerEndsDragAfterDrop() {
        let manager = DragDropManager()

        manager.beginDragTab(tabID: "tab-1", fromAssociationID: nil)
        #expect(manager.isDragging)

        _ = manager.handleDrop(on: .tab(id: "tab-2", inAssociationID: nil))

        // Drag should end automatically
        #expect(!manager.isDragging)
        #expect(manager.currentDragItem == nil)
    }

    @Test("DragDropManager returns noAction when no drag is active")
    func dragDropManagerHandlesNoDragState() {
        let manager = DragDropManager()

        // No active drag
        let result = manager.handleDrop(on: .tab(id: "tab-1", inAssociationID: nil))

        #expect(result == .noAction)
    }

    @Test("Integration: Full drag-and-drop workflow")
    func fullDragDropWorkflow() async throws {
        let state = makeTestState()

        // Set up tabs
        state.currentTabs = [
            TabInfo(id: "tab-1", url: URL(string: "https://github.com")!, title: "GitHub", windowID: "window-1", index: 0),
            TabInfo(id: "tab-2", url: URL(string: "https://stackoverflow.com")!, title: "Stack Overflow", windowID: "window-1", index: 1),
            TabInfo(id: "tab-3", url: URL(string: "https://apple.com")!, title: "Apple", windowID: "window-1", index: 2)
        ]

        // 1. Create association by dragging tab-1 onto tab-2
        let association = try await state.associationService.createAssociation(
            name: "Development",
            color: "#0066CC",
            tabIDs: ["tab-1", "tab-2"],
            windowID: state.currentWindowID
        )
        await state.loadInitialState()

        #expect(state.associationService.groups.count == 1)
        #expect(association.tabIDs.contains("tab-1"))
        #expect(association.tabIDs.contains("tab-2"))
        #expect(state.ungroupedTabs.count == 1)

        // 2. Add tab-3 to the association
        try await state.associationService.addTabToAssociation(
            tabID: "tab-3",
            associationID: association.id,
            windowID: state.currentWindowID
        )
        await state.refresh()

        #expect(state.associationService.groups.first?.tabIDs.count == 3)
        #expect(state.ungroupedTabs.isEmpty)

        // 3. Remove tab-3 from association
        try await state.associationService.removeTabFromAssociation(
            tabID: "tab-3",
            associationID: association.id,
            windowID: state.currentWindowID
        )
        await state.refresh()

        #expect(state.associationService.groups.first?.tabIDs.count == 2)
        #expect(state.ungroupedTabs.count == 1)
        #expect(state.ungroupedTabs.first?.id == "tab-3")
    }
}
