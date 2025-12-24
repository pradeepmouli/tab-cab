import Foundation
import TabOrganizerCore

/// Implementation of TabGroupRepository using StorageAdapter.
///
/// Stores all tab groups in a single array under a storage key.
/// Provides CRUD operations with duplicate name checking.
public actor DefaultTabGroupRepository: TabGroupRepository {
    private let storage: StorageAdapter
    private let storageKey: String
    
    /// Creates a tab group repository
    ///
    /// - Parameters:
    ///   - storage: Storage adapter for persistence
    ///   - storageKey: Key for storing groups (default: "tabOrganizer.groups")
    public init(storage: StorageAdapter, storageKey: String = "tabOrganizer.groups") {
        self.storage = storage
        self.storageKey = storageKey
    }
    
    public func save(_ group: TabGroup) async throws {
        // Validate the group
        try group.validate()
        
        // Get existing groups
        var groups = try await getAll()
        
        // Check for duplicate name (excluding self if updating)
        let isDuplicate = groups.contains { existingGroup in
            existingGroup.name == group.name && existingGroup.id != group.id
        }
        
        if isDuplicate {
            throw ValidationError.duplicateName(group.name)
        }
        
        // Update or insert
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
        } else {
            groups.append(group)
        }
        
        // Save back to storage
        try await storage.store(storageKey, value: groups)
    }
    
    public func delete(id: UUID) async throws {
        var groups = try await getAll()
        
        guard let index = groups.firstIndex(where: { $0.id == id }) else {
            throw StorageError.storageUnavailable("Group with ID \(id) not found")
        }
        
        groups.remove(at: index)
        try await storage.store(storageKey, value: groups)
    }
    
    public func get(id: UUID) async throws -> TabGroup? {
        let groups = try await getAll()
        return groups.first { $0.id == id }
    }
    
    public func getAll() async throws -> [TabGroup] {
        guard let groups: [TabGroup] = try await storage.retrieve(storageKey) else {
            return []
        }
        return groups
    }
    
    public func exists(name: String, excludingID: UUID? = nil) async throws -> Bool {
        let groups = try await getAll()
        return groups.contains { group in
            group.name == name && group.id != excludingID
        }
    }
    
    public func getGroupsContaining(tabID: String) async throws -> [TabGroup] {
        let groups = try await getAll()
        return groups.filter { $0.tabIDs.contains(tabID) }
    }
}
