//
//  SafariAssociationRepository.swift
//  TabOrganizerStorage
//
//  Production implementation of TabAssociationRepository using Safari local storage.
//  Stores tab associations in UserDefaults with JSON encoding per FR-030.
//

import Foundation
import TabOrganizerCore

/// Production repository for tab association persistence using UserDefaults.
///
/// **Storage Strategy**:
/// - Key format: "tab_groups_{windowID}" for window-specific groups
/// - JSON encoding via Codable (FR-030)
/// - 5MB storage limit per FR-030
/// - In-memory cache for performance
///
/// **Thread Safety**: @MainActor isolated for SwiftUI integration
@MainActor
public final class SafariAssociationRepository: TabAssociationRepository {

    // MARK: - Properties

    private let storage: SafariStorageAdapter
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// In-memory cache: windowID -> [TabAssociation]
    private var cache: [String: [TabAssociation]] = [:]

    /// Observers: windowID -> [Continuation]
    private var observers: [String: [AsyncStream<[TabAssociation]>.Continuation]] = [:]

    // MARK: - Initialization

    /// Creates a repository with the given storage adapter.
    ///
    /// - Parameter storage: The storage adapter to use (default: UserDefaultsStorageAdapter)
    public init(storage: SafariStorageAdapter = UserDefaultsStorageAdapter()) {
        self.storage = storage

        // Configure JSON encoder for consistent formatting
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]

        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - CRUD Operations

    public func save(_ group: TabAssociation, windowID: String) async throws {
        // FR-006: Check for duplicate name in this window
        var groups = try await getAllAssociations(windowID: windowID)

        if groups.contains(where: { $0.name == group.name && $0.id != group.id }) {
            throw StorageError.duplicateName("A group named '\(group.name)' already exists in this window")
        }

        // Add or update group
        if let existingIndex = groups.firstIndex(where: { $0.id == group.id }) {
            groups[existingIndex] = group
        } else {
            groups.append(group)
        }

        // Persist to storage
        try await saveGroups(groups, windowID: windowID)

        // Update cache
        cache[windowID] = groups

        // Notify observers
        notifyObservers(windowID: windowID, groups: groups)
    }

    public func delete(associationID: UUID) async throws {
        // Find association in all windows
        var foundWindow: String?
        var groups: [TabAssociation] = []

        for (windowID, cachedGroups) in cache {
            if cachedGroups.contains(where: { $0.id == associationID }) {
                foundWindow = windowID
                groups = cachedGroups
                break
            }
        }

        // If not in cache, search storage
        if foundWindow == nil {
            // Get all window IDs from storage keys
            let allKeys = await storage.allKeys()
            let windowIDs = allKeys
                .filter { $0.hasPrefix("tab_groups_") }
                .map { String($0.dropFirst("tab_groups_".count)) }

            for windowID in windowIDs {
                let windowGroups = try await getAllAssociations(windowID: windowID)
                if windowGroups.contains(where: { $0.id == associationID }) {
                    foundWindow = windowID
                    groups = windowGroups
                    break
                }
            }
        }

        guard let windowID = foundWindow else {
            throw StorageError.notFound("Association with ID \(associationID) not found")
        }

        // Remove association
        groups.removeAll { $0.id == associationID }

        // Persist to storage
        try await saveGroups(groups, windowID: windowID)

        // Update cache
        cache[windowID] = groups

        // Notify observers
        notifyObservers(windowID: windowID, groups: groups)
    }

    public func getAllAssociations(windowID: String) async throws -> [TabAssociation] {
        // Check cache first
        if let cachedGroups = cache[windowID] {
            return cachedGroups
        }

        // Load from storage
        let key = storageKey(windowID: windowID)

        guard let groups = try await storage.load(forKey: key, as: [TabAssociation].self) else {
            // No groups for this window yet
            cache[windowID] = []
            return []
        }

        // Update cache
        cache[windowID] = groups

        return groups.sorted { $0.createdAt < $1.createdAt }
    }

    public func getAssociation(associationID: UUID) async throws -> TabAssociation? {
        // Search cache first
        for groups in cache.values {
            if let group = groups.first(where: { $0.id == associationID }) {
                return group
            }
        }

        // Search storage
        let allKeys = await storage.allKeys()
        let windowIDs = allKeys
            .filter { $0.hasPrefix("tab_groups_") }
            .map { String($0.dropFirst("tab_groups_".count)) }

        for windowID in windowIDs {
            let groups = try await getAllAssociations(windowID: windowID)
            if let group = groups.first(where: { $0.id == associationID }) {
                return group
            }
        }

        return nil
    }

    public func update(_ group: TabAssociation, windowID: String) async throws {
        var groups = try await getAllAssociations(windowID: windowID)

        // Check if group exists
        guard let existingIndex = groups.firstIndex(where: { $0.id == group.id }) else {
            throw StorageError.notFound("Group with ID \(group.id) not found in window \(windowID)")
        }

        // FR-006: Check for duplicate name (excluding current group)
        if groups.contains(where: { $0.name == group.name && $0.id != group.id }) {
            throw StorageError.duplicateName("A group named '\(group.name)' already exists in this window")
        }

        // Update group
        groups[existingIndex] = group

        // Persist to storage
        try await saveGroups(groups, windowID: windowID)

        // Update cache
        cache[windowID] = groups

        // Notify observers
        notifyObservers(windowID: windowID, groups: groups)
    }

    // MARK: - Reactive Observation

    public func observeAssociations(windowID: String) -> AsyncStream<[TabAssociation]> {
        AsyncStream { continuation in
            // Add observer
            if observers[windowID] == nil {
                observers[windowID] = []
            }
            observers[windowID]?.append(continuation)

            // Send current state immediately
            Task {
                do {
                    let groups = try await getAllAssociations(windowID: windowID)
                    continuation.yield(groups)
                } catch {
                    continuation.finish()
                }
            }

            // Cleanup on cancellation - just clear all observers for this window
            // since multiple observers are rare and will be re-registered if needed
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.observers[windowID] = []
                }
            }
        }
    }

    // MARK: - Bulk Operations

    public func deleteAllAssociations(windowID: String) async throws {
        let key = storageKey(windowID: windowID)
        try await storage.remove(forKey: key)

        // Clear cache
        cache[windowID] = []

        // Notify observers
        notifyObservers(windowID: windowID, groups: [])
    }

    // MARK: - Private Helpers

    /// Generates storage key for a window's groups.
    ///
    /// - Parameter windowID: The window identifier
    /// - Returns: Storage key in format "tab_groups_{windowID}"
    private func storageKey(windowID: String) -> String {
        "tab_groups_\(windowID)"
    }

    /// Saves groups array to storage with quota checking.
    ///
    /// - Parameters:
    ///   - groups: The groups to save
    ///   - windowID: The window identifier
    /// - Throws: `StorageError.quotaExceeded` if data exceeds 5MB limit
    private func saveGroups(_ groups: [TabAssociation], windowID: String) async throws {
        let key = storageKey(windowID: windowID)
        let data = try encoder.encode(groups)

        // FR-030: Check 5MB quota limit
        let dataSizeMB = Double(data.count) / 1_048_576 // Convert to MB
        if dataSizeMB > 5.0 {
            throw StorageError.quotaExceeded(attemptedSize: data.count, availableSpace: 5_242_880)
        }

        try await storage.save(groups, forKey: key)
    }

    /// Notifies all observers of group changes.
    ///
    /// - Parameters:
    ///   - windowID: The window identifier
    ///   - groups: The updated groups array
    private func notifyObservers(windowID: String, groups: [TabAssociation]) {
        guard let continuations = observers[windowID] else { return }

        for continuation in continuations {
            continuation.yield(groups)
        }
    }
}
