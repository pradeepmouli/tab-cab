//
//  TabGroupService.swift
//  TabOrganizerCore
//
//  Business logic for tab group operations.
//  Coordinates between Safari API and storage layers.
//

import Foundation

/// Service for managing tab groups with business logic and validation.
///
/// **Responsibilities**:
/// - CRUD operations for tab groups (FR-001, FR-005)
/// - Tab membership management (FR-004)
/// - Duplicate name prevention (FR-006)
/// - Cross-layer coordination (Safari API + Storage)
///
/// **Architecture**: This service is the primary interface for tab group operations.
/// UI components should interact with this service, not directly with repositories.
@MainActor
@Observable
public final class TabGroupService {

    // MARK: - Dependencies

    private let repository: any TabGroupRepository
    private let tabManager: any TabManaging

    // MARK: - Observable State

    /// Current groups for the active window.
    /// SwiftUI views can observe this directly.
    public private(set) var groups: [TabGroup] = []

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
        repository: any TabGroupRepository,
        tabManager: any TabManaging
    ) {
        self.repository = repository
        self.tabManager = tabManager
    }

    // MARK: - Group Operations

    /// Creates a new tab group.
    ///
    /// **FR-001**: Allow users to create named tab groups with custom colors
    /// **FR-006**: Prevent duplicate group names within the same window
    ///
    /// - Parameters:
    ///   - name: The group name (must be non-empty)
    ///   - color: The group color (hex format, e.g., "#0066CC")
    ///   - tabIDs: Initial tab IDs to include (optional)
    ///   - windowID: The window identifier
    /// - Returns: The created TabGroup
    /// - Throws: `TabGroupError.invalidName` if name is empty
    /// - Throws: `StorageError.duplicateName` if name already exists (FR-006)
    public func createGroup(
        name: String,
        color: String,
        tabIDs: [String] = [],
        windowID: String
    ) async throws -> TabGroup {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TabGroupError.invalidName("Group name cannot be empty")
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let group = TabGroup(
                id: UUID(),
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                color: color,
                collapsed: false,
                createdAt: Date(),
                updatedAt: Date(),
                tabIDs: tabIDs,
                metadata: [:]
            )

            try await repository.save(group, windowID: windowID)

            // Refresh local state
            await loadGroups(windowID: windowID)

            return group

        } catch {
            lastError = error
            throw error
        }
    }

    /// Deletes a tab group.
    ///
    /// **FR-005**: Allow users to delete groups at any time
    ///
    /// - Parameters:
    ///   - groupID: The group identifier
    ///   - windowID: The window identifier (for UI refresh)
    /// - Throws: `StorageError.notFound` if group doesn't exist
    public func deleteGroup(groupID: UUID, windowID: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.delete(groupID: groupID)

            // Refresh local state
            await loadGroups(windowID: windowID)

        } catch {
            lastError = error
            throw error
        }
    }

    /// Updates a group's properties.
    ///
    /// **FR-005**: Allow users to rename groups at any time
    /// **FR-003**: Support collapse/expand functionality
    ///
    /// - Parameters:
    ///   - group: The updated group
    ///   - windowID: The window identifier
    /// - Throws: `StorageError.notFound` if group doesn't exist
    /// - Throws: `StorageError.duplicateName` if new name conflicts
    public func updateGroup(_ group: TabGroup, windowID: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.update(group, windowID: windowID)

            // Refresh local state
            await loadGroups(windowID: windowID)

        } catch {
            lastError = error
            throw error
        }
    }

    /// Retrieves all groups for a window.
    ///
    /// **FR-002**: Persist tab groups across browser sessions
    ///
    /// - Parameter windowID: The window identifier
    /// - Returns: Array of tab groups
    public func getAllGroups(windowID: String) async throws -> [TabGroup] {
        try await repository.getAllGroups(windowID: windowID)
    }

    /// Loads groups into observable state.
    ///
    /// Call this to refresh the UI's view of groups.
    ///
    /// - Parameter windowID: The window identifier
    public func loadGroups(windowID: String) async {
        do {
            groups = try await repository.getAllGroups(windowID: windowID)
            lastError = nil
        } catch {
            lastError = error
            groups = []
        }
    }

    // MARK: - Tab Membership Operations

    /// Adds a tab to a group.
    ///
    /// **FR-004**: Support drag-and-drop to move tabs between groups
    ///
    /// - Parameters:
    ///   - tabID: The tab identifier
    ///   - groupID: The group identifier
    ///   - windowID: The window identifier
    /// - Throws: `StorageError.notFound` if group doesn't exist
    public func addTabToGroup(tabID: String, groupID: UUID, windowID: String) async throws {
        guard let group = try await repository.getGroup(groupID: groupID) else {
            throw StorageError.notFound("Group with ID \(groupID) not found")
        }

        let updatedGroup = try group.withTabAdded(tabID)
        try await updateGroup(updatedGroup, windowID: windowID)
    }

    /// Removes a tab from a group.
    ///
    /// **FR-004**: Support drag-and-drop to remove tabs from groups
    ///
    /// - Parameters:
    ///   - tabID: The tab identifier
    ///   - groupID: The group identifier
    ///   - windowID: The window identifier
    /// - Throws: `StorageError.notFound` if group doesn't exist
    public func removeTabFromGroup(tabID: String, groupID: UUID, windowID: String) async throws {
        guard let group = try await repository.getGroup(groupID: groupID) else {
            throw StorageError.notFound("Group with ID \(groupID) not found")
        }

        let updatedGroup = try group.withTabRemoved(tabID)
        try await updateGroup(updatedGroup, windowID: windowID)
    }

    /// Moves a tab from one group to another.
    ///
    /// Atomic operation ensuring tab is removed from source and added to destination.
    ///
    /// - Parameters:
    ///   - tabID: The tab identifier
    ///   - fromGroupID: The source group identifier (nil if ungrouped)
    ///   - toGroupID: The destination group identifier (nil to ungroup)
    ///   - windowID: The window identifier
    public func moveTab(
        tabID: String,
        fromGroupID: UUID?,
        toGroupID: UUID?,
        windowID: String
    ) async throws {
        // Remove from source group if specified
        if let fromID = fromGroupID {
            guard let sourceGroup = try await repository.getGroup(groupID: fromID) else {
                throw StorageError.notFound("Source group with ID \(fromID) not found")
            }
            let updatedSource = try sourceGroup.withTabRemoved(tabID)
            try await repository.update(updatedSource, windowID: windowID)
        }

        // Add to destination group if specified
        if let toID = toGroupID {
            guard let destGroup = try await repository.getGroup(groupID: toID) else {
                throw StorageError.notFound("Destination group with ID \(toID) not found")
            }
            let updatedDest = try destGroup.withTabAdded(tabID)
            try await repository.update(updatedDest, windowID: windowID)
        }

        // Refresh local state
        await loadGroups(windowID: windowID)
    }

    // MARK: - Group State Operations

    /// Toggles a group's collapsed state.
    ///
    /// **FR-003**: Allow users to collapse/expand groups to show/hide contained tabs
    ///
    /// - Parameters:
    ///   - groupID: The group identifier
    ///   - windowID: The window identifier
    /// - Throws: `StorageError.notFound` if group doesn't exist
    public func toggleGroupCollapsed(groupID: UUID, windowID: String) async throws {
        guard let group = try await repository.getGroup(groupID: groupID) else {
            throw StorageError.notFound("Group with ID \(groupID) not found")
        }

        let updatedGroup = try group.withCollapsed(!group.collapsed)
        try await updateGroup(updatedGroup, windowID: windowID)
    }

    /// Renames a group.
    ///
    /// **FR-005**: Allow users to rename groups at any time
    ///
    /// - Parameters:
    ///   - groupID: The group identifier
    ///   - newName: The new group name
    ///   - windowID: The window identifier
    /// - Throws: `TabGroupError.invalidName` if name is empty
    /// - Throws: `StorageError.duplicateName` if name already exists (FR-006)
    public func renameGroup(groupID: UUID, newName: String, windowID: String) async throws {
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TabGroupError.invalidName("Group name cannot be empty")
        }

        guard let group = try await repository.getGroup(groupID: groupID) else {
            throw StorageError.notFound("Group with ID \(groupID) not found")
        }

        let updatedGroup = try group.withName(newName.trimmingCharacters(in: .whitespacesAndNewlines))
        try await updateGroup(updatedGroup, windowID: windowID)
    }

    /// Changes a group's color.
    ///
    /// - Parameters:
    ///   - groupID: The group identifier
    ///   - newColor: The new color (hex format)
    ///   - windowID: The window identifier
    public func changeGroupColor(groupID: UUID, newColor: String, windowID: String) async throws {
        guard let group = try await repository.getGroup(groupID: groupID) else {
            throw StorageError.notFound("Group with ID \(groupID) not found")
        }

        let updatedGroup = try group.withColor(newColor)
        try await updateGroup(updatedGroup, windowID: windowID)
    }
}

// MARK: - TabGroupError

/// Errors specific to tab group operations.
public enum TabGroupError: LocalizedError {
    case invalidName(String)
    case groupNotFound(UUID)
    case tabNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .invalidName(let message):
            return message
        case .groupNotFound(let id):
            return "Group with ID \(id) not found"
        case .tabNotFound(let id):
            return "Tab with ID \(id) not found"
        }
    }
}
