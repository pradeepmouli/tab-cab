# Tasks: AI-Powered Safari Tab Organizer

**Input**: Design documents from `/specs/001-ai-tab-organizer/`
**Prerequisites**: plan.md (complete), spec.md (complete), research.md (complete), data-model.md (complete), contracts/ (complete)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `- [ ] [ID] [P?] [Story?] Description with file path`

- **Checkbox**: `- [ ]` for uncompleted tasks
- **[ID]**: Task number (T001, T002, T003...)
- **[P]**: Parallelizable (different files, no dependencies)
- **[Story]**: User story label (US1, US2, US3, US4, US5) - only for user story phases
- **File paths**: Exact paths included in descriptions

---

## Phase 0: Project Initialization and Renaming

**Purpose**: Rename template project to TabCab and configure extension target

**Status**: ✅ Completed 2025-12-25

- [X] T000 Rename project from SwiftTemplateMacOS to TabCab (workspace, xcodeproj, folders, schemes)
- [X] T000.1 Update Config/Shared.xcconfig with TabCab product name and bundle ID (com.pmouli.TabCab)
- [X] T000.2 Update Config/TabCab.entitlements (renamed from SwiftTemplateMacOS.entitlements)
- [X] T000.3 Rename main app Swift file to TabCabApp.swift and update struct name
- [X] T000.4 Update all xcscheme files with TabCab target names
- [X] T000.5 Replace all SwiftTemplateMacOS references in project.pbxproj
- [X] T000.6 Create TabCabExtension target (Safari App Extension) in Xcode project
- [X] T000.7 Copy extension source files to TabCab/ folder (SafariExtensionHandler.swift, UI/PopoverView.swift)
- [X] T000.8 Add Swift Package dependencies to TabCabExtension target (TabOrganizerUI, Core, Storage, SafariAPI)
- [X] T000.9 Configure extension Frameworks build phase with package product dependencies
- [X] T000.10 Remove unavailable API methods from SafariExtensionHandler (windowOpened, windowClosed)
- [X] T000.11 Remove preview code from PopoverView (MockStorageAdapter not available in extension target)
- [X] T000.12 Verify project builds successfully (TabCab.app + TabCabExtension.appex)
- [X] T000.13 Update deployment targets to macOS 26.0+ and iOS 26.0+ for Liquid Glass and modern SwiftUI features

**Known Issue**: Extension embedding via "Embed Foundation Extensions" build phase needs manual verification in Xcode GUI

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and Safari Extension foundation

- [X] T001 Create root Package.swift with 5 library targets (TabOrganizerCore, TabOrganizerAI, TabOrganizerStorage, TabOrganizerUI, TabOrganizerSafariAPI)
- [X] T002 Create Xcode workspace TabOrganizer.xcworkspace linking Package.swift
- [X] T003 Create Safari Extension target TabOrganizerExtension in Xcode project
- [X] T004 [P] Configure Config/TabOrganizer.entitlements with Safari Extension permissions (tabs, windows, storage)
- [X] T005 [P] Configure Config/Shared.xcconfig with build settings (Swift 6.1, strict concurrency, macOS 26.0+, iOS 26.0+)
- [X] T006 Create Sources/TabOrganizerExtension/Info.plist with extension metadata and permissions
- [X] T007 [P] Create .swiftlint.yml for code style enforcement
- [X] T008 [P] Add swift-log dependency to Package.swift for logging
- [X] T009 Create Tests directory structure (5 test targets matching library targets + integration tests)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Safari API Layer (Foundation for all features)

- [X] T010 Define TabManaging protocol in Sources/TabOrganizerSafariAPI/Protocols/TabManaging.swift
- [X] T011 Define TabInfo struct (Codable, Sendable) in Sources/TabOrganizerSafariAPI/Models/TabInfo.swift
- [X] T012 Define TabAPIError enum in Sources/TabOrganizerSafariAPI/Errors/TabAPIError.swift
- [X] T013 Implement SafariTabManager (production) in Sources/TabOrganizerSafariAPI/Adapters/SafariTabManager.swift with private tab filtering
- [X] T014 Implement MockTabManager (testing) in Tests/TabOrganizerSafariAPITests/Mocks/MockTabManager.swift
- [X] T015 Write SafariTabManager tests in Tests/TabOrganizerSafariAPITests/SafariTabManagerTests.swift

### Storage Layer (Foundation for persistence)

- [X] T016 Define SafariStorageAdapter protocol in Sources/TabOrganizerStorage/Protocols/SafariStorageAdapter.swift
- [X] T017 Define StorageError enum in Sources/TabOrganizerStorage/Errors/StorageError.swift
- [X] T018 Implement UserDefaultsStorageAdapter in Sources/TabOrganizerStorage/Adapters/UserDefaultsStorageAdapter.swift with JSON encoding
- [X] T019 Implement MockStorageAdapter in Tests/TabOrganizerStorageTests/Mocks/MockStorageAdapter.swift
- [X] T020 Write StorageAdapter tests in Tests/TabOrganizerStorageTests/StorageAdapterTests.swift

### Core Domain Models (Foundation for all entities)

- [X] T021 Define TabAssociation struct in Sources/TabOrganizerCore/Models/TabAssociation.swift with validation
- [X] T022 Define Tab struct in Sources/TabOrganizerCore/Models/Tab.swift
- [X] T023 Define UserSettings struct in Sources/TabOrganizerCore/Models/UserSettings.swift with defaults
- [X] T024 [P] Define ContextAnalysis struct in Sources/TabOrganizerCore/Models/ContextAnalysis.swift
- [X] T025 [P] Define CleanupSuggestion struct in Sources/TabOrganizerCore/Models/CleanupSuggestion.swift
- [X] T026 Write model validation tests in Tests/TabOrganizerCoreTests/Models/ModelTests.swift

### Extension Entry Point

- [X] T027 Implement SafariExtensionHandler in Sources/TabOrganizerExtension/SafariExtensionHandler.swift with lifecycle methods
- [X] T028 Create extension Resources bundle structure in Sources/TabOrganizerExtension/Resources/
- [X] T029 [P] Add extension icon assets to Sources/TabOrganizerExtension/Resources/icon.png

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Manual Tab Group Organization (Priority: P1) 🎯 MVP

**Goal**: Users can manually create, edit, and persist tab associations through the extension UI

**Independent Test**: Create 10+ tabs, organize into 2-3 groups, close Safari, reopen, verify groups persist with correct tabs

**TDD Approach for SwiftUI**: Per Constitution Principle III, tests must be written first. For SwiftUI components, this follows a preview-driven approach:
1. Create SwiftUI Preview with realistic sample data BEFORE implementation
2. Preview serves as "visual test" - verify UI renders correctly with sample states
3. Implement component logic to match preview expectations
4. Write formal Swift Testing tests (T044) to verify state management and logic
5. This adapted TDD workflow ensures UI components meet acceptance criteria from the start

### US1 - Data & Persistence

- [X] T030 [P] [US1] Define TabAssociationRepository protocol in Sources/TabOrganizerStorage/Protocols/TabAssociationRepository.swift
- [X] T031 [US1] Implement SafariGroupRepository in Sources/TabOrganizerStorage/Repositories/SafariGroupRepository.swift with duplicate name prevention
- [X] T032 [US1] Implement MockGroupRepository in Tests/TabOrganizerStorageTests/Mocks/MockGroupRepository.swift
- [X] T033 [US1] Write TabAssociationRepository tests in Tests/TabOrganizerStorageTests/TabAssociationRepositoryTests.swift (save, delete, getAll, observeGroups)

### US1 - Business Logic

- [X] T034 [US1] Implement TabAssociationService in Sources/TabOrganizerCore/Services/TabAssociationService.swift with createGroup, deleteGroup, updateGroup, getAllGroups
- [X] T035 [US1] Implement TabTrackingService in Sources/TabOrganizerCore/Services/TabTrackingService.swift for lastViewedAt timestamps
- [X] T036 [US1] Write TabAssociationService tests in Tests/TabOrganizerCoreTests/Services/TabAssociationServiceTests.swift with mock dependencies

### US1 - UI Components

- [X] T037 [P] [US1] Create ExtensionState @Observable class in Sources/TabOrganizerUI/State/ExtensionState.swift for top-level state
- [X] T038 [P] [US1] Create TabCard SwiftUI component in Sources/TabOrganizerUI/Components/TabCard.swift with accessibilityLabel for tab title, accessibilityIdentifier for testing, and accessibilityHint for drag action
- [X] T039 [P] [US1] Create GroupHeader SwiftUI component in Sources/TabOrganizerUI/Components/GroupHeader.swift with collapse/expand, accessibilityLabel for group name, and accessibilityHint for collapse/expand action
- [X] T040 [US1] Create GroupListView in Sources/TabOrganizerUI/Views/GroupListView.swift showing all groups with drag-drop support, accessibilityLabel for list, and accessibilityElement grouping for each group
- [X] T041 [US1] Create GroupEditorView in Sources/TabOrganizerUI/Views/GroupEditorView.swift for create/edit group with accessibilityLabel for text fields and buttons
- [X] T042 [US1] Create TabDragView in Sources/TabOrganizerUI/Views/TabDragView.swift with drag-and-drop handlers and accessibility support for drag gestures
- [X] T043 [US1] Wire GroupListView to SafariExtensionHandler popover in Sources/TabOrganizerExtension/SafariExtensionHandler.swift

### US1 - Testing & Integration

- [X] T044 [US1] Write UI component tests in Tests/TabOrganizerUITests/Views/GroupListViewTests.swift
- [X] T045 [US1] Write US1 integration test in Tests/TabOrganizerIntegrationTests/US1_ManualGroupingTests.swift (full create-persist-restore flow)
- [X] T046 [US1] Manual accessibility testing with VoiceOver for all US1 UI components

---

## Phase 4: User Story 2 - AI-Suggested Tab Grouping (Priority: P2)

**Goal**: Extension analyzes tabs and suggests intelligent groupings with one-click acceptance

**Independent Test**: Open 20+ tabs from different topics, trigger AI analysis, verify suggestions make sense, accept suggestions

### US2 - AI Foundation

- [ ] T047 [P] [US2] Define ContextAnalyzer protocol in Sources/TabOrganizerAI/Protocols/ContextAnalyzer.swift
- [ ] T048 [P] [US2] Define TabClassifier protocol in Sources/TabOrganizerAI/Protocols/TabClassifier.swift
- [ ] T049 [P] [US2] Define SimilarityEngine protocol in Sources/TabOrganizerAI/Protocols/SimilarityEngine.swift
- [ ] T050 [P] [US2] Define GroupingSuggester protocol in Sources/TabOrganizerAI/Protocols/GroupingSuggester.swift
- [ ] T051 [P] [US2] Define AIError enum in Sources/TabOrganizerAI/Errors/AIError.swift

### US2 - Keyword & Similarity

- [ ] T052 [US2] Implement KeywordSimilarityEngine in Sources/TabOrganizerAI/Engines/KeywordSimilarityEngine.swift using NaturalLanguage framework
- [ ] T053 [US2] Implement NaturalLanguageContextAnalyzer in Sources/TabOrganizerAI/Analyzers/NaturalLanguageContextAnalyzer.swift with keyword extraction
- [ ] T054 [US2] Write SimilarityEngine tests in Tests/TabOrganizerAITests/KeywordSimilarityEngineTests.swift with deterministic inputs
- [ ] T055 [US2] Write ContextAnalyzer tests in Tests/TabOrganizerAITests/NaturalLanguageContextAnalyzerTests.swift

### US2 - Classification & Grouping

- [ ] T056 [US2] Create CoreML text classification model placeholder with rule-based fallback (MVP default: heuristics only, CoreML optional future enhancement) in Sources/TabOrganizerAI/Resources/TabClassifier.mlmodelc
- [ ] T057 [US2] Implement CoreMLTabClassifier in Sources/TabOrganizerAI/Classifiers/CoreMLTabClassifier.swift with fallback heuristics
- [ ] T058 [US2] Implement ClusteringGroupingSuggester in Sources/TabOrganizerAI/Suggesters/ClusteringGroupingSuggester.swift with hierarchical clustering
- [ ] T059 [US2] Write TabClassifier tests in Tests/TabOrganizerAITests/CoreMLTabClassifierTests.swift
- [ ] T060 [US2] Write GroupingSuggester tests in Tests/TabOrganizerAITests/ClusteringGroupingSuggesterTests.swift with 50+ mock tabs

### US2 - UI & Integration

- [ ] T061 [P] [US2] Create GroupSuggestion struct in Sources/TabOrganizerCore/Models/GroupSuggestion.swift
- [ ] T062 [US2] Create SuggestionsView in Sources/TabOrganizerUI/Views/SuggestionsView.swift with preview, edit capabilities, explanation labels showing grouping rationale (FR-008: "Same domain", "Similar keywords: X, Y, Z"), and accessibility labels for all interactive elements
- [ ] T063 [US2] Add "Suggest Groups" button to GroupListView toolbar in Sources/TabOrganizerUI/Views/GroupListView.swift
- [ ] T064 [US2] Wire AI analysis to SuggestionsView with progress indicator in Sources/TabOrganizerUI/Views/SuggestionsView.swift
- [ ] T065 [US2] Write US2 integration test in Tests/TabOrganizerIntegrationTests/US2_AIGroupingTests.swift (full suggest-accept flow)
- [ ] T066 [US2] Performance test: verify AI analysis completes in <5s for 50 tabs in Tests/TabOrganizerAITests/PerformanceTests.swift

---

## Phase 5: User Story 3 - Context-Aware Tab Highlighting (Priority: P3)

**Goal**: Selecting a tab highlights other related tabs based on content similarity

**Independent Test**: Open 15 tabs (5 Swift, 5 cooking, 5 travel), select Swift tab, verify Swift tabs highlighted, others not

### US3 - Context Analysis

- [ ] T067 [US2] Implement in-memory cache for ContextAnalysis in Sources/TabOrganizerAI/Cache/AnalysisCache.swift with 5-minute TTL
- [ ] T068 [US3] Create ContextService in Sources/TabOrganizerCore/Services/ContextService.swift coordinating ContextAnalyzer and cache
- [ ] T069 [US3] Write ContextService tests in Tests/TabOrganizerCoreTests/Services/ContextServiceTests.swift

### US3 - UI Highlighting

- [ ] T070 [P] [US3] Create HighlightIndicator SwiftUI component in Sources/TabOrganizerUI/Components/HighlightIndicator.swift with blue border style and accessibilityLabel indicating highlighted state
- [ ] T071 [US3] Add tab selection observer to ExtensionState in Sources/TabOrganizerUI/State/ExtensionState.swift
- [ ] T072 [US3] Implement highlighting logic in GroupListView in Sources/TabOrganizerUI/Views/GroupListView.swift updating on tab selection
- [ ] T073 [US3] Create SettingsView in Sources/TabOrganizerUI/Views/SettingsView.swift with context highlighting toggle, accessibilityLabel for all toggles and controls
- [ ] T074 [US3] Write US3 integration test in Tests/TabOrganizerIntegrationTests/US3_ContextHighlightingTests.swift

---

## Phase 6: User Story 4 - Automatic Tab Rearrangement (Priority: P4)

**Goal**: Enable automatic movement of related tabs to cluster them together

**Independent Test**: Enable auto-rearrange, open 20 mixed tabs, select Python tab, verify Python tabs move adjacent

### US4 - Rearrangement Logic

- [ ] T075 [US4] Implement TabRearrangementService in Sources/TabOrganizerCore/Services/TabRearrangementService.swift with pinned tab exclusion
- [ ] T076 [US4] Add rearrangement undo capability to TabRearrangementService in Sources/TabOrganizerCore/Services/TabRearrangementService.swift
- [ ] T077 [US4] Write TabRearrangementService tests in Tests/TabOrganizerCoreTests/Services/TabRearrangementServiceTests.swift

### US4 - Settings & Integration

- [ ] T078 [US4] Add autoRearrangementEnabled toggle to UserSettings in Sources/TabOrganizerCore/Models/UserSettings.swift
- [ ] T079 [US4] Implement SettingsRepository in Sources/TabOrganizerStorage/Repositories/SettingsRepository.swift
- [ ] T080 [US4] Add auto-rearrange toggle to SettingsView in Sources/TabOrganizerUI/Views/SettingsView.swift with accessibility labels
- [ ] T081 [US4] Wire rearrangement to tab selection in ExtensionState in Sources/TabOrganizerUI/State/ExtensionState.swift
- [ ] T082 [US4] Write US4 integration test in Tests/TabOrganizerIntegrationTests/US4_AutoRearrangementTests.swift
- [ ] T083 [US4] Performance test: verify rearrangement completes in <1s for 100 tabs in Tests/TabOrganizerCoreTests/Services/PerformanceTests.swift

---

## Phase 7: User Story 5 - Intelligent Tab Cleanup (Priority: P5)

**Goal**: Suggest closing inactive tabs with review and undo capabilities

**Independent Test**: Open 30 tabs, interact with only 10 over 30 minutes, verify 20 inactive tabs suggested for closure

### US5 - Cleanup Logic

- [ ] T084 [P] [US5] Implement CleanupHistoryRepository in Sources/TabOrganizerStorage/Repositories/CleanupHistoryRepository.swift
- [ ] T085 [US5] Implement CleanupService in Sources/TabOrganizerCore/Services/CleanupService.swift with inactivity detection
- [ ] T086 [US5] Add cleanup undo functionality to CleanupService in Sources/TabOrganizerCore/Services/CleanupService.swift
- [ ] T087 [US5] Write CleanupService tests in Tests/TabOrganizerCoreTests/Services/CleanupServiceTests.swift

### US5 - UI & Settings

- [ ] T088 [P] [US5] Create CleanupView in Sources/TabOrganizerUI/Views/CleanupView.swift with tab preview, keep/close actions, "Keep" marking to exclude specific tabs from future suggestions (FR-026), and accessibility labels for all actions
- [ ] T089 [US5] Add cleanup settings to SettingsView in Sources/TabOrganizerUI/Views/SettingsView.swift (threshold, auto-close toggle) with accessibility labels
- [ ] T090 [US5] Add cleanup notification/prompt to ExtensionState in Sources/TabOrganizerUI/State/ExtensionState.swift
- [ ] T091 [US5] Add undo button to CleanupView in Sources/TabOrganizerUI/Views/CleanupView.swift with accessibilityLabel and accessibilityHint
- [ ] T092 [US5] Write US5 integration test in Tests/TabOrganizerIntegrationTests/US5_CleanupTests.swift (suggest-accept-undo flow)

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final quality improvements, accessibility, and production readiness

### Error Handling & Logging

- [ ] T093 [P] Add structured logging to all services using swift-log in Sources/TabOrganizerCore/Services/
- [ ] T094 [P] Implement graceful degradation for permission denial in Sources/TabOrganizerSafariAPI/Adapters/SafariTabManager.swift
- [ ] T095 [P] Add error recovery for storage quota exceeded in Sources/TabOrganizerStorage/Adapters/UserDefaultsStorageAdapter.swift

### Accessibility (Advanced Testing & Audit)

**Note**: Basic accessibility (accessibilityLabel, accessibilityIdentifier, accessibilityHint) is built into each user story's UI tasks (US1-US5) per Constitution Principle VI. This section focuses on comprehensive audit and advanced testing.

- [ ] T096 Audit all UI components for complete accessibility coverage in Sources/TabOrganizerUI/ (verify Dynamic Type support, contrast ratios, focus order)
- [ ] T097 Enhance accessibility hints for complex interactions in Sources/TabOrganizerUI/Views/ (multi-step workflows, drag-and-drop)
- [ ] T098 Write accessibility tests for all views in Tests/TabOrganizerUITests/AccessibilityTests.swift (automated trait verification)
- [ ] T099 Manual VoiceOver testing across all user stories (end-to-end accessibility validation)

### Internationalization

- [ ] T100 [P] Create Localizable.strings for all UI strings in Sources/TabOrganizerUI/Resources/en.lproj/Localizable.strings
- [ ] T101 [P] Replace hard-coded strings with NSLocalizedString in Sources/TabOrganizerUI/
- [ ] T102 [P] Verify RTL layout support in SwiftUI views in Sources/TabOrganizerUI/Views/

### Documentation & Security

- [ ] T103 [P] Create privacy policy document explaining data usage in docs/privacy-policy.md
- [ ] T104 [P] Document all Safari Extension permissions in Sources/TabOrganizerExtension/Info.plist comments
- [ ] T105 Security audit: verify no external API calls, private tab exclusion, local storage only
- [ ] T106 [P] Create user-facing README with setup instructions in README.md

### Performance & Testing

- [ ] T107 Profile extension memory usage with 200 tabs using Instruments
- [ ] T108 Run full test suite with code coverage report (target 80% for critical paths)
- [ ] T109 End-to-end manual testing of all 5 user stories in Safari
- [ ] T110 Beta testing with 5-10 users for feedback on usability
- [ ] T111 [P] Implement keyboard shortcuts for common actions (create group, trigger suggestions, toggle highlighting) in Sources/TabOrganizerUI/KeyboardShortcutHandler.swift (FR-037)
- [ ] T112 [P] Implement backup/restore for groups and settings in Sources/TabOrganizerCore/Services/BackupService.swift with JSON export/import (FR-036)

---

## Dependencies Between User Stories

```
Foundation (Phase 2)
        ↓
     US1 (P1) ──────────────────────┐
        ↓                            ↓
     US2 (P2) ────────→ US3 (P3) ──→ US4 (P4)
                           ↓
                        US5 (P5)
                           ↓
                    Polish (Phase 8)
```

**Notes**:
- US1 is a prerequisite for all other user stories (foundation)
- US2 and US3 can be developed in parallel after US1
- US4 depends on US3 (requires context highlighting)
- US5 depends on US3 (uses context analysis)
- Phase 8 (Polish) applies to all completed user stories

---

## Parallel Execution Opportunities

### During Foundation (Phase 2):
- T010-T012 (protocols) can run parallel to T016-T017 (storage protocols)
- T021-T025 (models) can all run in parallel once interfaces defined
- T028-T029 (resources) can run parallel to T027 (extension handler)

### During US1 (MVP):
- T030-T032 (repositories) can run parallel to T037-T039 (UI components)
- All UI component tasks (T038, T039) can run in parallel

### During US2 (AI):
- T047-T051 (protocol definitions) can all run in parallel
- T052-T053 (similarity + context) can run in parallel
- T056-T057 (classifier) can run parallel to T058 (suggester) once protocols done

### During Polish (Phase 8):
- T093-T095 (error handling), T100-T102 (i18n), T103-T104 (docs) can all run in parallel

---

## Implementation Strategy

### MVP First (Minimum Viable Product):
**Recommended**: Implement only Phase 1, Phase 2, and Phase 3 (US1) for initial release.

**Rationale**:
- US1 provides immediate value (manual grouping + persistence)
- Establishes foundation for all other features
- Can be released independently for user feedback
- Reduces implementation risk

### Incremental Delivery:
After MVP is stable:
1. Add US2 (AI grouping) for intelligent organization
2. Add US3 (context highlighting) for discovery
3. Add US4 (auto-rearrange) and US5 (cleanup) based on user demand

---

## Task Summary

**Total Tasks**: 110
**Phase 1 (Setup)**: 9 tasks
**Phase 2 (Foundation)**: 20 tasks ← **BLOCKING**
**Phase 3 (US1 - MVP)**: 17 tasks
**Phase 4 (US2)**: 20 tasks
**Phase 5 (US3)**: 8 tasks
**Phase 6 (US4)**: 9 tasks
**Phase 7 (US5)**: 9 tasks
**Phase 8 (Polish)**: 18 tasks

**Estimated Timeline** (1 developer):
- Foundation: 2 weeks
- US1 (MVP): 2 weeks
- US2-US5: 4 weeks (1 week each)
- Polish: 1 week
- **Total**: ~9 weeks for full feature set
- **MVP Only**: ~4 weeks (Foundation + US1)

**Parallelization Potential**: With 2-3 developers, MVP can be reduced to ~2-3 weeks (parallel work on storage, UI, business logic).

---

## Success Validation

After each phase, verify:

✅ **Phase 2**: All tests pass, foundation libraries compile, mocks work
✅ **Phase 3 (US1)**: Can create group, persist, restore after Safari restart
✅ **Phase 4 (US2)**: AI suggests meaningful groups in <5s for 50 tabs
✅ **Phase 5 (US3)**: Highlighting works correctly, no false positives
✅ **Phase 6 (US4)**: Rearrangement completes in <1s, respects pinned tabs
✅ **Phase 7 (US5)**: Cleanup suggestions accurate, undo works reliably
✅ **Phase 8**: Accessibility verified, i18n ready, security audit passed

**Final Gate**: All 10 success criteria from spec.md met (SC-001 through SC-010)
