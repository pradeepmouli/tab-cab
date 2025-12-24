// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TabOrganizer",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .library(name: "TabOrganizerCore", targets: ["TabOrganizerCore"]),
        .library(name: "TabOrganizerStorage", targets: ["TabOrganizerStorage"]),
        .library(name: "TabOrganizerSafariAPI", targets: ["TabOrganizerSafariAPI"]),
        .library(name: "TabOrganizerAI", targets: ["TabOrganizerAI"]),
        .library(name: "TabOrganizerUI", targets: ["TabOrganizerUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4")
    ],
    targets: [
        // Core domain models and business logic
        .target(
            name: "TabOrganizerCore",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ],
            path: "Sources/TabOrganizerCore"
        ),
        
        // Storage and persistence layer
        .target(
            name: "TabOrganizerStorage",
            dependencies: [
                "TabOrganizerCore",
                "TabOrganizerSafariAPI"
            ],
            path: "Sources/TabOrganizerStorage"
        ),
        
        // Safari API wrappers and protocols
        .target(
            name: "TabOrganizerSafariAPI",
            dependencies: ["TabOrganizerCore"],
            path: "Sources/TabOrganizerSafariAPI"
        ),
        
        // AI/ML analysis (NaturalLanguage, CoreML)
        .target(
            name: "TabOrganizerAI",
            dependencies: ["TabOrganizerCore"],
            path: "Sources/TabOrganizerAI"
        ),
        
        // SwiftUI views and components
        .target(
            name: "TabOrganizerUI",
            dependencies: [
                "TabOrganizerCore",
                "TabOrganizerStorage",
                "TabOrganizerSafariAPI"
            ],
            path: "Sources/TabOrganizerUI"
        ),
        
        // Tests
        .testTarget(
            name: "TabOrganizerCoreTests",
            dependencies: ["TabOrganizerCore"],
            path: "Tests/TabOrganizerCoreTests"
        ),
        .testTarget(
            name: "TabOrganizerStorageTests",
            dependencies: ["TabOrganizerStorage"],
            path: "Tests/TabOrganizerStorageTests"
        ),
        .testTarget(
            name: "TabOrganizerSafariAPITests",
            dependencies: ["TabOrganizerSafariAPI"],
            path: "Tests/TabOrganizerSafariAPITests"
        ),
        .testTarget(
            name: "TabOrganizerAITests",
            dependencies: ["TabOrganizerAI"],
            path: "Tests/TabOrganizerAITests"
        ),
        .testTarget(
            name: "TabOrganizerUITests",
            dependencies: ["TabOrganizerUI"],
            path: "Tests/TabOrganizerUITests"
        )
    ]
)
