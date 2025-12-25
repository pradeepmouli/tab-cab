import Foundation
import TabOrganizerCore

/// Protocol for tab group persistence operations.
///
/// This protocol defines CRUD operations for TabGroup entities
/// with support for async operations and proper error handling.
public protocol TabGroupRepository: Sendable {
    /// Save a tab group to persistent storage
    ///
    /// - Parameter group: TabGroup to save
    /// - Throws: StorageError on persistence failure or validation error
    func save(_ group: TabGroup) async throws
    
    /// Delete a tab group by ID
    ///
    /// - Parameter id: Group identifier
    /// - Throws: StorageError if group not found or deletion fails
    func delete(id: UUID) async throws
    
    /// Retrieve a tab group by ID
    ///
    /// - Parameter id: Group identifier
    /// - Returns: TabGroup or nil if not found
    /// - Throws: StorageError on retrieval failure
    func get(id: UUID) async throws -> TabGroup?
    
    /// Retrieve all tab groups
    ///
    /// - Returns: Array of all stored TabGroups
    /// - Throws: StorageError on retrieval failure
    func getAll() async throws -> [TabGroup]
    
    /// Check if a group name already exists
    ///
    /// - Parameters:
    ///   - name: Group name to check
    ///   - excludingID: Optional ID to exclude from check (for updates)
    /// - Returns: true if name exists, false otherwise
    func exists(name: String, excludingID: UUID?) async throws -> Bool
    
    /// Get tab groups that contain a specific tab
    ///
    /// - Parameter tabID: Tab identifier
    /// - Returns: Array of TabGroups containing this tab
    func getGroupsContaining(tabID: String) async throws -> [TabGroup]
}
