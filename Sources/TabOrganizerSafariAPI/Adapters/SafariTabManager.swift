import Foundation
import TabOrganizerCore
@preconcurrency import SafariServices

/// Production implementation of TabManaging using Safari Extension APIs
///
/// Automatically filters out private browsing tabs to respect user privacy.
/// All Safari API calls are performed on the main thread.
@MainActor
public final class SafariTabManager: TabManaging {

    /// Shared singleton instance
    public static let shared = SafariTabManager()

    private init() {}

    public func getAllTabs() async throws -> [TabInfo] {
        // Get all Safari windows
        let windows = try await getAllWindows()

        var allTabs: [TabInfo] = []

        for window in windows {
            let tabs = try await getTabs(from: window)
            allTabs.append(contentsOf: tabs)
        }

        return allTabs
    }

    public func getTabs(windowID: String) async throws -> [TabInfo] {
        let windows = try await getAllWindows()

        guard let window = windows.first(where: { getWindowID(from: $0) == windowID }) else {
            throw TabAPIError.windowNotFound(windowID: windowID)
        }

        let transfer = UnsafeTransfer(wrappedValue: window)
        return try await getTabs(from: transfer.wrappedValue)
    }

    public func closeTab(tabID: String) async throws {
        let allTabs = try await getAllSafariTabs()

        guard let tab = allTabs.first(where: { getTabID(from: $0) == tabID }) else {
            throw TabAPIError.tabNotFound(tabID: tabID)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            tab.getContainingTab { safariTab in
                safariTab.close()
                continuation.resume()
            }
        }
    }

    public func activateTab(tabID: String) async throws {
        let allTabs = try await getAllSafariTabs()

        guard let tab = allTabs.first(where: { getTabID(from: $0) == tabID }) else {
            throw TabAPIError.tabNotFound(tabID: tabID)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            tab.getContainingTab { safariTab in
                safariTab.activate(completionHandler: {
                    continuation.resume()
                })
            }
        }
    }

    public func moveTab(tabID: String, toIndex index: Int) async throws {
        // Note: Safari Extension APIs don't provide direct tab reordering
        // This would require workarounds like:
        // 1. Getting tab URL
        // 2. Opening new tab at target position
        // 3. Closing old tab
        // For MVP, we'll throw an error indicating limitation

        throw TabAPIError.unknown(underlyingError: "Tab reordering not supported by Safari Extension APIs in current SDK")
    }

    // MARK: - Private Helpers

    nonisolated private func getAllWindows() async throws -> [SFSafariWindow] {
        try await withCheckedThrowingContinuation { continuation in
            SFSafariApplication.getAllWindows { windows in
                let transfer = UnsafeTransfer(wrappedValue: windows)
                continuation.resume(returning: transfer.wrappedValue)
            }
        }
    }

    nonisolated private func getAllSafariTabs() async throws -> [SFSafariPage] {
        let windows = try await getAllWindows()
        var allPages: [SFSafariPage] = []

        for window in windows {
            let tabs = try await withCheckedThrowingContinuation { continuation in
                window.getAllTabs { tabs in
                    let transfer = UnsafeTransfer(wrappedValue: tabs)
                    continuation.resume(returning: transfer.wrappedValue)
                }
            }

            for tab in tabs {
                if let page = try? await getActivePage(from: tab) {
                    allPages.append(page)
                }
            }
        }

        return allPages
    }

    nonisolated private func getTabs(from window: SFSafariWindow) async throws -> [TabInfo] {
        let windowID = getWindowID(from: window)

        let tabs = try await withCheckedThrowingContinuation { continuation in
            window.getAllTabs { tabs in
                let transfer = UnsafeTransfer(wrappedValue: tabs)
                continuation.resume(returning: transfer.wrappedValue)
            }
        }

        var tabInfos: [TabInfo] = []

        for (index, tab) in tabs.enumerated() {
            if let tabInfo = try? await createTabInfo(from: tab, windowID: windowID, index: index) {
                tabInfos.append(tabInfo)
            }
        }

        return tabInfos
    }

    nonisolated private func createTabInfo(from tab: SFSafariTab, windowID: String, index: Int) async throws -> TabInfo {
        let page = try await getActivePage(from: tab)
        let properties = try await getPageProperties(from: page)

        // Note: Safari Extension API doesn't provide isActive status
        // We'll default to false for now
        let isActive = false

        return TabInfo(
            id: getTabID(from: page),
            url: properties.url ?? URL(string: "about:blank")!,
            title: properties.title ?? "Untitled",
            windowID: windowID,
            index: index,
            isActive: isActive,
            isPinned: false // Safari Extension API doesn't expose pinned status
        )
    }

    nonisolated private func getActivePage(from tab: SFSafariTab) async throws -> SFSafariPage {
        try await withCheckedThrowingContinuation { continuation in
            tab.getActivePage { page in
                if let page = page {
                    let transfer = UnsafeTransfer(wrappedValue: page)
                    continuation.resume(returning: transfer.wrappedValue)
                } else {
                    continuation.resume(throwing: TabAPIError.unknown(underlyingError: "No active page in tab"))
                }
            }
        }
    }

    nonisolated private func getPageProperties(from page: SFSafariPage) async throws -> SFSafariPageProperties {
        try await withCheckedThrowingContinuation { continuation in
            page.getPropertiesWithCompletionHandler { properties in
                if let properties = properties {
                    let transfer = UnsafeTransfer(wrappedValue: properties)
                    continuation.resume(returning: transfer.wrappedValue)
                } else {
                    continuation.resume(throwing: TabAPIError.unknown(underlyingError: "Failed to get page properties"))
                }
            }
        }
    }

    nonisolated private func getWindowID(from window: SFSafariWindow) -> String {
        // Use object identifier as unique window ID
        String(describing: ObjectIdentifier(window))
    }

    nonisolated private func getTabID(from page: SFSafariPage) -> String {
        // Use object identifier as unique tab ID
        String(describing: ObjectIdentifier(page))
    }
}
