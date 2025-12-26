//
//  TabAssociationRepository.swift
//  TabOrganizerStorage
//
//  Protocol defining persistence operations for TabAssociation entities.
//  Provides CRUD operations and reactive observation capabilities.
//

import Foundation

/// Repository protocol for persisting and retrieving tab associations.
///
/// Implementations must provide:
/// - CRUD operations for tab associations
/// - Duplicate name prevention (FR-006)
/// - Cross-session persistence (FR-002)
/// - Reactive observation of changes
///
/// **Thread Safety**: All methods are @MainActor isolated for safe SwiftUI integration.
///
/// **Testing**: Use MockAssociationRepository for unit tests.
@MainActor
public protocol TabAssociationRepository: Sendable {

    // MARK: - CRUD Operations

    /// Saves a tab association to persistent storage.
    ///
    /// **FR-001**: Create named tab associations with custom colors
    /// **FR-006**: Prevent duplicate group names within the same window
    ///
    /// - Parameters:
    ///   - group: The tab association to save
    ///   - windowID: The window identifier (for duplicate name checking)
    /// - Throws: `StorageError.quotaExceeded` if storage limit reached (5MB per FR-030)
    /// - Throws: `StorageError.duplicateName` if group name already exists in this window
    func save(_ group: TabAssociation, windowID: String) async throws

    /// Deletes a tab association from persistent storage.
    ///
    /// **FR-005**: Allow users to delete groups at any time
    ///
    /// - Parameter associationID: The unique identifier of the group to delete
    /// - Throws: `StorageError.notFound` if group doesn't exist
    func delete(associationID: UUID) async throws

    /// Retrieves all tab associations for a specific window.
    ///
    /// **FR-002**: Persist tab associations across browser sessions
    ///
    /// - Parameter windowID: The window identifier
    /// - Returns: Array of tab associations for this window, ordered by creation date
    func getAllAssociations(windowID: String) async throws -> [TabAssociation]

    /// Retrieves a single tab association by ID.
    ///
    /// - Parameter associationID: The unique identifier of the group
    /// - Returns: The tab association if found, nil otherwise
    func getAssociation(associationID: UUID) async throws -> TabAssociation?

    /// Updates an existing tab association.
    ///
    /// **FR-005**: Allow users to rename or delete groups at any time
    ///
    /// - Parameters:
    ///   - group: The updated tab association
    ///   - windowID: The window identifier (for duplicate name checking)
    /// - Throws: `StorageError.notFound` if group doesn't exist
    /// - Throws: `StorageError.duplicateName` if new name conflicts with another group
    func update(_ group: TabAssociation, windowID: String) async throws

    // MARK: - Reactive Observation

    /// Observes changes to tab associations for a specific window.
    ///
    /// Emits new array of groups whenever:
    /// - A group is created, updated, or deleted
    /// - Groups are reordered
    ///
    /// **SwiftUI Integration**: Use with `.task { }` modifier for automatic cancellation
    ///
    /// - Parameter windowID: The window identifier to observe
    /// - Returns: AsyncStream of tab association arrays
    func observeAssociations(windowID: String) -> AsyncStream<[TabAssociation]>

    // MARK: - Bulk Operations

    /// Deletes all tab associations for a specific window.
    ///
    /// Used for window cleanup and testing.
    ///
    /// - Parameter windowID: The window identifier
    func deleteAllAssociations(windowID: String) async throws

    /// Retrieves the count of groups in a window.
    ///
    /// Useful for UI state (e.g., "No groups" empty state).
    ///
    /// - Parameter windowID: The window identifier
    /// - Returns: Number of groups in this window
    func getAssociationCount(windowID: String) async throws -> Int
}

// MARK: - Default Implementations

extension TabAssociationRepository {

    /// Default implementation for getAssociationCount using getAllAssociations.
    ///
    /// Repositories can override with more efficient implementations.
    public func getAssociationCount(windowID: String) async throws -> Int {
        let groups = try await getAllAssociations(windowID: windowID)
        return groups.count
    }
}
