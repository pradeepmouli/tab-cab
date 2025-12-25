import Foundation
@testable import TabOrganizerSafariAPI

/// Mock implementation of TabManaging for testing
///
/// Provides deterministic, controllable tab operations without Safari dependencies.
/// State is stored in-memory and can be manipulated directly for test scenarios.
@MainActor
public final class MockTabManager: TabManaging {

    // MARK: - Mock State

    /// In-memory tab storage
    public var tabs: [TabInfo] = []

    /// Simulates permission denial when true
    public var shouldDenyPermission: Bool = false

    /// Simulates Safari unavailability when true
    public var shouldSimulateSafariUnavailable: Bool = false

    /// Tracks closed tab IDs for verification
    public private(set) var closedTabIDs: [String] = []

    /// Tracks activated tab IDs for verification
    public private(set) var activatedTabIDs: [String] = []

    /// Tracks tab movements: (tabID, newIndex)
    public private(set) var tabMovements: [(tabID: String, newIndex: Int)] = []

    // MARK: - Initialization

    public init() {}

    /// Convenience initializer with sample tabs
    public init(tabs: [TabInfo]) {
        self.tabs = tabs
    }

    // MARK: - TabManaging Implementation

    public func getAllTabs() async throws -> [TabInfo] {
        try checkPermissions()
        return tabs
    }

    public func getTabs(windowID: String) async throws -> [TabInfo] {
        try checkPermissions()
        return tabs.filter { $0.windowID == windowID }
    }

    public func closeTab(tabID: String) async throws {
        try checkPermissions()

        guard tabs.contains(where: { $0.id == tabID }) else {
            throw TabAPIError.tabNotFound(tabID: tabID)
        }

        tabs.removeAll { $0.id == tabID }
        closedTabIDs.append(tabID)
    }

    public func activateTab(tabID: String) async throws {
        try checkPermissions()

        guard let tabIndex = tabs.firstIndex(where: { $0.id == tabID }) else {
            throw TabAPIError.tabNotFound(tabID: tabID)
        }

        // Deactivate all tabs in the same window
        let windowID = tabs[tabIndex].windowID
        for i in tabs.indices where tabs[i].windowID == windowID {
            tabs[i] = TabInfo(
                id: tabs[i].id,
                url: tabs[i].url,
                title: tabs[i].title,
                windowID: tabs[i].windowID,
                index: tabs[i].index,
                isActive: false,
                isPinned: tabs[i].isPinned
            )
        }

        // Activate the target tab
        tabs[tabIndex] = TabInfo(
            id: tabs[tabIndex].id,
            url: tabs[tabIndex].url,
            title: tabs[tabIndex].title,
            windowID: tabs[tabIndex].windowID,
            index: tabs[tabIndex].index,
            isActive: true,
            isPinned: tabs[tabIndex].isPinned
        )

        activatedTabIDs.append(tabID)
    }

    public func moveTab(tabID: String, toIndex index: Int) async throws {
        try checkPermissions()

        guard let currentIndex = tabs.firstIndex(where: { $0.id == tabID }) else {
            throw TabAPIError.tabNotFound(tabID: tabID)
        }

        let tab = tabs[currentIndex]
        let windowTabs = tabs.filter { $0.windowID == tab.windowID }

        guard index >= 0 && index <= windowTabs.count else {
            throw TabAPIError.invalidIndex(index: index, validRange: 0..<windowTabs.count)
        }

        // Cannot move pinned tabs
        guard !tab.isPinned else {
            throw TabAPIError.unknown(underlyingError: "Cannot move pinned tabs")
        }

        // Remove from current position
        tabs.remove(at: currentIndex)

        // Insert at new position
        let movedTab = TabInfo(
            id: tab.id,
            url: tab.url,
            title: tab.title,
            windowID: tab.windowID,
            index: index,
            isActive: tab.isActive,
            isPinned: tab.isPinned
        )

        // Find insertion point in global array
        let tabsBeforeWindow = tabs.filter { $0.windowID < tab.windowID }.count
        let insertionIndex = tabsBeforeWindow + index

        tabs.insert(movedTab, at: min(insertionIndex, tabs.count))

        // Update indices for all tabs in the same window
        reindexTabs(in: tab.windowID)

        tabMovements.append((tabID: tabID, newIndex: index))
    }

    // MARK: - Test Helpers

    /// Resets all mock state
    public func reset() {
        tabs = []
        shouldDenyPermission = false
        shouldSimulateSafariUnavailable = false
        closedTabIDs = []
        activatedTabIDs = []
        tabMovements = []
    }

    /// Adds a sample tab for testing
    public func addTab(
        id: String = UUID().uuidString,
        url: URL = URL(string: "https://example.com")!,
        title: String = "Example",
        windowID: String = "window-1",
        index: Int? = nil,
        isActive: Bool = false,
        isPinned: Bool = false
    ) {
        let tabIndex = index ?? tabs.filter { $0.windowID == windowID }.count
        let tab = TabInfo(
            id: id,
            url: url,
            title: title,
            windowID: windowID,
            index: tabIndex,
            isActive: isActive,
            isPinned: isPinned
        )
        tabs.append(tab)
    }

    /// Creates sample tabs for common test scenarios
    public static func withSampleTabs() -> MockTabManager {
        let manager = MockTabManager()

        // Window 1 tabs
        manager.addTab(id: "tab-1", url: URL(string: "https://github.com")!, title: "GitHub", windowID: "window-1", index: 0)
        manager.addTab(id: "tab-2", url: URL(string: "https://stackoverflow.com")!, title: "Stack Overflow", windowID: "window-1", index: 1)
        manager.addTab(id: "tab-3", url: URL(string: "https://apple.com")!, title: "Apple", windowID: "window-1", index: 2, isActive: true)

        // Window 2 tabs
        manager.addTab(id: "tab-4", url: URL(string: "https://swift.org")!, title: "Swift.org", windowID: "window-2", index: 0)
        manager.addTab(id: "tab-5", url: URL(string: "https://developer.apple.com")!, title: "Apple Developer", windowID: "window-2", index: 1)

        return manager
    }

    // MARK: - Private Helpers

    private func checkPermissions() throws {
        if shouldSimulateSafariUnavailable {
            throw TabAPIError.safariUnavailable
        }

        if shouldDenyPermission {
            throw TabAPIError.permissionDenied
        }
    }

    private func reindexTabs(in windowID: String) {
        let windowTabs = tabs.enumerated().filter { $0.element.windowID == windowID }

        for (newIndex, (globalIndex, tab)) in windowTabs.enumerated() {
            tabs[globalIndex] = TabInfo(
                id: tab.id,
                url: tab.url,
                title: tab.title,
                windowID: tab.windowID,
                index: newIndex,
                isActive: tab.isActive,
                isPinned: tab.isPinned
            )
        }
    }
}
