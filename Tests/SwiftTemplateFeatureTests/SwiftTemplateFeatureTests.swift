import XCTest
@testable import SwiftTemplateFeature

final class SwiftTemplateFeatureTests: XCTestCase {
    @MainActor
    func testContentViewExists() {
        let view = ContentView()
        XCTAssertNotNil(view)
    }
}
