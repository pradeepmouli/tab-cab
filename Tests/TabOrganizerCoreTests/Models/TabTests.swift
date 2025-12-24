import Testing
import Foundation
@testable import TabOrganizerCore

@Suite("Tab Model Tests")
struct TabTests {
    
    @Test("Tab initialization with required properties")
    func testInitializationWithRequiredProperties() {
        let url = URL(string: "https://github.com/example/repo")!
        let tab = Tab(id: "tab-1", url: url)
        
        #expect(tab.id == "tab-1")
        #expect(tab.url == url)
        #expect(tab.title == url.absoluteString)
        #expect(tab.domain == "github.com")
        #expect(tab.isActive == false)
        #expect(tab.isPinned == false)
        #expect(tab.isPrivate == false)
        #expect(tab.groupID == nil)
    }
    
    @Test("Tab initialization with custom title")
    func testInitializationWithCustomTitle() {
        let url = URL(string: "https://example.com")!
        let tab = Tab(id: "tab-1", url: url, title: "Example Website")
        
        #expect(tab.title == "Example Website")
    }
    
    @Test("Tab initialization with empty title uses URL")
    func testInitializationWithEmptyTitleUsesURL() {
        let url = URL(string: "https://example.com")!
        let tab = Tab(id: "tab-1", url: url, title: "")
        
        #expect(tab.title == url.absoluteString)
    }
    
    @Test("Tab extracts domain from URL")
    func testDomainExtraction() {
        let urls = [
            "https://github.com/user/repo": "github.com",
            "https://www.apple.com/iphone": "www.apple.com",
            "http://localhost:3000/app": "localhost",
            "file:///Users/test/document.txt": "file:///Users/test/document.txt"
        ]
        
        for (urlString, expectedDomain) in urls {
            let url = URL(string: urlString)!
            let tab = Tab(id: "tab-1", url: url)
            #expect(tab.domain == expectedDomain)
        }
    }
    
    @Test("Tab withGroup creates new instance with groupID")
    func testWithGroup() {
        let url = URL(string: "https://example.com")!
        let original = Tab(id: "tab-1", url: url)
        let groupID = UUID()
        let updated = original.withGroup(groupID)
        
        #expect(original.groupID == nil)
        #expect(updated.groupID == groupID)
        #expect(updated.id == original.id)
        #expect(updated.url == original.url)
    }
    
    @Test("Tab withGroup can remove groupID")
    func testWithGroupRemovesGroupID() {
        let url = URL(string: "https://example.com")!
        let groupID = UUID()
        let original = Tab(id: "tab-1", url: url, groupID: groupID)
        let updated = original.withGroup(nil)
        
        #expect(original.groupID == groupID)
        #expect(updated.groupID == nil)
    }
    
    @Test("Tab withUpdatedViewTime updates timestamp")
    func testWithUpdatedViewTime() async {
        let url = URL(string: "https://example.com")!
        let original = Tab(id: "tab-1", url: url)
        
        // Wait a bit to ensure timestamp difference
        try? await Task.sleep(for: .milliseconds(10))
        
        let updated = original.withUpdatedViewTime()
        
        #expect(updated.lastViewedAt > original.lastViewedAt)
    }
    
    @Test("Tab inactiveDuration calculates time since last view")
    func testInactiveDuration() {
        let pastDate = Date(timeIntervalSinceNow: -300) // 5 minutes ago
        let url = URL(string: "https://example.com")!
        let tab = Tab(id: "tab-1", url: url, lastViewedAt: pastDate)
        
        let duration = tab.inactiveDuration()
        
        // Should be approximately 300 seconds (allow 1 second tolerance)
        #expect(duration >= 299 && duration <= 301)
    }
    
    @Test("Tab isInactive returns true for old tabs")
    func testIsInactiveReturnsTrueForOldTabs() {
        let pastDate = Date(timeIntervalSinceNow: -600) // 10 minutes ago
        let url = URL(string: "https://example.com")!
        let tab = Tab(id: "tab-1", url: url, lastViewedAt: pastDate)
        
        #expect(tab.isInactive(threshold: 300)) // 5 minute threshold
    }
    
    @Test("Tab isInactive returns false for recent tabs")
    func testIsInactiveReturnsFalseForRecentTabs() {
        let recentDate = Date(timeIntervalSinceNow: -60) // 1 minute ago
        let url = URL(string: "https://example.com")!
        let tab = Tab(id: "tab-1", url: url, lastViewedAt: recentDate)
        
        #expect(!tab.isInactive(threshold: 300)) // 5 minute threshold
    }
    
    @Test("Tab pathComponents extracts URL path")
    func testPathComponents() {
        let url = URL(string: "https://github.com/apple/swift")!
        let tab = Tab(id: "tab-1", url: url)
        
        #expect(tab.pathComponents == ["apple", "swift"])
    }
    
    @Test("Tab pathComponents handles root URL")
    func testPathComponentsWithRootURL() {
        let url = URL(string: "https://example.com/")!
        let tab = Tab(id: "tab-1", url: url)
        
        #expect(tab.pathComponents.isEmpty)
    }
    
    @Test("Tab scheme returns URL scheme")
    func testScheme() {
        let httpURL = URL(string: "http://example.com")!
        let httpsURL = URL(string: "https://example.com")!
        let fileURL = URL(string: "file:///path/to/file")!
        
        #expect(Tab(id: "1", url: httpURL).scheme == "http")
        #expect(Tab(id: "2", url: httpsURL).scheme == "https")
        #expect(Tab(id: "3", url: fileURL).scheme == "file")
    }
    
    @Test("Tab searchableText combines title and domain")
    func testSearchableText() {
        let url = URL(string: "https://github.com")!
        let tab = Tab(id: "tab-1", url: url, title: "GitHub Homepage")
        
        #expect(tab.searchableText == "GitHub Homepage github.com")
    }
    
    @Test("Tab displayName prioritizes title")
    func testDisplayNamePrioritizesTitle() {
        let url = URL(string: "https://example.com")!
        let tab = Tab(id: "tab-1", url: url, title: "Example Site")
        
        #expect(tab.displayName == "Example Site")
    }
    
    @Test("Tab displayName uses URL when title is empty")
    func testDisplayNameUsesURLWhenTitleEmpty() {
        let url = URL(string: "https://example.com")!
        let tab = Tab(id: "tab-1", url: url, title: "")
        
        #expect(tab.displayName == url.absoluteString)
    }
    
    @Test("Tab is Codable")
    func testCodable() throws {
        let url = URL(string: "https://example.com")!
        let groupID = UUID()
        let original = Tab(
            id: "tab-1",
            url: url,
            title: "Test",
            isPinned: true,
            groupID: groupID
        )
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Tab.self, from: encoded)
        
        #expect(decoded.id == original.id)
        #expect(decoded.url == original.url)
        #expect(decoded.title == original.title)
        #expect(decoded.isPinned == original.isPinned)
        #expect(decoded.groupID == original.groupID)
    }
    
    @Test("Tab is Hashable")
    func testHashable() {
        let url = URL(string: "https://example.com")!
        let tab1 = Tab(id: "tab-1", url: url)
        let tab2 = Tab(id: "tab-1", url: url, title: "Different Title")
        
        // Same ID means same hash
        #expect(tab1.hashValue == tab2.hashValue)
        
        var set: Set<Tab> = []
        set.insert(tab1)
        set.insert(tab2)
        
        // Should only have one element (same ID)
        #expect(set.count == 1)
    }
}
