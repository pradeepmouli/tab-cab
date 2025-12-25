import Foundation

/// Protocol for tab manipulation operations.
///
/// This protocol abstracts Safari Extension tab APIs to enable testability
/// through dependency injection. Production implementations call real Safari APIs,
/// while test implementations provide controllable mock behavior.
@MainActor
public protocol TabManaging: Sendable {
    /// Retrieve all tabs in the active Safari window.
    ///
    /// - Returns: Array of TabInfo structures containing tab metadata
    /// - Throws: TabAPIError on permission, availability, or API issues
    /// - Note: Automatically filters out private browsing tabs
    func getAllTabs() async throws -> [TabInfo]
    
    /// Make the specified tab active (bring to foreground).
    ///
    /// - Parameter id: Safari tab identifier from TabInfo.id
    /// - Throws: TabAPIError if tab not found or permission denied
    func activateTab(id: String) async throws
    
    /// Close the specified tab.
    ///
    /// - Parameter id: Safari tab identifier from TabInfo.id
    /// - Throws: TabAPIError if tab not found or is last tab
    func closeTab(id: String) async throws
    
    /// Open a new tab with the specified URL.
    ///
    /// - Parameter url: URL to open in the new tab
    /// - Returns: ID of the newly created tab
    /// - Throws: TabAPIError on permission or API issues
    func openTab(url: URL) async throws -> String
    
    /// Move a tab to a specific index in the tab bar.
    ///
    /// - Parameters:
    ///   - tabID: ID of the tab to move
    ///   - index: Target position in the tab bar (0-based)
    /// - Throws: TabAPIError if tab not found or index invalid
    func moveTab(id: String, toIndex index: Int) async throws
}
