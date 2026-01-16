# Phase 2: Cross-Platform Architecture with AI & Accessibility

## Executive Summary

We're migrating from a Safari App Extension to a modern Safari Web Extension with a native Swift AI engine. This enables:

- **iOS + macOS Support**: AI features work on both platforms
- **Advanced Tab Control**: macOS gets real Safari tab manipulation via Accessibility API
- **High Performance AI**: Native CoreML + Metal for tab analysis
- **Future-Proof**: Aligned with Apple's extension direction

## Current State (Phase 1)

```
┌─────────────────────────────┐
│  Safari App Extension       │
│  (macOS only)               │
│  - SwiftUI Popover          │
│  - Drag-drop within UI      │
│  - UserDefaults storage     │
└─────────────────────────────┘
```

**Limitations:**
- ❌ macOS only (no iOS)
- ❌ Cannot manipulate real Safari tabs
- ❌ Cannot access native tab groups
- ⚠️ App Extension API being deprecated

## Target State (Phase 2)

```
┌──────────────────────────────────────────────────────────┐
│              Safari Web Extension                        │
│              (iOS 18+ and macOS 26+)                     │
│  ┌────────────────────────────────────────────────────┐  │
│  │  UI Layer (HTML/CSS/JavaScript)                    │  │
│  │  - popup.html: Tab list with drag-drop            │  │
│  │  - background.js: Event handling                  │  │
│  │  - AI suggestions display                         │  │
│  └────────────────────┬───────────────────────────────┘  │
└────────────────────────┼──────────────────────────────────┘
                         │ browser.runtime.sendNativeMessage()
┌────────────────────────▼──────────────────────────────────┐
│         Native Extension (Message Bridge)                 │
│         (Swift - iOS + macOS)                             │
│  - NSExtensionRequestHandling                             │
│  - Routes messages to main app                            │
└────────────────────────┬──────────────────────────────────┘
                         │ XPC / App Groups
┌────────────────────────▼──────────────────────────────────┐
│              Main Application                             │
│              (Swift - iOS + macOS)                        │
│  ┌────────────────────────────────────────────────────┐   │
│  │  TabOrganizerAI Package (Cross-Platform)          │   │
│  │  ┌──────────────────────────────────────────────┐ │   │
│  │  │  AI Analysis Engine                          │ │   │
│  │  │  - CoreML: Tab categorization               │ │   │
│  │  │  - Metal: GPU-accelerated processing        │ │   │
│  │  │  - Pattern recognition & clustering         │ │   │
│  │  │  - Smart organization suggestions           │ │   │
│  │  └──────────────────────────────────────────────┘ │   │
│  │  ┌──────────────────────────────────────────────┐ │   │
│  │  │  Storage & Sync                             │ │   │
│  │  │  - Core Data: Local persistence             │ │   │
│  │  │  - CloudKit: Cross-device sync              │ │   │
│  │  └──────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────┘   │
│                                                            │
│  #if os(macOS)                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  Accessibility API Layer (macOS Exclusive)        │   │
│  │  - AXUIElement: Safari window/tab access         │   │
│  │  - Real tab manipulation                         │   │
│  │  - NSWindowTabGroup integration                  │   │
│  │  - Keyboard/mouse event simulation               │   │
│  └────────────────────────────────────────────────────┘   │
│  #endif                                                    │
└────────────────────────────────────────────────────────────┘
```

## Feature Availability Matrix

| Feature | iOS | macOS | Notes |
|---------|-----|-------|-------|
| **View All Tabs** | ✅ | ✅ | Web extension API |
| **Manual Association (Drag-Drop)** | ✅ | ✅ | Within extension popup |
| **AI Tab Categorization** | ✅ | ✅ | CoreML + Metal |
| **AI Organization Suggestions** | ✅ | ✅ | Native AI engine |
| **Smart Clustering** | ✅ | ✅ | Pattern recognition |
| **CloudKit Sync** | ✅ | ✅ | Associations sync across devices |
| **Association Storage** | ✅ | ✅ | Core Data + CloudKit |
| **Real Tab Movement** | ❌ | ✅ | Accessibility API (macOS) |
| **Native Tab Group Access** | ❌ | ✅ | NSWindowTabGroup (macOS) |
| **Automated Organization** | ⚠️ Manual | ✅ | iOS shows instructions, macOS executes |

## Implementation Phases

### Phase 2A: Web Extension Foundation (Week 1)
**Goal**: Get basic web extension working on macOS

- [ ] Create web extension using Apple's converter
- [ ] Build popup.html UI (tab list)
- [ ] Implement basic drag-drop in JavaScript
- [ ] Set up browser.tabs API integration
- [ ] Test on macOS Safari

**Deliverable**: Working web extension popup showing tabs

### Phase 2B: Native Messaging (Week 1)
**Goal**: Enable communication between web extension and native code

- [ ] Create Native Extension target
- [ ] Implement NSExtensionRequestHandling
- [ ] Set up bidirectional messaging
- [ ] Test message passing roundtrip
- [ ] Error handling & validation

**Deliverable**: Web extension can call native code

### Phase 2C: AI Engine Package (Week 2)
**Goal**: Cross-platform AI analysis engine

- [ ] Create TabOrganizerAI Swift Package
- [ ] Define TabCategory, TabPattern models
- [ ] Implement TabAnalysisEngine actor
- [ ] Add CoreML placeholder model
- [ ] Metal GPU processing setup
- [ ] Write unit tests
- [ ] iOS & macOS build verification

**Deliverable**: Shared AI package working on both platforms

### Phase 2D: Accessibility Layer (Week 2)
**Goal**: Real tab manipulation on macOS

- [ ] Create AXUIElementWrapper
- [ ] Implement permissions request flow
- [ ] Safari app/window detection
- [ ] Tab group discovery (AXTabGroup)
- [ ] Tab movement logic
- [ ] Error handling & recovery
- [ ] Fallback when permissions denied

**Deliverable**: macOS can manipulate Safari tabs

### Phase 2E: iOS Support (Week 3)
**Goal**: Enable iOS functionality

- [ ] Add iOS target to Xcode project
- [ ] Test web extension on iOS Safari
- [ ] Verify AI engine on iOS
- [ ] Handle iOS limitations gracefully
- [ ] CloudKit sync setup
- [ ] Cross-device testing

**Deliverable**: Working on iPhone/iPad

## Technical Deep Dive

### 1. Web Extension Structure

```
TabCab Extension/
├── manifest.json                    # Extension configuration
├── _locales/
│   └── en/
│       └── messages.json           # Localization
├── Resources/
│   ├── popup.html                  # Main UI
│   ├── popup.css                   # Styling (Liquid Glass effects)
│   ├── popup.js                    # UI logic & drag-drop
│   ├── background.js               # Service worker
│   ├── models/
│   │   ├── TabInfo.js
│   │   ├── TabAssociation.js
│   │   └── TabCategory.js
│   ├── ui/
│   │   ├── AssociationList.js
│   │   ├── TabCard.js
│   │   └── DragDropManager.js
│   └── icons/
│       ├── icon-16.png
│       ├── icon-32.png
│       ├── icon-48.png
│       └── icon-128.png
└── Info.plist
```

### 2. Native Extension Communication Protocol

**Message Types:**

```swift
enum MessageType: String, Codable {
    case getTabs              // Request current tabs
    case analyzeTabs          // Run AI analysis
    case getAssociations      // Get saved associations
    case createAssociation    // Create new association
    case updateAssociation    // Update existing
    case deleteAssociation    // Delete
    case organizeTabs         // Execute AI suggestions (macOS only)
    case requestPermissions   // Request accessibility (macOS)
}

struct Message: Codable {
    let type: MessageType
    let payload: [String: Any]
    let requestId: String
}

struct Response: Codable {
    let requestId: String
    let success: Bool
    let data: [String: Any]?
    let error: String?
}
```

### 3. AI Engine Architecture

```swift
@available(iOS 18.0, macOS 26.0, *)
public actor TabAnalysisEngine {
    // MARK: - Models
    private let categorizationModel: TabCategorizationModel
    private let patternModel: TabPatternRecognitionModel
    
    // MARK: - GPU Processing
    private let metalDevice: MTLDevice?
    private let commandQueue: MTLCommandQueue?
    
    // MARK: - Analysis Methods
    
    /// Categorize a single tab (1-5ms per tab)
    public func categorizeTab(_ tab: TabInfo) async -> TabCategory {
        let features = await extractFeatures(tab)
        let prediction = try await categorizationModel.prediction(input: features)
        return TabCategory(from: prediction)
    }
    
    /// Batch analysis using Metal GPU (100+ tabs in parallel)
    public func analyzeTabs(_ tabs: [TabInfo]) async -> [TabAnalysis] {
        guard let device = metalDevice else {
            // Fallback to CPU
            return await analyzeCPU(tabs)
        }
        
        return await analyzeGPU(tabs, device: device)
    }
    
    /// Generate organization suggestions
    public func suggestOrganization(_ tabs: [TabInfo]) async -> [TabAssociation] {
        // 1. Categorize all tabs
        let categories = await analyzeTabs(tabs)
        
        // 2. Cluster similar tabs
        let clusters = await clusterByPattern(categories)
        
        // 3. Generate association suggestions
        return clusters.map { cluster in
            TabAssociation(
                name: suggestName(for: cluster),
                color: suggestColor(for: cluster),
                tabIDs: cluster.tabIDs
            )
        }
    }
}
```

### 4. Accessibility API Implementation

```swift
#if os(macOS)
@MainActor
public class SafariAccessibilityController {
    private let axWrapper: AXUIElementWrapper
    
    public init() {
        self.axWrapper = AXUIElementWrapper()
    }
    
    // MARK: - Permission Management
    
    public func requestPermissions() async -> Bool {
        let trusted = AXIsProcessTrustedWithOptions([
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary)
        
        if !trusted {
            // Show instructions to user
            await showPermissionsInstructions()
        }
        
        return trusted
    }
    
    // MARK: - Safari Control
    
    public func getSafariWindows() async throws -> [SafariWindow] {
        let safari = try await axWrapper.getSafariApplication()
        let windows = try await safari.getWindows()
        return windows
    }
    
    public func moveTabToGroup(_ tabID: String, groupName: String) async throws {
        // 1. Find the tab element
        let tab = try await findTab(id: tabID)
        
        // 2. Find or create the group
        let group = try await findOrCreateGroup(name: groupName)
        
        // 3. Move tab (via drag-drop simulation or keyboard shortcuts)
        try await performMove(tab: tab, to: group)
    }
    
    // MARK: - Private Implementation
    
    private func findTab(id: String) async throws -> AXUIElement {
        // Navigate Safari's accessibility hierarchy
        // Path: AXApplication → AXWindow → AXToolbar → AXTabButton
        let windows = try await getSafariWindows()
        
        for window in windows {
            if let tab = try await window.findTab(withID: id) {
                return tab
            }
        }
        
        throw AccessibilityError.tabNotFound(id)
    }
    
    private func performMove(tab: AXUIElement, to group: AXUIElement) async throws {
        // Option 1: Use AXPress action
        try await tab.performAction(kAXPressAction)
        
        // Option 2: Simulate keyboard shortcuts
        // Cmd+Shift+\ for tab groups menu
        
        // Option 3: Simulate drag-drop via CGEvent
        try await simulateDragDrop(from: tab, to: group)
    }
}
#endif
```

### 5. CloudKit Sync Strategy

```swift
public actor CloudKitSyncEngine {
    private let container: CKContainer
    private let database: CKDatabase
    
    // MARK: - Sync Operations
    
    public func syncAssociations() async throws {
        // 1. Fetch remote changes
        let remoteChanges = try await fetchChanges()
        
        // 2. Merge with local
        let merged = await mergeAssociations(remote: remoteChanges)
        
        // 3. Push local changes
        try await pushChanges(merged.localChanges)
        
        // 4. Resolve conflicts
        try await resolveConflicts(merged.conflicts)
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveConflicts(_ conflicts: [AssociationConflict]) async throws {
        // Strategy: Last-write-wins with merge
        for conflict in conflicts {
            let resolved = mergeConflictedAssociation(
                local: conflict.local,
                remote: conflict.remote
            )
            try await save(resolved)
        }
    }
}
```

## Privacy & Permissions

### Accessibility Permissions (macOS)

**When Requested:**
- Only when user enables "Advanced Mode" or "Automated Organization"
- Clear explanation of why it's needed
- Graceful fallback if denied

**What We Access:**
- Safari application windows
- Tab bar elements
- Tab group structures
- **NOT accessed**: Web page content, passwords, form data

**Privacy Policy:**
- No data leaves the device except CloudKit sync
- No analytics or tracking
- User data encrypted in CloudKit
- Open source accessibility wrapper

### Web Extension Permissions

**Required:**
- `tabs`: Read tab URLs and titles
- `storage`: Save associations locally
- `nativeMessaging`: Communicate with native app

**NOT Requested:**
- `webNavigation`: Don't track browsing
- `history`: Don't access history
- `cookies`: Don't access cookies
- `webRequest`: Don't intercept network

## Performance Targets

| Operation | Target | Platform |
|-----------|--------|----------|
| Tab categorization | < 5ms per tab | iOS + macOS |
| Batch analysis (100 tabs) | < 500ms | macOS (Metal) |
| Batch analysis (100 tabs) | < 2s | iOS (CoreML) |
| Organization suggestions | < 1s | Both |
| CloudKit sync | < 3s | Both |
| Tab movement (macOS) | < 200ms | macOS |
| Popup open time | < 100ms | Both |

## Testing Strategy

### Unit Tests
- AI engine categorization accuracy
- Message passing protocol
- CloudKit sync logic
- Accessibility API wrapper

### Integration Tests
- Web extension ↔ Native messaging
- AI analysis ↔ Tab data
- macOS accessibility ↔ Safari

### Platform Tests
- iOS Safari 18+
- macOS Safari 26+
- iPhone 15 Pro (AI performance)
- Mac with Apple Silicon (Metal)

### User Acceptance Tests
- Manual tab organization
- AI suggestion quality
- Automated organization (macOS)
- Cross-device sync

## Success Criteria

**Phase 2A (Week 1):**
- [ ] Web extension popup opens in < 100ms
- [ ] All tabs display correctly
- [ ] Drag-drop works smoothly

**Phase 2B (Week 1):**
- [ ] Messages roundtrip in < 50ms
- [ ] Error handling works
- [ ] No crashes

**Phase 2C (Week 2):**
- [ ] AI categorizes tabs accurately (>80%)
- [ ] Batch processing meets performance targets
- [ ] Works on iOS and macOS

**Phase 2D (Week 2):**
- [ ] Accessibility permissions flow clear
- [ ] Tab movement works reliably
- [ ] Graceful fallback when denied

**Phase 2E (Week 3):**
- [ ] Working on iPhone/iPad
- [ ] CloudKit sync functional
- [ ] Feature parity (where applicable)

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Accessibility API breaks | High | Fallback to manual instructions |
| Safari API changes | Medium | Abstract into protocols |
| Performance on older devices | Medium | Optimize ML models, add settings |
| User confusion with permissions | High | Clear UI, good docs |
| CloudKit conflicts | Medium | Robust conflict resolution |

## Next Steps

1. **Review this architecture** - Get approval
2. **Set up git branch** - `git checkout -b phase-2-web-extension`
3. **Start Phase 2A** - Create web extension
4. **Iterate quickly** - Deploy, test, refine

Ready to proceed? 🚀
