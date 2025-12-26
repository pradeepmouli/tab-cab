import Testing
import Foundation
@testable import TabOrganizerCore

@Suite("TabAssociation Model Tests")
struct TabAssociationTests {
    
    @Test("TabAssociation initialization with defaults")
    func testInitializationWithDefaults() {
        let group = TabAssociation(name: "Work")
        
        #expect(!group.id.uuidString.isEmpty)
        #expect(group.name == "Work")
        #expect(group.color == TabAssociation.defaultColor)
        #expect(group.collapsed == false)
        #expect(group.tabIDs.isEmpty)
        #expect(group.metadata.isEmpty)
    }
    
    @Test("TabAssociation initialization with custom values")
    func testInitializationWithCustomValues() {
        let id = UUID()
        let tabIDs = ["tab-1", "tab-2", "tab-3"]
        let metadata = ["aiSuggested": "true"]
        
        let group = TabAssociation(
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
    
    @Test("TabAssociation validates successfully with valid data")
    func testValidationSucceeds() throws {
        let group = TabAssociation(name: "Valid Name", color: "#007AFF")
        
        // Should not throw
        try group.validate()
    }
    
    @Test("TabAssociation validation fails with empty name")
    func testValidationFailsWithEmptyName() {
        let group = TabAssociation(name: "")
        
        #expect(throws: ValidationError.self) {
            try group.validate()
        }
    }
    
    @Test("TabAssociation validation fails with whitespace-only name")
    func testValidationFailsWithWhitespaceOnlyName() {
        let group = TabAssociation(name: "   ")
        
        #expect(throws: ValidationError.self) {
            try group.validate()
        }
    }
    
    @Test("TabAssociation validation fails with name too long")
    func testValidationFailsWithNameTooLong() {
        let longName = String(repeating: "a", count: TabAssociation.maxNameLength + 1)
        let group = TabAssociation(name: longName)
        
        #expect(throws: ValidationError.self) {
            try group.validate()
        }
    }
    
    @Test("TabAssociation validation succeeds with maximum length name")
    func testValidationSucceedsWithMaxLengthName() throws {
        let maxName = String(repeating: "a", count: TabAssociation.maxNameLength)
        let group = TabAssociation(name: maxName)
        
        // Should not throw
        try group.validate()
    }
    
    @Test("TabAssociation validates hex colors correctly")
    func testHexColorValidation() throws {
        let validColors = ["#FF0000", "#00FF00", "#0000FF", "#FFF", "#000"]
        
        for color in validColors {
            let group = TabAssociation(name: "Test", color: color)
            try group.validate()
        }
    }
    
    @Test("TabAssociation validates predefined color names")
    func testPredefinedColorValidation() throws {
        let validColors = ["blue", "red", "green", "yellow", "orange", "purple", "pink", "gray"]
        
        for color in validColors {
            let group = TabAssociation(name: "Test", color: color)
            try group.validate()
        }
    }
    
    @Test("TabAssociation validation fails with invalid color")
    func testValidationFailsWithInvalidColor() {
        let group = TabAssociation(name: "Test", color: "invalid-color")
        
        #expect(throws: ValidationError.self) {
            try group.validate()
        }
    }
    
    @Test("TabAssociation withName creates new instance with updated name")
    func testWithName() {
        let original = TabAssociation(name: "Original")
        let updated = original.withName("Updated")
        
        #expect(original.name == "Original")
        #expect(updated.name == "Updated")
        #expect(updated.id == original.id)
        #expect(updated.updatedAt > original.updatedAt)
    }
    
    @Test("TabAssociation withAddedTab adds tab to group")
    func testWithAddedTab() {
        let original = TabAssociation(name: "Test", tabIDs: ["tab-1"])
        let updated = original.withAddedTab("tab-2")
        
        #expect(original.tabIDs == ["tab-1"])
        #expect(updated.tabIDs == ["tab-1", "tab-2"])
    }
    
    @Test("TabAssociation withAddedTab ignores duplicate tabs")
    func testWithAddedTabIgnoresDuplicates() {
        let original = TabAssociation(name: "Test", tabIDs: ["tab-1"])
        let updated = original.withAddedTab("tab-1")
        
        #expect(updated.tabIDs == ["tab-1"])
        #expect(updated.updatedAt == original.updatedAt)
    }
    
    @Test("TabAssociation withRemovedTab removes tab from group")
    func testWithRemovedTab() {
        let original = TabAssociation(name: "Test", tabIDs: ["tab-1", "tab-2", "tab-3"])
        let updated = original.withRemovedTab("tab-2")
        
        #expect(original.tabIDs == ["tab-1", "tab-2", "tab-3"])
        #expect(updated.tabIDs == ["tab-1", "tab-3"])
    }
    
    @Test("TabAssociation withRemovedTab handles non-existent tab")
    func testWithRemovedTabHandlesNonExistent() {
        let original = TabAssociation(name: "Test", tabIDs: ["tab-1"])
        let updated = original.withRemovedTab("tab-999")
        
        #expect(updated.tabIDs == ["tab-1"])
    }
    
    @Test("TabAssociation is Codable")
    func testCodable() throws {
        let original = TabAssociation(
            name: "Test",
            color: "#FF0000",
            tabIDs: ["tab-1", "tab-2"]
        )
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TabAssociation.self, from: encoded)
        
        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.color == original.color)
        #expect(decoded.tabIDs == original.tabIDs)
    }
    
    @Test("TabAssociation is Hashable")
    func testHashable() {
        let group1 = TabAssociation(id: UUID(), name: "Test")
        let group2 = TabAssociation(id: group1.id, name: "Different Name")
        
        // Same ID means same hash (for Set/Dictionary usage)
        #expect(group1.hashValue == group2.hashValue)
        
        var set: Set<TabAssociation> = []
        set.insert(group1)
        set.insert(group2)
        
        // Should only have one element (same ID)
        #expect(set.count == 1)
    }
}
