//
//  PopoverView.swift
//  TabOrganizerExtension
//
//  Root SwiftUI view for the Safari Extension popover.
//  Wires together all UI components and services for User Story 1.
//

import SwiftUI
import SafariServices
import TabOrganizerUI
import TabOrganizerCore
import TabOrganizerStorage
import TabOrganizerSafariAPI

/// Root view for the Safari Extension popover.
///
/// **Architecture**: This is the entry point that:
/// 1. Creates service dependencies
/// 2. Initializes ExtensionState
/// 3. Presents GroupListView
///
/// **User Story 1 Integration**: Implements FR-001 to FR-006 by providing
/// complete UI for manual tab association organization.
@MainActor
public struct PopoverView: View {

    // MARK: - State

    @State private var extensionState: ExtensionState

    // MARK: - Initialization

    /// Creates the popover view with dependency injection.
    ///
    /// - Parameters:
    ///   - windowID: The current Safari window ID
    ///   - tabManager: Optional tab manager (uses production if nil)
    ///   - storage: Optional storage adapter (uses production if nil)
    public init(
        windowID: String = "default",
        tabManager: (any TabManaging)? = nil,
        storage: SafariStorageAdapter? = nil
    ) {
        // Create dependencies
        let actualStorage = storage ?? UserDefaultsStorageAdapter()
        let actualTabManager = tabManager ?? SafariTabManager()

        // Create repository
        let repository = SafariAssociationRepository(storage: actualStorage)

        // Create services
        let associationService = TabAssociationService(
            repository: repository,
            tabManager: actualTabManager
        )

        let trackingService = TabTrackingService(storage: actualStorage)

        // Create state
        let state = ExtensionState(
            associationService: associationService,
            trackingService: trackingService
        )
        state.currentWindowID = windowID

        _extensionState = State(initialValue: state)
    }

    // MARK: - Body

    public var body: some View {
        GroupListView()
            .environment(extensionState)
            .frame(width: 400, height: 600)
            .task {
                // Load initial state when popover appears
                await extensionState.loadInitialState()
            }
            // MARK: - Accessibility
            .accessibilityLabel("Tab Organizer")
            .accessibilityIdentifier("PopoverView")
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Popover with Sample Data") {
    PopoverView(
        windowID: "preview-window",
        tabManager: MockTabManager.withSampleTabs(),
        storage: MockStorageAdapter()
    )
}

#Preview("Popover Empty State") {
    PopoverView(
        windowID: "preview-window",
        tabManager: MockTabManager(),
        storage: MockStorageAdapter()
    )
}
#endif
