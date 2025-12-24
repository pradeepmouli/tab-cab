@testable import App
import XCTest

final class AppTests: XCTestCase {
    func testAsyncComputation() async throws {
        // Simple async function to validate concurrency works
        func compute() async -> Int {
            await withTaskGroup(of: Int.self) { group in
                group.addTask { 2 }
                group.addTask { 3 }
                var sum = 0
                for await v in group {
                    sum += v
                }
                return sum
            }
        }
        let result = await compute()
        XCTAssertEqual(result, 5)
    }
}
