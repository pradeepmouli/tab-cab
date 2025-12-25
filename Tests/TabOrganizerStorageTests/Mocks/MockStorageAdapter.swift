import Foundation
@testable import TabOrganizerStorage

/// Mock implementation of SafariStorageAdapter for testing
///
/// Provides in-memory storage with deterministic behavior.
/// State can be inspected and manipulated directly for test scenarios.
public actor MockStorageAdapter: SafariStorageAdapter {

    // MARK: - Mock State

    /// In-memory storage dictionary
    private var storage: [String: Data] = [:]

    /// Simulates quota exceeded when true
    public var shouldSimulateQuotaExceeded: Bool = false

    /// Simulates encoding failure when true
    public var shouldSimulateEncodingFailure: Bool = false

    /// Simulates decoding failure when true
    public var shouldSimulateDecodingFailure: Bool = false

    /// Maximum storage size in bytes (default: 5MB)
    public var maxStorageSize: Int = 5 * 1024 * 1024

    /// Tracks all save operations for verification
    public private(set) var savedKeys: [String] = []

    /// Tracks all remove operations for verification
    public private(set) var removedKeys: [String] = []

    // MARK: - Initialization

    public init() {}

    // MARK: - SafariStorageAdapter Implementation

    public func save<T: Codable>(_ value: T, forKey key: String) async throws {
        if shouldSimulateEncodingFailure {
            throw StorageError.encodingFailed(key: key, underlyingError: "Simulated encoding failure")
        }

        let encoder = JSONEncoder()
        let data = try encoder.encode(value)

        if shouldSimulateQuotaExceeded {
            let currentSize = storage.values.reduce(0) { $0 + $1.count }
            throw StorageError.quotaExceeded(
                attemptedSize: data.count,
                availableSpace: max(0, maxStorageSize - currentSize)
            )
        }

        storage[key] = data
        savedKeys.append(key)
    }

    public func load<T: Codable>(forKey key: String, as type: T.Type) async throws -> T? {
        guard let data = storage[key] else {
            return nil
        }

        if shouldSimulateDecodingFailure {
            throw StorageError.decodingFailed(key: key, underlyingError: "Simulated decoding failure")
        }

        let decoder = JSONDecoder()
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
        storage.removeValue(forKey: key)
        removedKeys.append(key)
    }

    public func exists(forKey key: String) async -> Bool {
        storage[key] != nil
    }

    public func removeAll() async throws {
        let keys = Array(storage.keys)
        storage.removeAll()
        removedKeys.append(contentsOf: keys)
    }

    public func allKeys() async -> [String] {
        Array(storage.keys)
    }

    // MARK: - Test Helpers

    /// Resets all mock state
    public func reset() {
        storage.removeAll()
        shouldSimulateQuotaExceeded = false
        shouldSimulateEncodingFailure = false
        shouldSimulateDecodingFailure = false
        savedKeys.removeAll()
        removedKeys.removeAll()
    }

    /// Returns current storage size in bytes
    public func storageSize() -> Int {
        storage.values.reduce(0) { $0 + $1.count }
    }

    /// Returns number of stored items
    public func itemCount() -> Int {
        storage.count
    }

    /// Directly sets a value (bypassing encoding for test setup)
    public func setRawData(_ data: Data, forKey key: String) {
        storage[key] = data
    }
}
