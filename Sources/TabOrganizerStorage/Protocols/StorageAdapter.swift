import Foundation

/// Protocol for key-value storage operations.
///
/// This protocol abstracts persistent storage to enable testability.
/// Production implementations use UserDefaults while test implementations
/// provide in-memory storage.
public protocol StorageAdapter: Sendable {
    /// Store a Codable value for the given key
    ///
    /// - Parameters:
    ///   - key: Storage key
    ///   - value: Codable value to store
    /// - Throws: StorageError on encoding or persistence failure
    func store<T: Codable & Sendable>(_ key: String, value: T) async throws
    
    /// Retrieve a Codable value for the given key
    ///
    /// - Parameter key: Storage key
    /// - Returns: Decoded value or nil if key doesn't exist
    /// - Throws: StorageError on decoding failure
    func retrieve<T: Codable & Sendable>(_ key: String) async throws -> T?
    
    /// Remove a value for the given key
    ///
    /// - Parameter key: Storage key
    func remove(_ key: String) async throws
    
    /// Remove all values from the underlying storage backend associated with this adapter.
    ///
    /// Implementations are expected to clear the entire backing store for the adapter’s
    /// domain (for example, all keys in the associated UserDefaults suite), which may
    /// include keys that were not originally written via this adapter.
    func removeAll() async throws
    
    /// Check if a key exists in storage
    ///
    /// - Parameter key: Storage key
    /// - Returns: true if key exists, false otherwise
    func exists(_ key: String) async -> Bool
}

/// Errors that can occur during storage operations
public enum StorageError: Error, LocalizedError, Sendable, Equatable {
    /// Failed to encode value to JSON
    case encodingFailed(String)
    
    /// Failed to decode value from JSON
    case decodingFailed(String)
    
    /// Storage quota exceeded
    case quotaExceeded
    
    /// General storage error
    case storageUnavailable(String)
    
    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let message):
            return "Failed to encode data: \(message)"
        case .decodingFailed(let message):
            return "Failed to decode data: \(message)"
        case .quotaExceeded:
            return "Storage quota exceeded. Please free up space."
        case .storageUnavailable(let message):
            return "Storage unavailable: \(message)"
        }
    }
}
