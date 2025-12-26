import Foundation

/// Wrapper to transfer non-Sendable values across concurrency boundaries.
///
/// **Use with caution**: Only use when you know the value is safe to transfer
/// (e.g., Safari API callbacks that always run on main thread).
@propertyWrapper
struct UnsafeTransfer<T>: @unchecked Sendable {
    var wrappedValue: T

    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}
