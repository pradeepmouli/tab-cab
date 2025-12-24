// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftTemplate",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .executable(name: "SwiftTemplate", targets: ["App"]),
        .library(name: "SwiftTemplateFeature", targets: ["SwiftTemplateFeature"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ],
            path: "Sources/App",
            resources: []
        ),
        .target(
            name: "SwiftTemplateFeature",
            dependencies: [],
            path: "Sources/SwiftTemplateFeature"
        ),
        .testTarget(
            name: "AppTests",
            dependencies: ["App"],
            path: "Tests/AppTests"
        ),
        .testTarget(
            name: "SwiftTemplateFeatureTests",
            dependencies: ["SwiftTemplateFeature"],
            path: "Tests/SwiftTemplateFeatureTests"
        )
    ]
)
