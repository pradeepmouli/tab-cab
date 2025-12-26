import Testing
import Foundation
@testable import TabOrganizerCore

@Suite("Model Tests")
struct ModelTests {

    // MARK: - TabAssociation Tests

    @Test("TabAssociation validates name is not empty")
    func tabGroupRejectsEmptyName() throws {
        #expect(throws: TabAssociation.ValidationError.nameEmpty) {
            try TabAssociation(name: "")
        }
    }

    @Test("TabAssociation validates name length")
    func tabGroupRejectsLongName() throws {
        let longName = String(repeating: "a", count: 51)
        #expect(throws: TabAssociation.ValidationError.nameTooLong) {
            try TabAssociation(name: longName)
        }
    }

    @Test("TabAssociation accepts valid name")
    func tabGroupAcceptsValidName() throws {
        let group = try TabAssociation(name: "Work")
        #expect(group.name == "Work")
    }

    @Test("TabAssociation validates hex color format")
    func tabGroupValidatesHexColor() throws {
        #expect(throws: TabAssociation.ValidationError.invalidColorFormat) {
            try TabAssociation(name: "Test", color: "invalid")
        }

        #expect(throws: TabAssociation.ValidationError.invalidColorFormat) {
            try TabAssociation(name: "Test", color: "#GGGGGG")
        }

        // Valid hex color should work
        let group = try TabAssociation(name: "Test", color: "#007AFF")
        #expect(group.color == "#007AFF")
    }

    @Test("TabAssociation accepts predefined color names")
    func tabGroupAcceptsPredefinedColors() throws {
        let group = try TabAssociation(name: "Test", color: "blue")
        #expect(group.color == "blue")
    }

    @Test("TabAssociation allows empty tab list")
    func tabGroupAllowsEmptyTabs() throws {
        let group = try TabAssociation(name: "Empty Group")
        #expect(group.isEmpty)
        #expect(group.tabCount == 0)
    }

    @Test("TabAssociation withTabAdded adds tab")
    func tabGroupAddsTab() throws {
        let group = try TabAssociation(name: "Test")
        let updated = try group.withTabAdded("tab-1")

        #expect(updated.tabIDs.contains("tab-1"))
        #expect(updated.tabCount == 1)
    }

    @Test("TabAssociation withTabAdded prevents duplicates")
    func tabGroupPreventsDuplicateTabs() throws {
        let group = try TabAssociation(name: "Test", tabIDs: ["tab-1"])
        let updated = try group.withTabAdded("tab-1")

        #expect(updated.tabCount == 1)
        #expect(updated.tabIDs == group.tabIDs)
    }

    @Test("TabAssociation withTabRemoved removes tab")
    func tabGroupRemovesTab() throws {
        let group = try TabAssociation(name: "Test", tabIDs: ["tab-1", "tab-2"])
        let updated = try group.withTabRemoved("tab-1")

        #expect(!updated.tabIDs.contains("tab-1"))
        #expect(updated.tabCount == 1)
    }

    @Test("TabAssociation withCollapsedToggled toggles state")
    func tabGroupTogglesCollapsed() throws {
        let group = try TabAssociation(name: "Test", collapsed: false)
        let toggled = try group.withCollapsedToggled()

        #expect(toggled.collapsed == true)
    }

    @Test("TabAssociation tracks AI suggested metadata")
    func tabGroupTracksAISuggested() throws {
        let group = try TabAssociation(name: "AI Group", metadata: ["aiSuggested": "true"])
        #expect(group.isAISuggested)

        let manual = try TabAssociation(name: "Manual Group")
        #expect(!manual.isAISuggested)
    }

    // MARK: - Tab Tests

    @Test("Tab extracts domain from URL")
    func tabExtractsDomain() {
        let tab = Tab(
            id: "test-tab",
            url: URL(string: "https://github.com/user/repo")!,
            title: "GitHub"
        )

        #expect(tab.domain == "github.com")
    }

    @Test("Tab defaults title to URL when empty")
    func tabDefaultsTitle() {
        let url = URL(string: "https://example.com")!
        let tab = Tab(id: "test", url: url, title: "")

        #expect(tab.title == url.absoluteString)
    }

    @Test("Tab detects same domain")
    func tabDetectsSameDomain() {
        let tab1 = Tab(id: "1", url: URL(string: "https://github.com/repo1")!)
        let tab2 = Tab(id: "2", url: URL(string: "https://github.com/repo2")!)
        let tab3 = Tab(id: "3", url: URL(string: "https://gitlab.com/repo")!)

        #expect(tab1.isSameDomain(as: tab2))
        #expect(!tab1.isSameDomain(as: tab3))
    }

    @Test("Tab tracks inactivity")
    func tabTracksInactivity() {
        let pastDate = Date().addingTimeInterval(-35 * 60) // 35 minutes ago
        let tab = Tab(id: "test", url: URL(string: "https://example.com")!, lastViewedAt: pastDate)

        #expect(tab.isInactive(threshold: 30 * 60))
        #expect(tab.timeSinceLastView > 30 * 60)
    }

    @Test("Tab withActive updates timestamp")
    func tabUpdatesLastViewedOnActive() {
        let oldDate = Date().addingTimeInterval(-100)
        let tab = Tab(id: "test", url: URL(string: "https://example.com")!, lastViewedAt: oldDate)

        let activated = tab.withActive(true)

        #expect(activated.isActive)
        #expect(activated.lastViewedAt > oldDate)
    }

    @Test("Tab displayTitle truncates long titles")
    func tabTruncatesLongTitles() {
        let longTitle = String(repeating: "a", count: 100)
        let tab = Tab(id: "test", url: URL(string: "https://example.com")!, title: longTitle)

        let display = tab.displayTitle(maxLength: 50)

        #expect(display.count == 50)
        #expect(display.hasSuffix("..."))
    }

    // MARK: - UserSettings Tests

    @Test("UserSettings has valid defaults")
    func userSettingsHasDefaults() {
        let defaults = UserSettings.default

        #expect(defaults.contextHighlightingEnabled == true)
        #expect(defaults.autoRearrangementEnabled == false)
        #expect(defaults.inactivityThreshold == 30 * 60)
    }

    @Test("UserSettings validates inactivity threshold")
    func userSettingsValidatesThreshold() throws {
        // Too low
        #expect(throws: UserSettings.ValidationError.invalidThreshold) {
            try UserSettings(inactivityThreshold: 10 * 60) // 10 minutes (below minimum)
        }

        // Too high
        #expect(throws: UserSettings.ValidationError.invalidThreshold) {
            try UserSettings(inactivityThreshold: 5 * 60 * 60) // 5 hours (above maximum)
        }

        // Valid range
        let settings = try UserSettings(inactivityThreshold: 60 * 60) // 1 hour
        #expect(settings.inactivityThreshold == 60 * 60)
    }

    @Test("UserSettings formats threshold for display")
    func userSettingsFormatsThreshold() throws {
        let settings30Min = try UserSettings(inactivityThreshold: 30 * 60)
        #expect(settings30Min.inactivityThresholdFormatted == "30 minutes")

        let settings2Hours = try UserSettings(inactivityThreshold: 120 * 60)
        #expect(settings2Hours.inactivityThresholdFormatted == "2 hours")

        let settings90Min = try UserSettings(inactivityThreshold: 90 * 60)
        #expect(settings90Min.inactivityThresholdFormatted == "1h 30m")
    }

    // MARK: - ContextAnalysis Tests

    @Test("ContextAnalysis validates similarity scores")
    func contextAnalysisValidatesSimilarityScores() throws {
        #expect(throws: ContextAnalysis.ValidationError.invalidSimilarityScore) {
            try ContextAnalysis(
                sourceTabID: "tab-1",
                similarityScores: ["tab-2": 1.5], // Invalid: > 1.0
                confidence: 0.8
            )
        }

        #expect(throws: ContextAnalysis.ValidationError.invalidSimilarityScore) {
            try ContextAnalysis(
                sourceTabID: "tab-1",
                similarityScores: ["tab-2": -0.1], // Invalid: < 0.0
                confidence: 0.8
            )
        }
    }

    @Test("ContextAnalysis validates confidence")
    func contextAnalysisValidatesConfidence() throws {
        #expect(throws: ContextAnalysis.ValidationError.invalidConfidence) {
            try ContextAnalysis(sourceTabID: "tab-1", confidence: 1.5)
        }
    }

    @Test("ContextAnalysis detects expiration")
    func contextAnalysisDetectsExpiration() throws {
        let pastDate = Date().addingTimeInterval(-10 * 60) // 10 minutes ago
        let analysis = try ContextAnalysis(
            sourceTabID: "tab-1",
            confidence: 0.8,
            analyzedAt: pastDate,
            expiresAt: pastDate.addingTimeInterval(5 * 60) // Expired 5 minutes ago
        )

        #expect(analysis.isExpired)
        #expect(!analysis.isValid)
    }

    @Test("ContextAnalysis calculates average similarity")
    func contextAnalysisCalculatesAverage() throws {
        let analysis = try ContextAnalysis(
            sourceTabID: "tab-1",
            relatedTabIDs: ["tab-2", "tab-3"],
            similarityScores: ["tab-2": 0.8, "tab-3": 0.6],
            confidence: 0.9
        )

        #expect(analysis.averageSimilarity == 0.7)
    }

    @Test("ContextAnalysis sorts tabs by similarity")
    func contextAnalysisSortsTabs() throws {
        let analysis = try ContextAnalysis(
            sourceTabID: "tab-1",
            relatedTabIDs: ["tab-2", "tab-3", "tab-4"],
            similarityScores: ["tab-2": 0.5, "tab-3": 0.9, "tab-4": 0.7],
            confidence: 0.8
        )

        let sorted = analysis.sortedRelatedTabs()

        #expect(sorted[0].tabID == "tab-3")
        #expect(sorted[0].score == 0.9)
        #expect(sorted[2].tabID == "tab-2")
    }

    @Test("ContextAnalysis filters highly related tabs")
    func contextAnalysisFiltersHighlyRelated() throws {
        let analysis = try ContextAnalysis(
            sourceTabID: "tab-1",
            relatedTabIDs: ["tab-2", "tab-3", "tab-4"],
            similarityScores: ["tab-2": 0.5, "tab-3": 0.9, "tab-4": 0.75],
            confidence: 0.8
        )

        let highlyRelated = analysis.highlyRelatedTabs(threshold: 0.7)

        #expect(highlyRelated.count == 2)
        #expect(highlyRelated.contains("tab-3"))
        #expect(highlyRelated.contains("tab-4"))
    }

    // MARK: - CleanupSuggestion Tests

    @Test("CleanupSuggestion initializes with pending decisions")
    func cleanupSuggestionDefaultsPending() {
        let suggestion = CleanupSuggestion(suggestedTabIDs: ["tab-1", "tab-2"])

        #expect(suggestion.decision(for: "tab-1") == .pending)
        #expect(suggestion.decision(for: "tab-2") == .pending)
        #expect(suggestion.pendingTabIDs.count == 2)
    }

    @Test("CleanupSuggestion tracks user decisions")
    func cleanupSuggestionTracksDecisions() {
        let suggestion = CleanupSuggestion(suggestedTabIDs: ["tab-1", "tab-2", "tab-3"])

        let updated = suggestion
            .withDecision(.accepted, for: "tab-1")
            .withDecision(.rejected, for: "tab-2")
            .withDecision(.kept, for: "tab-3")

        #expect(updated.acceptedTabIDs == ["tab-1"])
        #expect(updated.rejectedTabIDs == ["tab-2"])
        #expect(updated.keptTabIDs == ["tab-3"])
        #expect(updated.allDecided)
    }

    @Test("CleanupSuggestion calculates acceptance rate")
    func cleanupSuggestionCalculatesAcceptanceRate() {
        let suggestion = CleanupSuggestion(suggestedTabIDs: ["tab-1", "tab-2", "tab-3", "tab-4"])

        let updated = suggestion
            .withDecision(.accepted, for: "tab-1")
            .withDecision(.accepted, for: "tab-2")
            .withDecision(.rejected, for: "tab-3")
        // tab-4 remains pending

        #expect(updated.acceptanceRate == 2.0 / 3.0) // 2 accepted out of 3 decided
    }

    @Test("CleanupSuggestion sorts by inactivity")
    func cleanupSuggestionSortsByInactivity() {
        let suggestion = CleanupSuggestion(
            suggestedTabIDs: ["tab-1", "tab-2", "tab-3"],
            inactivityDurations: [
                "tab-1": 60 * 60,      // 1 hour
                "tab-2": 120 * 60,     // 2 hours
                "tab-3": 30 * 60       // 30 minutes
            ]
        )

        let sorted = suggestion.sortedByInactivity()

        #expect(sorted[0].tabID == "tab-2")
        #expect(sorted[1].tabID == "tab-1")
        #expect(sorted[2].tabID == "tab-3")
    }

    @Test("CleanupSuggestion formats inactivity duration")
    func cleanupSuggestionFormatsInactivity() {
        let suggestion = CleanupSuggestion(
            suggestedTabIDs: ["tab-1", "tab-2", "tab-3"],
            inactivityDurations: [
                "tab-1": 45 * 60,          // 45 minutes
                "tab-2": 120 * 60,         // 2 hours
                "tab-3": 2 * 24 * 60 * 60  // 2 days
            ]
        )

        #expect(suggestion.formattedInactivity(for: "tab-1") == "45 minutes")
        #expect(suggestion.formattedInactivity(for: "tab-2") == "2 hours")
        #expect(suggestion.formattedInactivity(for: "tab-3") == "2 days")
    }

    @Test("CleanupSuggestion marks completion")
    func cleanupSuggestionMarksCompletion() {
        let suggestion = CleanupSuggestion(suggestedTabIDs: ["tab-1"])
        let completed = suggestion.withCompleted()

        #expect(completed.isCompleted)
        #expect(completed.completedAt != nil)
    }
}
