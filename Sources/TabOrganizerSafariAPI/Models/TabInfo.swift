import Foundation

/// Information about a Safari tab extracted from Safari Extension APIs.
///
/// TabInfo is a value type that represents a snapshot of a tab's state at a point in time.
/// It's designed to be Sendable for safe cross-actor usage and Codable for storage.
public struct TabInfo: Identifiable, Codable, Sendable, Hashable {
    /// Safari's internal tab identifier
    public let id: String
    
    /// Tab's current URL
    public let url: URL
    
    /// Page title
    public let title: String
    
    /// Extracted domain
    public let domain: String
    
    /// Whether this tab is currently active
    public let isActive: Bool
    
    /// Whether this tab is pinned
    public let isPinned: Bool
    
    /// Whether this tab is in private browsing mode
    public let isPrivate: Bool
    
    /// Optional favicon URL
    public let faviconURL: URL?
    
    /// Creates a TabInfo instance
    public init(
        id: String,
        url: URL,
        title: String,
        domain: String? = nil,
        isActive: Bool = false,
        isPinned: Bool = false,
        isPrivate: Bool = false,
        faviconURL: URL? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.domain = domain ?? url.host ?? url.absoluteString
        self.isActive = isActive
        self.isPinned = isPinned
        self.isPrivate = isPrivate
        self.faviconURL = faviconURL
    }
}
