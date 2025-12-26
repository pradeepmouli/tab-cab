import Foundation

/// Represents a Safari tab tracked by the extension
///
/// Immutable value type safe for concurrent access.
/// Private browsing tabs MUST be filtered before creating Tab instances.
public struct Tab: Codable, Sendable, Identifiable, Equatable {
    /// Safari's internal tab identifier
    public let id: String

    /// Tab's current URL
    public let url: URL

    /// Page title
    public let title: String

    /// Extracted domain (e.g., "github.com")
    public let domain: String

    /// Optional favicon URL for display
    public let faviconURL: URL?

    /// Whether this tab is currently selected
    public let isActive: Bool

    /// Whether this tab is pinned (excludes from rearrangement)
    public let isPinned: Bool

    /// Timestamp of last user interaction with this tab
    public let lastViewedAt: Date

    /// Optional reference to parent TabAssociation
    public let associationID: UUID?

    // MARK: - Initialization

    /// Creates a new Tab instance
    ///
    /// - Parameters:
    ///   - id: Safari's internal tab identifier
    ///   - url: Tab's current URL
    ///   - title: Page title (defaults to URL if empty)
    ///   - faviconURL: Optional favicon URL
    ///   - isActive: Whether currently selected (default: false)
    ///   - isPinned: Whether pinned (default: false)
    ///   - lastViewedAt: Last interaction timestamp (default: now)
    ///   - associationID: Optional parent group ID
    ///
    /// ## Important
    /// This initializer MUST NOT be called with private browsing tabs.
    /// Private tabs should be filtered at the Safari API boundary.
    public init(
        id: String,
        url: URL,
        title: String? = nil,
        faviconURL: URL? = nil,
        isActive: Bool = false,
        isPinned: Bool = false,
        lastViewedAt: Date = Date(),
        associationID: UUID? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title?.isEmpty == false ? title! : url.absoluteString
        self.domain = Self.extractDomain(from: url)
        self.faviconURL = faviconURL
        self.isActive = isActive
        self.isPinned = isPinned
        self.lastViewedAt = lastViewedAt
        self.associationID = associationID
    }

    // MARK: - Mutations (Value Semantics)

    /// Returns a new Tab with updated URL and title
    public func withNavigation(to url: URL, title: String?) -> Tab {
        Tab(
            id: id,
            url: url,
            title: title,
            faviconURL: faviconURL,
            isActive: isActive,
            isPinned: isPinned,
            lastViewedAt: Date(),
            associationID: associationID
        )
    }

    /// Returns a new Tab with updated active state
    public func withActive(_ active: Bool) -> Tab {
        Tab(
            id: id,
            url: url,
            title: title,
            faviconURL: faviconURL,
            isActive: active,
            isPinned: isPinned,
            lastViewedAt: active ? Date() : lastViewedAt,
            associationID: associationID
        )
    }

    /// Returns a new Tab with updated association assignment
    public func withAssociation(_ newAssociationID: UUID?) -> Tab {
        Tab(
            id: id,
            url: url,
            title: title,
            faviconURL: faviconURL,
            isActive: isActive,
            isPinned: isPinned,
            lastViewedAt: lastViewedAt,
            associationID: newAssociationID
        )
    }

    /// Returns a new Tab with updated last viewed timestamp
    public func withLastViewed(at timestamp: Date = Date()) -> Tab {
        Tab(
            id: id,
            url: url,
            title: title,
            faviconURL: faviconURL,
            isActive: isActive,
            isPinned: isPinned,
            lastViewedAt: timestamp,
            associationID: associationID
        )
    }

    // MARK: - Computed Properties

    /// Whether this tab belongs to an association
    public var isGrouped: Bool {
        associationID != nil
    }

    /// Time since last view
    public var timeSinceLastView: TimeInterval {
        Date().timeIntervalSince(lastViewedAt)
    }

    /// Whether tab is considered inactive (not viewed in 30+ minutes)
    public func isInactive(threshold: TimeInterval = 30 * 60) -> Bool {
        timeSinceLastView > threshold
    }

    /// Formatted display title (truncated if too long)
    public func displayTitle(maxLength: Int = 50) -> String {
        if title.count <= maxLength {
            return title
        }
        let truncated = title.prefix(maxLength - 3)
        return "\(truncated)..."
    }

    // MARK: - Domain Extraction

    /// Extracts domain from URL
    private static func extractDomain(from url: URL) -> String {
        url.host ?? ""
    }

    /// Whether this tab is from the same domain as another
    public func isSameDomain(as other: Tab) -> Bool {
        !domain.isEmpty && domain == other.domain
    }
}

// MARK: - Convenience Extensions

extension Tab {
    /// Creates a sample tab for testing/previews
    public static func sample(
        id: String = "sample-tab",
        urlString: String = "https://github.com",
        title: String = "GitHub",
        isActive: Bool = false
    ) -> Tab {
        Tab(
            id: id,
            url: URL(string: urlString)!,
            title: title,
            isActive: isActive
        )
    }
}
