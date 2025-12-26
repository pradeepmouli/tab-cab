//
//  TabTrackingService.swift
//  TabOrganizerCore
//
//  Service for tracking tab view timestamps and activity.
//  Used for cleanup suggestions (User Story 5) based on inactivity.
//

import Foundation

/// Service for tracking tab view timestamps and activity.
///
/// **Responsibilities**:
/// - Track last viewed timestamp for tabs (FR-023)
/// - Identify inactive tabs based on threshold (FR-024)
/// - Persist view history across sessions
///
/// **User Story 5**: This service provides the foundation for intelligent cleanup
/// by tracking which tabs haven't been viewed recently.
@MainActor
@Observable
public final class TabTrackingService {

    // MARK: - Dependencies

    private let storage: SafariStorageAdapter

    // MARK: - State

    /// Tab view history: tabID -> lastViewedAt timestamp
    private var viewHistory: [String: Date] = [:]

    /// Storage key for view history
    private let storageKey = "tab_view_history"

    // MARK: - Initialization

    /// Creates a tracking service with injected storage.
    ///
    /// - Parameter storage: The storage adapter
    public init(storage: SafariStorageAdapter) {
        self.storage = storage
    }

    // MARK: - Tracking Operations

    /// Records that a tab was viewed.
    ///
    /// **FR-023**: System MUST track tab view timestamps
    ///
    /// - Parameter tabID: The tab identifier
    public func recordTabView(tabID: String) async throws {
        viewHistory[tabID] = Date()
        try await persistViewHistory()
    }

    /// Records view for multiple tabs (batch operation).
    ///
    /// - Parameter tabIDs: The tab identifiers
    public func recordTabViews(tabIDs: [String]) async throws {
        let now = Date()
        for tabID in tabIDs {
            viewHistory[tabID] = now
        }
        try await persistViewHistory()
    }

    /// Gets the last viewed timestamp for a tab.
    ///
    /// - Parameter tabID: The tab identifier
    /// - Returns: The last viewed date, or nil if never viewed
    public func getLastViewed(tabID: String) -> Date? {
        viewHistory[tabID]
    }

    /// Gets inactive tabs based on threshold.
    ///
    /// **FR-024**: System MUST suggest cleanup for tabs inactive beyond threshold
    ///
    /// - Parameter threshold: The inactivity duration (e.g., 30 minutes)
    /// - Returns: Array of tab IDs that haven't been viewed within threshold
    public func getInactiveTabs(threshold: TimeInterval) -> [String] {
        let cutoffDate = Date().addingTimeInterval(-threshold)

        return viewHistory
            .filter { _, lastViewed in lastViewed < cutoffDate }
            .map { tabID, _ in tabID }
    }

    /// Gets tabs that have never been viewed.
    ///
    /// Useful for identifying tabs opened but not yet interacted with.
    ///
    /// - Parameter allTabIDs: All current tab IDs
    /// - Returns: Tab IDs with no view history
    public func getNeverViewedTabs(allTabIDs: [String]) -> [String] {
        allTabIDs.filter { viewHistory[$0] == nil }
    }

    /// Removes tracking for a tab (e.g., when tab is closed).
    ///
    /// - Parameter tabID: The tab identifier
    public func removeTab(tabID: String) async throws {
        viewHistory.removeValue(forKey: tabID)
        try await persistViewHistory()
    }

    /// Removes tracking for multiple tabs (batch operation).
    ///
    /// - Parameter tabIDs: The tab identifiers
    public func removeTabs(tabIDs: [String]) async throws {
        for tabID in tabIDs {
            viewHistory.removeValue(forKey: tabID)
        }
        try await persistViewHistory()
    }

    /// Loads view history from storage.
    ///
    /// Call this on service initialization to restore state.
    public func loadViewHistory() async throws {
        guard let history = try await storage.load(forKey: storageKey, as: [String: Date].self) else {
            // No history yet
            viewHistory = [:]
            return
        }

        viewHistory = history
    }

    /// Clears all view history.
    ///
    /// Used for testing or user-initiated reset.
    public func clearAllHistory() async throws {
        viewHistory.removeAll()
        try await storage.remove(forKey: storageKey)
    }

    /// Gets statistics about tab activity.
    ///
    /// - Returns: Summary statistics for UI display
    public func getActivityStats() -> TabActivityStats {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let oneDayAgo = now.addingTimeInterval(-86400)

        let viewedLastHour = viewHistory.values.filter { $0 > oneHourAgo }.count
        let viewedLastDay = viewHistory.values.filter { $0 > oneDayAgo }.count
        let totalTracked = viewHistory.count

        let mostRecentlyViewed = viewHistory.max { $0.value < $1.value }?.key
        let leastRecentlyViewed = viewHistory.min { $0.value < $1.value }?.key

        return TabActivityStats(
            totalTracked: totalTracked,
            viewedLastHour: viewedLastHour,
            viewedLastDay: viewedLastDay,
            mostRecentlyViewedTabID: mostRecentlyViewed,
            leastRecentlyViewedTabID: leastRecentlyViewed
        )
    }

    // MARK: - Private Helpers

    /// Persists view history to storage.
    private func persistViewHistory() async throws {
        try await storage.save(viewHistory, forKey: storageKey)
    }
}

// MARK: - TabActivityStats

/// Statistics about tab viewing activity.
public struct TabActivityStats: Sendable {
    /// Total number of tabs being tracked
    public let totalTracked: Int

    /// Tabs viewed in last hour
    public let viewedLastHour: Int

    /// Tabs viewed in last day
    public let viewedLastDay: Int

    /// Most recently viewed tab ID
    public let mostRecentlyViewedTabID: String?

    /// Least recently viewed tab ID
    public let leastRecentlyViewedTabID: String?

    /// Computed: Tabs not viewed in last day
    public var notViewedLastDay: Int {
        totalTracked - viewedLastDay
    }
}
