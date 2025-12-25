import Testing
import Foundation
@testable import TabOrganizerCore

@Suite("UserSettings Model Tests")
struct UserSettingsTests {
    
    @Test("UserSettings initialization with defaults")
    func testInitializationWithDefaults() {
        let settings = UserSettings()
        
        #expect(settings.inactivityThreshold == UserSettings.defaultInactivityThreshold)
        #expect(settings.contextHighlightingEnabled == true)
        #expect(settings.autoRearrangementEnabled == false)
        #expect(settings.autoCleanupEnabled == false)
        #expect(settings.autoCleanupCriteria == nil)
        #expect(settings.keyboardShortcuts.isEmpty)
    }
    
    @Test("UserSettings defaultSettings provides expected values")
    func testDefaultSettings() {
        let settings = UserSettings.defaultSettings()
        
        #expect(settings.privacyConsents["tabTracking"] == true)
        #expect(settings.privacyConsents["contextAnalysis"] == true)
    }
    
    @Test("UserSettings validates successfully with valid threshold")
    func testValidationSucceedsWithValidThreshold() throws {
        let settings = UserSettings(inactivityThreshold: 1800) // 30 minutes
        
        // Should not throw
        try settings.validate()
    }
    
    @Test("UserSettings validation fails with threshold too low")
    func testValidationFailsWithThresholdTooLow() {
        let settings = UserSettings(inactivityThreshold: 300) // 5 minutes, below min
        
        #expect(throws: SettingsValidationError.self) {
            try settings.validate()
        }
    }
    
    @Test("UserSettings validation fails with threshold too high")
    func testValidationFailsWithThresholdTooHigh() {
        let settings = UserSettings(inactivityThreshold: 20000) // Over 4 hours
        
        #expect(throws: SettingsValidationError.self) {
            try settings.validate()
        }
    }
    
    @Test("UserSettings validation succeeds with minimum threshold")
    func testValidationSucceedsWithMinimumThreshold() throws {
        let settings = UserSettings(inactivityThreshold: UserSettings.minInactivityThreshold)
        
        // Should not throw
        try settings.validate()
    }
    
    @Test("UserSettings validation succeeds with maximum threshold")
    func testValidationSucceedsWithMaximumThreshold() throws {
        let settings = UserSettings(inactivityThreshold: UserSettings.maxInactivityThreshold)
        
        // Should not throw
        try settings.validate()
    }
    
    @Test("UserSettings validation fails when autoRearrangement enabled without contextHighlighting")
    func testValidationFailsWhenAutoRearrangementWithoutContextHighlighting() {
        let settings = UserSettings(
            contextHighlightingEnabled: false,
            autoRearrangementEnabled: true
        )
        
        #expect(throws: SettingsValidationError.self) {
            try settings.validate()
        }
    }
    
    @Test("UserSettings validation succeeds when both features enabled")
    func testValidationSucceedsWhenBothFeaturesEnabled() throws {
        let settings = UserSettings(
            contextHighlightingEnabled: true,
            autoRearrangementEnabled: true
        )
        
        // Should not throw
        try settings.validate()
    }
    
    @Test("UserSettings validation fails when autoCleanup enabled without criteria")
    func testValidationFailsWhenAutoCleanupWithoutCriteria() {
        let settings = UserSettings(
            autoCleanupEnabled: true,
            autoCleanupCriteria: nil
        )
        
        #expect(throws: SettingsValidationError.self) {
            try settings.validate()
        }
    }
    
    @Test("UserSettings validation succeeds when autoCleanup enabled with criteria")
    func testValidationSucceedsWhenAutoCleanupWithCriteria() throws {
        let settings = UserSettings(
            autoCleanupEnabled: true,
            autoCleanupCriteria: .ungroupedOnly
        )
        
        // Should not throw
        try settings.validate()
    }
    
    @Test("UserSettings is Codable")
    func testCodable() throws {
        let original = UserSettings(
            inactivityThreshold: 3600,
            contextHighlightingEnabled: true,
            autoRearrangementEnabled: true,
            autoCleanupEnabled: false,
            keyboardShortcuts: ["createGroup": "cmd+g"]
        )
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserSettings.self, from: encoded)
        
        #expect(decoded.id == original.id)
        #expect(decoded.inactivityThreshold == original.inactivityThreshold)
        #expect(decoded.contextHighlightingEnabled == original.contextHighlightingEnabled)
        #expect(decoded.autoRearrangementEnabled == original.autoRearrangementEnabled)
        #expect(decoded.keyboardShortcuts == original.keyboardShortcuts)
    }
    
    @Test("CleanupCriteria is Codable")
    func testCleanupCriteriaCodable() throws {
        let criteria: [CleanupCriteria] = [
            .ungroupedOnly,
            .allInactive,
            .excludePinned,
            .excludeSpecificDomains
        ]
        
        for criterion in criteria {
            let encoded = try JSONEncoder().encode(criterion)
            let decoded = try JSONDecoder().decode(CleanupCriteria.self, from: encoded)
            #expect(decoded == criterion)
        }
    }
}
