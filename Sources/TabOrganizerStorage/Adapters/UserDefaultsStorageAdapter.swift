import Foundation

/// UserDefaults-based implementation of StorageAdapter.
///
/// Provides persistent storage using Foundation's UserDefaults with JSON encoding.
/// All operations are performed on a background actor to avoid blocking the main thread.
public actor UserDefaultsStorageAdapter: StorageAdapter {
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    /// Maximum allowed data size per key (5MB)
    private let maxDataSize = 5 * 1024 * 1024
    
    /// Creates a UserDefaults storage adapter
    ///
    /// - Parameter suiteName: Optional suite name for app group sharing
    public init(suiteName: String? = nil) {
        if let suiteName = suiteName {
            self.userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        } else {
            self.userDefaults = .standard
        }
        
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
            
            userDefaults.set(data, forKey: key)
            userDefaults.synchronize()
        } catch let error as StorageError {
            throw error
        } catch {
            throw StorageError.encodingFailed(error.localizedDescription)
        }
    }
    
    public func retrieve<T: Codable & Sendable>(_ key: String) async throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw StorageError.decodingFailed(error.localizedDescription)
        }
    }
    
    public func remove(_ key: String) async throws {
        userDefaults.removeObject(forKey: key)
        userDefaults.synchronize()
    }
    
    public func removeAll() async throws {
        // Get all keys from our domain
        let domain = userDefaults.dictionaryRepresentation()
        for key in domain.keys {
            userDefaults.removeObject(forKey: key)
        }
        userDefaults.synchronize()
    }
    
    public func exists(_ key: String) async -> Bool {
        return userDefaults.object(forKey: key) != nil
    }
}
