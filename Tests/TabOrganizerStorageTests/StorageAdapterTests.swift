import Testing
import Foundation
@testable import TabOrganizerStorage

@Suite("StorageAdapter Tests")
struct StorageAdapterTests {

    // MARK: - Test Models

    struct TestData: Codable, Equatable {
        let id: String
        let value: Int
        let name: String
    }

    // MARK: - Save Tests

    @Test("MockStorageAdapter saves and loads value")
    func saveAndLoadValue() async throws {
        let adapter = MockStorageAdapter()
        let testData = TestData(id: "test-1", value: 42, name: "Test")

        try await adapter.save(testData, forKey: "test-key")
        let loaded = try await adapter.load(forKey: "test-key", as: TestData.self)

        #expect(loaded == testData)
        #expect(adapter.savedKeys.contains("test-key"))
    }

    @Test("MockStorageAdapter returns nil for non-existent key")
    func loadNonExistentKeyReturnsNil() async throws {
        let adapter = MockStorageAdapter()

        let loaded = try await adapter.load(forKey: "non-existent", as: TestData.self)

        #expect(loaded == nil)
    }

    @Test("MockStorageAdapter overwrites existing value")
    func saveOverwritesExistingValue() async throws {
        let adapter = MockStorageAdapter()
        let original = TestData(id: "test-1", value: 42, name: "Original")
        let updated = TestData(id: "test-1", value: 99, name: "Updated")

        try await adapter.save(original, forKey: "test-key")
        try await adapter.save(updated, forKey: "test-key")

        let loaded = try await adapter.load(forKey: "test-key", as: TestData.self)
        #expect(loaded == updated)
        #expect(adapter.savedKeys.count == 2)
    }

    @Test("MockStorageAdapter throws quota exceeded error")
    func saveThrowsQuotaExceededError() async throws {
        let adapter = MockStorageAdapter()
        adapter.shouldSimulateQuotaExceeded = true
        let testData = TestData(id: "test-1", value: 42, name: "Test")

        await #expect(throws: StorageError.self) {
            try await adapter.save(testData, forKey: "test-key")
        }
    }

    @Test("MockStorageAdapter throws encoding failure")
    func saveThrowsEncodingError() async throws {
        let adapter = MockStorageAdapter()
        adapter.shouldSimulateEncodingFailure = true
        let testData = TestData(id: "test-1", value: 42, name: "Test")

        await #expect(throws: StorageError.encodingFailed) {
            try await adapter.save(testData, forKey: "test-key")
        }
    }

    // MARK: - Load Tests

    @Test("MockStorageAdapter throws decoding failure")
    func loadThrowsDecodingError() async throws {
        let adapter = MockStorageAdapter()
        let testData = TestData(id: "test-1", value: 42, name: "Test")
        try await adapter.save(testData, forKey: "test-key")

        adapter.shouldSimulateDecodingFailure = true

        await #expect(throws: StorageError.decodingFailed) {
            _ = try await adapter.load(forKey: "test-key", as: TestData.self)
        }
    }

    @Test("MockStorageAdapter throws type mismatch error")
    func loadThrowsTypeMismatchError() async throws {
        let adapter = MockStorageAdapter()
        let testData = TestData(id: "test-1", value: 42, name: "Test")
        try await adapter.save(testData, forKey: "test-key")

        await #expect(throws: StorageError.typeMismatch) {
            _ = try await adapter.load(forKey: "test-key", as: String.self)
        }
    }

    // MARK: - Remove Tests

    @Test("MockStorageAdapter removes value")
    func removeDeletesValue() async throws {
        let adapter = MockStorageAdapter()
        let testData = TestData(id: "test-1", value: 42, name: "Test")
        try await adapter.save(testData, forKey: "test-key")

        try await adapter.remove(forKey: "test-key")

        let loaded = try await adapter.load(forKey: "test-key", as: TestData.self)
        #expect(loaded == nil)
        #expect(adapter.removedKeys.contains("test-key"))
    }

    @Test("MockStorageAdapter removes all values")
    func removeAllClearsStorage() async throws {
        let adapter = MockStorageAdapter()
        try await adapter.save(TestData(id: "1", value: 1, name: "One"), forKey: "key-1")
        try await adapter.save(TestData(id: "2", value: 2, name: "Two"), forKey: "key-2")
        try await adapter.save(TestData(id: "3", value: 3, name: "Three"), forKey: "key-3")

        try await adapter.removeAll()

        let keys = await adapter.allKeys()
        #expect(keys.isEmpty)
        #expect(await adapter.itemCount() == 0)
    }

    // MARK: - Exists Tests

    @Test("MockStorageAdapter checks key existence")
    func existsReturnsTrueForExistingKey() async throws {
        let adapter = MockStorageAdapter()
        let testData = TestData(id: "test-1", value: 42, name: "Test")
        try await adapter.save(testData, forKey: "test-key")

        let exists = await adapter.exists(forKey: "test-key")
        let notExists = await adapter.exists(forKey: "other-key")

        #expect(exists == true)
        #expect(notExists == false)
    }

    // MARK: - AllKeys Tests

    @Test("MockStorageAdapter returns all keys")
    func allKeysReturnsAllStoredKeys() async throws {
        let adapter = MockStorageAdapter()
        try await adapter.save(TestData(id: "1", value: 1, name: "One"), forKey: "key-1")
        try await adapter.save(TestData(id: "2", value: 2, name: "Two"), forKey: "key-2")
        try await adapter.save(TestData(id: "3", value: 3, name: "Three"), forKey: "key-3")

        let keys = await adapter.allKeys()

        #expect(keys.count == 3)
        #expect(keys.contains("key-1"))
        #expect(keys.contains("key-2"))
        #expect(keys.contains("key-3"))
    }

    @Test("MockStorageAdapter returns empty array when no keys")
    func allKeysReturnsEmptyArrayWhenEmpty() async throws {
        let adapter = MockStorageAdapter()

        let keys = await adapter.allKeys()

        #expect(keys.isEmpty)
    }

    // MARK: - Storage Size Tests

    @Test("MockStorageAdapter tracks storage size")
    func storageSizeIncreasesWithData() async throws {
        let adapter = MockStorageAdapter()
        let initialSize = await adapter.storageSize()

        try await adapter.save(TestData(id: "test-1", value: 42, name: "Test"), forKey: "key-1")
        let afterSave = await adapter.storageSize()

        #expect(afterSave > initialSize)
    }

    @Test("MockStorageAdapter enforces storage quota")
    func storageQuotaIsEnforced() async throws {
        let adapter = MockStorageAdapter()
        adapter.maxStorageSize = 100 // Very small quota for testing
        adapter.shouldSimulateQuotaExceeded = true

        let largeData = TestData(id: "test-1", value: 42, name: String(repeating: "x", count: 1000))

        await #expect(throws: StorageError.quotaExceeded) {
            try await adapter.save(largeData, forKey: "large-key")
        }
    }

    // MARK: - Reset Tests

    @Test("MockStorageAdapter reset clears all state")
    func resetClearsAllState() async throws {
        let adapter = MockStorageAdapter()
        try await adapter.save(TestData(id: "1", value: 1, name: "One"), forKey: "key-1")
        try await adapter.remove(forKey: "key-1")
        adapter.shouldSimulateQuotaExceeded = true

        await adapter.reset()

        let keys = await adapter.allKeys()
        #expect(keys.isEmpty)
        #expect(adapter.savedKeys.isEmpty)
        #expect(adapter.removedKeys.isEmpty)
        #expect(adapter.shouldSimulateQuotaExceeded == false)
    }

    // MARK: - Multiple Value Types Tests

    @Test("MockStorageAdapter handles different value types")
    func handlesMultipleValueTypes() async throws {
        let adapter = MockStorageAdapter()

        // Save different types
        try await adapter.save("Hello", forKey: "string-key")
        try await adapter.save(42, forKey: "int-key")
        try await adapter.save([1, 2, 3], forKey: "array-key")
        try await adapter.save(["name": "Test"], forKey: "dict-key")

        // Load and verify
        let stringValue = try await adapter.load(forKey: "string-key", as: String.self)
        let intValue = try await adapter.load(forKey: "int-key", as: Int.self)
        let arrayValue = try await adapter.load(forKey: "array-key", as: [Int].self)
        let dictValue = try await adapter.load(forKey: "dict-key", as: [String: String].self)

        #expect(stringValue == "Hello")
        #expect(intValue == 42)
        #expect(arrayValue == [1, 2, 3])
        #expect(dictValue == ["name": "Test"])
    }
}
