import Foundation
@testable import TabOrganizerStorage

/// In-memory mock implementation of StorageAdapter for testing.
///
/// Provides controllable storage behavior without persistence.
public actor MockStorageAdapter: StorageAdapter {
    /// In-memory storage
    private var storage: [String: Data] = [:]
    
    /// Error to throw from operations (for error testing)
    public var errorToThrow: StorageError?
    
    /// Track all store operations
    public var storedKeys: [String] = []
    
    /// Track all retrieve operations
    public var retrievedKeys: [String] = []
    
    public init() {}
    
    public func store<T: Codable & Sendable>(_ key: String, value: T) async throws {
        if let error = errorToThrow {
            throw error
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(value)
            storage[key] = data
            storedKeys.append(key)
        } catch {
            throw StorageError.encodingFailed(error.localizedDescription)
        }
    }
    
    public func retrieve<T: Codable & Sendable>(_ key: String) async throws -> T? {
        if let error = errorToThrow {
            throw error
        }
        
        retrievedKeys.append(key)
        
        guard let data = storage[key] else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw StorageError.decodingFailed(error.localizedDescription)
        }
    }
    
    public func remove(_ key: String) async throws {
        if let error = errorToThrow {
            throw error
        }
        
        storage.removeValue(forKey: key)
    }
    
    public func removeAll() async throws {
        if let error = errorToThrow {
            throw error
        }
        
        storage.removeAll()
    }
    
    public func exists(_ key: String) async -> Bool {
        return storage[key] != nil
    }
    
    /// Reset all tracking and storage
    public func reset() {
        storage.removeAll()
        storedKeys.removeAll()
        retrievedKeys.removeAll()
        errorToThrow = nil
    }
}
