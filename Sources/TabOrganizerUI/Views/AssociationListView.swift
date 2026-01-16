//
//  GroupListView.swift
//  TabOrganizerUI
//
//  Main view displaying all tab associations and their tabs.
//  Primary UI for User Story 1 (Manual Tab Group Organization).
//

import SwiftUI
import TabOrganizerCore
import TabOrganizerSafariAPI
import TabOrganizerUI

/// Main view for displaying and managing tab associations.
///
/// **User Story 1 (FR-001 to FR-006)**: Manual tab association organization
/// - Display all groups with tabs
/// - Collapse/expand groups
/// - Drag-and-drop tab organization
/// - Create, edit, delete groups
///
/// **TDD Approach**: See Preview at bottom for visual testing with realistic states.
public struct GroupListView: View {

    // MARK: - Environment

    @Environment(ExtensionState.self) private var state

    // MARK: - State

    @State private var showDeleteConfirmation: Bool = false
    @State private var groupToDelete: TabAssociation?
    @State private var showConvertConfirmation: Bool = false
    @State private var groupToConvert: TabAssociation?

    // Drag-and-drop state (T042)
    @State private var dragDropManager = DragDropManager()
    @State private var showNewAssociationDialog: Bool = false
    @State private var newAssociationTabs: (String, String)?

    // Association merge state (T042.1)
    @State private var showMergeDialog: Bool = false
    @State private var mergeAssociationIDs: (source: UUID, target: UUID)?

    // MARK: - Initialization

    public init() {}

    // MARK: - Body

    public var body: some View {
        @Bindable var bindableState = state

        VStack(spacing: 0) {
            // Header with search and actions
            headerView(bindableState: state)

            Divider()

            // Main content
            if state.associationService.isLoading {
                loadingView
            } else if state.filteredAssociations.isEmpty && state.ungroupedTabs.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                        // Grouped tabs
                        ForEach(state.filteredAssociations) { group in
                            groupSection(for: group)
                        }

                        // Ungrouped tabs
                        if !state.ungroupedTabs.isEmpty {
                            ungroupedSection
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $bindableState.isPresentingGroupEditor) {
            GroupEditorView(
                group: state.associationBeingEdited,
                windowID: state.currentWindowID
            )
        }
        .sheet(isPresented: $bindableState.isPresentingSettings) {
            SettingsView()
        }
        .alert("Delete Group", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let group = groupToDelete {
                    deleteAssociation(group)
                }
            }
        } message: {
            if let group = groupToDelete {
                Text("Are you sure you want to delete '\(group.name)'? Tabs will not be closed.")
            }
        }
        .alert("Convert to Native", isPresented: $showConvertConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Convert") {
                if let group = groupToConvert {
                    convertToNative(group)
                }
            }
        } message: {
            if let group = groupToConvert {
                Text("Convert '\(group.name)' to a native Safari tab association? This action cannot be undone.")
            }
        }
        .sheet(isPresented: $showNewAssociationDialog) {
            if let (tab1ID, tab2ID) = newAssociationTabs,
               let tab1 = state.currentTabs.first(where: { $0.id == tab1ID }),
               let tab2 = state.currentTabs.first(where: { $0.id == tab2ID }) {
                NewAssociationDialog(
                    tab1: tab1,
                    tab2: tab2,
                    onCreate: { name, color in
                        createNewAssociation(name: name, color: color, tab1: tab1ID, tab2: tab2ID)
                        showNewAssociationDialog = false
                    },
                    onCancel: {
                        showNewAssociationDialog = false
                    }
                )
            }
        }
        .sheet(isPresented: $showMergeDialog) {
            if let (sourceID, targetID) = mergeAssociationIDs,
               let sourceAssociation = state.filteredAssociations.first(where: { $0.id == sourceID }),
               let targetAssociation = state.filteredAssociations.first(where: { $0.id == targetID }) {
                MergeAssociationsDialog(
                    sourceAssociation: sourceAssociation,
                    targetAssociation: targetAssociation,
                    onMerge: {
                        mergeAssociations(sourceID: sourceID, targetID: targetID)
                        showMergeDialog = false
                    },
                    onCancel: {
                        showMergeDialog = false
                    }
                )
            }
        }
        .task {
            await state.loadInitialState()
        }
        // MARK: - Accessibility
        .accessibilityLabel("Tab associations list")
        .accessibilityIdentifier("GroupListView")
    }

    // MARK: - Subviews

    /// Header with search and create button.
    @ViewBuilder
    private func headerView(bindableState: ExtensionState) -> some View {
        @Bindable var bindableState = bindableState
        HStack(spacing: 12) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))

                TextField("Search groups", text: $bindableState.searchText)
                    .textFieldStyle(.plain)
                    .accessibilityLabel("Search groups")

                if !state.searchText.isEmpty {
                    Button {
                        state.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )

            // Create group button
            Button {
                state.showCreateAssociation()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create new group")

            // Settings button
            Button {
                state.showSettings()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding()
    }

    /// Loading state view.
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading groups...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Loading groups")
    }

    /// Empty state when no groups exist.
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Tab Groups")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create a group to organize your tabs")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                state.showCreateAssociation()
            } label: {
                Label("Create Group", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Create first group")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    /// Section for a single group with its tabs.
    @ViewBuilder
    private func groupSection(for group: TabAssociation) -> some View {
        Section {
            if !group.collapsed {
                // Tabs in this group
                let groupTabs = state.currentTabs.filter { group.tabIDs.contains($0.id) }

                if groupTabs.isEmpty {
                    emptyGroupView
                } else {
                    ForEach(groupTabs) { tab in
                        TabCard(
                            tab: tab,
                            isSelected: state.selectedTabIDs.contains(tab.id),
                            onTap: {
                                state.toggleTabSelection(tab.id)
                            },
                            onActivate: {
                                activateTab(tab)
                            }
                        )
                        .draggable(fromAssociationID: group.id)
                        .dropDestination(for: DraggableTab.self) { items, location in
                            handleTabDrop(items: items, targetTab: tab.id, targetAssociation: group.id)
                        }
                    }
                }
            }
        } header: {
            GroupHeader(
                group: group,
                tabCount: group.tabIDs.count,
                onToggleCollapse: {
                    toggleCollapse(group)
                },
                onEdit: {
                    editGroup(group)
                },
                onDelete: {
                    confirmDelete(group)
                },
                onDoubleClick: {
                    confirmConvertToNative(group)
                }
            )
            .draggable()
            .dropDestination(for: DraggableTab.self) { items, location in
                handleTabDrop(items: items, targetTab: nil, targetAssociation: group.id)
            }
            .dropDestination(for: DraggableAssociation.self) { items, location in
                handleAssociationDrop(items: items, targetAssociation: group.id)
            }
        }
    }

    /// Section for ungrouped tabs.
    private var ungroupedSection: some View {
        Section {
            ForEach(state.ungroupedTabs) { tab in
                TabCard(
                    tab: tab,
                    isSelected: state.selectedTabIDs.contains(tab.id),
                    onTap: {
                        state.toggleTabSelection(tab.id)
                    },
                    onActivate: {
                        activateTab(tab)
                    }
                )
                .draggable(fromAssociationID: Optional<UUID>.none)
                .dropDestination(for: DraggableTab.self) { items, location in
                    handleTabDrop(items: items, targetTab: tab.id, targetAssociation: nil)
                }
            }
        } header: {
            HStack {
                Text("Ungrouped Tabs")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("\(state.ungroupedTabs.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                    )

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .accessibilityLabel("Ungrouped tabs, \(state.ungroupedTabs.count) tabs")
        }
    }

    /// Empty group placeholder.
    private var emptyGroupView: some View {
        Text("Drag tabs here to add them to this group")
            .font(.caption)
            .foregroundStyle(.secondary)
            .italic()
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.05))
                    .strokeBorder(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
            .accessibilityLabel("Empty group, drag tabs here to add")
    }

    // MARK: - Actions

    /// Toggles group collapsed state (FR-003).
    private func toggleCollapse(_ group: TabAssociation) {
        Task {
            do {
                try await state.associationService.toggleAssociationCollapsed(
                    associationID: group.id,
                    windowID: state.currentWindowID
                )
            } catch {
                state.handleError(error)
            }
        }
    }

    /// Shows edit sheet for group (FR-005).
    private func editGroup(_ group: TabAssociation) {
        state.showEditAssociation(group)
    }

    /// Shows delete confirmation (FR-005).
    private func confirmDelete(_ group: TabAssociation) {
        groupToDelete = group
        showDeleteConfirmation = true
    }

    /// Deletes a group.
    private func deleteAssociation(_ group: TabAssociation) {
        Task {
            do {
                try await state.associationService.deleteAssociation(
                    associationID: group.id,
                    windowID: state.currentWindowID
                )
            } catch {
                state.handleError(error)
            }
        }
    }

    /// Shows convert to native confirmation (US7, FR-047).
    private func confirmConvertToNative(_ group: TabAssociation) {
        groupToConvert = group
        showConvertConfirmation = true
    }

    /// Converts group to native Safari tab association.
    private func convertToNative(_ group: TabAssociation) {
        // TODO: Phase 8 (US7) - Implement native conversion
        print("Convert to native: \(group.name)")
    }

    /// Activates (navigates to) a tab.
    private func activateTab(_ tab: TabInfo) {
        // TODO: Call Safari API to activate tab
        print("Activate tab: \(tab.title)")
    }

    // MARK: - Drag-and-Drop Actions (T042)

    /// Handles the result of a drop operation.
    ///
    /// **FR-001**: Shows dialog only for new association creation
    /// **FR-004**: Silently adds tabs to existing associations
    /// **FR-004.1**: Removes tabs from associations
    /// **FR-004.2**: Merges associations
    private func handleDropResult(_ result: DragDropManager.DropResult) {
        switch result {
        case let .createNewAssociation(tab1, tab2):
            // Only show dialog for NEW associations (per user feedback)
            newAssociationTabs = (tab1, tab2)
            showNewAssociationDialog = true

        case let .addToAssociation(tabID, associationID, fromAssociationID):
            // Silently add to existing association (no dialog)
            addTabToAssociation(tabID: tabID, associationID: associationID, fromAssociationID: fromAssociationID)

        case let .removeFromAssociation(tabID, fromAssociationID):
            removeTabFromAssociation(tabID: tabID, fromAssociationID: fromAssociationID)

        case let .mergeAssociations(source, target):
            // Show merge confirmation dialog (T042.1)
            mergeAssociationIDs = (source: source, target: target)
            showMergeDialog = true

        case .noAction:
            break
        }
    }

    /// Creates a new association from two ungrouped tabs.
    private func createNewAssociation(name: String, color: String, tab1: String, tab2: String) {
        Task {
            do {
                _ = try await state.associationService.createAssociation(
                    name: name,
                    color: color,
                    tabIDs: [tab1, tab2],
                    windowID: state.currentWindowID
                )
            } catch {
                state.handleError(error)
            }
        }
    }

    /// Adds a tab to an existing association.
    private func addTabToAssociation(tabID: String, associationID: UUID, fromAssociationID: UUID?) {
        Task {
            do {
                // If moving from another association, remove first
                if let fromID = fromAssociationID {
                    try await state.associationService.removeTabFromAssociation(
                        tabID: tabID,
                        associationID: fromID,
                        windowID: state.currentWindowID
                    )
                }

                // Add to target association
                try await state.associationService.addTabToAssociation(
                    tabID: tabID,
                    associationID: associationID,
                    windowID: state.currentWindowID
                )
            } catch {
                state.handleError(error)
            }
        }
    }

    /// Removes a tab from an association.
    private func removeTabFromAssociation(tabID: String, fromAssociationID: UUID) {
        Task {
            do {
                try await state.associationService.removeTabFromAssociation(
                    tabID: tabID,
                    associationID: fromAssociationID,
                    windowID: state.currentWindowID
                )
            } catch {
                state.handleError(error)
            }
        }
    }

    /// Merges two associations together (T042.1).
    ///
    /// **FR-004.2**: Merge associations by combining all tabs
    ///
    /// - Parameters:
    ///   - sourceID: The association to merge from (will be deleted)
    ///   - targetID: The association to merge into (will contain all tabs)
    private func mergeAssociations(sourceID: UUID, targetID: UUID) {
        Task {
            do {
                // Get both associations
                guard let sourceAssoc = state.filteredAssociations.first(where: { $0.id == sourceID }),
                      let targetAssoc = state.filteredAssociations.first(where: { $0.id == targetID }) else {
                    return
                }

                // Add all tabs from source to target
                for tabID in sourceAssoc.tabIDs {
                    try await state.associationService.addTabToAssociation(
                        tabID: tabID,
                        associationID: targetID,
                        windowID: state.currentWindowID
                    )
                }

                // Delete the source association
                try await state.associationService.deleteAssociation(
                    associationID: sourceID,
                    windowID: state.currentWindowID
                )
            } catch {
                state.handleError(error)
            }
        }
    }

    // MARK: - Modern Drop Handlers

    /// Handles tab drops using modern Transferable API.
    private func handleTabDrop(items: [DraggableTab], targetTab: String?, targetAssociation: UUID?) -> Bool {
        guard let draggedTab = items.first else { return false }

        // Determine the drop target
        let target: DragDropManager.DropTarget
        if let tabID = targetTab {
            target = .tab(id: tabID, inAssociationID: targetAssociation)
        } else if let assocID = targetAssociation {
            target = .association(id: assocID)
        } else {
            target = .emptyArea
        }

        // Set up the drag state
        dragDropManager.beginDragTab(tabID: draggedTab.tabID, fromAssociationID: draggedTab.fromAssociationID)

        // Handle the drop
        let result = dragDropManager.handleDrop(on: target)
        handleDropResult(result)

        return result != .noAction
    }

    /// Handles association drops (merges).
    private func handleAssociationDrop(items: [DraggableAssociation], targetAssociation: UUID) -> Bool {
        guard let draggedAssoc = items.first else { return false }

        // Set up the drag state
        dragDropManager.beginDragAssociation(associationID: draggedAssoc.associationID)

        // Handle the drop
        let target = DragDropManager.DropTarget.association(id: targetAssociation)
        let result = dragDropManager.handleDrop(on: target)
        handleDropResult(result)

        return result != .noAction
    }
}

// MARK: - Drop Delegates

/// DropDelegate for handling tab drop operations.
private struct TabDropDelegate: DropDelegate {
    let manager: DragDropManager
    let target: DragDropManager.DropTarget
    let onDrop: (DragDropManager.DropResult) -> Void

    func performDrop(info: DropInfo) -> Bool {
        // Extract the dragged tab ID and source association from the drop info
        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }

        // Load the tab ID (synchronously for simplicity in this context)
        var draggedTabID: String?
        var sourceAssociationID: UUID?

        let semaphore = DispatchSemaphore(value: 0)

        itemProvider.loadObject(ofClass: NSString.self) { object, error in
            if let tabID = object as? String {
                draggedTabID = tabID

                // Extract source association from suggested name if present
                if let suggestedName = itemProvider.suggestedName,
                   let uuid = UUID(uuidString: suggestedName) {
                    sourceAssociationID = uuid
                }
            }
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 1.0)

        guard let tabID = draggedTabID else {
            return false
        }

        // Set the drag item in the manager
        manager.beginDragTab(tabID: tabID, fromAssociationID: sourceAssociationID)

        // Handle the drop
        let result = manager.handleDrop(on: target)
        onDrop(result)
        return result != .noAction
    }

    func dropEntered(info: DropInfo) {
        // Visual feedback could be added here
    }

    func dropExited(info: DropInfo) {
        // Clear visual feedback
    }

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [.text])
    }
}

/// DropDelegate for handling association header drop operations (merge).
private struct AssociationDropDelegate: DropDelegate {
    let manager: DragDropManager
    let target: DragDropManager.DropTarget
    let onDrop: (DragDropManager.DropResult) -> Void

    func performDrop(info: DropInfo) -> Bool {
        // Extract the dragged item from the drop info
        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }

        // Check if this is an association being dragged
        var draggedItem: String?
        var draggedAssociationID: UUID?

        let semaphore = DispatchSemaphore(value: 0)

        itemProvider.loadObject(ofClass: NSString.self) { object, error in
            if let item = object as? String {
                draggedItem = item

                // Extract association ID from suggested name
                if let suggestedName = itemProvider.suggestedName,
                   let uuid = UUID(uuidString: suggestedName) {
                    draggedAssociationID = uuid
                }
            }
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 1.0)

        // Determine if this is an association drag or tab drag
        if draggedItem == "association", let associationID = draggedAssociationID {
            // Association being dragged - set up for merge
            manager.beginDragAssociation(associationID: associationID)
        } else if let tabID = draggedItem {
            // Tab being dragged onto association - set up for add
            manager.beginDragTab(tabID: tabID, fromAssociationID: draggedAssociationID)
        } else {
            return false
        }

        // Handle the drop
        let result = manager.handleDrop(on: target)
        onDrop(result)
        return result != .noAction
    }

    func dropEntered(info: DropInfo) {
        // Visual feedback could be added here
    }

    func dropExited(info: DropInfo) {
        // Clear visual feedback
    }

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [.text])
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With Groups") {
    GroupListView()
        .environment(ExtensionState.preview)
        .frame(width: 400, height: 600)
}

#Preview("Empty State") {
    GroupListView()
        .environment(ExtensionState.preview)
        .frame(width: 400, height: 600)
}

#Preview("Loading State") {
    GroupListView()
        .environment(ExtensionState.preview)
        .frame(width: 400, height: 600)
}
#endif
