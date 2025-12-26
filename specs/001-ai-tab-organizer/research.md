# Research: AI-Powered Safari Tab Organizer

**Phase**: 0 (Outline & Research)
**Date**: 2025-12-24
**Purpose**: Resolve all NEEDS CLARIFICATION items from Constitution Check

## Research Tasks

Based on Constitution Check, we need to research:

1. Safari Extension API capabilities for tab manipulation and grouping
2. Keychain access patterns for Safari extensions
3. Private browsing tab handling in Safari Extension APIs
4. Safari Extension testing patterns and mock strategies
5. SPM + Safari Extension build integration and entitlements
6. Safari Extension permission model and user consent flows
7. SwiftUI accessibility in Safari Extension UI contexts

---

## R1: Safari Extension API Capabilities

**Question**: What APIs are available in Safari Extensions (macOS 15.0+, iOS 18.0+) for tab manipulation, grouping, and metadata access?

### Decision

Safari Extensions provide comprehensive tab manipulation through the `SFSafariTab` and `SFSafariWindow` APIs. Available capabilities:

- **Tab Access**: `SFSafariWindow.getAllTabs()` retrieves all tabs in a window
- **Tab Properties**: Access to `title`, `url` (with permission), `isActive`
- **Tab Manipulation**: Can activate tabs, close tabs, open new tabs
- **Tab Groups**: Native Safari tab associations are NOT directly accessible via Extension APIs as of Safari 15-17
- **Custom Groups**: Must implement custom grouping via persistent storage and UI overlay

### Rationale

Safari Extensions are sandboxed and have limited tab association API access. Native Safari tab associations (introduced in macOS Big Sur) are managed by Safari itself and not exposed to extensions. This means:

1. **We cannot read or modify native Safari tab associations** - must build independent grouping system
2. **We CAN track tabs by URL/title** - sufficient for our AI grouping and context features
3. **We CAN use custom UI** - extension popover can display our own group interface

**Alternatives Considered**:
- ❌ Wait for Apple to expose native tab association APIs (no timeline, blocks MVP)
- ❌ Use AppleScript/JavaScript for Automation (security issues, not sandboxed)
- ✅ Build independent grouping system with custom UI (full control, testable)

### Implementation Impact

- Store tab associations in our own persistence layer (Safari local storage)
- Build custom SwiftUI UI for group management (popover + toolbar)
- Map tabs to groups by URL matching on each window refresh
- Accept limitation: groups won't appear in Safari's native tab bar (only in extension UI)

---

## R2: Keychain Access for Safari Extensions

**Question**: Can Safari Extensions access Keychain for secure storage? What are the best practices?

### Decision

Safari Extensions CAN access Keychain with proper entitlements, but it's **NOT NEEDED** for our MVP features (P1-P5). All data (tab associations, settings, tracking) can use Safari's local storage APIs without sensitive data concerns.

### Rationale

Our feature stores:
- Tab association names, colors, tab URLs (not sensitive - users already see these in browser)
- User settings (thresholds, toggles - not sensitive)
- Tab view timestamps (not sensitive)

**No passwords, tokens, or credentials** are stored. Keychain is overkill for this use case.

**Alternatives Considered**:
- ❌ Use Keychain for all storage (unnecessary complexity, performance overhead)
- ✅ Safari local storage for all data (simpler, faster, sufficient security)
- Reserve Keychain for future features (if we add cloud sync tokens, OAuth, etc.)

### Implementation Impact

- Use `UserDefaults` suite with App Group for extension-app communication
- Use Safari's `localStorage` equivalent for tab association data
- No Keychain entitlements needed in MVP
- Document Keychain as future enhancement for cloud sync features

---

## R3: Private Browsing Tab Handling

**Question**: Can Safari Extensions detect and exclude private browsing tabs?

### Decision

Safari Extensions CAN detect private browsing context through `SFSafariTab.isPrivate` property (available in Safari 14+). We MUST exclude private tabs from all tracking, grouping, and AI analysis per Constitution Principle II.

### Rationale

Private browsing tabs are explicitly opted out of tracking by users. Including them in our features would:
- Violate user privacy expectations
- Risk App Store rejection
- Break Constitution Principle II (Privacy-First)

**Implementation Approach**:
- Check `tab.isPrivate` property before ANY processing
- Filter private tabs from group suggestions
- Exclude private tabs from cleanup recommendations
- Exclude private tabs from context highlighting
- Show clear UI indication when private tabs are present but excluded

**Alternatives Considered**:
- ❌ Process private tabs (constitution violation, App Store risk)
- ❌ Make it user-configurable (opt-in still violates privacy expectations)
- ✅ Hard-coded exclusion with clear UI messaging (safest, compliant)

### Implementation Impact

- Add `isPrivate` check at entry point of all services (TabAssociationService, ContextAnalyzer, etc.)
- Unit tests must verify private tab exclusion for all features
- UI must show "X private tabs excluded" message when applicable
- Document in privacy policy that private tabs are never processed

---

## R4: Safari Extension Testing Patterns

**Question**: How do we test Safari Extension code with Swift Testing framework? What mocking strategies work?

### Decision

Use **Protocol-Oriented Architecture** with mock implementations for Safari APIs. Swift Testing framework supports async tests and works with protocol mocks.

### Rationale

Safari Extension APIs (`SFSafariTab`, `SFSafariWindow`) are final classes that cannot be mocked directly. Solution:

1. **Create protocol wrappers** for Safari APIs (e.g., `TabManaging` protocol)
2. **Implement real adapters** that call Safari APIs (production)
3. **Implement mock adapters** for tests (controllable, deterministic)
4. **Inject dependencies** via initializers (no singletons)

**Testing Strategy**:
```swift
// Protocol wrapper
protocol TabManaging {
    func getAllTabs() async throws -> [TabInfo]
    func activateTab(id: String) async throws
}

// Production adapter (calls Safari APIs)
final class SafariTabManager: TabManaging {
    func getAllTabs() async throws -> [TabInfo] {
        let window = await SFSafariApplication.getActiveWindow()
        let tabs = await window?.getAllTabs() ?? []
        return tabs.map { TabInfo(from: $0) }
    }
}

// Mock for tests
final class MockTabManager: TabManaging {
    var stubbedTabs: [TabInfo] = []
    func getAllTabs() async throws -> [TabInfo] {
        return stubbedTabs
    }
}

// Tests
@Test func testGroupCreation() async throws {
    let mockTabs = MockTabManager()
    mockTabs.stubbedTabs = [/* test data */]
    let service = TabAssociationService(tabManager: mockTabs)
    // ... test logic
}
```

**Alternatives Considered**:
- ❌ Integration tests only (slow, brittle, hard to test edge cases)
- ❌ Subclass Safari APIs (not possible - final classes)
- ✅ Protocol wrappers + dependency injection (testable, flexible)

### Implementation Impact

- Create `TabOrganizerSafariAPI` library with protocol-first design
- All services accept protocol dependencies (not concrete Safari types)
- Tests use mock implementations (fast, deterministic)
- Integration tests use real Safari APIs on simulator (slower, e2e validation)
- Aim for 80% unit test coverage, 20% integration tests

---

## R5: SPM + Safari Extension Build Integration

**Question**: How do we integrate Swift Package Manager libraries with Safari Extension target in Xcode?

### Decision

Use **SPM local package with Xcode project wrapper** - same pattern as current project structure. Extension target imports SPM library products as dependencies.

### Rationale

Current project already uses this pattern successfully:
- Root `Package.swift` defines all library targets
- Xcode project (SwiftTemplateiOS, SwiftTemplateMacOS) imports package products
- Works well for iOS/macOS apps - same approach for Safari Extension

**Build Configuration**:
```swift
// Package.swift
let package = Package(
    name: "TabOrganizer",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [
        .library(name: "TabOrganizerCore", targets: ["TabOrganizerCore"]),
        .library(name: "TabOrganizerUI", targets: ["TabOrganizerUI"]),
        // ... other libraries
    ],
    targets: [
        .target(name: "TabOrganizerCore", dependencies: []),
        .target(name: "TabOrganizerAI", dependencies: ["TabOrganizerCore"]),
        // ... other targets
    ]
)
```

**Xcode Extension Target**:
- Link against SPM library products in "Frameworks and Libraries"
- Entitlements flow through Xcode project settings
- Extension target has own `Info.plist` for metadata
- SPM targets remain pure Swift (no entitlements needed)

**Alternatives Considered**:
- ❌ All code in extension target (untestable, monolithic)
- ❌ Separate SPM package (complicates build, version management)
- ✅ Local SPM package + Xcode wrapper (proven pattern, testable)

### Implementation Impact

- Create `TabOrganizer.xcodeproj` for Safari Extension target
- Extension target imports library products from root `Package.swift`
- Keep SPM libraries pure Swift (no Safari dependencies except SafariAPI library)
- Extension target contains only `SafariExtensionHandler` and UI glue code
- CI/CD builds both SPM tests and extension target

---

## R6: Safari Extension Permission Model

**Question**: What permissions do Safari Extensions require? How is user consent obtained?

### Decision

Safari Extensions use **declarative permissions** in `Info.plist` with runtime prompts. Required permissions for our features:

1. **`SFSafariTab`** - Access tab information (title, URL)
2. **`SFSafariWindow`** - Access window and tab list
3. **Website Access** - NONE for MVP (no content script injection needed for P1-P5)

### Rationale

Our MVP features (P1-P5) only need tab metadata (title, URL) and manipulation APIs. We do NOT need:
- ❌ Website content access (no DOM manipulation)
- ❌ Cross-site tracking (privacy violation)
- ❌ History access (not needed for our features)

**Permission Flow**:
1. User installs extension from App Store
2. User enables extension in Safari Preferences
3. Extension requests tab access on first use (Safari shows system prompt)
4. User grants permission (one-time for extension)
5. Extension can access tab list and metadata

**Graceful Degradation**:
- If tab permission denied: Show UI message "Extension requires tab access to function"
- Provide button to open Safari Preferences
- No silent failures - clear error messaging

**Alternatives Considered**:
- ❌ Request website access (overreach, privacy concern, App Store risk)
- ❌ No permission handling (poor UX when denied)
- ✅ Minimal permissions + graceful degradation (compliant, good UX)

### Implementation Impact

- `Info.plist` declares `SFSafariTab` and `SFSafariWindow` permissions
- `SafariPermissions.swift` checks permission status before operations
- UI shows permission prompt with explanation when needed
- Error handling for permission denial cases
- Document permissions in App Store submission and privacy policy

---

## R7: SwiftUI Accessibility in Safari Extensions

**Question**: Do SwiftUI accessibility modifiers work correctly in Safari Extension UI contexts?

### Decision

SwiftUI accessibility modifiers work FULLY in Safari Extensions. Extension UI is rendered as standard SwiftUI hosted in Safari's process - all accessibility APIs available.

### Rationale

Safari Extension UI is either:
1. **Popover**: SwiftUI hosted in `SFSafariExtensionViewController` - full accessibility support
2. **Toolbar button**: System UI with icon - use descriptive `NSAccessibilityLabel` in code

**Accessibility Requirements** (Constitution Principle VI):
- All interactive elements: `.accessibilityLabel(_)`
- All buttons: `.accessibilityHint(_)` if action unclear
- All form inputs: `.accessibilityValue(_)` for current state
- Dynamic content: `.accessibilityAddTraits(.updatesFrequently)`
- VoiceOver testing: Mandatory for all UI features

**Testing Approach**:
```swift
@Test func testGroupListAccessibility() {
    let view = GroupListView(groups: testGroups)
    // SwiftUI accessibility tree is inspectable in tests
    // Verify labels, hints, traits are set correctly
}
```

**Alternatives Considered**:
- ❌ Skip accessibility (constitution violation, App Store rejection risk)
- ❌ AppKit fallback for accessibility (unnecessary complexity)
- ✅ Standard SwiftUI accessibility modifiers (simple, compliant)

### Implementation Impact

- All SwiftUI views must include accessibility modifiers from day 1
- UI tests verify accessibility labels exist
- VoiceOver manual testing before each release
- Accessibility audit checklist in PR template
- No additional frameworks or workarounds needed

---

## Summary: All Research Complete

### Resolved Clarifications

✅ **Safari Extension APIs**: Comprehensive tab access available, must build custom groups (native groups not exposed)
✅ **Keychain**: Not needed for MVP - Safari local storage sufficient
✅ **Private Browsing**: `isPrivate` property available - must exclude from all processing
✅ **Testing**: Protocol-oriented architecture with mocks - Swift Testing fully supported
✅ **Build Integration**: Local SPM + Xcode wrapper - proven pattern from current project
✅ **Permissions**: Minimal permissions (tab/window access only) - clear user prompts
✅ **Accessibility**: Full SwiftUI accessibility support - standard modifiers work

### Constitution Re-Check

All 6 principles remain **FULLY COMPLIANT** after research:

- ✅ **Principle I**: Swift 6.1+, SwiftUI, Swift Concurrency confirmed feasible
- ✅ **Principle II**: Privacy-first confirmed (private tab exclusion, local storage, no external APIs)
- ✅ **Principle III**: Test-first architecture confirmed (protocol mocks, Swift Testing works)
- ✅ **Principle IV**: SPM modular architecture confirmed (local package + Xcode wrapper)
- ✅ **Principle V**: Minimal permissions confirmed (tab/window only, graceful degradation)
- ✅ **Principle VI**: Accessibility confirmed (SwiftUI modifiers work in extensions)

### Key Architectural Decisions

1. **Custom Tab Groups**: Build independent grouping system (Safari's native groups not accessible)
2. **Protocol Wrappers**: Wrap Safari APIs in protocols for testability
3. **Local Storage Only**: No Keychain needed for MVP
4. **Private Tab Exclusion**: Hard-coded exclusion from all features
5. **Minimal Permissions**: Only tab/window access, no website content
6. **Standard SwiftUI**: No special accessibility workarounds needed

### Risk Mitigation

- **Risk**: Native tab association integration not possible → **Mitigation**: Build superior custom UI with AI features
- **Risk**: Testing Safari APIs is complex → **Mitigation**: Protocol-oriented architecture with comprehensive mocks
- **Risk**: Permission denial breaks extension → **Mitigation**: Graceful degradation with clear UI messaging

### Ready for Phase 1

All NEEDS CLARIFICATION items resolved. No blockers for design phase. Proceeding to Phase 1: Design & Contracts.
