import Foundation

/// Recommendation to close inactive tabs
///
/// Immutable value type representing cleanup analysis and suggestions.
/// Tracks user decisions for learning preferences.
public struct CleanupSuggestion: Codable, Sendable, Identifiable, Equatable {
    /// Unique identifier for this suggestion
    public let id: UUID

    /// Tab IDs suggested for closure
    public let suggestedTabIDs: [String]

    /// Map of tab ID to inactivity duration (seconds)
    public let inactivityDurations: [String: TimeInterval]

    /// Map of tab ID to reason for suggestion
    public let reasons: [String: String]

    /// When this suggestion was generated
    public let createdAt: Date

    /// User's decision for each tab (accepted/rejected/kept)
    public let userDecisions: [String: Decision]

    /// Whether this suggestion has been acted upon
    public let isCompleted: Bool

    /// When the user completed this suggestion (if applicable)
    public let completedAt: Date?

    // MARK: - Types

    public enum Decision: String, Codable, Sendable {
        case pending       // No decision yet
        case accepted      // User agreed to close
        case rejected      // User rejected suggestion
        case kept          // User explicitly marked to keep (exclude from future)
    }

    // MARK: - Initialization

    /// Creates a cleanup suggestion
    ///
    /// - Parameters:
    ///   - id: Unique identifier (default: new UUID)
    ///   - suggestedTabIDs: Tabs recommended for closure
    ///   - inactivityDurations: Tab ID to inactivity duration map
    ///   - reasons: Tab ID to suggestion reason map
    ///   - createdAt: Creation timestamp (default: now)
    ///   - userDecisions: User decisions (default: all pending)
    ///   - isCompleted: Whether acted upon (default: false)
    ///   - completedAt: Completion timestamp (default: nil)
    public init(
        id: UUID = UUID(),
        suggestedTabIDs: [String],
        inactivityDurations: [String: TimeInterval] = [:],
        reasons: [String: String] = [:],
        createdAt: Date = Date(),
        userDecisions: [String: Decision]? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.suggestedTabIDs = suggestedTabIDs
        self.inactivityDurations = inactivityDurations
        self.reasons = reasons
        self.createdAt = createdAt

        // Default all tabs to pending if not specified
        if let decisions = userDecisions {
            self.userDecisions = decisions
        } else {
            self.userDecisions = Dictionary(uniqueKeysWithValues: suggestedTabIDs.map { ($0, .pending) })
        }

        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }

    // MARK: - Mutations (Value Semantics)

    /// Returns suggestion with updated user decision for a tab
    public func withDecision(_ decision: Decision, for tabID: String) -> CleanupSuggestion {
        var updatedDecisions = userDecisions
        updatedDecisions[tabID] = decision

        return CleanupSuggestion(
            id: id,
            suggestedTabIDs: suggestedTabIDs,
            inactivityDurations: inactivityDurations,
            reasons: reasons,
            createdAt: createdAt,
            userDecisions: updatedDecisions,
            isCompleted: isCompleted,
            completedAt: completedAt
        )
    }

    /// Returns suggestion marked as completed
    public func withCompleted() -> CleanupSuggestion {
        CleanupSuggestion(
            id: id,
            suggestedTabIDs: suggestedTabIDs,
            inactivityDurations: inactivityDurations,
            reasons: reasons,
            createdAt: createdAt,
            userDecisions: userDecisions,
            isCompleted: true,
            completedAt: Date()
        )
    }

    // MARK: - Computed Properties

    /// Total number of suggested tabs
    public var totalSuggestions: Int {
        suggestedTabIDs.count
    }

    /// Tabs that user accepted for closure
    public var acceptedTabIDs: [String] {
        suggestedTabIDs.filter { userDecisions[$0] == .accepted }
    }

    /// Tabs that user rejected
    public var rejectedTabIDs: [String] {
        suggestedTabIDs.filter { userDecisions[$0] == .rejected }
    }

    /// Tabs that user marked to keep
    public var keptTabIDs: [String] {
        suggestedTabIDs.filter { userDecisions[$0] == .kept }
    }

    /// Tabs with pending decision
    public var pendingTabIDs: [String] {
        suggestedTabIDs.filter { userDecisions[$0] == .pending }
    }

    /// User acceptance rate (0.0-1.0)
    public var acceptanceRate: Double {
        guard !suggestedTabIDs.isEmpty else { return 0.0 }
        let decidedCount = suggestedTabIDs.count - pendingTabIDs.count
        guard decidedCount > 0 else { return 0.0 }
        return Double(acceptedTabIDs.count) / Double(decidedCount)
    }

    /// Whether all suggestions have been decided
    public var allDecided: Bool {
        pendingTabIDs.isEmpty
    }

    /// Age of this suggestion
    public var age: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }

    // MARK: - Query Methods

    /// Returns inactivity duration for a specific tab
    public func inactivityDuration(for tabID: String) -> TimeInterval? {
        inactivityDurations[tabID]
    }

    /// Returns reason for suggesting a specific tab
    public func reason(for tabID: String) -> String? {
        reasons[tabID]
    }

    /// Returns user decision for a specific tab
    public func decision(for tabID: String) -> Decision {
        userDecisions[tabID] ?? .pending
    }

    /// Returns tabs sorted by inactivity duration (longest first)
    public func sortedByInactivity() -> [(tabID: String, duration: TimeInterval)] {
        suggestedTabIDs.compactMap { tabID in
            guard let duration = inactivityDurations[tabID] else { return nil }
            return (tabID, duration)
        }
        .sorted { $0.duration > $1.duration }
    }

    /// Formatted inactivity duration for display
    public func formattedInactivity(for tabID: String) -> String {
        guard let duration = inactivityDurations[tabID] else {
            return "Unknown"
        }

        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes) minutes"
        } else if minutes < 1440 { // Less than 24 hours
            let hours = minutes / 60
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            let days = minutes / 1440
            return "\(days) day\(days == 1 ? "" : "s")"
        }
    }
}

// MARK: - Convenience Extensions

extension CleanupSuggestion {
    /// Common cleanup reasons
    public enum CleanupReason {
        case inactive(duration: TimeInterval)
        case ungrouped
        case duplicate
        case lowPriority

        public var description: String {
            switch self {
            case .inactive(let duration):
                let minutes = Int(duration / 60)
                if minutes < 60 {
                    return "Inactive for \(minutes) minutes"
                } else {
                    let hours = minutes / 60
                    return "Inactive for \(hours) hour\(hours == 1 ? "" : "s")"
                }
            case .ungrouped:
                return "Not in any group"
            case .duplicate:
                return "Duplicate of another tab"
            case .lowPriority:
                return "Low priority content"
            }
        }
    }

    /// Creates suggestion from inactive tabs
    public static func fromInactiveTabs(
        tabs: [(id: String, inactiveDuration: TimeInterval)]
    ) -> CleanupSuggestion {
        let tabIDs = tabs.map { $0.id }
        let durations = Dictionary(uniqueKeysWithValues: tabs.map { ($0.id, $0.inactiveDuration) })
        let reasons = Dictionary(uniqueKeysWithValues: tabs.map {
            ($0.id, CleanupReason.inactive(duration: $0.inactiveDuration).description)
        })

        return CleanupSuggestion(
            suggestedTabIDs: tabIDs,
            inactivityDurations: durations,
            reasons: reasons
        )
    }
}
