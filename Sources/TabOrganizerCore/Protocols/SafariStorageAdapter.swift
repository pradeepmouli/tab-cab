import Foundation

/// Protocol for persistent storage operations
///
/// Abstracts storage mechanisms to enable testing with mock implementations.
/// All implementations must handle JSON encoding/decoding and quota limits.
///
/// ## Thread Safety
/// All methods are async and safe to call from any context.
/// Implementations must handle their own synchronization.
///
/// ## Storage Limits
/// Safari local storage has a 5MB limit per extension.
/// Implementations MUST handle quota exceeded errors gracefully.
public protocol SafariStorageAdapter: Sendable {
    /// Saves a Codable value to storage
    ///
    /// - Parameters:
    ///   - value: The value to save (must be Codable)
    ///   - key: Unique storage key
    /// - Throws: `StorageError.encodingFailed` if JSON encoding fails
    /// - Throws: `StorageError.quotaExceeded` if storage limit is reached
    /// - Throws: `StorageError.unknown` for other storage failures
    ///
    /// ## Pre-conditions
    /// - `key` is a valid storage key (non-empty)
    /// - `value` is encodable to JSON
    ///
    /// ## Post-conditions
    /// - Value is persisted and retrievable via `load(key:)`
    /// - Previous value for `key` is overwritten
    func save<T: Codable & Sendable>(_ value: T, forKey key: String) async throws

    /// Loads a Codable value from storage
    ///
    /// - Parameters:
    ///   - key: Unique storage key
    ///   - type: Expected type of the stored value
    /// - Returns: Decoded value, or `nil` if key doesn't exist
    /// - Throws: `StorageError.decodingFailed` if stored data is invalid
    /// - Throws: `StorageError.typeMismatch` if type doesn't match stored data
    ///
    /// ## Pre-conditions
    /// - `key` is a valid storage key
    ///
    /// ## Post-conditions
    /// - Returns decoded value if key exists and type matches
    /// - Returns `nil` if key doesn't exist (not an error)
    func load<T: Codable & Sendable>(forKey key: String, as type: T.Type) async throws -> T?

    /// Removes a value from storage
    ///
    /// - Parameter key: Unique storage key
    /// - Throws: `StorageError.unknown` for storage failures
    ///
    /// ## Pre-conditions
    /// - `key` is a valid storage key
    ///
    /// ## Post-conditions
    /// - Key no longer exists in storage
    /// - Subsequent `load(forKey:)` returns `nil`
    func remove(forKey key: String) async throws

    /// Checks if a key exists in storage
    ///
    /// - Parameter key: Unique storage key
    /// - Returns: `true` if key exists, `false` otherwise
    ///
    /// ## Post-conditions
    /// - Returns existence status without throwing
    func exists(forKey key: String) async -> Bool

    /// Removes all stored values
    ///
    /// - Throws: `StorageError.unknown` for storage failures
    ///
    /// ## Pre-conditions
    /// - Storage is accessible
    ///
    /// ## Post-conditions
    /// - All keys are removed
    /// - `exists(forKey:)` returns `false` for all keys
    func removeAll() async throws

    /// Returns all storage keys
    ///
    /// - Returns: Array of all stored keys
    ///
    /// ## Post-conditions
    /// - Returns all keys currently in storage
    /// - Empty array if no keys exist
    func allKeys() async -> [String]
}
