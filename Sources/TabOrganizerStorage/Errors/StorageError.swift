import Foundation

/// Errors that can occur during storage operations
public enum StorageError: Error, Sendable, Equatable {
    /// Failed to encode value to JSON
    case encodingFailed(key: String, underlyingError: String)

    /// Failed to decode value from JSON
    case decodingFailed(key: String, underlyingError: String)

    /// Stored data type doesn't match requested type
    case typeMismatch(key: String, expectedType: String, actualType: String)

    /// Storage quota exceeded (Safari limit: 5MB)
    case quotaExceeded(attemptedSize: Int, availableSpace: Int)

    /// Storage operation failed for unknown reason
    case unknown(underlyingError: String)
}

extension StorageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let key, let error):
            return "Failed to encode value for key '\(key)': \(error)"
        case .decodingFailed(let key, let error):
            return "Failed to decode value for key '\(key)': \(error)"
        case .typeMismatch(let key, let expectedType, let actualType):
            return "Type mismatch for key '\(key)': expected \(expectedType), found \(actualType)"
        case .quotaExceeded(let attemptedSize, let availableSpace):
            return "Storage quota exceeded: attempted to save \(attemptedSize) bytes, only \(availableSpace) bytes available"
        case .unknown(let error):
            return "Storage operation failed: \(error)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .encodingFailed:
            return "Ensure the value conforms to Codable and doesn't contain non-encodable types."
        case .decodingFailed:
            return "The stored data may be corrupted or from an incompatible version. Consider removing the key."
        case .typeMismatch:
            return "Verify the correct type is being requested for this storage key."
        case .quotaExceeded:
            return "Delete unused tab groups or reduce the number of stored items. Safari extensions have a 5MB storage limit."
        case .unknown:
            return "Try the operation again or restart the Safari Extension."
        }
    }
}
