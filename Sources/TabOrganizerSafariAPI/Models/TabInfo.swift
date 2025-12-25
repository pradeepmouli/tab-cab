import Foundation

/// Represents a Safari tab with its metadata
///
/// Immutable value type capturing tab state at a point in time.
/// Safe to pass across concurrency boundaries.
public struct TabInfo: Codable, Sendable, Identifiable, Equatable {
    /// Unique identifier for the tab
    public let id: String

    /// Tab's current URL
    public let url: URL

    /// Tab's title (page title or URL if title unavailable)
    public let title: String

    /// Identifier of the window containing this tab
    public let windowID: String

    /// Tab's position in the window (0-based index)
    public let index: Int

    /// Whether the tab is currently active (selected)
    public let isActive: Bool

    /// Whether the tab is pinned
    public let isPinned: Bool

    /// Extracted domain from URL (e.g., "github.com")
    public var domain: String {
        url.host ?? ""
    }

    /// Creates a new TabInfo instance
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the tab
    ///   - url: Tab's current URL
    ///   - title: Tab's title
    ///   - windowID: Identifier of the containing window
    ///   - index: Tab's position in the window (0-based)
    ///   - isActive: Whether the tab is currently selected
    ///   - isPinned: Whether the tab is pinned
    public init(
        id: String,
        url: URL,
        title: String,
        windowID: String,
        index: Int,
        isActive: Bool,
        isPinned: Bool
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.windowID = windowID
        self.index = index
        self.isActive = isActive
        self.isPinned = isPinned
    }
}
