import Foundation

/// Errors that can occur when interacting with Safari tabs through the extension API.
public enum TabAPIError: Error, LocalizedError, Sendable {
    /// User hasn't granted tab access permission
    case permissionDenied
    
    /// No Safari window is currently active
    case noActiveWindow
    
    /// Safari Extension host is unavailable
    case safariUnavailable
    
    /// Tab with the given ID doesn't exist
    case tabNotFound(String)
    
    /// Cannot close the last tab in a window
    case cannotCloseLastTab
    
    /// General Safari API error
    case apiError(String)
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Safari tab access permission not granted. Please enable the extension in Safari preferences."
        case .noActiveWindow:
            return "No active Safari window found."
        case .safariUnavailable:
            return "Safari Extension host is unavailable. Please restart Safari."
        case .tabNotFound(let id):
            return "Tab with ID '\(id)' not found."
        case .cannotCloseLastTab:
            return "Cannot close the last tab in a window."
        case .apiError(let message):
            return "Safari API error: \(message)"
        }
    }
}
