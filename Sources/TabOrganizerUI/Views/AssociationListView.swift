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
