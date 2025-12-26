//
//  ExtensionState.swift
//  TabOrganizerUI
//
//  Top-level state management for the Safari Extension UI.
//  Uses @Observable for native SwiftUI state management (no ViewModels per constitution).
//

import Foundation
import SwiftUI
import TabOrganizerCore
import TabOrganizerStorage
import TabOrganizerSafariAPI

/// Top-level observable state for the Safari Extension UI.
///
/// **Architecture (Constitution Principle I)**: This is NOT a ViewModel.
/// It's a state container using Swift's @Observable macro for direct SwiftUI integration.
/// Services handle business logic; this class only manages UI state.
///
/// **Usage**:
/// ```swift
/// @State private var state = ExtensionState(
///     associationService: TabAssociationService(...),
///     trackingService: TabTrackingService(...)
/// )
/// .environment(state)
/// ```
@MainActor
@Observable
public final class ExtensionState {

    // MARK: - Dependencies (Services)

    public let associationService: TabAssociationService
    public let trackingService: TabTrackingService

    // MARK: - UI State

    /// Current window ID
    public var currentWindowID: String = "window-1" // TODO: Get from Safari API

    /// Currently selected tab association (for editing)
    public var selectedAssociation: TabAssociation?

    /// Sheet presentation state
    public var isPresentingGroupEditor: Bool = false
    public var isPresentingSettings: Bool = false

    /// Group being edited (nil = create new, non-nil = edit existing)
    public var associationBeingEdited: TabAssociation?

    /// Current tabs (from Safari)
    public var currentTabs: [TabInfo] = []

    /// Selected tabs (for bulk operations)
    public var selectedTabIDs: Set<String> = []

    /// Search/filter state
    public var searchText: String = ""

    /// View mode
    public var viewMode: ViewMode = .grouped

    // MARK: - Error State

    /// Current error to display
    public var errorMessage: String?

    /// Show error alert
    public var showError: Bool = false

    // MARK: - Loading State

    /// Global loading indicator
    public var isLoading: Bool = false

    // MARK: - Initialization

    /// Creates extension state with injected services.
    ///
    /// - Parameters:
    ///   - associationService: The tab association service
    ///   - trackingService: The tab tracking service
    public init(
        associationService: TabAssociationService,
        trackingService: TabTrackingService
    ) {
        self.associationService = associationService
        self.trackingService = trackingService
    }

    // MARK: - Actions

    /// Loads initial state (call on view appear).
    public func loadInitialState() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load groups for current window
            await associationService.loadAssociations(windowID: currentWindowID)

            // Load tab tracking history
            try await trackingService.loadViewHistory()

            // TODO: Load current tabs from Safari API
            // currentTabs = try await tabManager.getAllTabs()

        } catch {
            handleError(error)
        }
    }

    /// Refreshes data from services.
    public func refresh() async {
        await loadInitialState()
    }

    /// Shows the group editor for creating a new group.
    public func showCreateAssociation() {
        associationBeingEdited = nil
        isPresentingGroupEditor = true
    }

    /// Shows the group editor for editing an existing group.
    ///
    /// - Parameter group: The group to edit
    public func showEditAssociation(_ group: TabAssociation) {
        associationBeingEdited = group
        isPresentingGroupEditor = true
    }

    /// Shows the settings view.
    public func showSettings() {
        isPresentingSettings = true
    }

    /// Dismisses the group editor.
    public func dismissGroupEditor() {
        isPresentingGroupEditor = false
        associationBeingEdited = nil
    }

    /// Dismisses the settings view.
    public func dismissSettings() {
        isPresentingSettings = false
    }

    /// Toggles tab selection (for bulk operations).
    ///
    /// - Parameter tabID: The tab identifier
    public func toggleTabSelection(_ tabID: String) {
        if selectedTabIDs.contains(tabID) {
            selectedTabIDs.remove(tabID)
        } else {
            selectedTabIDs.insert(tabID)
        }
    }

    /// Clears all tab selections.
    public func clearSelection() {
        selectedTabIDs.removeAll()
    }

    /// Handles errors by setting error state.
    ///
    /// - Parameter error: The error to handle
    public func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }

    /// Clears the current error.
    public func clearError() {
        errorMessage = nil
        showError = false
    }

    // MARK: - Computed Properties

    /// Groups filtered by search text.
    public var filteredAssociations: [TabAssociation] {
        guard !searchText.isEmpty else {
            return associationService.associations
        }

        return associationService.associations.filter { group in
            group.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Tabs that are not in any group.
    public var ungroupedTabs: [TabInfo] {
        let groupedTabIDs = Set(associationService.associations.flatMap { $0.tabIDs })
        return currentTabs.filter { !groupedTabIDs.contains($0.id) }
    }

    /// Number of selected tabs.
    public var selectedCount: Int {
        selectedTabIDs.count
    }

    /// Whether any tabs are selected.
    public var hasSelection: Bool {
        !selectedTabIDs.isEmpty
    }
}

// MARK: - ViewMode

/// View mode for the extension UI.
public enum ViewMode: String, CaseIterable, Sendable {
    case grouped = "Grouped"
    case list = "List"
    case grid = "Grid"

    public var icon: String {
        switch self {
        case .grouped: return "square.stack.3d.up.fill"
        case .list: return "list.bullet"
        case .grid: return "square.grid.2x2"
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension ExtensionState {
    /// Creates a sample state for previews.
    ///
    /// **TDD Approach**: This provides realistic sample data for SwiftUI Previews,
    /// serving as a "visual test" per Constitution Principle III.
    @MainActor
    public static var preview: ExtensionState {
        // Use real implementations for previews
        let repository: any TabAssociationRepository = SafariAssociationRepository()
        let tabManager: any TabManaging = MockTabManager()
        let storage: any SafariStorageAdapter = UserDefaultsStorageAdapter(keyPrefix: "preview.")

        // Create services
        let associationService = TabAssociationService(
            repository: repository,
            tabManager: tabManager
        )

        let trackingService = TabTrackingService(storage: storage)

        // Create state
        let state = ExtensionState(
            associationService: associationService,
            trackingService: trackingService
        )

        // Set up sample tabs
        state.currentTabs = [
            TabInfo(
                id: "tab-1",
                url: URL(string: "https://github.com")!,
                title: "GitHub",
                windowID: "window-1",
                index: 0,
                isActive: false,
                isPinned: false
            ),
            TabInfo(
                id: "tab-2",
                url: URL(string: "https://stackoverflow.com")!,
                title: "Stack Overflow",
                windowID: "window-1",
                index: 1,
                isActive: false,
                isPinned: false
            ),
            TabInfo(
                id: "tab-3",
                url: URL(string: "https://apple.com")!,
                title: "Apple",
                windowID: "window-1",
                index: 2,
                isActive: false,
                isPinned: false
            )
        ]

        return state
    }
}
#endif
