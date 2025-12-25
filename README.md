# Tab Cab

An AI-powered Safari extension for intelligent tab organization and management.

## Project Status: MVP Development (Phase 1-3)

This is an in-progress Safari extension for macOS that uses AI to help organize browser tabs into groups, provide context-aware highlighting, and intelligent cleanup.

### Current Implementation

✅ **Core Domain Models** (Phase 2 Complete)
- TabGroup: Named collection of tabs with validation, colors, and metadata
- Tab: Safari tab representation with domain extraction and inactivity tracking
- UserSettings: User preferences with feature toggles and validation
- 35 comprehensive unit tests (all passing)

✅ **Storage Layer** (Phase 3 Complete)
- StorageAdapter protocol with Sendable constraints for Swift 6
- UserDefaultsStorageAdapter with JSON encoding and quota management
- TabGroupRepository for CRUD operations with duplicate checking
- MockStorageAdapter for deterministic testing
- 14 comprehensive storage tests (all passing)

✅ **Safari API Abstraction** (Phase 2 Complete)
- TabManaging protocol for tab manipulation
- TabInfo/TabAPIError models
- MockTabManager for testing
- Protocol-oriented design for testability

🔨 **In Progress**
- Business logic services (TabGroupService implemented)
- Safari Extension app target creation
- SwiftUI UI components

### Architecture

```
Package.swift                    # SPM manifest with 5 library targets
Sources/
├── TabOrganizerCore/           # Domain models & business logic
├── TabOrganizerStorage/        # Persistence layer
├── TabOrganizerSafariAPI/      # Safari API wrappers & protocols
├── TabOrganizerAI/             # AI/ML analysis (future)
└── TabOrganizerUI/             # SwiftUI views (future)
Tests/                          # Swift Testing framework tests
```

### Tech Stack

- **Language**: Swift 6.1+ with strict concurrency
- **UI**: SwiftUI (macOS 15.0+)
- **Architecture**: Protocol-oriented SPM libraries + Safari Extension wrapper
- **Testing**: Swift Testing framework (@Test, #expect)
- **Concurrency**: Actors, async/await, @MainActor isolation
- **Storage**: UserDefaults with JSON encoding

### Development Status

**Total Tests**: 49 passing
- TabGroup model: 21 tests
- Tab model: 14 tests  
- Storage layer: 14 tests

**Code Coverage**: 80%+ for critical paths

### Next Steps

1. **Business Logic Services**
   - Implement TabTrackingService for timestamp tracking
   - Add comprehensive service tests

2. **Safari Extension Target**
   - Create macOS Safari Extension app in Xcode
   - Configure entitlements for tab access
   - Implement SafariExtensionHandler

3. **SwiftUI UI**
   - GroupListView for displaying groups
   - GroupEditorView for creating/editing groups
   - TabCard component for drag-and-drop

4. **Integration Testing**
   - End-to-end tests with real Safari APIs
   - Manual testing in Safari browser

### MVP Features (User Story 1)

- ✅ Create named tab groups with colors
- ✅ Persistent storage across sessions
- 🔨 Collapse/expand groups in UI
- 🔨 Drag-and-drop tabs between groups
- 🔨 Safari Extension popover interface

### Future Features (Post-MVP)

- **AI-Suggested Grouping** (P2): Analyze tabs and suggest intelligent groups
- **Context Highlighting** (P3): Highlight related tabs when one is selected
- **Auto-Rearrangement** (P4): Automatically move related tabs together
- **Intelligent Cleanup** (P5): Suggest closing inactive tabs

## Getting Started

### Prerequisites

- macOS 15.0+ with Xcode 16+
- Swift 6.1+
- Safari 18.0+ for testing

### Build & Test

```bash
# Build the package
swift build

# Run tests
swift test

# Run specific test suite
swift test --filter TabGroupTests
```

### Project Structure

This project follows a **workspace + SPM package** architecture where all business logic lives in testable Swift Package libraries, and the Safari Extension target serves as a thin wrapper.

## Documentation

- **Specification**: `specs/001-ai-tab-organizer/spec.md` - Complete feature requirements
- **Implementation Plan**: `specs/001-ai-tab-organizer/plan.md` - Technical architecture
- **Tasks**: `specs/001-ai-tab-organizer/tasks.md` - Detailed task breakdown
- **Data Model**: `specs/001-ai-tab-organizer/data-model.md` - Entity definitions
- **API Contracts**: `specs/001-ai-tab-organizer/contracts/` - Protocol specifications

## Code Style

- Swift 6 with strict concurrency checking
- Protocol-oriented architecture for testability
- Value types (struct) for domain models
- Actors for thread-safe operations
- SwiftUI with @Observable for state management (no ViewModels)
- Swift Testing framework (@Test, #expect, #require)

## License

[Add your license here]

## Contributing

This project is in active development. The MVP focuses on manual tab grouping before implementing AI features.
