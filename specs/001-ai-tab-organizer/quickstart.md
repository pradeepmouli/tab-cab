# Quickstart Guide: AI-Powered Safari Tab Organizer

**For**: Developers implementing this feature  
**Updated**: 2025-12-24

---

## Overview

This Safari extension provides AI-powered tab organization through:
- Manual and AI-suggested tab associationing
- Context-aware tab highlighting
- Automatic tab rearrangement
- Intelligent tab cleanup

**Tech Stack**: Swift 6.1+, SwiftUI, SPM, Safari Extensions, NaturalLanguage, CoreML

---

## Project Structure at a Glance

```
Package.swift                    # SPM manifest (5 library targets)
Sources/
├── TabOrganizerExtension/      # Safari Extension (thin wrapper)
├── TabOrganizerCore/           # Domain models & business logic
├── TabOrganizerAI/             # AI/ML analysis (NaturalLanguage, CoreML)
├── TabOrganizerStorage/        # Persistence layer
├── TabOrganizerUI/             # SwiftUI views
└── TabOrganizerSafariAPI/      # Safari API wrappers
Tests/                          # Swift Testing tests for each library
```

**Key Insight**: Extension target is minimal glue code. All logic lives in testable SPM libraries.

---

## Getting Started

### Prerequisites

- macOS 15.0+ with Xcode 16+
- Safari 18.0+ for testing
- Basic knowledge of Swift 6, SwiftUI, Safari Extensions

### Initial Setup

```bash
# Clone repository
git clone <repo-url>
cd tab-cab

# Switch to feature branch
git checkout 001-ai-tab-organizer

# Open Xcode workspace (when created)
open TabOrganizer.xcworkspace

# Build SPM libraries first
swift build

# Run tests
swift test
```

---

## Architecture Overview

### Layer 1: Safari Extension (Entry Point)

**File**: `Sources/TabOrganizerExtension/SafariExtensionHandler.swift`

**Responsibilities**:
- Handle Safari extension lifecycle (`messageReceived`, `toolbarItemClicked`)
- Present SwiftUI popover UI
- Bridge Safari events to service layer

**Key Code Pattern**:
```swift
import SafariServices
import TabOrganizerUI
import TabOrganizerCore

class SafariExtensionHandler: SFSafariExtensionHandler {
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        // Handle messages from content script
    }
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        // Show popover UI
    }
}
```

---

### Layer 2: Core Domain (Business Logic)

**Library**: `TabOrganizerCore`  
**Files**: `Sources/TabOrganizerCore/Models/*.swift`, `Services/*.swift`

**Responsibilities**:
- Define domain entities (TabAssociation, Tab, etc.)
- Implement business rules (group validation, cleanup logic)
- Coordinate between storage and AI layers

**Key Service Pattern**:
```swift
import TabOrganizerSafariAPI
import TabOrganizerStorage

@MainActor
final class TabAssociationService: Sendable {
    private let tabManager: TabManaging
    private let repository: TabAssociationRepository
    
    init(tabManager: TabManaging, repository: TabAssociationRepository) {
        self.tabManager = tabManager
        self.repository = repository
    }
    
    func createGroup(name: String, tabIDs: [String]) async throws -> TabAssociation {
        // Validate name uniqueness
        // Create TabAssociation entity
        // Save to repository
        // Return created group
    }
}
```

---

### Layer 3: AI Analysis (On-Device ML)

**Library**: `TabOrganizerAI`  
**Files**: `Sources/TabOrganizerAI/*.swift`

**Responsibilities**:
- Extract keywords from tab titles (NaturalLanguage)
- Classify tabs into categories (CoreML)
- Compute tab similarity scores
- Generate grouping suggestions

**Key Pattern**:
```swift
import NaturalLanguage
import CoreML

final class NaturalLanguageContextAnalyzer: ContextAnalyzer {
    private let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
    
    func analyzeContext(for sourceTab: TabInfo, allTabs: [TabInfo]) async throws -> ContextAnalysis {
        // Extract keywords from sourceTab
        // Compute similarities with allTabs
        // Return ContextAnalysis
    }
}
```

---

### Layer 4: Storage (Persistence)

**Library**: `TabOrganizerStorage`  
**Files**: `Sources/TabOrganizerStorage/*.swift`

**Responsibilities**:
- Wrap Safari local storage APIs
- Serialize/deserialize entities (Codable)
- Implement repository pattern for CRUD operations

**Key Pattern**:
```swift
final actor SafariStorageAdapter {
    func store<T: Codable>(key: String, value: T) async throws {
        // Encode to JSON
        // Write to Safari localStorage
    }
    
    func retrieve<T: Codable>(key: String) async throws -> T? {
        // Read from Safari localStorage
        // Decode from JSON
    }
}
```

---

### Layer 5: UI (SwiftUI)

**Library**: `TabOrganizerUI`  
**Files**: `Sources/TabOrganizerUI/Views/*.swift`

**Responsibilities**:
- Render extension popover UI
- Handle user interactions (drag-and-drop, buttons)
- Display AI suggestions and cleanup prompts

**Key Pattern** (per Constitution - no ViewModels):
```swift
import SwiftUI
import TabOrganizerCore

@MainActor
struct GroupListView: View {
    @Environment(TabAssociationService.self) private var groupService
    @State private var groups: [TabAssociation] = []
    
    var body: some View {
        List(groups) { group in
            GroupRow(group: group)
        }
        .task {
            groups = try? await groupService.getAllGroups()
        }
    }
}
```

---

## Development Workflow

### Step 1: Implement Core Models (P1 - Manual Groups)

**Order**:
1. Define `TabAssociation` struct in `TabOrganizerCore/Models/TabAssociation.swift`
2. Define `Tab` struct in `TabOrganizerCore/Models/Tab.swift`
3. Write Swift Testing tests in `Tests/TabOrganizerCoreTests/ModelTests.swift`

**Example Test**:
```swift
import Testing
@testable import TabOrganizerCore

@Test func testTabAssociationValidation() {
    let group = TabAssociation(name: "", tabIDs: [])
    #expect(throws: ValidationError.self) {
        try group.validate()
    }
}
```

---

### Step 2: Implement Safari API Wrappers

**Order**:
1. Define `TabManaging` protocol in `TabOrganizerSafariAPI/TabManaging.swift`
2. Implement `SafariTabManager` (production)
3. Implement `MockTabManager` (tests)
4. Write tests using mock

**Testing Pattern**:
```swift
@Test func testGetAllTabs() async throws {
    let mockManager = MockTabManager()
    mockManager.stubbedTabs = [
        TabInfo(id: "1", url: URL(string: "https://example.com")!, title: "Example")
    ]
    
    let tabs = try await mockManager.getAllTabs()
    #expect(tabs.count == 1)
    #expect(tabs[0].id == "1")
}
```

---

### Step 3: Implement Storage Layer

**Order**:
1. Implement `SafariStorageAdapter` (low-level storage)
2. Implement `TabAssociationRepository` (group CRUD)
3. Implement `SettingsRepository` (settings persistence)
4. Write tests with in-memory mock storage

---

### Step 4: Implement Business Logic Services

**Order**:
1. `TabAssociationService` (P1 - manual grouping)
2. `TabTrackingService` (track lastViewedAt timestamps)
3. `SettingsService` (load/save settings)

**Dependency Injection Pattern**:
```swift
let tabManager: TabManaging = SafariTabManager()
let repository: TabAssociationRepository = SafariGroupRepository()
let groupService = TabAssociationService(tabManager: tabManager, repository: repository)
```

---

### Step 5: Build SwiftUI UI

**Order**:
1. `GroupListView` (show existing groups)
2. `GroupEditorView` (create/edit group)
3. `TabDragView` (drag-and-drop tabs)
4. Wire up to extension popover

**SwiftUI Preview Pattern**:
```swift
#Preview {
    GroupListView()
        .environment(TabAssociationService(
            tabManager: MockTabManager(),
            repository: MockGroupRepository()
        ))
}
```

---

### Step 6: AI Features (P2-P5)

**Order** (after P1 is complete and tested):
1. Implement `ContextAnalyzer` (P3 - context highlighting)
2. Implement `GroupingSuggester` (P2 - AI grouping)
3. Implement cleanup logic (P5 - intelligent cleanup)
4. Implement auto-rearrangement (P4 - optional advanced feature)

---

## Testing Strategy

### Unit Tests (Fast, Isolated)

**Run**: `swift test`

**Coverage Target**: 80% for critical paths, 60% for utility code

**Mocking Strategy**:
- Use protocol-oriented architecture
- Inject mock dependencies via initializers
- No singletons or global state

**Example Test Structure**:
```swift
@Suite("TabAssociationService Tests")
struct TabAssociationServiceTests {
    let mockTabManager = MockTabManager()
    let mockRepository = MockGroupRepository()
    var service: TabAssociationService!
    
    init() {
        service = TabAssociationService(
            tabManager: mockTabManager,
            repository: mockRepository
        )
    }
    
    @Test func testCreateGroup() async throws {
        // Given: mock tabs
        mockTabManager.stubbedTabs = [/* test data */]
        
        // When: create group
        let group = try await service.createGroup(name: "Work", tabIDs: ["1"])
        
        // Then: group created
        #expect(group.name == "Work")
        #expect(mockRepository.savedGroups.count == 1)
    }
}
```

---

### Integration Tests (Slower, Real APIs)

**Run**: `swift test --filter TabOrganizerIntegrationTests`

**Purpose**: Validate real Safari API integration

**Requirements**:
- Safari must be running
- Test extension must be installed
- May require manual steps (open tabs, grant permissions)

**Example**:
```swift
@Test(.enabled(if: ProcessInfo.processInfo.environment["CI"] == nil))
func testRealSafariTabAccess() async throws {
    let realManager = SafariTabManager()
    let tabs = try await realManager.getAllTabs()
    #expect(!tabs.isEmpty, "Safari should have at least one tab open")
}
```

---

## Debugging Tips

### Extension Not Loading

1. Check Safari > Preferences > Extensions > Tab Organizer is enabled
2. Verify code signing: `codesign -dv TabOrganizer.appex`
3. Check Console.app for extension crash logs

### Storage Issues

```swift
// Log storage contents for debugging
let adapter = SafariStorageAdapter()
if let groups: [TabAssociation] = try? await adapter.retrieve(key: "groups.main") {
    print("Stored groups: \(groups)")
}
```

### AI Analysis Slow

- Profile with Instruments (Time Profiler)
- Check tab count (>200 tabs may hit 5s timeout)
- Verify CoreML model loaded: `print(tabClassifier.modelLoaded)`

---

## Common Pitfalls

❌ **Don't**: Put business logic in extension handler  
✅ **Do**: Keep extension handler thin, delegate to services

❌ **Don't**: Use force-unwrapping (`!`) with Safari APIs  
✅ **Do**: Use proper error handling and graceful degradation

❌ **Don't**: Store private tabs or track them  
✅ **Do**: Filter `isPrivate` tabs at API boundary

❌ **Don't**: Create ViewModels (constitution violation)  
✅ **Do**: Use SwiftUI `@State` and `@Observable` models

❌ **Don't**: Use GCD or completion handlers  
✅ **Do**: Use Swift Concurrency (async/await, actors)

---

## Useful Commands

```bash
# Build extension
xcodebuild -workspace TabOrganizer.xcworkspace -scheme TabOrganizer

# Run tests
swift test

# Run specific test
swift test --filter testGroupCreation

# Build and run in Safari
# (Xcode: Product > Run - launches Safari with extension)

# Check storage
defaults read ~/Library/Safari/LocalStorage/tabOrganizer
```

---

## Resources

**Documentation**:
- [Safari Extension Guide](https://developer.apple.com/documentation/safariservices/safari_app_extensions)
- [Swift Testing](https://developer.apple.com/documentation/testing)
- [NaturalLanguage Framework](https://developer.apple.com/documentation/naturallanguage)
- [CoreML](https://developer.apple.com/documentation/coreml)

**Project Documentation**:
- [spec.md](spec.md) - Feature requirements
- [research.md](research.md) - Technical research findings
- [data-model.md](data-model.md) - Entity definitions
- [contracts/](contracts/) - API contracts

**Constitution**:
- [.specify/memory/constitution.md](../../.specify/memory/constitution.md) - Non-negotiable principles

---

## Next Steps

1. ✅ Read this quickstart guide
2. ✅ Review [spec.md](spec.md) for user requirements
3. ✅ Review [data-model.md](data-model.md) for entity structure
4. ✅ Review [contracts/](contracts/) for API details
5. ⏭️ Run `/speckit.tasks` to generate detailed task breakdown
6. ⏭️ Start implementing P1 (Manual Tab Groups) following TDD approach

---

**Questions?** Refer to research.md for architectural decisions and rationale.
