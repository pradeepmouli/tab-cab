import Testing
import Foundation
@testable import TabOrganizerStorage
@testable import TabOrganizerCore

@Suite("UserDefaultsStorageAdapter Tests")
struct UserDefaultsStorageAdapterTests {

    // Use unique prefixes per test to avoid conflicts

    @Test("Store and retrieve simple value")
    func testStoreAndRetrieveSimpleValue() async throws {
        let adapter = UserDefaultsStorageAdapter(keyPrefix: "test1.prefix.")
        let testValue = "Hello, World!"

        try await adapter.store("testKey", value: testValue)
        let retrieved: String? = try await adapter.retrieve("testKey")

        #expect(retrieved == testValue)
    }

    @Test("Store and retrieve struct")
    func testStoreAndRetrieveStruct() async throws {
        struct TestData: Codable, Sendable, Equatable {
            let name: String
            let age: Int
            let active: Bool
        }

        let adapter = UserDefaultsStorageAdapter(keyPrefix: "test2.struct.")
        let testData = TestData(name: "Alice", age: 30, active: true)

        try await adapter.store("person", value: testData)
        let retrieved: TestData? = try await adapter.retrieve("person")

        #expect(retrieved == testData)
    }

    @Test("Retrieve returns nil for non-existent key")
    func testRetrieveReturnsNilForNonExistentKey() async throws {
        let adapter = UserDefaultsStorageAdapter(keyPrefix: "test3.nil.")

        let retrieved: String? = try await adapter.retrieve("nonExistentKey")

        #expect(retrieved == nil)
    }

    @Test("Store throws quota exceeded for large data")
    func testStoreThrowsQuotaExceededForLargeData() async throws {
        let adapter = UserDefaultsStorageAdapter(keyPrefix: "test4.quota.")
        // Create data larger than 5MB
        let largeData = String(repeating: "x", count: 6 * 1024 * 1024)

        await #expect(throws: StorageError.self) {
            try await adapter.store("largeKey", value: largeData)
        }
    }

    @Test("Store accepts data just under quota")
    func testStoreAcceptsDataJustUnderQuota() async throws {
        let adapter = UserDefaultsStorageAdapter(keyPrefix: "test5.underquota.")
        // Create data just under 5MB (account for JSON encoding overhead)
        let data = String(repeating: "x", count: 4 * 1024 * 1024)

        // Should not throw
        try await adapter.store("acceptableKey", value: data)

        let retrieved: String? = try await adapter.retrieve("acceptableKey")
        #expect(retrieved == data)
    }

    @Test("Remove deletes stored value")
    func testRemoveDeletesStoredValue() async throws {
        let adapter = UserDefaultsStorageAdapter(keyPrefix: "test6.remove.")

        try await adapter.store("toDelete", value: "temporary data")
        #expect(await adapter.exists("toDelete"))

        try await adapter.remove("toDelete")

        #expect(!(await adapter.exists("toDelete")))
        let retrieved: String? = try await adapter.retrieve("toDelete")
        #expect(retrieved == nil)
    }

    @Test("Exists returns true for existing key")
    func testExistsReturnsTrueForExistingKey() async throws {
        let adapter = UserDefaultsStorageAdapter(keyPrefix: "test7.exists.")

        try await adapter.store("existingKey", value: "data")

        let exists = await adapter.exists("existingKey")
        #expect(exists)
    }

    @Test("Exists returns false for non-existent key")
    func testExistsReturnsFalseForNonExistentKey() async {
        let adapter = UserDefaultsStorageAdapter(keyPrefix: "test8.notexists.")

        let exists = await adapter.exists("nonExistentKey")
        #expect(!exists)
    }

    @Test("RemoveAll only removes keys with adapter prefix")
    func testRemoveAllOnlyRemovesKeysWithPrefix() async throws {
        let adapter1 = UserDefaultsStorageAdapter(keyPrefix: "test9.removeall1.")
        let adapter2 = UserDefaultsStorageAdapter(keyPrefix: "test9.removeall2.")

        // Store data in both adapters
        try await adapter1.store("key1", value: "data1")
        try await adapter1.store("key2", value: "data2")
        try await adapter2.store("key1", value: "other data")

        // Remove all from adapter1
        try await adapter1.removeAll()

        // Adapter1 keys should be gone
        #expect(!(await adapter1.exists("key1")))
        #expect(!(await adapter1.exists("key2")))

        // Adapter2 keys should still exist
        #expect(await adapter2.exists("key1"))
    }

    @Test("Store with date encoding strategy")
    func testStoreWithDateEncodingStrategy() async throws {
        struct DateData: Codable, Sendable, Equatable {
            let timestamp: Date
        }

        let adapter = UserDefaultsStorageAdapter(keyPrefix: "test10.date.")
        let now = Date()
        let testData = DateData(timestamp: now)

        try await adapter.store("dateKey", value: testData)
        let retrieved: DateData? = try await adapter.retrieve("dateKey")

        #expect(retrieved != nil)
        // Compare with tolerance for ISO8601 encoding/decoding and test execution time
        #expect(abs(retrieved!.timestamp.timeIntervalSince(now)) < 1.0)
    }

    @Test("Store and retrieve array")
    func testStoreAndRetrieveArray() async throws {
        let adapter = UserDefaultsStorageAdapter(keyPrefix: "test11.array.")
        let testArray = ["apple", "banana", "cherry"]

        try await adapter.store("fruits", value: testArray)
        let retrieved: [String]? = try await adapter.retrieve("fruits")

        #expect(retrieved == testArray)
    }

    @Test("Key prefix is applied correctly")
    func testKeyPrefixIsAppliedCorrectly() async throws {
        let adapter = UserDefaultsStorageAdapter(keyPrefix: "test12.custom.prefix.")

        try await adapter.store("testKey", value: "testValue")

        // Verify the key is stored with the prefix in UserDefaults
        let defaults = UserDefaults.standard
        let directValue = defaults.data(forKey: "test12.custom.prefix.testKey")
        #expect(directValue != nil)

        // Key without prefix should not exist
        let withoutPrefix = defaults.data(forKey: "testKey")
        #expect(withoutPrefix == nil)
    }
}
