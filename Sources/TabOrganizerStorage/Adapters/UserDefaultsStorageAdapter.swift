import Foundation

/// UserDefaults-based implementation of StorageAdapter.
///
/// Provides persistent storage using Foundation's UserDefaults with JSON encoding.
/// All operations are performed on a background actor to avoid blocking the main thread.
public actor UserDefaultsStorageAdapter: StorageAdapter {
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    /// Key prefix for all stored values
    private let keyPrefix: String
    
    /// Maximum allowed data size per key (5MB)
    private let maxDataSize = 5 * 1024 * 1024
    
    /// Creates a UserDefaults storage adapter
    ///
    /// - Parameters:
    ///   - suiteName: Optional suite name for app group sharing
    ///   - keyPrefix: Prefix for all keys (default: "tabOrganizer.")
    public init(suiteName: String? = nil, keyPrefix: String = "tabOrganizer.") {
        if let suiteName = suiteName {
            self.userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        } else {
            self.userDefaults = .standard
        }
        
        self.keyPrefix = keyPrefix
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    public func store<T: Codable & Sendable>(_ key: String, value: T) async throws {
        do {
            let data = try encoder.encode(value)
            
            // Check quota
            guard data.count <= maxDataSize else {
                throw StorageError.quotaExceeded
            }
            
            userDefaults.set(data, forKey: keyPrefix + key)
        } catch let error as StorageError {
            throw error
        } catch {
            throw StorageError.encodingFailed(error.localizedDescription)
        }
    }
    
    public func retrieve<T: Codable & Sendable>(_ key: String) async throws -> T? {
        guard let data = userDefaults.data(forKey: keyPrefix + key) else {
            return nil
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw StorageError.decodingFailed(error.localizedDescription)
        }
    }
    
    public func remove(_ key: String) async throws {
        userDefaults.removeObject(forKey: keyPrefix + key)
    }
    
    public func removeAll() async throws {
        // Only remove keys with our prefix
        let domain = userDefaults.dictionaryRepresentation()
        for key in domain.keys where key.hasPrefix(keyPrefix) {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    public func exists(_ key: String) async -> Bool {
        return userDefaults.object(forKey: keyPrefix + key) != nil
    }
}
