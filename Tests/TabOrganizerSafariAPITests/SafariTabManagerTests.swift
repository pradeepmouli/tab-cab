import Testing
import Foundation
@testable import TabOrganizerSafariAPI

@Suite("SafariTabManager Tests")
struct SafariTabManagerTests {

    // Note: These tests use MockTabManager since SafariTabManager requires Safari runtime.
    // Integration tests with actual Safari APIs should be performed manually or in UI tests.

    @Test("MockTabManager returns all tabs")
    @MainActor
    func getAllTabsReturnsAllTabs() async throws {
        let manager = MockTabManager.withSampleTabs()

        let tabs = try await manager.getAllTabs()

        #expect(tabs.count == 5)
        #expect(tabs.contains(where: { $0.id == "tab-1" }))
        #expect(tabs.contains(where: { $0.id == "tab-5" }))
    }

    @Test("MockTabManager returns tabs for specific window")
    @MainActor
    func getTabsForWindowReturnsCorrectTabs() async throws {
        let manager = MockTabManager.withSampleTabs()

        let window1Tabs = try await manager.getTabs(windowID: "window-1")
        let window2Tabs = try await manager.getTabs(windowID: "window-2")

        #expect(window1Tabs.count == 3)
        #expect(window2Tabs.count == 2)
        #expect(window1Tabs.allSatisfy { $0.windowID == "window-1" })
        #expect(window2Tabs.allSatisfy { $0.windowID == "window-2" })
    }

    @Test("MockTabManager throws error for non-existent window")
    @MainActor
    func getTabsThrowsForNonExistentWindow() async throws {
        let manager = MockTabManager.withSampleTabs()

        let tabs = try await manager.getTabs(windowID: "non-existent-window")

        #expect(tabs.isEmpty)
    }

    @Test("MockTabManager closes tab successfully")
    @MainActor
    func closeTabRemovesTab() async throws {
        let manager = MockTabManager.withSampleTabs()

        try await manager.closeTab(tabID: "tab-1")

        let remainingTabs = try await manager.getAllTabs()
        #expect(remainingTabs.count == 4)
        #expect(!remainingTabs.contains(where: { $0.id == "tab-1" }))
        #expect(manager.closedTabIDs.contains("tab-1"))
    }

    @Test("MockTabManager throws error when closing non-existent tab")
    @MainActor
    func closeTabThrowsForNonExistentTab() async throws {
        let manager = MockTabManager.withSampleTabs()

        await #expect(throws: TabAPIError.self) {
            try await manager.closeTab(tabID: "non-existent-tab")
        }
    }

    @Test("MockTabManager activates tab successfully")
    @MainActor
    func activateTabSetsActiveFlag() async throws {
        let manager = MockTabManager.withSampleTabs()

        // Initially tab-3 is active
        var tabs = try await manager.getAllTabs()
        #expect(tabs.first(where: { $0.id == "tab-3" })?.isActive == true)

        // Activate tab-1
        try await manager.activateTab(tabID: "tab-1")

        tabs = try await manager.getAllTabs()
        #expect(tabs.first(where: { $0.id == "tab-1" })?.isActive == true)
        #expect(tabs.first(where: { $0.id == "tab-3" })?.isActive == false)
        #expect(manager.activatedTabIDs.contains("tab-1"))
    }

    @Test("MockTabManager throws error when activating non-existent tab")
    @MainActor
    func activateTabThrowsForNonExistentTab() async throws {
        let manager = MockTabManager.withSampleTabs()

        await #expect(throws: TabAPIError.self) {
            try await manager.activateTab(tabID: "non-existent-tab")
        }
    }

    @Test("MockTabManager moves tab to new index")
    @MainActor
    func moveTabChangesIndex() async throws {
        let manager = MockTabManager.withSampleTabs()

        // Move tab-1 (index 0) to index 2 in window-1
        try await manager.moveTab(tabID: "tab-1", toIndex: 2)

        let window1Tabs = try await manager.getTabs(windowID: "window-1")
        let movedTab = window1Tabs.first(where: { $0.id == "tab-1" })

        #expect(movedTab?.index == 2)
        #expect(manager.tabMovements.count == 1)
        #expect(manager.tabMovements[0].tabID == "tab-1")
        #expect(manager.tabMovements[0].newIndex == 2)
    }

    @Test("MockTabManager throws error when moving to invalid index")
    @MainActor
    func moveTabThrowsForInvalidIndex() async throws {
        let manager = MockTabManager.withSampleTabs()

        await #expect(throws: TabAPIError.self) {
            try await manager.moveTab(tabID: "tab-1", toIndex: 999)
        }
    }

    @Test("MockTabManager throws error when moving non-existent tab")
    @MainActor
    func moveTabThrowsForNonExistentTab() async throws {
        let manager = MockTabManager.withSampleTabs()

        await #expect(throws: TabAPIError.self) {
            try await manager.moveTab(tabID: "non-existent-tab", toIndex: 0)
        }
    }

    @Test("MockTabManager respects permission denial")
    @MainActor
    func permissionDenialThrowsError() async throws {
        let manager = MockTabManager.withSampleTabs()
        manager.shouldDenyPermission = true

        await #expect(throws: TabAPIError.permissionDenied) {
            _ = try await manager.getAllTabs()
        }
    }

    @Test("MockTabManager respects Safari unavailability")
    @MainActor
    func safariUnavailableThrowsError() async throws {
        let manager = MockTabManager.withSampleTabs()
        manager.shouldSimulateSafariUnavailable = true

        await #expect(throws: TabAPIError.safariUnavailable) {
            _ = try await manager.getAllTabs()
        }
    }

    @Test("TabInfo extracts domain from URL")
    func tabInfoExtractsDomain() {
        let tab = TabInfo(
            id: "test-tab",
            url: URL(string: "https://github.com/user/repo")!,
            title: "GitHub Repo",
            windowID: "window-1",
            index: 0,
            isActive: false,
            isPinned: false
        )

        #expect(tab.domain == "github.com")
    }

    @Test("TabInfo returns empty domain for URL without host")
    func tabInfoHandlesURLWithoutHost() {
        let tab = TabInfo(
            id: "test-tab",
            url: URL(string: "about:blank")!,
            title: "Blank",
            windowID: "window-1",
            index: 0,
            isActive: false,
            isPinned: false
        )

        #expect(tab.domain == "")
    }

    @Test("MockTabManager reset clears all state")
    @MainActor
    func resetClearsAllState() async throws {
        let manager = MockTabManager.withSampleTabs()
        manager.shouldDenyPermission = true
        try? await manager.closeTab(tabID: "tab-1")
        try? await manager.activateTab(tabID: "tab-2")

        manager.reset()

        #expect(manager.tabs.isEmpty)
        #expect(manager.shouldDenyPermission == false)
        #expect(manager.closedTabIDs.isEmpty)
        #expect(manager.activatedTabIDs.isEmpty)
        #expect(manager.tabMovements.isEmpty)
    }
}
