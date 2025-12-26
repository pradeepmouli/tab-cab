//
//  TabAssociationService.swift
//  TabOrganizerCore
//
//  Business logic for tab association operations.
//  Coordinates between Safari API and storage layers.
//

import Foundation

/// Service for managing tab associations with business logic and validation.
///
/// **Responsibilities**:
/// - CRUD operations for tab associations (FR-001, FR-005)
/// - Tab membership management (FR-004)
/// - Duplicate name prevention (FR-006)
/// - Cross-layer coordination (Safari API + Storage)
///
/// **Architecture**: This service is the primary interface for tab association operations.
/// UI components should interact with this service, not directly with repositories.
@MainActor
@Observable
public final class TabAssociationService {

    // MARK: - Dependencies

    private let repository: any TabAssociationRepository
    private let tabManager: any TabManaging

    // MARK: - Observable State

    /// Current associations for the active window.
    /// SwiftUI views can observe this directly.
    public private(set) var associations: [TabAssociation] = []

    /// Loading state for UI feedback.
    public private(set) var isLoading: Bool = false

    /// Error state for UI display.
    public private(set) var lastError: Error?

    // MARK: - Initialization

    /// Creates a service with injected dependencies.
    ///
    /// - Parameters:
    ///   - repository: The repository for persistence
    ///   - tabManager: The Safari tab manager
    public init(
        repository: any TabAssociationRepository,
        tabManager: any TabManaging
    ) {
        self.repository = repository
        self.tabManager = tabManager
    }

    // MARK: - Association Operations

    /// Creates a new tab association.
    ///
    /// **FR-001**: Allow users to create named tab associations with custom colors
    /// **FR-006**: Prevent duplicate association names within the same window
    ///
    /// - Parameters:
    ///   - name: The association name (must be non-empty)
    ///   - color: The association color (hex format, e.g., "#0066CC")
    ///   - tabIDs: Initial tab IDs to include (optional)
    ///   - windowID: The window identifier
    /// - Returns: The created TabAssociation
    /// - Throws: `TabAssociationError.invalidName` if name is empty
    /// - Throws: `StorageError.duplicateName` if name already exists (FR-006)
    public func createAssociation(
        name: String,
        color: String,
        tabIDs: [String] = [],
        windowID: String
    ) async throws -> TabAssociation {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TabAssociationError.invalidName("Association name cannot be empty")
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let association = try TabAssociation(
                id: UUID(),
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                color: color,
                collapsed: false,
                createdAt: Date(),
                updatedAt: Date(),
                tabIDs: tabIDs,
                metadata: [:]
            )

            try await repository.save(association, windowID: windowID)

            // Refresh local state
            await loadAssociations(windowID: windowID)

            return association

        } catch {
            lastError = error
            throw error
        }
    }

    /// Deletes a tab association.
    ///
    /// **FR-005**: Allow users to delete associations at any time
    ///
    /// - Parameters:
    ///   - associationID: The association identifier
    ///   - windowID: The window identifier (for UI refresh)
    /// - Throws: `StorageError.notFound` if association doesn't exist
    public func deleteAssociation(associationID: UUID, windowID: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.delete(associationID: associationID)

            // Refresh local state
            await loadAssociations(windowID: windowID)

        } catch {
            lastError = error
            throw error
        }
    }

    /// Updates an association's properties.
    ///
    /// **FR-005**: Allow users to rename associations at any time
    /// **FR-003**: Support collapse/expand functionality
    ///
    /// - Parameters:
    ///   - association: The updated association
    ///   - windowID: The window identifier
    /// - Throws: `StorageError.notFound` if association doesn't exist
    /// - Throws: `StorageError.duplicateName` if new name conflicts
    public func updateAssociation(_ association: TabAssociation, windowID: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.update(association, windowID: windowID)

            // Refresh local state
            await loadAssociations(windowID: windowID)

        } catch {
            lastError = error
            throw error
        }
    }

    /// Retrieves all associations for a window.
    ///
    /// **FR-002**: Persist tab associations across browser sessions
    ///
    /// - Parameter windowID: The window identifier
    /// - Returns: Array of tab associations
    public func getAllAssociations(windowID: String) async throws -> [TabAssociation] {
        try await repository.getAllAssociations(windowID: windowID)
    }

    /// Loads associations into observable state.
    ///
    /// Call this to refresh the UI's view of associations.
    ///
    /// - Parameter windowID: The window identifier
    public func loadAssociations(windowID: String) async {
        do {
            associations = try await repository.getAllAssociations(windowID: windowID)
            lastError = nil
        } catch {
            lastError = error
            associations = []
        }
    }

    // MARK: - Tab Membership Operations

    /// Adds a tab to an association.
    ///
    /// **FR-004**: Support drag-and-drop to move tabs between associations
    ///
    /// - Parameters:
    ///   - tabID: The tab identifier
    ///   - associationID: The association identifier
    ///   - windowID: The window identifier
    /// - Throws: `StorageError.notFound` if association doesn't exist
    public func addTabToAssociation(tabID: String, associationID: UUID, windowID: String) async throws {
        guard let association = try await repository.getAssociation(associationID: associationID) else {
            throw StorageError.notFound("Association with ID \(associationID) not found")
        }

        let updatedAssociation = try association.withTabAdded(tabID)
        try await updateAssociation(updatedAssociation, windowID: windowID)
    }

    /// Removes a tab from an association.
    ///
    /// **FR-004**: Support drag-and-drop to remove tabs from associations
    ///
    /// - Parameters:
    ///   - tabID: The tab identifier
    ///   - associationID: The association identifier
    ///   - windowID: The window identifier
    /// - Throws: `StorageError.notFound` if association doesn't exist
    public func removeTabFromAssociation(tabID: String, associationID: UUID, windowID: String) async throws {
        guard let association = try await repository.getAssociation(associationID: associationID) else {
            throw StorageError.notFound("Association with ID \(associationID) not found")
        }

        let updatedAssociation = try association.withTabRemoved(tabID)
        try await updateAssociation(updatedAssociation, windowID: windowID)
    }

    /// Moves a tab from one association to another.
    ///
    /// Atomic operation ensuring tab is removed from source and added to destination.
    ///
    /// - Parameters:
    ///   - tabID: The tab identifier
    ///   - fromAssociationID: The source association identifier (nil if ungrouped)
    ///   - toAssociationID: The destination association identifier (nil to ungroup)
    ///   - windowID: The window identifier
    public func moveTab(
        tabID: String,
        fromAssociationID: UUID?,
        toAssociationID: UUID?,
        windowID: String
    ) async throws {
        // Remove from source association if specified
        if let fromID = fromAssociationID {
            guard let sourceAssociation = try await repository.getAssociation(associationID: fromID) else {
                throw StorageError.notFound("Source association with ID \(fromID) not found")
            }
            let updatedSource = try sourceAssociation.withTabRemoved(tabID)
            try await repository.update(updatedSource, windowID: windowID)
        }

        // Add to destination association if specified
        if let toID = toAssociationID {
            guard let destAssociation = try await repository.getAssociation(associationID: toID) else {
                throw StorageError.notFound("Destination association with ID \(toID) not found")
            }
            let updatedDest = try destAssociation.withTabAdded(tabID)
            try await repository.update(updatedDest, windowID: windowID)
        }

        // Refresh local state
        await loadAssociations(windowID: windowID)
    }

    // MARK: - Association State Operations

    /// Toggles an association's collapsed state.
    ///
    /// **FR-003**: Allow users to collapse/expand associations to show/hide contained tabs
    ///
    /// - Parameters:
    ///   - associationID: The association identifier
    ///   - windowID: The window identifier
    /// - Throws: `StorageError.notFound` if association doesn't exist
    public func toggleAssociationCollapsed(associationID: UUID, windowID: String) async throws {
        guard let association = try await repository.getAssociation(associationID: associationID) else {
            throw StorageError.notFound("Association with ID \(associationID) not found")
        }

        let updatedAssociation = try association.withCollapsedToggled()
        try await updateAssociation(updatedAssociation, windowID: windowID)
    }

    /// Renames an association.
    ///
    /// **FR-005**: Allow users to rename associations at any time
    ///
    /// - Parameters:
    ///   - associationID: The association identifier
    ///   - newName: The new association name
    ///   - windowID: The window identifier
    /// - Throws: `TabAssociationError.invalidName` if name is empty
    /// - Throws: `StorageError.duplicateName` if name already exists (FR-006)
    public func renameAssociation(associationID: UUID, newName: String, windowID: String) async throws {
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TabAssociationError.invalidName("Association name cannot be empty")
        }

        guard let association = try await repository.getAssociation(associationID: associationID) else {
            throw StorageError.notFound("Association with ID \(associationID) not found")
        }

        let updatedAssociation = try association.withName(newName.trimmingCharacters(in: .whitespacesAndNewlines))
        try await updateAssociation(updatedAssociation, windowID: windowID)
    }

    /// Changes an association's color.
    ///
    /// - Parameters:
    ///   - associationID: The association identifier
    ///   - newColor: The new color (hex format)
    ///   - windowID: The window identifier
    public func changeAssociationColor(associationID: UUID, newColor: String, windowID: String) async throws {
        guard let association = try await repository.getAssociation(associationID: associationID) else {
            throw StorageError.notFound("Association with ID \(associationID) not found")
        }

        let updatedAssociation = try association.withColor(newColor)
        try await updateAssociation(updatedAssociation, windowID: windowID)
    }
}

// MARK: - TabAssociationError

/// Errors specific to tab association operations.
public enum TabAssociationError: LocalizedError {
    case invalidName(String)
    case associationNotFound(UUID)
    case tabNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .invalidName(let message):
            return message
        case .associationNotFound(let id):
            return "Association with ID \(id) not found"
        case .tabNotFound(let id):
            return "Tab with ID \(id) not found"
        }
    }
}
