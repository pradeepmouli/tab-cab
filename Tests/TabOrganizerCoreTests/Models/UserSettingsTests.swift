import Testing
import Foundation
@testable import TabOrganizerCore

@Suite("UserSettings Model Tests")
struct UserSettingsTests {

    @Test("UserSettings initialization with defaults")
    func testInitializationWithDefaults() throws {
        let settings = try UserSettings()

        #expect(settings.inactivityThreshold == 30 * 60) // 30 minutes default
        #expect(settings.contextHighlightingEnabled == true)
        #expect(settings.autoRearrangementEnabled == false)
        #expect(settings.cleanupSuggestionsEnabled == true)
        #expect(settings.autoCloseEnabled == false)
        #expect(settings.autoCloseUngroupedOnly == true)
    }

    @Test("UserSettings default provides expected values")
    func testDefaultSettings() {
        let settings = UserSettings.default

        #expect(settings.contextHighlightingEnabled == true)
        #expect(settings.aiAnalysisConsent == false) // Default: user must opt-in
        #expect(settings.theme == .system)
    }

    @Test("UserSettings validates successfully with valid threshold")
    func testValidationSucceedsWithValidThreshold() throws {
        // Should not throw with valid threshold
        let settings = try UserSettings(inactivityThreshold: 1800) // 30 minutes
        #expect(settings.inactivityThreshold == 1800)
    }

    @Test("UserSettings validation fails with threshold too low")
    func testValidationFailsWithThresholdTooLow() {
        #expect(throws: UserSettings.ValidationError.self) {
            try UserSettings(inactivityThreshold: 300) // 5 minutes, below min
        }
    }

    @Test("UserSettings validation fails with threshold too high")
    func testValidationFailsWithThresholdTooHigh() {
        #expect(throws: UserSettings.ValidationError.self) {
            try UserSettings(inactivityThreshold: 20000) // Over 4 hours
        }
    }

    @Test("UserSettings validation succeeds with minimum threshold")
    func testValidationSucceedsWithMinimumThreshold() throws {
        let minThreshold = UserSettings.inactivityThresholdRange.lowerBound
        let settings = try UserSettings(inactivityThreshold: minThreshold)
        #expect(settings.inactivityThreshold == minThreshold)
    }

    @Test("UserSettings validation succeeds with maximum threshold")
    func testValidationSucceedsWithMaximumThreshold() throws {
        let maxThreshold = UserSettings.inactivityThresholdRange.upperBound
        let settings = try UserSettings(inactivityThreshold: maxThreshold)
        #expect(settings.inactivityThreshold == maxThreshold)
    }

    @Test("UserSettings allows autoRearrangement with contextHighlighting disabled")
    func testAutoRearrangementWithoutContextHighlighting() throws {
        // The actual implementation doesn't enforce this dependency in initialization
        let settings = try UserSettings(
            contextHighlightingEnabled: false,
            autoRearrangementEnabled: true
        )
        #expect(settings.contextHighlightingEnabled == false)
        #expect(settings.autoRearrangementEnabled == true)
    }

    @Test("UserSettings allows both features enabled")
    func testBothFeaturesEnabled() throws {
        let settings = try UserSettings(
            contextHighlightingEnabled: true,
            autoRearrangementEnabled: true
        )
        #expect(settings.contextHighlightingEnabled == true)
        #expect(settings.autoRearrangementEnabled == true)
    }

    @Test("UserSettings allows autoClose configuration")
    func testAutoCloseConfiguration() throws {
        let settings = try UserSettings(
            autoCloseEnabled: true,
            autoCloseUngroupedOnly: false
        )
        #expect(settings.autoCloseEnabled == true)
        #expect(settings.autoCloseUngroupedOnly == false)
    }

    @Test("UserSettings is Codable")
    func testCodable() throws {
        let original = try UserSettings(
            inactivityThreshold: 3600,
            contextHighlightingEnabled: true,
            autoRearrangementEnabled: true,
            cleanupSuggestionsEnabled: false
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserSettings.self, from: encoded)

        #expect(decoded.inactivityThreshold == original.inactivityThreshold)
        #expect(decoded.contextHighlightingEnabled == original.contextHighlightingEnabled)
        #expect(decoded.autoRearrangementEnabled == original.autoRearrangementEnabled)
        #expect(decoded.cleanupSuggestionsEnabled == original.cleanupSuggestionsEnabled)
    }

    @Test("UserSettings theme is Codable")
    func testThemeCodable() throws {
        let themes: [UserSettings.Theme] = [.light, .dark, .system]

        for theme in themes {
            let encoded = try JSONEncoder().encode(theme)
            let decoded = try JSONDecoder().decode(UserSettings.Theme.self, from: encoded)
            #expect(decoded == theme)
        }
    }

    @Test("UserSettings withContextHighlighting returns new instance")
    func testWithContextHighlighting() throws {
        let original = try UserSettings()
        let modified = try original.withContextHighlighting(false)

        #expect(original.contextHighlightingEnabled == true)
        #expect(modified.contextHighlightingEnabled == false)
    }

    @Test("UserSettings withInactivityThreshold validates threshold")
    func testWithInactivityThresholdValidation() throws {
        let original = try UserSettings()

        // Valid threshold should succeed
        let validModified = try original.withInactivityThreshold(3600)
        #expect(validModified.inactivityThreshold == 3600)

        // Invalid threshold should throw
        #expect(throws: UserSettings.ValidationError.self) {
            try original.withInactivityThreshold(100)
        }
    }
}
