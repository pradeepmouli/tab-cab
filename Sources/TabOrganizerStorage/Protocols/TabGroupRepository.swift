//
//  TabGroupRepository.swift
//  TabOrganizerStorage
//
//  Protocol defining persistence operations for TabGroup entities.
//  Provides CRUD operations and reactive observation capabilities.
//

import Foundation
import TabOrganizerCore

/// Repository protocol for persisting and retrieving tab groups.
///
/// Implementations must provide:
/// - CRUD operations for tab groups
/// - Duplicate name prevention (FR-006)
/// - Cross-session persistence (FR-002)
/// - Reactive observation of changes
///
/// **Thread Safety**: All methods are @MainActor isolated for safe SwiftUI integration.
///
/// **Testing**: Use MockGroupRepository for unit tests.
@MainActor
public protocol TabGroupRepository: Sendable {

    // MARK: - CRUD Operations

    /// Saves a tab group to persistent storage.
    ///
    /// **FR-001**: Create named tab groups with custom colors
    /// **FR-006**: Prevent duplicate group names within the same window
    ///
    /// - Parameters:
    ///   - group: The tab group to save
    ///   - windowID: The window identifier (for duplicate name checking)
    /// - Throws: `StorageError.quotaExceeded` if storage limit reached (5MB per FR-030)
    /// - Throws: `StorageError.duplicateName` if group name already exists in this window
    func save(_ group: TabGroup, windowID: String) async throws

    /// Deletes a tab group from persistent storage.
    ///
    /// **FR-005**: Allow users to delete groups at any time
    ///
    /// - Parameter groupID: The unique identifier of the group to delete
    /// - Throws: `StorageError.notFound` if group doesn't exist
    func delete(groupID: UUID) async throws

    /// Retrieves all tab groups for a specific window.
    ///
    /// **FR-002**: Persist tab groups across browser sessions
    ///
    /// - Parameter windowID: The window identifier
    /// - Returns: Array of tab groups for this window, ordered by creation date
    func getAllGroups(windowID: String) async throws -> [TabGroup]

    /// Retrieves a single tab group by ID.
    ///
    /// - Parameter groupID: The unique identifier of the group
    /// - Returns: The tab group if found, nil otherwise
    func getGroup(groupID: UUID) async throws -> TabGroup?

    /// Updates an existing tab group.
    ///
    /// **FR-005**: Allow users to rename or delete groups at any time
    ///
    /// - Parameters:
    ///   - group: The updated tab group
    ///   - windowID: The window identifier (for duplicate name checking)
    /// - Throws: `StorageError.notFound` if group doesn't exist
    /// - Throws: `StorageError.duplicateName` if new name conflicts with another group
    func update(_ group: TabGroup, windowID: String) async throws

    // MARK: - Reactive Observation

    /// Observes changes to tab groups for a specific window.
    ///
    /// Emits new array of groups whenever:
    /// - A group is created, updated, or deleted
    /// - Groups are reordered
    ///
    /// **SwiftUI Integration**: Use with `.task { }` modifier for automatic cancellation
    ///
    /// - Parameter windowID: The window identifier to observe
    /// - Returns: AsyncStream of tab group arrays
    func observeGroups(windowID: String) -> AsyncStream<[TabGroup]>

    // MARK: - Bulk Operations

    /// Deletes all tab groups for a specific window.
    ///
    /// Used for window cleanup and testing.
    ///
    /// - Parameter windowID: The window identifier
    func deleteAllGroups(windowID: String) async throws

    /// Retrieves the count of groups in a window.
    ///
    /// Useful for UI state (e.g., "No groups" empty state).
    ///
    /// - Parameter windowID: The window identifier
    /// - Returns: Number of groups in this window
    func getGroupCount(windowID: String) async throws -> Int
}

// MARK: - Default Implementations

extension TabGroupRepository {

    /// Default implementation for getGroupCount using getAllGroups.
    ///
    /// Repositories can override with more efficient implementations.
    public func getGroupCount(windowID: String) async throws -> Int {
        let groups = try await getAllGroups(windowID: windowID)
        return groups.count
    }
}
