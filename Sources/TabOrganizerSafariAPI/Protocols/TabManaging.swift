import Foundation

/// Protocol for managing Safari tabs
///
/// Provides an abstraction over Safari Extension APIs for tab manipulation,
/// enabling testability through mock implementations.
///
/// ## Thread Safety
/// All methods are async and can be called from any context.
/// Implementations must handle Safari API calls on the main thread internally.
///
/// ## Privacy
/// Implementations MUST exclude private browsing tabs from all operations.
@MainActor
public protocol TabManaging: Sendable {
    /// Retrieves all non-private tabs from all Safari windows
    ///
    /// - Returns: Array of `TabInfo` for all accessible tabs, excluding private tabs
    /// - Throws: `TabAPIError.permissionDenied` if tab access is not granted
    /// - Throws: `TabAPIError.safariUnavailable` if Safari Extension APIs are unavailable
    ///
    /// ## Pre-conditions
    /// - Safari Extension permissions granted for tab access
    ///
    /// ## Post-conditions
    /// - Returned tabs are from non-private windows only
    /// - Tab order matches Safari's native ordering
    func getAllTabs() async throws -> [TabInfo]

    /// Retrieves tabs from a specific Safari window
    ///
    /// - Parameter windowID: Unique identifier for the Safari window
    /// - Returns: Array of `TabInfo` for tabs in the specified window
    /// - Throws: `TabAPIError.windowNotFound` if window doesn't exist
    /// - Throws: `TabAPIError.permissionDenied` if access is not granted
    ///
    /// ## Pre-conditions
    /// - Window with `windowID` exists and is accessible
    ///
    /// ## Post-conditions
    /// - Returns empty array if window has no tabs or is private
    func getTabs(windowID: String) async throws -> [TabInfo]

    /// Closes a tab by its identifier
    ///
    /// - Parameter tabID: Unique identifier for the tab to close
    /// - Throws: `TabAPIError.tabNotFound` if tab doesn't exist
    /// - Throws: `TabAPIError.permissionDenied` if access is not granted
    ///
    /// ## Pre-conditions
    /// - Tab with `tabID` exists and is closeable
    ///
    /// ## Post-conditions
    /// - Tab is removed from Safari
    /// - Tab's window remains open (even if last tab)
    func closeTab(tabID: String) async throws

    /// Activates (selects) a tab by its identifier
    ///
    /// - Parameter tabID: Unique identifier for the tab to activate
    /// - Throws: `TabAPIError.tabNotFound` if tab doesn't exist
    /// - Throws: `TabAPIError.permissionDenied` if access is not granted
    ///
    /// ## Pre-conditions
    /// - Tab with `tabID` exists and is activatable
    ///
    /// ## Post-conditions
    /// - Tab is brought to foreground
    /// - Tab's window is brought to foreground
    func activateTab(tabID: String) async throws

    /// Moves a tab to a new position within the same window
    ///
    /// - Parameters:
    ///   - tabID: Unique identifier for the tab to move
    ///   - index: Target position (0-based index)
    /// - Throws: `TabAPIError.tabNotFound` if tab doesn't exist
    /// - Throws: `TabAPIError.invalidIndex` if index is out of bounds
    /// - Throws: `TabAPIError.permissionDenied` if access is not granted
    ///
    /// ## Pre-conditions
    /// - Tab with `tabID` exists
    /// - `index` is within valid range [0, tabCount]
    /// - Tab is not pinned (pinned tabs cannot be moved)
    ///
    /// ## Post-conditions
    /// - Tab is at position `index`
    /// - Other tabs shift to accommodate
    func moveTab(tabID: String, toIndex index: Int) async throws
}
