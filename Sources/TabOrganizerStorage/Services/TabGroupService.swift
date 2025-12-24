import Foundation
import TabOrganizerCore
import TabOrganizerSafariAPI

/// Service for managing tab groups with business logic and validation.
///
/// Coordinates between Safari tab APIs and persistent storage to provide
/// high-level operations for creating, updating, and organizing tab groups.
@MainActor
public final class TabGroupService: Sendable {
    private let tabManager: TabManaging
    private let repository: TabGroupRepository
    
    /// Creates a tab group service
    ///
    /// - Parameters:
    ///   - tabManager: Safari tab management interface
    ///   - repository: Tab group persistence layer
    public init(tabManager: TabManaging, repository: TabGroupRepository) {
        self.tabManager = tabManager
        self.repository = repository
    }
    
    /// Create a new tab group
    ///
    /// - Parameters:
    ///   - name: Group name (must be unique)
    ///   - color: Optional hex color (defaults to blue)
    ///   - tabIDs: Optional array of tab IDs to include
    /// - Returns: Created TabGroup
    /// - Throws: ValidationError if name is invalid or duplicate
    public func createGroup(
        name: String,
        color: String = TabGroup.defaultColor,
        tabIDs: [String] = []
    ) async throws -> TabGroup {
        let group = TabGroup(
            name: name,
            color: color,
            tabIDs: tabIDs
        )
        
        try await repository.save(group)
        return group
    }
    
    /// Update an existing tab group
    ///
    /// - Parameter group: Updated group to save
    /// - Throws: ValidationError or StorageError
    public func updateGroup(_ group: TabGroup) async throws {
        try await repository.save(group)
    }
    
    /// Delete a tab group by ID
    ///
    /// - Parameter id: Group identifier
    /// - Throws: StorageError if group not found
    public func deleteGroup(id: UUID) async throws {
        try await repository.delete(id: id)
    }
    
    /// Get a specific tab group by ID
    ///
    /// - Parameter id: Group identifier
    /// - Returns: TabGroup or nil if not found
    public func getGroup(id: UUID) async throws -> TabGroup? {
        try await repository.get(id: id)
    }
    
    /// Get all tab groups
    ///
    /// - Returns: Array of all tab groups sorted by creation date
    public func getAllGroups() async throws -> [TabGroup] {
        let groups = try await repository.getAll()
        return groups.sorted { $0.createdAt < $1.createdAt }
    }
    
    /// Add a tab to a group
    ///
    /// - Parameters:
    ///   - tabID: Tab identifier
    ///   - groupID: Group identifier
    /// - Throws: StorageError if group not found
    public func addTab(_ tabID: String, toGroup groupID: UUID) async throws {
        guard let group = try await repository.get(id: groupID) else {
            throw StorageError.storageUnavailable("Group not found: \(groupID)")
        }
        
        let updated = group.withAddedTab(tabID)
        try await repository.save(updated)
    }
    
    /// Remove a tab from a group
    ///
    /// - Parameters:
    ///   - tabID: Tab identifier
    ///   - groupID: Group identifier
    /// - Throws: StorageError if group not found
    public func removeTab(_ tabID: String, fromGroup groupID: UUID) async throws {
        guard let group = try await repository.get(id: groupID) else {
            throw StorageError.storageUnavailable("Group not found: \(groupID)")
        }
        
        let updated = group.withRemovedTab(tabID)
        try await repository.save(updated)
    }
    
    /// Remove a tab from all groups
    ///
    /// - Parameter tabID: Tab identifier
    public func removeTabFromAllGroups(_ tabID: String) async throws {
        let groups = try await repository.getGroupsContaining(tabID: tabID)
        
        for group in groups {
            let updated = group.withRemovedTab(tabID)
            try await repository.save(updated)
        }
    }
    
    /// Move a tab from one group to another
    ///
    /// - Parameters:
    ///   - tabID: Tab identifier
    ///   - fromGroupID: Source group identifier (nil if ungrouped)
    ///   - toGroupID: Target group identifier (nil to ungroup)
    /// - Throws: StorageError if group not found
    public func moveTab(
        _ tabID: String,
        fromGroup fromGroupID: UUID?,
        toGroup toGroupID: UUID?
    ) async throws {
        // Remove from source group if specified
        if let fromGroupID = fromGroupID {
            try await removeTab(tabID, fromGroup: fromGroupID)
        }
        
        // Add to target group if specified
        if let toGroupID = toGroupID {
            try await addTab(tabID, toGroup: toGroupID)
        }
    }
    
    /// Check if a group name is available (not used by another group)
    ///
    /// - Parameters:
    ///   - name: Group name to check
    ///   - excludingID: Optional group ID to exclude (for updates)
    /// - Returns: true if name is available
    public func isNameAvailable(_ name: String, excludingID: UUID? = nil) async throws -> Bool {
        let exists = try await repository.exists(name: name, excludingID: excludingID)
        return !exists
    }
    
    /// Rename a group
    ///
    /// - Parameters:
    ///   - groupID: Group identifier
    ///   - newName: New group name
    /// - Throws: ValidationError or StorageError
    public func renameGroup(_ groupID: UUID, to newName: String) async throws {
        guard let group = try await repository.get(id: groupID) else {
            throw StorageError.storageUnavailable("Group not found: \(groupID)")
        }
        
        let renamed = group.withName(newName)
        try await repository.save(renamed)
    }
    
    /// Change a group's color
    ///
    /// - Parameters:
    ///   - groupID: Group identifier
    ///   - newColor: New color hex code
    /// - Throws: ValidationError or StorageError
    public func changeGroupColor(_ groupID: UUID, to newColor: String) async throws {
        guard let group = try await repository.get(id: groupID) else {
            throw StorageError.storageUnavailable("Group not found: \(groupID)")
        }
        
        var updated = group
        updated.color = newColor
        updated.updatedAt = Date()
        
        try await repository.save(updated)
    }
    
    /// Toggle a group's collapsed state
    ///
    /// - Parameter groupID: Group identifier
    /// - Throws: StorageError if group not found
    public func toggleCollapsed(_ groupID: UUID) async throws {
        guard let group = try await repository.get(id: groupID) else {
            throw StorageError.storageUnavailable("Group not found: \(groupID)")
        }
        
        var updated = group
        updated.collapsed = !updated.collapsed
        updated.updatedAt = Date()
        
        try await repository.save(updated)
    }
    
    /// Get all tabs that are currently in any group
    ///
    /// - Returns: Set of tab IDs that are in groups
    public func getGroupedTabIDs() async throws -> Set<String> {
        let groups = try await repository.getAll()
        return Set(groups.flatMap { $0.tabIDs })
    }
    
    /// Get all tabs that are not in any group
    ///
    /// - Returns: Array of ungrouped TabInfo
    public func getUngroupedTabs() async throws -> [TabInfo] {
        let allTabs = try await tabManager.getAllTabs()
        let groupedIDs = try await getGroupedTabIDs()
        
        return allTabs.filter { !groupedIDs.contains($0.id) }
    }
}
