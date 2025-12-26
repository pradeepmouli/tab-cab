import Foundation

/// User preferences and feature toggles
///
/// Immutable value type storing all user-configurable settings.
/// Safe for concurrent access across actors.
public struct UserSettings: Codable, Sendable, Equatable {

    // MARK: - Feature Toggles

    /// Whether context-aware tab highlighting is enabled
    public let contextHighlightingEnabled: Bool

    /// Whether automatic tab rearrangement is enabled
    public let autoRearrangementEnabled: Bool

    /// Whether intelligent cleanup suggestions are enabled
    public let cleanupSuggestionsEnabled: Bool

    // MARK: - Cleanup Configuration

    /// Inactivity threshold in seconds (default: 30 minutes)
    public let inactivityThreshold: TimeInterval

    /// Whether to auto-close tabs matching cleanup criteria
    public let autoCloseEnabled: Bool

    /// Whether to auto-close only ungrouped tabs
    public let autoCloseUngroupedOnly: Bool

    // MARK: - UI Preferences

    /// Preferred theme for the extension UI
    public let theme: Theme

    /// Whether to show tab favicons
    public let showFavicons: Bool

    /// Whether to show tab counts on groups
    public let showTabCounts: Bool

    // MARK: - Privacy Preferences

    /// Whether user has consented to on-device AI analysis
    public let aiAnalysisConsent: Bool

    /// Whether to exclude specific domains from AI analysis
    public let excludedDomains: [String]

    // MARK: - Types

    public enum Theme: String, Codable, Sendable {
        case light
        case dark
        case system
    }

    // MARK: - Validation Errors

    public enum ValidationError: Error, LocalizedError {
        case invalidThreshold(value: TimeInterval, validRange: ClosedRange<TimeInterval>)

        public var errorDescription: String? {
            switch self {
            case .invalidThreshold(let value, let validRange):
                return "Invalid inactivity threshold: \(value) seconds. Must be between \(validRange.lowerBound) and \(validRange.upperBound) seconds."
            }
        }
    }

    // MARK: - Constants

    /// Valid range for inactivity threshold (15 minutes to 4 hours)
    public static let inactivityThresholdRange: ClosedRange<TimeInterval> = (15 * 60)...(4 * 60 * 60)

    // MARK: - Defaults

    /// Default user settings
    public static let `default` = try! UserSettings(
        contextHighlightingEnabled: true,
        autoRearrangementEnabled: false,
        cleanupSuggestionsEnabled: true,
        inactivityThreshold: 30 * 60, // 30 minutes
        autoCloseEnabled: false,
        autoCloseUngroupedOnly: true,
        theme: .system,
        showFavicons: true,
        showTabCounts: true,
        aiAnalysisConsent: false,
        excludedDomains: []
    )

    // MARK: - Initialization

    /// Creates user settings
    ///
    /// - Parameters:
    ///   - contextHighlightingEnabled: Enable context highlighting
    ///   - autoRearrangementEnabled: Enable auto-rearrangement
    ///   - cleanupSuggestionsEnabled: Enable cleanup suggestions
    ///   - inactivityThreshold: Inactivity threshold (15min to 4hrs)
    ///   - autoCloseEnabled: Enable auto-close
    ///   - autoCloseUngroupedOnly: Auto-close only ungrouped tabs
    ///   - theme: UI theme preference
    ///   - showFavicons: Show favicons in UI
    ///   - showTabCounts: Show tab counts on groups
    ///   - aiAnalysisConsent: User consent for AI analysis
    ///   - excludedDomains: Domains to exclude from AI
    /// - Throws: `ValidationError` if validation fails
    public init(
        contextHighlightingEnabled: Bool = true,
        autoRearrangementEnabled: Bool = false,
        cleanupSuggestionsEnabled: Bool = true,
        inactivityThreshold: TimeInterval = 30 * 60,
        autoCloseEnabled: Bool = false,
        autoCloseUngroupedOnly: Bool = true,
        theme: Theme = .system,
        showFavicons: Bool = true,
        showTabCounts: Bool = true,
        aiAnalysisConsent: Bool = false,
        excludedDomains: [String] = []
    ) throws {
        // Validate inactivity threshold
        guard Self.inactivityThresholdRange.contains(inactivityThreshold) else {
            throw ValidationError.invalidThreshold(
                value: inactivityThreshold,
                validRange: Self.inactivityThresholdRange
            )
        }

        self.contextHighlightingEnabled = contextHighlightingEnabled
        self.autoRearrangementEnabled = autoRearrangementEnabled
        self.cleanupSuggestionsEnabled = cleanupSuggestionsEnabled
        self.inactivityThreshold = inactivityThreshold
        self.autoCloseEnabled = autoCloseEnabled
        self.autoCloseUngroupedOnly = autoCloseUngroupedOnly
        self.theme = theme
        self.showFavicons = showFavicons
        self.showTabCounts = showTabCounts
        self.aiAnalysisConsent = aiAnalysisConsent
        self.excludedDomains = excludedDomains
    }

    // MARK: - Mutations (Value Semantics)

    /// Returns settings with updated context highlighting toggle
    public func withContextHighlighting(_ enabled: Bool) throws -> UserSettings {
        try UserSettings(
            contextHighlightingEnabled: enabled,
            autoRearrangementEnabled: autoRearrangementEnabled,
            cleanupSuggestionsEnabled: cleanupSuggestionsEnabled,
            inactivityThreshold: inactivityThreshold,
            autoCloseEnabled: autoCloseEnabled,
            autoCloseUngroupedOnly: autoCloseUngroupedOnly,
            theme: theme,
            showFavicons: showFavicons,
            showTabCounts: showTabCounts,
            aiAnalysisConsent: aiAnalysisConsent,
            excludedDomains: excludedDomains
        )
    }

    /// Returns settings with updated auto-rearrangement toggle
    public func withAutoRearrangement(_ enabled: Bool) throws -> UserSettings {
        try UserSettings(
            contextHighlightingEnabled: contextHighlightingEnabled,
            autoRearrangementEnabled: enabled,
            cleanupSuggestionsEnabled: cleanupSuggestionsEnabled,
            inactivityThreshold: inactivityThreshold,
            autoCloseEnabled: autoCloseEnabled,
            autoCloseUngroupedOnly: autoCloseUngroupedOnly,
            theme: theme,
            showFavicons: showFavicons,
            showTabCounts: showTabCounts,
            aiAnalysisConsent: aiAnalysisConsent,
            excludedDomains: excludedDomains
        )
    }

    /// Returns settings with updated cleanup suggestions toggle
    public func withCleanupSuggestions(_ enabled: Bool) throws -> UserSettings {
        try UserSettings(
            contextHighlightingEnabled: contextHighlightingEnabled,
            autoRearrangementEnabled: autoRearrangementEnabled,
            cleanupSuggestionsEnabled: enabled,
            inactivityThreshold: inactivityThreshold,
            autoCloseEnabled: autoCloseEnabled,
            autoCloseUngroupedOnly: autoCloseUngroupedOnly,
            theme: theme,
            showFavicons: showFavicons,
            showTabCounts: showTabCounts,
            aiAnalysisConsent: aiAnalysisConsent,
            excludedDomains: excludedDomains
        )
    }

    /// Returns settings with updated inactivity threshold
    public func withInactivityThreshold(_ threshold: TimeInterval) throws -> UserSettings {
        try UserSettings(
            contextHighlightingEnabled: contextHighlightingEnabled,
            autoRearrangementEnabled: autoRearrangementEnabled,
            cleanupSuggestionsEnabled: cleanupSuggestionsEnabled,
            inactivityThreshold: threshold,
            autoCloseEnabled: autoCloseEnabled,
            autoCloseUngroupedOnly: autoCloseUngroupedOnly,
            theme: theme,
            showFavicons: showFavicons,
            showTabCounts: showTabCounts,
            aiAnalysisConsent: aiAnalysisConsent,
            excludedDomains: excludedDomains
        )
    }

    /// Returns settings with updated auto-close ungrouped only toggle
    public func withAutoCloseUngroupedOnly(_ enabled: Bool) throws -> UserSettings {
        try UserSettings(
            contextHighlightingEnabled: contextHighlightingEnabled,
            autoRearrangementEnabled: autoRearrangementEnabled,
            cleanupSuggestionsEnabled: cleanupSuggestionsEnabled,
            inactivityThreshold: inactivityThreshold,
            autoCloseEnabled: autoCloseEnabled,
            autoCloseUngroupedOnly: enabled,
            theme: theme,
            showFavicons: showFavicons,
            showTabCounts: showTabCounts,
            aiAnalysisConsent: aiAnalysisConsent,
            excludedDomains: excludedDomains
        )
    }

    /// Returns settings with updated theme
    public func withTheme(_ newTheme: Theme) throws -> UserSettings {
        try UserSettings(
            contextHighlightingEnabled: contextHighlightingEnabled,
            autoRearrangementEnabled: autoRearrangementEnabled,
            cleanupSuggestionsEnabled: cleanupSuggestionsEnabled,
            inactivityThreshold: inactivityThreshold,
            autoCloseEnabled: autoCloseEnabled,
            autoCloseUngroupedOnly: autoCloseUngroupedOnly,
            theme: newTheme,
            showFavicons: showFavicons,
            showTabCounts: showTabCounts,
            aiAnalysisConsent: aiAnalysisConsent,
            excludedDomains: excludedDomains
        )
    }

    /// Returns settings with updated AI consent
    public func withAIConsent(_ consent: Bool) throws -> UserSettings {
        try UserSettings(
            contextHighlightingEnabled: contextHighlightingEnabled,
            autoRearrangementEnabled: autoRearrangementEnabled,
            cleanupSuggestionsEnabled: cleanupSuggestionsEnabled,
            inactivityThreshold: inactivityThreshold,
            autoCloseEnabled: autoCloseEnabled,
            autoCloseUngroupedOnly: autoCloseUngroupedOnly,
            theme: theme,
            showFavicons: showFavicons,
            showTabCounts: showTabCounts,
            aiAnalysisConsent: consent,
            excludedDomains: excludedDomains
        )
    }

    // MARK: - Computed Properties

    /// Formatted inactivity threshold for display
    public var inactivityThresholdFormatted: String {
        let minutes = Int(inactivityThreshold / 60)
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
}
