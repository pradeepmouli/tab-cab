# Implementation Plan: AI-Powered Safari Tab Organizer

**Branch**: `001-ai-tab-organizer` | **Date**: 2025-12-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-ai-tab-organizer/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Create a Safari extension that intelligently organizes browser tabs through manual grouping, AI-suggested grouping, context-aware highlighting, automatic rearrangement, and intelligent cleanup. Core MVP (P1) provides manual tab groups with persistence. Advanced features (P2-P5) leverage on-device ML for context analysis while maintaining strict privacy-first architecture.

**Technical Approach**: Swift Package Manager architecture with extension logic in libraries. Native SwiftUI for extension UI. Safari Extension APIs for tab manipulation. On-device NaturalLanguage framework for keyword extraction and CoreML for content classification (no external API calls). Local storage via Safari's secure APIs.

## Technical Context

**Language/Version**: Swift 6.1+ (strict concurrency mode enabled)  
**Primary Dependencies**: Safari Extensions framework, SwiftUI, NaturalLanguage framework, CoreML (on-device), Combine (for reactive state)  
**Storage**: Safari local storage APIs (localStorage equivalent), Keychain for sensitive data (if needed for future features)  
**Testing**: Swift Testing framework (@Test, @Suite, #expect, #require)  
**Target Platform**: macOS 15.0+, iOS 18.0+ (Safari extension support)
**Project Type**: Safari Extension + SPM Libraries (hybrid: extension target + shared packages)  
**Performance Goals**: <5s for AI analysis of 50 tabs, <1s for tab rearrangement, <100ms UI response time  
**Constraints**: <100MB memory for 200 tabs, on-device processing only (no external APIs), HTTPS-only network requests (future features)  
**Scale/Scope**: Support 20-200 tabs per user, 5 user stories (P1-P5), ~15 SwiftUI views, 5-8 SPM library targets

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Swift-First, Modern APIs Required
- ✅ **PASS**: Swift 6.1+ with strict concurrency mode
- ✅ **PASS**: SwiftUI for all UI components
- ✅ **PASS**: Swift Concurrency (async/await, @MainActor) for all async operations
- ✅ **PASS**: No GCD or completion handlers
- ✅ **PASS**: Target macOS 15.0+, iOS 18.0+
- ⚠️ **NEEDS RESEARCH**: Safari Extension APIs - verify availability for tab manipulation, storage, and UI injection

### Principle II: Privacy-First Data Handling
- ✅ **PASS**: On-device processing only (NaturalLanguage, CoreML)
- ✅ **PASS**: No external API calls for AI analysis
- ✅ **PASS**: Local storage via Safari APIs (no cloud sync)
- ✅ **PASS**: HTTPS-only requirement documented
- ⚠️ **NEEDS RESEARCH**: Keychain usage patterns for Safari extensions - verify API availability and best practices
- ⚠️ **NEEDS RESEARCH**: Private browsing tab exclusion - verify Safari Extension API support

### Principle III: Test-First Architecture (NON-NEGOTIABLE)
- ✅ **PASS**: Swift Testing framework specified
- ✅ **PASS**: User stories designed for independent testing (P1-P5)
- ✅ **PASS**: 80% coverage target for critical paths, 60% for utility
- ⚠️ **NEEDS RESEARCH**: Safari Extension testing patterns - mock tab APIs, content script injection tests

### Principle IV: Modular Architecture with SPM
- ✅ **PASS**: SPM-based architecture planned
- ✅ **PASS**: Extension logic in library targets
- ✅ **PASS**: Extension target as thin wrapper
- ⚠️ **NEEDS RESEARCH**: Safari Extension + SPM integration - verify build system compatibility, entitlements flow

### Principle V: User-Centered Security & Permissions
- ✅ **PASS**: Permission documentation required (FR-032)
- ✅ **PASS**: Graceful degradation on permission denial
- ⚠️ **NEEDS RESEARCH**: Safari Extension permission model - tabs, storage, scripting permissions and user consent flows

### Principle VI: Accessibility & Internationalization Standards
- ✅ **PASS**: Accessibility labels required for all UI
- ✅ **PASS**: VoiceOver support documented
- ✅ **PASS**: Localizable.strings for i18n (initial English, future expansion)
- ⚠️ **NEEDS RESEARCH**: Safari Extension UI accessibility patterns - verify SwiftUI accessibility in extension context

### Gate Evaluation

**Status**: ✅ **CONDITIONAL PASS** - No violations, but 6 research items required before implementation

**Research Requirements (Phase 0)**:
1. Safari Extension API capabilities for tab manipulation and grouping
2. Keychain access patterns for Safari extensions
3. Private browsing tab handling in Safari Extension APIs
4. Safari Extension testing patterns and mock strategies
5. SPM + Safari Extension build integration and entitlements
6. Safari Extension permission model and user consent flows
7. SwiftUI accessibility in Safari Extension UI contexts

**No Constitution Violations** - All principles can be followed with proper API research.

## Project Structure

### Documentation (this feature)

```text
specs/001-ai-tab-organizer/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── tab-api.md       # Internal APIs for tab manipulation
│   ├── storage-api.md   # Storage and persistence APIs
│   └── ai-api.md        # AI analysis and context APIs
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
Package.swift                          # SPM package manifest with Safari Extension targets
Sources/
├── TabOrganizerExtension/            # Safari Extension target (thin wrapper)
│   ├── SafariExtensionHandler.swift  # Main extension message handler
│   ├── Resources/
│   │   ├── Info.plist                # Extension entitlements and metadata
│   │   ├── icon.png                  # Extension icon assets
│   │   └── Script.js                 # Content script for tab context injection
│   └── UI/
│       └── PopoverView.swift         # Extension popover UI (imports TabOrganizerUI)
│
├── TabOrganizerCore/                 # SPM Library: Core domain models and logic
│   ├── Models/
│   │   ├── TabGroup.swift            # TabGroup entity
│   │   ├── Tab.swift                 # Tab entity
│   │   ├── ContextAnalysis.swift     # AI analysis results
│   │   ├── CleanupSuggestion.swift   # Cleanup recommendation
│   │   └── UserSettings.swift        # User preferences
│   └── Services/
│       ├── TabGroupService.swift     # Group CRUD operations
│       ├── TabTrackingService.swift  # Tab view timestamp tracking
│       └── SettingsService.swift     # User preferences management
│
├── TabOrganizerAI/                   # SPM Library: AI analysis and ML
│   ├── ContextAnalyzer.swift         # NaturalLanguage-based context analysis
│   ├── TabClassifier.swift           # CoreML-based tab categorization
│   ├── SimilarityEngine.swift        # Tab similarity scoring
│   └── GroupingSuggester.swift       # AI grouping recommendations
│
├── TabOrganizerStorage/              # SPM Library: Persistence layer
│   ├── SafariStorageAdapter.swift    # Safari local storage wrapper
│   ├── TabGroupRepository.swift      # Group persistence
│   ├── TabHistoryRepository.swift    # Tab view history persistence
│   └── SettingsRepository.swift      # Settings persistence
│
├── TabOrganizerUI/                   # SPM Library: SwiftUI views
│   ├── Views/
│   │   ├── GroupListView.swift       # Tab group list
│   │   ├── GroupEditorView.swift     # Create/edit group
│   │   ├── TabDragView.swift         # Drag-and-drop tab cards
│   │   ├── SuggestionsView.swift     # AI suggestions preview
│   │   ├── CleanupView.swift         # Cleanup suggestions
│   │   └── SettingsView.swift        # Extension settings
│   ├── Components/
│   │   ├── TabCard.swift             # Individual tab representation
│   │   ├── GroupHeader.swift         # Group header with collapse/expand
│   │   └── HighlightIndicator.swift  # Visual highlight component
│   └── ViewModels/                   # @Observable state objects (NOT ViewModels per constitution)
│       └── ExtensionState.swift      # Top-level extension state
│
└── TabOrganizerSafariAPI/            # SPM Library: Safari API wrappers
    ├── SafariTabManager.swift        # Tab manipulation APIs
    ├── SafariWindowManager.swift     # Window and tab bar APIs
    └── SafariPermissions.swift       # Permission checking and requests

Tests/
├── TabOrganizerCoreTests/            # Core domain logic tests
│   ├── TabGroupServiceTests.swift
│   ├── TabTrackingServiceTests.swift
│   └── ModelTests.swift
│
├── TabOrganizerAITests/              # AI analysis tests
│   ├── ContextAnalyzerTests.swift
│   ├── TabClassifierTests.swift
│   └── GroupingSuggesterTests.swift
│
├── TabOrganizerStorageTests/         # Storage layer tests
│   ├── MockSafariStorage.swift       # Mock storage for testing
│   └── RepositoryTests.swift
│
├── TabOrganizerUITests/              # UI component tests
│   └── ViewTests.swift
│
└── TabOrganizerIntegrationTests/     # End-to-end integration tests
    ├── TabManipulationTests.swift    # Tab API integration
    ├── AIGroupingFlowTests.swift     # Full AI grouping workflow
    └── StoragePersistenceTests.swift # Storage + core integration

Config/
├── TabOrganizer.entitlements         # Safari Extension entitlements
└── Shared.xcconfig                   # Build configuration
```

**Structure Decision**: Safari Extension + SPM Libraries architecture. Extension target (TabOrganizerExtension) serves as thin entry point with UI wrapper. All business logic lives in 5 SPM libraries (Core, AI, Storage, UI, SafariAPI) for testability and reusability. Follows Constitution Principle IV (Modular Architecture with SPM).

**Rationale**:
- **TabOrganizerCore**: Pure Swift domain models and business logic (no Safari dependencies) - highly testable
- **TabOrganizerAI**: Isolated AI/ML logic with NaturalLanguage and CoreML - can be tested with mock tab data
- **TabOrganizerStorage**: Persistence abstraction - mockable for tests
- **TabOrganizerUI**: SwiftUI views and components - can be previewed independently
- **TabOrganizerSafariAPI**: Safari Extension API wrappers - provides mockable interface for testing
- **TabOrganizerExtension**: Minimal glue code importing libraries - cannot be unit tested but integration tested

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations to track.** All constitution principles can be followed with the planned architecture. Research items identified in Constitution Check are knowledge gaps, not principle violations.

---

## Phase 0: Research & Clarification

**Status**: ✅ **COMPLETE**

All research tasks completed. See [research.md](research.md) for detailed findings.

**Key Decisions**:
1. Custom tab groups (Safari's native groups not accessible via APIs)
2. Protocol-oriented architecture for testability
3. Local storage only (no Keychain needed for MVP)
4. Private tab exclusion (hard-coded, no user configuration)
5. Minimal permissions (tab/window access only)

**No blockers** - ready for Phase 1 implementation.

---

## Phase 1: Design & Contracts

**Status**: ✅ **COMPLETE**

Generated design artifacts:

1. ✅ **[data-model.md](data-model.md)**: 5 core entities (TabGroup, Tab, ContextAnalysis, CleanupSuggestion, UserSettings)
2. ✅ **[contracts/tab-api.md](contracts/tab-api.md)**: Tab manipulation APIs (TabManaging protocol)
3. ✅ **[contracts/storage-api.md](contracts/storage-api.md)**: Persistence APIs (3 repository protocols)
4. ✅ **[contracts/ai-api.md](contracts/ai-api.md)**: AI/ML APIs (4 analyzer protocols)
5. ✅ **[quickstart.md](quickstart.md)**: Developer onboarding guide

**Agent Context Updated**: ✅ Copilot instructions updated with Safari Extension technologies

### Constitution Re-Check (Post-Design)

**Status**: ✅ **FULL COMPLIANCE** - All 6 principles satisfied after design phase

#### Principle I: Swift-First, Modern APIs Required
- ✅ Swift 6.1+ with strict concurrency mode
- ✅ SwiftUI for all UI (no AppKit/UIKit except Safari Extension APIs)
- ✅ Swift Concurrency throughout (async/await, actors, @MainActor)
- ✅ Target macOS 15.0+, iOS 18.0+

#### Principle II: Privacy-First Data Handling
- ✅ On-device processing only (NaturalLanguage, CoreML)
- ✅ No external API calls for AI features
- ✅ Safari local storage (no cloud sync in MVP)
- ✅ Private tab exclusion implemented at API boundary
- ✅ Minimal data retention (context analysis cached 5 min max)

#### Principle III: Test-First Architecture (NON-NEGOTIABLE)
- ✅ Swift Testing framework specified in all test targets
- ✅ Protocol-oriented design enables comprehensive mocking
- ✅ 80%/60% coverage targets defined
- ✅ Unit + integration test strategy documented

#### Principle IV: Modular Architecture with SPM
- ✅ 5 SPM library targets (Core, AI, Storage, UI, SafariAPI)
- ✅ Extension target is thin wrapper (minimal code)
- ✅ Clear dependency graph (no circular dependencies)
- ✅ Each library has isolated test target

#### Principle V: User-Centered Security & Permissions
- ✅ Minimal permissions (tab/window access only, no website content)
- ✅ Permission denial handled gracefully
- ✅ Info.plist documents all permissions
- ✅ Private tab handling respects user privacy

#### Principle VI: Accessibility & Internationalization Standards
- ✅ SwiftUI accessibility modifiers required for all UI
- ✅ VoiceOver support mandatory
- ✅ Localizable.strings for i18n (initial English)
- ✅ Accessibility tests included in test strategy

**No violations introduced during design phase.** Architecture fully complies with constitution.

---

## Phase 2: Task Generation

**Status**: ⏭️ **PENDING** - Run `/speckit.tasks` to generate detailed task breakdown

Tasks will be organized by user story (P1-P5) for independent implementation and testing.

---

## Summary

**Current Status**: Planning phase complete (Phases 0-1 done)

**Deliverables**:
- ✅ Technical context filled with concrete details
- ✅ Constitution check passed (no violations)
- ✅ Research completed (7 key decisions documented)
- ✅ Data model designed (5 entities)
- ✅ API contracts defined (3 contract files)
- ✅ Quickstart guide created
- ✅ Agent context updated

**Next Steps**:
1. Run `/speckit.tasks` to generate Phase 2 task breakdown
2. Begin implementing P1 (Manual Tab Groups) following TDD approach
3. Security review approval before implementing privacy features (FR-029 to FR-033)
