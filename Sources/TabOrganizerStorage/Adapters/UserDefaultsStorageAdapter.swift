import Foundation
import TabOrganizerCore

/// UserDefaults-backed storage adapter for Safari Extension
///
/// Uses JSON encoding for all values to ensure Sendable compliance.
/// Monitors storage size to prevent quota exceeded errors (5MB Safari limit).
public actor UserDefaultsStorageAdapter: SafariStorageAdapter, StorageAdapter {

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Maximum storage size in bytes (5MB for Safari extensions)
    private let maxStorageSize: Int = 5 * 1024 * 1024

    /// Key prefix to namespace extension storage
    private let keyPrefix: String

    // MARK: - Initialization

    /// Creates a storage adapter with UserDefaults
    ///
    /// - Parameters:
    ///   - userDefaults: UserDefaults instance (default: .standard)
    ///   - keyPrefix: Prefix for all storage keys to avoid conflicts (default: "tab-organizer.")
    public init(userDefaults: UserDefaults = .standard, keyPrefix: String = "tab-organizer.") {
        self.userDefaults = userDefaults
        self.keyPrefix = keyPrefix
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    // MARK: - SafariStorageAdapter Implementation

    public func save<T: Codable & Sendable>(_ value: T, forKey key: String) async throws {
        let prefixedKey = keyPrefix + key

        do {
            let data = try encoder.encode(value)

            // Check storage quota before saving
            let currentSize = await estimateStorageSize()
            let newSize = currentSize + data.count

            if newSize > maxStorageSize {
                throw StorageError.quotaExceeded(
                    attemptedSize: data.count,
                    availableSpace: maxStorageSize - currentSize
                )
            }

            userDefaults.set(data, forKey: prefixedKey)

        } catch let error as StorageError {
            throw error
        } catch {
            throw StorageError.encodingFailed(key: key, underlyingError: error.localizedDescription)
        }
    }

    public func load<T: Codable & Sendable>(forKey key: String, as type: T.Type) async throws -> T? {
        let prefixedKey = keyPrefix + key

        guard let data = userDefaults.data(forKey: prefixedKey) else {
            return nil
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch let DecodingError.typeMismatch(attemptedType, _) {
            throw StorageError.typeMismatch(
                key: key,
                expectedType: String(describing: T.self),
                actualType: String(describing: attemptedType)
            )
        } catch {
            throw StorageError.decodingFailed(key: key, underlyingError: error.localizedDescription)
        }
    }

    public func remove(forKey key: String) async throws {
        let prefixedKey = keyPrefix + key
        userDefaults.removeObject(forKey: prefixedKey)
    }

    public func exists(forKey key: String) async -> Bool {
        let prefixedKey = keyPrefix + key
        return userDefaults.object(forKey: prefixedKey) != nil
    }

    public func removeAll() async throws {
        let keys = await allKeys()
        for key in keys {
            try await remove(forKey: key)
        }
    }

    public func allKeys() async -> [String] {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        return allKeys
            .filter { $0.hasPrefix(keyPrefix) }
            .map { String($0.dropFirst(keyPrefix.count)) }
    }

    // MARK: - StorageAdapter Implementation

    public func store<T: Codable & Sendable>(_ key: String, value: T) async throws {
        try await save(value, forKey: key)
    }

    public func retrieve<T: Codable & Sendable>(_ key: String) async throws -> T? {
        return try await load(forKey: key, as: T.self)
    }

    public func remove(_ key: String) async throws {
        try await remove(forKey: key)
    }

    public func exists(_ key: String) async -> Bool {
        return await exists(forKey: key)
    }

    // MARK: - Private Helpers

    /// Estimates total storage size in bytes
    private func estimateStorageSize() async -> Int {
        let keys = await allKeys()
        var totalSize = 0

        for key in keys {
            let prefixedKey = keyPrefix + key
            if let data = userDefaults.data(forKey: prefixedKey) {
                totalSize += data.count
            }
        }

        return totalSize
    }
}
