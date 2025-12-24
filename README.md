# SwiftTemplate

A modern Swift 6 template with SPM executable + iOS/macOS apps using a **shared package architecture**.

## Project Structure

```
swift-template/
├── Package.swift                       # Root SPM package (shared code)
├── Sources/
│   ├── App/                           # CLI executable
│   └── SwiftTemplateFeature/          # 🚀 Shared UI/feature code
├── Tests/
│   ├── AppTests/                      # CLI tests
│   └── SwiftTemplateFeatureTests/     # Feature tests
├── SwiftTemplateiOS.xcworkspace/      # iOS app (imports SwiftTemplateFeature)
├── SwiftTemplateiOS/                  # iOS app shell
├── SwiftTemplateMacOS.xcworkspace/    # macOS app (imports SwiftTemplateFeature)
├── SwiftTemplateMacOS/                # macOS app shell
├── Config/                            # Build configuration (.xcconfig)
└── .github/workflows/                 # CI pipeline
```

## Getting Started

### CLI Executable
```bash
swift build
swift run SwiftTemplate
swift test
```

### iOS App
1. Open `SwiftTemplateiOS.xcworkspace` in Xcode
2. Select iPhone simulator
3. Build & Run (⌘R)

### macOS App
1. Open `SwiftTemplateMacOS.xcworkspace` in Xcode
2. Build & Run (⌘R)

## Architecture

### Shared Package
- **SwiftTemplateFeature**: Shared UI components and business logic used by iOS/macOS apps
- **App**: Standalone CLI executable (macOS only)
- Both platforms import `SwiftTemplateFeature` from the root `Package.swift`

### App Shells
- `SwiftTemplateiOS/` and `SwiftTemplateMacOS/` contain minimal app lifecycle code
- Feature development happens in `Sources/SwiftTemplateFeature/`
- Reduces duplication, enables code sharing across platforms

### Public API Requirements
Types exposed to app targets need `public` access:
```swift
public struct MyView: View {
    public init() {}
    
    public var body: some View {
        // Your view code
    }
}
```

## Development

### Adding Dependencies
Edit root `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/example/SomePackage", from: "1.0.0")
]
```

### Lint & Format
```bash
swiftlint --strict
swiftformat .
```

### CI
GitHub Actions workflow runs on macOS with build, test, lint, and format checks.

## Code Style
- Swift 6+ with strict concurrency
- SwiftUI for all UI code
- Prefer `struct` over `class`; explicit access control
- Use `async/await`, `TaskGroup`, `Actor` for concurrency
- Logging via `swift-log` (`Logging.Logger`)

See `.swiftlint.yml` and `.swiftformat` for style configuration.
