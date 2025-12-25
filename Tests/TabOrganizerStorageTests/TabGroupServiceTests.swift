import Testing
import Foundation
@testable import TabOrganizerStorage
@testable import TabOrganizerCore
@testable import TabOrganizerSafariAPI

@Suite("TabGroupService Tests")
@MainActor
struct TabGroupServiceTests {
    
    @Test("Create group saves to repository")
    func testCreateGroupSavesToRepository() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        let tabManager = MockTabManager()
        let service = TabGroupService(tabManager: tabManager, repository: repository)
        
        let group = try await service.createGroup(name: "Work", tabIDs: ["tab-1"])
        
        #expect(group.name == "Work")
        #expect(group.tabIDs == ["tab-1"])
        
        let retrieved = try await repository.get(id: group.id)
        #expect(retrieved != nil)
    }
    
    @Test("Update group modifies existing group")
    func testUpdateGroupModifiesExistingGroup() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        let tabManager = MockTabManager()
        let service = TabGroupService(tabManager: tabManager, repository: repository)
        
        let group = try await service.createGroup(name: "Original")
        let updated = group.withName("Updated")
        
        try await service.updateGroup(updated)
        
        let retrieved = try await repository.get(id: group.id)
        #expect(retrieved?.name == "Updated")
    }
    
    @Test("Delete group removes from repository")
    func testDeleteGroupRemovesFromRepository() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        let tabManager = MockTabManager()
        let service = TabGroupService(tabManager: tabManager, repository: repository)
        
        let group = try await service.createGroup(name: "ToDelete")
        
        try await service.deleteGroup(id: group.id)
        
        let retrieved = try await repository.get(id: group.id)
        #expect(retrieved == nil)
    }
    
    @Test("Get all groups returns sorted by creation date")
    func testGetAllGroupsReturnsSortedByCreationDate() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        let tabManager = MockTabManager()
        let service = TabGroupService(tabManager: tabManager, repository: repository)
        
        let group1 = try await service.createGroup(name: "First")
        try await Task.sleep(for: .milliseconds(10))
        let group2 = try await service.createGroup(name: "Second")
        try await Task.sleep(for: .milliseconds(10))
        let group3 = try await service.createGroup(name: "Third")
        
        let all = try await service.getAllGroups()
        
        #expect(all.count == 3)
        #expect(all[0].id == group1.id)
        #expect(all[1].id == group2.id)
        #expect(all[2].id == group3.id)
    }
    
    @Test("Add tab to group updates group")
    func testAddTabToGroupUpdatesGroup() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        let tabManager = MockTabManager()
        let service = TabGroupService(tabManager: tabManager, repository: repository)
        
        let group = try await service.createGroup(name: "Work", tabIDs: ["tab-1"])
        
        try await service.addTab("tab-2", toGroup: group.id)
        
        let updated = try await repository.get(id: group.id)
        #expect(updated?.tabIDs.contains("tab-2") == true)
    }
    
    @Test("Remove tab from group updates group")
    func testRemoveTabFromGroupUpdatesGroup() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        let tabManager = MockTabManager()
        let service = TabGroupService(tabManager: tabManager, repository: repository)
        
        let group = try await service.createGroup(name: "Work", tabIDs: ["tab-1", "tab-2"])
        
        try await service.removeTab("tab-1", fromGroup: group.id)
        
        let updated = try await repository.get(id: group.id)
        #expect(updated?.tabIDs == ["tab-2"])
    }
    
    @Test("Remove tab from all groups removes from multiple groups")
    func testRemoveTabFromAllGroupsRemovesFromMultipleGroups() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        let tabManager = MockTabManager()
        let service = TabGroupService(tabManager: tabManager, repository: repository)
        
        let group1 = try await service.createGroup(name: "Work", tabIDs: ["tab-1", "tab-2"])
        let group2 = try await service.createGroup(name: "Personal", tabIDs: ["tab-2", "tab-3"])
        
        try await service.removeTabFromAllGroups("tab-2")
        
        let updated1 = try await repository.get(id: group1.id)
        let updated2 = try await repository.get(id: group2.id)
        
        #expect(updated1?.tabIDs == ["tab-1"])
        #expect(updated2?.tabIDs == ["tab-3"])
    }
    
    @Test("Move tab between groups")
    func testMoveTabBetweenGroups() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        let tabManager = MockTabManager()
        let service = TabGroupService(tabManager: tabManager, repository: repository)
        
        let group1 = try await service.createGroup(name: "Work", tabIDs: ["tab-1"])
        let group2 = try await service.createGroup(name: "Personal", tabIDs: [])
        
        try await service.moveTab("tab-1", fromGroup: group1.id, toGroup: group2.id)
        
        let updated1 = try await repository.get(id: group1.id)
        let updated2 = try await repository.get(id: group2.id)
        
        #expect(!updated1!.tabIDs.contains("tab-1"))
        #expect(updated2!.tabIDs.contains("tab-1"))
    }
    
    @Test("Is name available returns true for new name")
    func testIsNameAvailableReturnsTrueForNewName() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        let tabManager = MockTabManager()
        let service = TabGroupService(tabManager: tabManager, repository: repository)
        
        try await service.createGroup(name: "Work")
        
        let available = try await service.isNameAvailable("Personal")
        #expect(available)
    }
    
    @Test("Is name available returns false for existing name")
    func testIsNameAvailableReturnsFalseForExistingName() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        let tabManager = MockTabManager()
        let service = TabGroupService(tabManager: tabManager, repository: repository)
        
        try await service.createGroup(name: "Work")
        
        let available = try await service.isNameAvailable("Work")
        #expect(!available)
    }
    
    @Test("Rename group updates name")
    func testRenameGroupUpdatesName() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        let tabManager = MockTabManager()
        let service = TabGroupService(tabManager: tabManager, repository: repository)
        
        let group = try await service.createGroup(name: "Original")
        
        try await service.renameGroup(group.id, to: "Renamed")
        
        let updated = try await repository.get(id: group.id)
        #expect(updated?.name == "Renamed")
    }
    
    @Test("Change group color updates color")
    func testChangeGroupColorUpdatesColor() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        let tabManager = MockTabManager()
        let service = TabGroupService(tabManager: tabManager, repository: repository)
        
        let group = try await service.createGroup(name: "Work", color: "#FF0000")
        
        try await service.changeGroupColor(group.id, to: "#00FF00")
        
        let updated = try await repository.get(id: group.id)
        #expect(updated?.color == "#00FF00")
    }
    
    @Test("Toggle collapsed changes collapsed state")
    func testToggleCollapsedChangesCollapsedState() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        let tabManager = MockTabManager()
        let service = TabGroupService(tabManager: tabManager, repository: repository)
        
        let group = try await service.createGroup(name: "Work")
        #expect(group.collapsed == false)
        
        try await service.toggleCollapsed(group.id)
        let updated1 = try await repository.get(id: group.id)
        #expect(updated1?.collapsed == true)
        
        try await service.toggleCollapsed(group.id)
        let updated2 = try await repository.get(id: group.id)
        #expect(updated2?.collapsed == false)
    }
    
    @Test("Get grouped tab IDs returns all tabs in groups")
    func testGetGroupedTabIDsReturnsAllTabsInGroups() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        let tabManager = MockTabManager()
        let service = TabGroupService(tabManager: tabManager, repository: repository)
        
        try await service.createGroup(name: "Work", tabIDs: ["tab-1", "tab-2"])
        try await service.createGroup(name: "Personal", tabIDs: ["tab-3"])
        
        let groupedIDs = try await service.getGroupedTabIDs()
        
        #expect(groupedIDs.contains("tab-1"))
        #expect(groupedIDs.contains("tab-2"))
        #expect(groupedIDs.contains("tab-3"))
        #expect(groupedIDs.count == 3)
    }
    
    @Test("Get ungrouped tabs filters out grouped tabs")
    func testGetUngroupedTabsFiltersOutGroupedTabs() async throws {
        let storage = MockStorageAdapter()
        let repository = DefaultTabGroupRepository(storage: storage)
        let tabManager = MockTabManager()
        let service = TabGroupService(tabManager: tabManager, repository: repository)
        
        tabManager.stubbedTabs = [
            TabInfo(id: "tab-1", url: URL(string: "https://example.com")!, title: "Tab 1"),
            TabInfo(id: "tab-2", url: URL(string: "https://example.com")!, title: "Tab 2"),
            TabInfo(id: "tab-3", url: URL(string: "https://example.com")!, title: "Tab 3")
        ]
        
        try await service.createGroup(name: "Work", tabIDs: ["tab-1"])
        
        let ungrouped = try await service.getUngroupedTabs()
        
        #expect(ungrouped.count == 2)
        #expect(ungrouped.contains { $0.id == "tab-2" })
        #expect(ungrouped.contains { $0.id == "tab-3" })
    }
}
