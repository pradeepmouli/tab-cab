import Foundation

/// Represents a Safari tab tracked by the extension.
///
/// Tab contains all metadata needed to identify, display, and analyze browser tabs.
/// Tabs are ephemeral and tied to Safari's tab lifecycle - they exist only while
/// the browser tab is open.
public struct Tab: Identifiable, Codable, Sendable {
    /// Safari's internal tab identifier
    public let id: String
    
    /// Tab's current URL
    public let url: URL
    
    /// Page title
    public let title: String
    
    /// Extracted domain (e.g., "github.com" from "https://github.com/user/repo")
    public let domain: String
    
    /// Optional favicon URL for display
    public let faviconURL: URL?
    
    /// Whether this tab is currently selected
    public let isActive: Bool
    
    /// Whether this tab is pinned (excludes from rearrangement)
    public let isPinned: Bool
    
    /// Whether this tab is in private browsing mode
    /// - Note: Private tabs MUST NOT be stored per Constitution Principle II
    public let isPrivate: Bool
    
    /// Timestamp of last user interaction with this tab
    public let lastViewedAt: Date
    
    /// Optional reference to parent TabGroup
    public let groupID: UUID?
    
    /// Creates a new Tab with the specified properties
    ///
    /// - Parameters:
    ///   - id: Safari tab identifier
    ///   - url: Tab URL
    ///   - title: Page title (defaults to URL string if empty)
    ///   - domain: Extracted domain (auto-computed if nil)
    ///   - faviconURL: Optional favicon URL
    ///   - isActive: Whether tab is currently selected
    ///   - isPinned: Whether tab is pinned
    ///   - isPrivate: Whether tab is in private mode
    ///   - lastViewedAt: Last interaction timestamp
    ///   - groupID: Optional group membership
    public init(
        id: String,
        url: URL,
        title: String? = nil,
        domain: String? = nil,
        faviconURL: URL? = nil,
        isActive: Bool = false,
        isPinned: Bool = false,
        isPrivate: Bool = false,
        lastViewedAt: Date = Date(),
        groupID: UUID? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title?.isEmpty == false ? title! : url.absoluteString
        self.domain = domain ?? url.host ?? url.absoluteString
        self.faviconURL = faviconURL
        self.isActive = isActive
        self.isPinned = isPinned
        self.isPrivate = isPrivate
        self.lastViewedAt = lastViewedAt
        self.groupID = groupID
    }
    
    /// Creates a copy of this tab assigned to a group
    public func withGroup(_ groupID: UUID?) -> Tab {
        Tab(
            id: id,
            url: url,
            title: title,
            domain: domain,
            faviconURL: faviconURL,
            isActive: isActive,
            isPinned: isPinned,
            isPrivate: isPrivate,
            lastViewedAt: lastViewedAt,
            groupID: groupID
        )
    }
    
    /// Creates a copy of this tab with updated lastViewedAt timestamp
    public func withUpdatedViewTime() -> Tab {
        Tab(
            id: id,
            url: url,
            title: title,
            domain: domain,
            faviconURL: faviconURL,
            isActive: isActive,
            isPinned: isPinned,
            isPrivate: isPrivate,
            lastViewedAt: Date(),
            groupID: groupID
        )
    }
    
    /// Calculates the duration since this tab was last viewed
    public func inactiveDuration() -> TimeInterval {
        return Date().timeIntervalSince(lastViewedAt)
    }
    
    /// Checks if this tab has been inactive for longer than the given threshold
    public func isInactive(threshold: TimeInterval) -> Bool {
        return inactiveDuration() > threshold
    }
}

/// Extension providing computed properties for tab analysis
public extension Tab {
    /// URL path components for similarity analysis
    var pathComponents: [String] {
        url.pathComponents.filter { $0 != "/" }
    }
    
    /// URL scheme (http, https, etc.)
    var scheme: String {
        url.scheme ?? ""
    }
    
    /// Combined text for keyword extraction (title + domain)
    var searchableText: String {
        "\(title) \(domain)"
    }
    
    /// Display name prioritizing title over URL
    var displayName: String {
        title.isEmpty ? url.absoluteString : title
    }
}

// MARK: - Hashable & Equatable

extension Tab: Hashable {
    /// Hash based on ID only for Set/Dictionary usage
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// Equality based on ID only
    public static func == (lhs: Tab, rhs: Tab) -> Bool {
        lhs.id == rhs.id
    }
}
