import Foundation

/// Errors that can occur during Safari tab operations
public enum TabAPIError: Error, Sendable, Equatable {
    /// Safari Extension tab access permission not granted
    case permissionDenied

    /// Safari Extension APIs are unavailable or not loaded
    case safariUnavailable

    /// Requested tab does not exist or has been closed
    case tabNotFound(tabID: String)

    /// Requested window does not exist or has been closed
    case windowNotFound(windowID: String)

    /// Provided index is out of valid range
    case invalidIndex(index: Int, validRange: Range<Int>)

    /// Operation failed for an unknown reason
    case unknown(underlyingError: String)
}

extension TabAPIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Safari Extension does not have permission to access tabs. Please grant tab access in Safari preferences."
        case .safariUnavailable:
            return "Safari Extension APIs are not available. Please ensure the extension is enabled."
        case .tabNotFound(let tabID):
            return "Tab with ID '\(tabID)' not found. It may have been closed."
        case .windowNotFound(let windowID):
            return "Window with ID '\(windowID)' not found. It may have been closed."
        case .invalidIndex(let index, let validRange):
            return "Index \(index) is out of valid range \(validRange). Cannot move tab to this position."
        case .unknown(let underlyingError):
            return "Safari tab operation failed: \(underlyingError)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Open Safari Preferences > Extensions > Tab Organizer and enable 'Access to all websites' or 'Access to tabs'."
        case .safariUnavailable:
            return "Reload the Safari Extension or restart Safari."
        case .tabNotFound, .windowNotFound:
            return "Refresh the tab list and try again."
        case .invalidIndex:
            return "Ensure the target position is within the valid range for this window."
        case .unknown:
            return "Try the operation again or restart the Safari Extension."
        }
    }
}
