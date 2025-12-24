import Testing
import Foundation
@testable import TabOrganizerCore

@Suite("TabGroup Model Tests")
struct TabGroupTests {
    
    @Test("TabGroup initialization with defaults")
    func testInitializationWithDefaults() {
        let group = TabGroup(name: "Work")
        
        #expect(!group.id.uuidString.isEmpty)
        #expect(group.name == "Work")
        #expect(group.color == TabGroup.defaultColor)
        #expect(group.collapsed == false)
        #expect(group.tabIDs.isEmpty)
        #expect(group.metadata.isEmpty)
    }
    
    @Test("TabGroup initialization with custom values")
    func testInitializationWithCustomValues() {
        let id = UUID()
        let tabIDs = ["tab-1", "tab-2", "tab-3"]
        let metadata = ["aiSuggested": "true"]
        
        let group = TabGroup(
            id: id,
            name: "Research",
            color: "#FF0000",
            collapsed: true,
            tabIDs: tabIDs,
            metadata: metadata
        )
        
        #expect(group.id == id)
        #expect(group.name == "Research")
        #expect(group.color == "#FF0000")
        #expect(group.collapsed == true)
        #expect(group.tabIDs == tabIDs)
        #expect(group.metadata == metadata)
    }
    
    @Test("TabGroup validates successfully with valid data")
    func testValidationSucceeds() throws {
        let group = TabGroup(name: "Valid Name", color: "#007AFF")
        
        // Should not throw
        try group.validate()
    }
    
    @Test("TabGroup validation fails with empty name")
    func testValidationFailsWithEmptyName() {
        let group = TabGroup(name: "")
        
        #expect(throws: ValidationError.self) {
            try group.validate()
        }
    }
    
    @Test("TabGroup validation fails with whitespace-only name")
    func testValidationFailsWithWhitespaceOnlyName() {
        let group = TabGroup(name: "   ")
        
        #expect(throws: ValidationError.self) {
            try group.validate()
        }
    }
    
    @Test("TabGroup validation fails with name too long")
    func testValidationFailsWithNameTooLong() {
        let longName = String(repeating: "a", count: TabGroup.maxNameLength + 1)
        let group = TabGroup(name: longName)
        
        #expect(throws: ValidationError.self) {
            try group.validate()
        }
    }
    
    @Test("TabGroup validation succeeds with maximum length name")
    func testValidationSucceedsWithMaxLengthName() throws {
        let maxName = String(repeating: "a", count: TabGroup.maxNameLength)
        let group = TabGroup(name: maxName)
        
        // Should not throw
        try group.validate()
    }
    
    @Test("TabGroup validates hex colors correctly")
    func testHexColorValidation() throws {
        let validColors = ["#FF0000", "#00FF00", "#0000FF", "#FFF", "#000"]
        
        for color in validColors {
            let group = TabGroup(name: "Test", color: color)
            try group.validate()
        }
    }
    
    @Test("TabGroup validates predefined color names")
    func testPredefinedColorValidation() throws {
        let validColors = ["blue", "red", "green", "yellow", "orange", "purple", "pink", "gray"]
        
        for color in validColors {
            let group = TabGroup(name: "Test", color: color)
            try group.validate()
        }
    }
    
    @Test("TabGroup validation fails with invalid color")
    func testValidationFailsWithInvalidColor() {
        let group = TabGroup(name: "Test", color: "invalid-color")
        
        #expect(throws: ValidationError.self) {
            try group.validate()
        }
    }
    
    @Test("TabGroup withName creates new instance with updated name")
    func testWithName() {
        let original = TabGroup(name: "Original")
        let updated = original.withName("Updated")
        
        #expect(original.name == "Original")
        #expect(updated.name == "Updated")
        #expect(updated.id == original.id)
        #expect(updated.updatedAt > original.updatedAt)
    }
    
    @Test("TabGroup withAddedTab adds tab to group")
    func testWithAddedTab() {
        let original = TabGroup(name: "Test", tabIDs: ["tab-1"])
        let updated = original.withAddedTab("tab-2")
        
        #expect(original.tabIDs == ["tab-1"])
        #expect(updated.tabIDs == ["tab-1", "tab-2"])
    }
    
    @Test("TabGroup withAddedTab ignores duplicate tabs")
    func testWithAddedTabIgnoresDuplicates() {
        let original = TabGroup(name: "Test", tabIDs: ["tab-1"])
        let updated = original.withAddedTab("tab-1")
        
        #expect(updated.tabIDs == ["tab-1"])
        #expect(updated.updatedAt == original.updatedAt)
    }
    
    @Test("TabGroup withRemovedTab removes tab from group")
    func testWithRemovedTab() {
        let original = TabGroup(name: "Test", tabIDs: ["tab-1", "tab-2", "tab-3"])
        let updated = original.withRemovedTab("tab-2")
        
        #expect(original.tabIDs == ["tab-1", "tab-2", "tab-3"])
        #expect(updated.tabIDs == ["tab-1", "tab-3"])
    }
    
    @Test("TabGroup withRemovedTab handles non-existent tab")
    func testWithRemovedTabHandlesNonExistent() {
        let original = TabGroup(name: "Test", tabIDs: ["tab-1"])
        let updated = original.withRemovedTab("tab-999")
        
        #expect(updated.tabIDs == ["tab-1"])
    }
    
    @Test("TabGroup is Codable")
    func testCodable() throws {
        let original = TabGroup(
            name: "Test",
            color: "#FF0000",
            tabIDs: ["tab-1", "tab-2"]
        )
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TabGroup.self, from: encoded)
        
        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.color == original.color)
        #expect(decoded.tabIDs == original.tabIDs)
    }
    
    @Test("TabGroup is Hashable")
    func testHashable() {
        let group1 = TabGroup(id: UUID(), name: "Test")
        let group2 = TabGroup(id: group1.id, name: "Different Name")
        
        // Same ID means same hash (for Set/Dictionary usage)
        #expect(group1.hashValue == group2.hashValue)
        
        var set: Set<TabGroup> = []
        set.insert(group1)
        set.insert(group2)
        
        // Should only have one element (same ID)
        #expect(set.count == 1)
    }
}
