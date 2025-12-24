import Foundation

/// Represents user preferences and feature toggles.
///
/// UserSettings is a singleton entity that persists user configuration across sessions.
public struct UserSettings: Codable, Sendable {
    /// Unique identifier (singleton per user)
    public let id: UUID
    
    /// Cleanup threshold in seconds (default: 1800 = 30 minutes)
    public var inactivityThreshold: TimeInterval
    
    /// Whether to highlight related tabs (default: true)
    public var contextHighlightingEnabled: Bool
    
    /// Whether to auto-move related tabs (default: false)
    public var autoRearrangementEnabled: Bool
    
    /// Whether to auto-close inactive tabs (default: false)
    public var autoCleanupEnabled: Bool
    
    /// Optional criteria for auto-cleanup
    public var autoCleanupCriteria: CleanupCriteria?
    
    /// Map of action to keyboard shortcut
    public var keyboardShortcuts: [String: String]
    
    /// Map of privacy consent types
    public var privacyConsents: [String: Bool]
    
    /// Last settings backup timestamp
    public var lastBackupAt: Date?
    
    /// Settings schema version (for future migrations)
    public let version: Int
    
    /// Default inactivity threshold (30 minutes)
    public static let defaultInactivityThreshold: TimeInterval = 1800
    
    /// Minimum allowed inactivity threshold (15 minutes)
    public static let minInactivityThreshold: TimeInterval = 900
    
    /// Maximum allowed inactivity threshold (4 hours)
    public static let maxInactivityThreshold: TimeInterval = 14400
    
    /// Current settings schema version
    public static let currentVersion = 1
    
    /// Creates a new UserSettings with default values
    public init(
        id: UUID = UUID(),
        inactivityThreshold: TimeInterval = UserSettings.defaultInactivityThreshold,
        contextHighlightingEnabled: Bool = true,
        autoRearrangementEnabled: Bool = false,
        autoCleanupEnabled: Bool = false,
        autoCleanupCriteria: CleanupCriteria? = nil,
        keyboardShortcuts: [String: String] = [:],
        privacyConsents: [String: Bool] = [:],
        lastBackupAt: Date? = nil,
        version: Int = UserSettings.currentVersion
    ) {
        self.id = id
        self.inactivityThreshold = inactivityThreshold
        self.contextHighlightingEnabled = contextHighlightingEnabled
        self.autoRearrangementEnabled = autoRearrangementEnabled
        self.autoCleanupEnabled = autoCleanupEnabled
        self.autoCleanupCriteria = autoCleanupCriteria
        self.keyboardShortcuts = keyboardShortcuts
        self.privacyConsents = privacyConsents
        self.lastBackupAt = lastBackupAt
        self.version = version
    }
    
    /// Creates default settings for a new user
    public static func defaultSettings() -> UserSettings {
        UserSettings(
            privacyConsents: [
                "tabTracking": true,
                "contextAnalysis": true
            ]
        )
    }
    
    /// Validates the settings against business rules
    ///
    /// - Throws: `SettingsValidationError` if any validation rule fails
    public func validate() throws {
        // Inactivity threshold must be within allowed range
        guard inactivityThreshold >= UserSettings.minInactivityThreshold else {
            throw SettingsValidationError.thresholdTooLow(
                min: UserSettings.minInactivityThreshold
            )
        }
        
        guard inactivityThreshold <= UserSettings.maxInactivityThreshold else {
            throw SettingsValidationError.thresholdTooHigh(
                max: UserSettings.maxInactivityThreshold
            )
        }
        
        // Auto-rearrangement requires context highlighting
        if autoRearrangementEnabled && !contextHighlightingEnabled {
            throw SettingsValidationError.invalidDependency(
                feature: "autoRearrangement",
                requires: "contextHighlighting"
            )
        }
        
        // Auto-cleanup requires cleanup criteria
        if autoCleanupEnabled && autoCleanupCriteria == nil {
            throw SettingsValidationError.missingRequiredSetting(
                feature: "autoCleanup",
                setting: "autoCleanupCriteria"
            )
        }
    }
}

/// Criteria for automatic tab cleanup
public enum CleanupCriteria: String, Codable, Sendable {
    /// Only close tabs not in any group
    case ungroupedOnly
    
    /// Close all inactive tabs
    case allInactive
    
    /// Close inactive except pinned
    case excludePinned
    
    /// Close inactive except whitelisted domains
    case excludeSpecificDomains
}

/// Validation errors for UserSettings
public enum SettingsValidationError: Error, LocalizedError, Sendable {
    case thresholdTooLow(min: TimeInterval)
    case thresholdTooHigh(max: TimeInterval)
    case invalidDependency(feature: String, requires: String)
    case missingRequiredSetting(feature: String, setting: String)
    
    public var errorDescription: String? {
        switch self {
        case .thresholdTooLow(let min):
            return "Inactivity threshold must be at least \(Int(min / 60)) minutes"
        case .thresholdTooHigh(let max):
            return "Inactivity threshold cannot exceed \(Int(max / 3600)) hours"
        case .invalidDependency(let feature, let requires):
            return "\(feature) requires \(requires) to be enabled"
        case .missingRequiredSetting(let feature, let setting):
            return "\(feature) requires \(setting) to be configured"
        }
    }
}
