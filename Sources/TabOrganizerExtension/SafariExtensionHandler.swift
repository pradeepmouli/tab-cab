//
//  SafariExtensionHandler.swift
//  TabOrganizerExtension
//
//  Safari Extension main handler for tab organization extension.
//  Handles lifecycle events, message passing between content scripts and extension,
//  and coordinates with core services.
//

import SafariServices
import os.log

/// Main Safari Extension handler coordinating tab organization features.
///
/// This class serves as the entry point for the Safari Extension, handling:
/// - Extension lifecycle events (load, unload, window/tab events)
/// - Message passing between content scripts and extension backend
/// - Toolbar item state and popover presentation
/// - Permission requests and validation
///
/// **Architecture**: This is a thin wrapper that delegates business logic to
/// TabOrganizerCore services. All heavy lifting happens in SPM libraries.
@MainActor
final class SafariExtensionHandler: SFSafariExtensionHandler {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.taborganizer.extension", category: "handler")

    // MARK: - Lifecycle

    override init() {
        super.init()
        logger.info("Safari Extension initialized")
    }

    // MARK: - Extension Lifecycle

    /// Called when the extension is about to be loaded.
    ///
    /// Use this to perform one-time initialization:
    /// - Load user settings from storage
    /// - Initialize services and repositories
    /// - Set up logging and analytics
    override func messageReceived(
        withName messageName: String,
        from page: SFSafariPage,
        userInfo: [String: Any]?
    ) {
        logger.debug("Message received: \(messageName)")

        Task {
            await handleMessage(messageName: messageName, from: page, userInfo: userInfo)
        }
    }

    /// Called when the toolbar item is clicked.
    ///
    /// Shows the extension popover with tab association management UI.
    override func toolbarItemClicked(in window: SFSafariWindow) {
        logger.debug("Toolbar item clicked")

        Task {
            await handleToolbarClick(in: window)
        }
    }

    /// Called to validate the toolbar item (enable/disable state).
    ///
    /// Returns whether the toolbar item should be enabled for the current window.
    /// Disabled for private browsing windows per privacy requirements (FR-031).
    override func validateToolbarItem(
        in window: SFSafariWindow,
        validationHandler: @escaping (Bool, String) -> Void
    ) {
        Task {
            await validateToolbar(in: window, validationHandler: validationHandler)
        }
    }

    /// Called when a new window is opened.
    override func windowOpened(_ window: SFSafariWindow) {
        logger.debug("Window opened")

        Task {
            await handleWindowOpened(window)
        }
    }

    /// Called when a window is closed.
    override func windowClosed(_ window: SFSafariWindow) {
        logger.debug("Window closed")

        Task {
            await handleWindowClosed(window)
        }
    }

    /// Called when a new tab is opened in a window.
    ///
    /// **User Story 8**: Triggers automatic tab assignment based on domain matching
    /// and cached AI category mappings (FR-053 to FR-060).
    override func page(
        _ page: SFSafariPage,
        willNavigateTo url: URL?
    ) {
        guard let url else { return }
        logger.debug("Page will navigate to: \(url.absoluteString)")

        Task {
            await handlePageNavigation(page: page, url: url)
        }
    }

    // MARK: - Private Handlers

    /// Handles messages from content scripts.
    ///
    /// Message types:
    /// - "getTabAssociations": Returns current tab associations for UI display
    /// - "createGroup": Creates a new tab association
    /// - "updateGroup": Updates existing group properties
    /// - "deleteGroup": Removes a tab association
    /// - "suggestGroups": Triggers AI grouping analysis
    /// - "highlightContext": Triggers context-aware highlighting
    ///
    /// - Parameters:
    ///   - messageName: The message identifier
    ///   - page: The page that sent the message
    ///   - userInfo: Optional message payload
    private func handleMessage(
        messageName: String,
        from page: SFSafariPage,
        userInfo: [String: Any]?
    ) async {
        logger.debug("Handling message: \(messageName)")

        // TODO: Phase 3+ - Implement message routing to services
        // This will be implemented in user story phases:
        // - US1 (P1): Manual group CRUD operations
        // - US2 (P2): AI grouping suggestions
        // - US3 (P3): Context highlighting
        // - US4 (P4): Auto-rearrangement
        // - US5 (P5): Cleanup suggestions

        switch messageName {
        case "getTabAssociations":
            logger.debug("Get tab associations requested")
            // TODO: T034 - Call TabAssociationService.getAllAssociations()

        case "createGroup":
            logger.debug("Create group requested")
            // TODO: T034 - Call TabAssociationService.createGroup()

        case "updateGroup":
            logger.debug("Update group requested")
            // TODO: T034 - Call TabAssociationService.updateGroup()

        case "deleteGroup":
            logger.debug("Delete group requested")
            // TODO: T034 - Call TabAssociationService.deleteGroup()

        case "suggestGroups":
            logger.debug("AI grouping suggestions requested")
            // TODO: Phase 4 (US2) - Call AI services

        case "highlightContext":
            logger.debug("Context highlighting requested")
            // TODO: Phase 5 (US3) - Call context analyzer

        default:
            logger.warning("Unknown message: \(messageName)")
        }
    }

    /// Handles toolbar item click - shows extension popover.
    ///
    /// - Parameter window: The window where toolbar was clicked
    private func handleToolbarClick(in window: SFSafariWindow) async {
        logger.debug("Showing extension popover")

        // Get active tab to provide context to popover
        do {
            let activePage = try await window.getActiveTab()?.getActivePage()
            logger.debug("Active page retrieved for popover context")

            // TODO: Phase 3 (T037-T042) - Initialize PopoverView with current state
            // PopoverView will import TabOrganizerUI and display GroupListView

        } catch {
            logger.error("Failed to get active page: \(error.localizedDescription)")
        }
    }

    /// Validates toolbar item state.
    ///
    /// **Privacy Requirement (FR-031)**: Disables extension in private browsing mode.
    ///
    /// - Parameters:
    ///   - window: The window to validate
    ///   - validationHandler: Callback with (enabled, label) state
    private func validateToolbar(
        in window: SFSafariWindow,
        validationHandler: @escaping (Bool, String) -> Void
    ) async {
        logger.debug("Validating toolbar state")

        // Check if window is private browsing
        // FR-031: Exclude private browsing tabs from all features
        let isPrivate = await isPrivateBrowsing(window: window)

        if isPrivate {
            logger.info("Private browsing detected - disabling extension")
            validationHandler(false, "Tab Organizer (Private Browsing)")
        } else {
            validationHandler(true, "Tab Organizer")
        }
    }

    /// Handles new window opened event.
    ///
    /// - Parameter window: The newly opened window
    private func handleWindowOpened(_ window: SFSafariWindow) async {
        logger.debug("Processing new window")

        // TODO: Phase 3+ - Initialize window-specific state
        // - Load tab associations for this window
        // - Set up tab tracking
    }

    /// Handles window closed event.
    ///
    /// - Parameter window: The closed window
    private func handleWindowClosed(_ window: SFSafariWindow) async {
        logger.debug("Processing closed window")

        // TODO: Phase 3+ - Clean up window state
        // - Persist any unsaved changes
        // - Clear window-specific tracking
    }

    /// Handles page navigation - triggers automatic tab assignment (US8).
    ///
    /// **User Story 8 (FR-053 to FR-060)**: Automatically assigns new tabs to
    /// existing dynamic groups based on domain matching and cached AI mappings.
    ///
    /// - Parameters:
    ///   - page: The page being navigated
    ///   - url: The destination URL
    private func handlePageNavigation(page: SFSafariPage, url: URL) async {
        logger.debug("Processing navigation to: \(url.absoluteString)")

        // TODO: Phase 9 (US8) - Implement automatic tab assignment
        // 1. Check user settings (FR-059) - is auto-assignment enabled?
        // 2. Extract domain from URL
        // 3. Check cached domain→category mappings (FR-054)
        // 4. If no cached mapping, run AI analysis (FR-055)
        // 5. Find matching dynamic group with 70%+ similarity (FR-056)
        // 6. Assign tab to group or leave ungrouped (FR-057)
        // 7. Exclude native groups from assignment (FR-058)
    }

    // MARK: - Utilities

    /// Checks if a window is in private browsing mode.
    ///
    /// - Parameter window: The window to check
    /// - Returns: True if window is private browsing
    private func isPrivateBrowsing(window: SFSafariWindow) async -> Bool {
        // Safari Extension API doesn't provide direct private browsing detection
        // Workaround: Check if localStorage is accessible (disabled in private mode)
        // This is a best-effort check - may need refinement based on testing

        // TODO: Research phase verification - confirm private browsing detection method
        // See plan.md research requirement #3

        return false // Placeholder - implement after research
    }
}

// MARK: - SFSafariWindow Extensions

extension SFSafariWindow {
    /// Gets the active tab in this window.
    ///
    /// - Returns: The active tab, or nil if none
    func getActiveTab() async throws -> SFSafariTab? {
        try await withCheckedThrowingContinuation { continuation in
            self.getActiveTab { tab in
                continuation.resume(returning: tab)
            }
        }
    }
}

// MARK: - SFSafariTab Extensions

extension SFSafariTab {
    /// Gets the active page in this tab.
    ///
    /// - Returns: The active page, or nil if none
    func getActivePage() async throws -> SFSafariPage? {
        try await withCheckedThrowingContinuation { continuation in
            self.getActivePage { page in
                continuation.resume(returning: page)
            }
        }
    }
}
