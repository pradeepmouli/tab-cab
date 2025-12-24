import Foundation
import Logging

let logger = Logger(label: "com.pmouli.swifttemplate")

@main
struct SwiftTemplateApp {
    static func main() async {
        logger.info("SwiftTemplate starting up")

        // Run a simple concurrent task group
        await withTaskGroup(of: Int.self) { group in
            for i in 1 ... 3 {
                group.addTask {
                    try? await Task.sleep(nanoseconds: UInt64(i) * 200_000_000)
                    return i * i
                }
            }

            var sum = 0
            for await value in group {
                sum += value
            }
            logger.info("Computed sum: \(sum)")
        }

        logger.info("SwiftTemplate finished")
    }
}
