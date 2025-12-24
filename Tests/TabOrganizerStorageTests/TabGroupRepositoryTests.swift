import Testing
import Foundation
@testable import TabOrganizerStorage
@testable import TabOrganizerCore

@Suite("TabGroupRepository Tests")
struct TabGroupRepositoryTests {
    
    @Test("Save creates new group")
    func testSaveCreatesNewGroup() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        
        let group = TabGroup(name: "Work", tabIDs: ["tab-1", "tab-2"])
        
        try await repository.save(group)
        
        let retrieved = try await repository.get(id: group.id)
        #expect(retrieved != nil)
        #expect(retrieved?.name == "Work")
        #expect(retrieved?.tabIDs == ["tab-1", "tab-2"])
    }
    
    @Test("Save updates existing group")
    func testSaveUpdatesExistingGroup() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        
        let group = TabGroup(name: "Original", tabIDs: ["tab-1"])
        try await repository.save(group)
        
        let updated = group.withName("Updated")
        try await repository.save(updated)
        
        let all = try await repository.getAll()
        #expect(all.count == 1)
        #expect(all[0].name == "Updated")
    }
    
    @Test("Save throws on duplicate name")
    func testSaveThrowsOnDuplicateName() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        
        let group1 = TabGroup(name: "Work")
        try await repository.save(group1)
        
        let group2 = TabGroup(name: "Work") // Different ID, same name
        
        await #expect(throws: ValidationError.self) {
            try await repository.save(group2)
        }
    }
    
    @Test("Save allows same name for same group (update)")
    func testSaveAllowsSameNameForSameGroup() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        
        let group = TabGroup(name: "Work", tabIDs: ["tab-1"])
        try await repository.save(group)
        
        let updated = group.withAddedTab("tab-2")
        
        // Should not throw even though name is the same
        try await repository.save(updated)
        
        let retrieved = try await repository.get(id: group.id)
        #expect(retrieved?.tabIDs.count == 2)
    }
    
    @Test("Delete removes group")
    func testDeleteRemovesGroup() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        
        let group = TabGroup(name: "To Delete")
        try await repository.save(group)
        
        var all = try await repository.getAll()
        #expect(all.count == 1)
        
        try await repository.delete(id: group.id)
        
        all = try await repository.getAll()
        #expect(all.isEmpty)
    }
    
    @Test("Delete throws on non-existent group")
    func testDeleteThrowsOnNonExistentGroup() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        
        let nonExistentID = UUID()
        
        await #expect(throws: StorageError.self) {
            try await repository.delete(id: nonExistentID)
        }
    }
    
    @Test("Get returns nil for non-existent group")
    func testGetReturnsNilForNonExistentGroup() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        
        let nonExistentID = UUID()
        let result = try await repository.get(id: nonExistentID)
        
        #expect(result == nil)
    }
    
    @Test("GetAll returns empty array when no groups")
    func testGetAllReturnsEmptyArrayWhenNoGroups() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        
        let groups = try await repository.getAll()
        
        #expect(groups.isEmpty)
    }
    
    @Test("GetAll returns all saved groups")
    func testGetAllReturnsAllSavedGroups() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        
        let group1 = TabGroup(name: "Work")
        let group2 = TabGroup(name: "Personal")
        let group3 = TabGroup(name: "Research")
        
        try await repository.save(group1)
        try await repository.save(group2)
        try await repository.save(group3)
        
        let groups = try await repository.getAll()
        
        #expect(groups.count == 3)
        #expect(groups.contains { $0.name == "Work" })
        #expect(groups.contains { $0.name == "Personal" })
        #expect(groups.contains { $0.name == "Research" })
    }
    
    @Test("Exists returns true for existing name")
    func testExistsReturnsTrueForExistingName() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        
        let group = TabGroup(name: "Work")
        try await repository.save(group)
        
        let exists = try await repository.exists(name: "Work", excludingID: nil)
        
        #expect(exists)
    }
    
    @Test("Exists returns false for non-existent name")
    func testExistsReturnsFalseForNonExistentName() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        
        let exists = try await repository.exists(name: "Work", excludingID: nil)
        
        #expect(!exists)
    }
    
    @Test("Exists excludes specified ID")
    func testExistsExcludesSpecifiedID() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        
        let group = TabGroup(name: "Work")
        try await repository.save(group)
        
        let exists = try await repository.exists(name: "Work", excludingID: group.id)
        
        #expect(!exists)
    }
    
    @Test("GetGroupsContaining returns groups with tab")
    func testGetGroupsContainingReturnsGroupsWithTab() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        
        let group1 = TabGroup(name: "Work", tabIDs: ["tab-1", "tab-2"])
        let group2 = TabGroup(name: "Personal", tabIDs: ["tab-3", "tab-4"])
        let group3 = TabGroup(name: "Research", tabIDs: ["tab-2", "tab-5"])
        
        try await repository.save(group1)
        try await repository.save(group2)
        try await repository.save(group3)
        
        let groupsWithTab2 = try await repository.getGroupsContaining(tabID: "tab-2")
        
        #expect(groupsWithTab2.count == 2)
        #expect(groupsWithTab2.contains { $0.name == "Work" })
        #expect(groupsWithTab2.contains { $0.name == "Research" })
    }
    
    @Test("GetGroupsContaining returns empty for non-existent tab")
    func testGetGroupsContainingReturnsEmptyForNonExistentTab() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        
        let group = TabGroup(name: "Work", tabIDs: ["tab-1"])
        try await repository.save(group)
        
        let groups = try await repository.getGroupsContaining(tabID: "tab-999")
        
        #expect(groups.isEmpty)
    }
}
