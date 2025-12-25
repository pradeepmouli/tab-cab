import Foundation
import TabOrganizerSafariAPI

/// Mock implementation of TabManaging for unit tests.
///
/// Provides controllable, deterministic tab operations for testing
/// without requiring Safari Extension APIs or a running Safari instance.
@MainActor
public final class MockTabManager: TabManaging {
    /// Stubbed tabs to return from getAllTabs()
    public var stubbedTabs: [TabInfo] = []
    
    /// Tracks calls to activateTab(id:)
    public var activatedTabIDs: [String] = []
    
    /// Tracks calls to closeTab(id:)
    public var closedTabIDs: [String] = []
    
    /// Tracks calls to openTab(url:)
    public var openedURLs: [URL] = []
    
    /// Tracks calls to moveTab(id:toIndex:)
    public var movedTabs: [(id: String, index: Int)] = []
    
    /// Error to throw from operations (for error testing)
    public var errorToThrow: TabAPIError?
    
    /// Counter for generating new tab IDs
    private var nextTabID = 1
    
    public init() {}
    
    public func getAllTabs() async throws -> [TabInfo] {
        if let error = errorToThrow {
            throw error
        }
        return stubbedTabs
    }
    
    public func activateTab(id: String) async throws {
        if let error = errorToThrow {
            throw error
        }
        
        guard stubbedTabs.contains(where: { $0.id == id }) else {
            throw TabAPIError.tabNotFound(id)
        }
        
        activatedTabIDs.append(id)
    }
    
    public func closeTab(id: String) async throws {
        if let error = errorToThrow {
            throw error
        }
        
        guard stubbedTabs.contains(where: { $0.id == id }) else {
            throw TabAPIError.tabNotFound(id)
        }
        
        // Prevent closing last tab
        if stubbedTabs.count == 1 {
            throw TabAPIError.cannotCloseLastTab
        }
        
        closedTabIDs.append(id)
        stubbedTabs.removeAll { $0.id == id }
    }
    
    public func openTab(url: URL) async throws -> String {
        if let error = errorToThrow {
            throw error
        }
        
        openedURLs.append(url)
        
        let newID = "tab-\(nextTabID)"
        nextTabID += 1
        
        let newTab = TabInfo(
            id: newID,
            url: url,
            title: url.lastPathComponent,
            isActive: false
        )
        stubbedTabs.append(newTab)
        
        return newID
    }
    
    public func moveTab(id: String, toIndex index: Int) async throws {
        if let error = errorToThrow {
            throw error
        }
        
        guard let tabIndex = stubbedTabs.firstIndex(where: { $0.id == id }) else {
            throw TabAPIError.tabNotFound(id)
        }
        
        guard index >= 0 && index < stubbedTabs.count else {
            throw TabAPIError.apiError("Invalid tab index: \(index)")
        }
        
        movedTabs.append((id: id, index: index))
        
        // Simulate moving tab in the array
        let tab = stubbedTabs.remove(at: tabIndex)
        stubbedTabs.insert(tab, at: index)
    }
    
    /// Reset all tracking arrays for a fresh test
    public func reset() {
        stubbedTabs = []
        activatedTabIDs = []
        closedTabIDs = []
        openedURLs = []
        movedTabs = []
        errorToThrow = nil
        nextTabID = 1
    }
}
