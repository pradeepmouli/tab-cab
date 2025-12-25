//
//  MockGroupRepository.swift
//  TabOrganizerStorageTests
//
//  Mock implementation of TabGroupRepository for testing.
//  Provides in-memory storage and call tracking.
//

import Foundation
import TabOrganizerCore
@testable import TabOrganizerStorage

/// Mock repository for testing tab group operations.
///
/// **Features**:
/// - In-memory storage (no persistence)
/// - Call tracking for verification
/// - Configurable error injection
/// - Deterministic behavior for tests
@MainActor
public final class MockGroupRepository: TabGroupRepository {

    // MARK: - State Tracking

    /// In-memory storage: windowID -> [TabGroup]
    public private(set) var groups: [String: [TabGroup]] = [:]

    /// Tracks all save operations
    public private(set) var saveCalls: [(group: TabGroup, windowID: String)] = []

    /// Tracks all delete operations
    public private(set) var deleteCalls: [UUID] = []

    /// Tracks all update operations
    public private(set) var updateCalls: [(group: TabGroup, windowID: String)] = []

    /// Tracks all getAllGroups operations
    public private(set) var getAllGroupsCalls: [String] = []

    /// Observers: windowID -> [Continuation]
    private var observers: [String: [AsyncStream<[TabGroup]>.Continuation]] = [:]

    // MARK: - Error Injection

    /// If set, save() will throw this error
    public var saveError: Error?

    /// If set, delete() will throw this error
    public var deleteError: Error?

    /// If set, update() will throw this error
    public var updateError: Error?

    /// If set, getAllGroups() will throw this error
    public var getAllGroupsError: Error?

    // MARK: - Initialization

    public init() {}

    // MARK: - CRUD Operations

    public func save(_ group: TabGroup, windowID: String) async throws {
        saveCalls.append((group, windowID))

        if let error = saveError {
            throw error
        }

        // Check for duplicate name
        let windowGroups = groups[windowID] ?? []
        if windowGroups.contains(where: { $0.name == group.name && $0.id != group.id }) {
            throw StorageError.duplicateName("A group named '\(group.name)' already exists in this window")
        }

        // Add or update group
        var updatedGroups = windowGroups
        if let existingIndex = updatedGroups.firstIndex(where: { $0.id == group.id }) {
            updatedGroups[existingIndex] = group
        } else {
            updatedGroups.append(group)
        }

        groups[windowID] = updatedGroups

        // Notify observers
        notifyObservers(windowID: windowID, groups: updatedGroups)
    }

    public func delete(groupID: UUID) async throws {
        deleteCalls.append(groupID)

        if let error = deleteError {
            throw error
        }

        // Find and remove group
        var foundWindow: String?
        for (windowID, windowGroups) in groups {
            if windowGroups.contains(where: { $0.id == groupID }) {
                foundWindow = windowID
                break
            }
        }

        guard let windowID = foundWindow else {
            throw StorageError.notFound("Group with ID \(groupID) not found")
        }

        groups[windowID]?.removeAll { $0.id == groupID }

        // Notify observers
        let updatedGroups = groups[windowID] ?? []
        notifyObservers(windowID: windowID, groups: updatedGroups)
    }

    public func getAllGroups(windowID: String) async throws -> [TabGroup] {
        getAllGroupsCalls.append(windowID)

        if let error = getAllGroupsError {
            throw error
        }

        return groups[windowID] ?? []
    }

    public func getGroup(groupID: UUID) async throws -> TabGroup? {
        for windowGroups in groups.values {
            if let group = windowGroups.first(where: { $0.id == groupID }) {
                return group
            }
        }
        return nil
    }

    public func update(_ group: TabGroup, windowID: String) async throws {
        updateCalls.append((group, windowID))

        if let error = updateError {
            throw error
        }

        var windowGroups = groups[windowID] ?? []

        // Check if group exists
        guard let existingIndex = windowGroups.firstIndex(where: { $0.id == group.id }) else {
            throw StorageError.notFound("Group with ID \(group.id) not found in window \(windowID)")
        }

        // Check for duplicate name
        if windowGroups.contains(where: { $0.name == group.name && $0.id != group.id }) {
            throw StorageError.duplicateName("A group named '\(group.name)' already exists in this window")
        }

        windowGroups[existingIndex] = group
        groups[windowID] = windowGroups

        // Notify observers
        notifyObservers(windowID: windowID, groups: windowGroups)
    }

    // MARK: - Reactive Observation

    public func observeGroups(windowID: String) -> AsyncStream<[TabGroup]> {
        AsyncStream { continuation in
            // Add observer
            if observers[windowID] == nil {
                observers[windowID] = []
            }
            observers[windowID]?.append(continuation)

            // Send current state immediately
            let currentGroups = groups[windowID] ?? []
            continuation.yield(currentGroups)

            // Cleanup on cancellation
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.observers[windowID]?.removeAll { $0 === continuation }
                }
            }
        }
    }

    // MARK: - Bulk Operations

    public func deleteAllGroups(windowID: String) async throws {
        groups[windowID] = []
        notifyObservers(windowID: windowID, groups: [])
    }

    // MARK: - Test Helpers

    /// Resets all state and call tracking.
    public func reset() {
        groups.removeAll()
        saveCalls.removeAll()
        deleteCalls.removeAll()
        updateCalls.removeAll()
        getAllGroupsCalls.removeAll()
        saveError = nil
        deleteError = nil
        updateError = nil
        getAllGroupsError = nil
        observers.removeAll()
    }

    /// Creates a sample repository with predefined groups.
    ///
    /// - Parameter windowID: The window ID to populate
    /// - Returns: Mock repository with sample data
    public static func withSampleGroups(windowID: String = "window-1") -> MockGroupRepository {
        let repo = MockGroupRepository()

        let workGroup = TabGroup(
            id: UUID(),
            name: "Work",
            color: "#0066CC",
            collapsed: false,
            createdAt: Date(),
            updatedAt: Date(),
            tabIDs: ["tab-1", "tab-2", "tab-3"],
            metadata: [:]
        )

        let researchGroup = TabGroup(
            id: UUID(),
            name: "Research",
            color: "#00CC66",
            collapsed: false,
            createdAt: Date().addingTimeInterval(60),
            updatedAt: Date().addingTimeInterval(60),
            tabIDs: ["tab-4", "tab-5"],
            metadata: [:]
        )

        repo.groups[windowID] = [workGroup, researchGroup]

        return repo
    }

    /// Adds a sample group to the repository.
    ///
    /// - Parameters:
    ///   - name: Group name
    ///   - windowID: Window identifier
    ///   - tabIDs: Tab identifiers
    public func addSampleGroup(name: String, windowID: String, tabIDs: [String] = []) {
        let group = TabGroup(
            id: UUID(),
            name: name,
            color: "#FF6600",
            collapsed: false,
            createdAt: Date(),
            updatedAt: Date(),
            tabIDs: tabIDs,
            metadata: [:]
        )

        if groups[windowID] == nil {
            groups[windowID] = []
        }
        groups[windowID]?.append(group)
    }

    // MARK: - Private Helpers

    /// Notifies all observers of group changes.
    private func notifyObservers(windowID: String, groups: [TabGroup]) {
        guard let continuations = observers[windowID] else { return }

        for continuation in continuations {
            continuation.yield(groups)
        }
    }
}
