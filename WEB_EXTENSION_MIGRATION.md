# Safari Web Extension Migration Plan

This document outlines the migration from Safari App Extension to Safari Web Extension for cross-platform support (iOS + macOS) and better AI integration.

## Why Migrate?

1. **Cross-Platform**: Web extensions work on both iOS and macOS
2. **Future-Proof**: Apple is moving away from App Extensions
3. **AI Performance**: Native app handles heavy AI processing, web extension handles UI
4. **Better Separation**: UI layer (web) vs Processing layer (native)

## Architecture Overview

```
┌─────────────────────────────────────┐
│   Safari Web Extension              │
│   - manifest.json                   │
│   - popup.html (Tab list UI)        │
│   - background.js (Event handling)  │
│   - content.js (Optional)           │
└──────────────┬──────────────────────┘
               │ browser.runtime.sendNativeMessage()
┌──────────────▼──────────────────────┐
│   Native Extension (Swift)          │
│   - NSExtensionRequestHandling      │
│   - Message forwarding              │
└──────────────┬──────────────────────┘
               │ XPC / App Groups
┌──────────────▼──────────────────────┐
│   Main App (iOS + macOS)            │
│  ┌──────────────────────────────┐   │
│  │  TabOrganizerAI (Shared)     │   │
│  │  - CoreML                    │   │
│  │  - Metal GPU                 │   │
│  │  - CloudKit Sync             │   │
│  └──────────────────────────────┘   │
│                                     │
│  #if os(macOS)                      │
│  │  Accessibility API             │  │
│  │  - AXUIElement                │  │
│  │  - Tab manipulation           │  │
│  #endif                             │
└─────────────────────────────────────┘
```

## Migration Steps

### Phase 2A: Create Web Extension

1. **Use Apple's Converter Tool**
   ```bash
   xcrun safari-web-extension-converter \
       --app-name TabCab \
       --bundle-identifier com.yourorg.tabcab \
       --swift \
       --macos-only  # Start with macOS, add iOS later
   ```

2. **Web Extension Structure**
   ```
   TabCab Extension/
   ├── manifest.json           # Extension configuration
   ├── Resources/
   │   ├── popup.html         # Main UI
   │   ├── popup.css          # Styling
   │   ├── popup.js           # UI logic
   │   ├── background.js      # Background service worker
   │   └── icons/             # Extension icons
   └── Info.plist
   ```

3. **Key manifest.json Configuration**
   ```json
   {
     "manifest_version": 3,
     "name": "TabCab",
     "version": "1.0",
     "description": "AI-powered tab organization for Safari",
     "permissions": [
       "tabs",
       "storage",
       "nativeMessaging"
     ],
     "background": {
       "service_worker": "background.js",
       "type": "module"
     },
     "action": {
       "default_popup": "popup.html",
       "default_icon": {
         "16": "icons/icon-16.png",
         "32": "icons/icon-32.png",
         "48": "icons/icon-48.png",
         "128": "icons/icon-128.png"
       }
     },
     "browser_specific_settings": {
       "safari": {
         "strict_min_version": "18.0"
       }
     }
   }
   ```

### Phase 2B: Implement Native Messaging

1. **Create Native Extension Target**
   - Add new target: File → New → Target → App Extension → Generic Extension
   - Name: "TabCab Native Extension"

2. **Implement Message Handler**
   ```swift
   // In Native Extension
   import Foundation
   
   class TabCabNativeExtension: NSObject, NSExtensionRequestHandling {
       func beginRequest(with context: NSExtensionContext) {
           guard let item = context.inputItems.first as? NSExtensionItem,
                 let userInfo = item.userInfo as? [String: Any],
                 let message = userInfo[SFExtensionMessageKey] else {
               context.completeRequest(returningItems: nil)
               return
           }
           
           // Forward to main app or process here
           Task {
               let result = await processMessage(message)
               
               let response = NSExtensionItem()
               response.userInfo = [SFExtensionMessageKey: result]
               context.completeRequest(returningItems: [response])
           }
       }
       
       func processMessage(_ message: Any) async -> [String: Any] {
           // Handle different message types
           // - "getTabs": Return tab list
           // - "analyzeTab": Run AI analysis
           // - "organizeTabs": Use accessibility API (macOS)
           return ["status": "success"]
       }
   }
   ```

3. **Web Extension → Native Communication**
   ```javascript
   // In popup.js
   async function analyzeTabsWithAI(tabs) {
       const response = await browser.runtime.sendNativeMessage(
           "application.id",
           {
               action: "analyzeTabs",
               tabs: tabs.map(t => ({
                   id: t.id,
                   url: t.url,
                   title: t.title
               }))
           }
       );
       return response;
   }
   ```

### Phase 2C: Build Cross-Platform AI Package

1. **Create Swift Package: TabOrganizerAI**
   ```
   TabOrganizerAI/
   ├── Package.swift
   ├── Sources/
   │   └── TabOrganizerAI/
   │       ├── Models/
   │       │   ├── TabCategory.swift
   │       │   ├── TabPattern.swift
   │       │   └── TabAssociation.swift
   │       ├── Engine/
   │       │   ├── TabAnalysisEngine.swift
   │       │   ├── CoreMLWrapper.swift
   │       │   └── MetalProcessor.swift
   │       └── Protocols/
   │           └── TabController.swift  # Platform-specific
   └── Tests/
   ```

2. **Platform-Agnostic AI Engine**
   ```swift
   // TabAnalysisEngine.swift
   @available(iOS 18.0, macOS 26.0, *)
   public actor TabAnalysisEngine {
       private let mlModel: TabCategorizationModel
       private let metalDevice: MTLDevice?
       
       public init() async throws {
           self.mlModel = try TabCategorizationModel()
           self.metalDevice = MTLCreateSystemDefaultDevice()
       }
       
       public func categorizeTab(_ tab: TabInfo) async -> TabCategory {
           // CoreML inference - works on iOS and macOS
           let features = extractFeatures(from: tab)
           let prediction = try await mlModel.prediction(input: features)
           return TabCategory(from: prediction)
       }
       
       public func suggestOrganization(_ tabs: [TabInfo]) async -> [TabAssociation] {
           // AI-powered grouping suggestions
           // Uses Metal for parallel processing
           return await withTaskGroup(of: TabCategory.self) { group in
               for tab in tabs {
                   group.addTask { await self.categorizeTab(tab) }
               }
               // Cluster similar tabs
               return await clusterTabs(group)
           }
       }
   }
   ```

3. **Platform-Specific Tab Control**
   ```swift
   // TabController.swift - Protocol
   public protocol TabController {
       func moveTabs(_ tabIDs: [String], toGroup groupID: String) async throws
       func createGroup(name: String, color: String) async throws -> String
   }
   
   #if os(macOS)
   // macOSTabController.swift
   public class macOSTabController: TabController {
       private let accessibilityAPI: AXUIElementWrapper
       
       public func moveTabs(_ tabIDs: [String], toGroup groupID: String) async throws {
           // Use Accessibility API to manipulate Safari
           let safari = try await accessibilityAPI.getSafariApp()
           try await safari.moveTabsToGroup(tabIDs, group: groupID)
       }
   }
   #endif
   
   #if os(iOS)
   // iOSTabController.swift
   public class iOSTabController: TabController {
       public func moveTabs(_ tabIDs: [String], toGroup groupID: String) async throws {
           // iOS: Show instructions or use limited APIs
           throw TabControlError.notSupported(
               message: "iOS doesn't support programmatic tab control. Suggestions saved for manual organization."
           )
       }
   }
   #endif
   ```

### Phase 2D: Implement Accessibility API (macOS Only)

1. **Create AXUIElement Wrapper**
   ```swift
   // AXUIElementWrapper.swift
   #if os(macOS)
   import ApplicationServices
   
   public actor AXUIElementWrapper {
       private var safariApp: AXUIElement?
       
       public func requestPermissions() async -> Bool {
           let options: NSDictionary = [
               kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
           ]
           return AXIsProcessTrustedWithOptions(options)
       }
       
       public func getSafariApp() async throws -> SafariAppElement {
           if let app = safariApp {
               return SafariAppElement(element: app)
           }
           
           let safari = NSWorkspace.shared.runningApplications
               .first(where: { $0.bundleIdentifier == "com.apple.Safari" })
           
           guard let pid = safari?.processIdentifier else {
               throw AXError.safariNotRunning
           }
           
           let app = AXUIElementCreateApplication(pid)
           self.safariApp = app
           return SafariAppElement(element: app)
       }
   }
   
   public struct SafariAppElement {
       let element: AXUIElement
       
       public func getWindows() async throws -> [SafariWindowElement] {
           var value: CFTypeRef?
           let result = AXUIElementCopyAttributeValue(
               element,
               kAXWindowsAttribute as CFString,
               &value
           )
           
           guard result == .success,
                 let windows = value as? [AXUIElement] else {
               throw AXError.failedToGetWindows
           }
           
           return windows.map { SafariWindowElement(element: $0) }
       }
   }
   
   public struct SafariWindowElement {
       let element: AXUIElement
       
       public func getTabGroup() async throws -> AXUIElement? {
           // Find AXTabGroup element
           // Navigate: AXWindow → AXSplitGroup → AXTabGroup
           var value: CFTypeRef?
           AXUIElementCopyAttributeValue(
               element,
               "AXTabGroup" as CFString,
               &value
           )
           return value as? AXUIElement
       }
   }
   #endif
   ```

2. **Tab Manipulation**
   ```swift
   #if os(macOS)
   extension macOSTabController {
       func moveTabToWindow(_ tabElement: AXUIElement, window: AXUIElement) async throws {
           // Use accessibility actions
           try await performAction(on: tabElement, action: kAXPressAction)
           // Manipulate via keyboard shortcuts or drag-drop simulation
       }
   }
   #endif
   ```

### Phase 2E: Update UI for Web Extension

1. **popup.html - Modern Tab List**
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <meta charset="UTF-8">
       <link rel="stylesheet" href="popup.css">
   </head>
   <body>
       <div id="app">
           <div class="header">
               <input type="search" id="search" placeholder="Search tabs...">
               <button id="ai-suggest">🤖 AI Suggestions</button>
           </div>
           
           <div id="associations-list">
               <!-- Populated by popup.js -->
           </div>
           
           <div id="ungrouped-tabs">
               <!-- Ungrouped tabs -->
           </div>
       </div>
       <script type="module" src="popup.js"></script>
   </body>
   </html>
   ```

2. **popup.js - Web Extension Logic**
   ```javascript
   // Modern ESM syntax
   class TabOrganizerUI {
       async init() {
           const tabs = await browser.tabs.query({ currentWindow: true });
           await this.renderTabs(tabs);
           
           // Set up drag-and-drop
           this.setupDragDrop();
           
           // AI button
           document.getElementById('ai-suggest').addEventListener('click', 
               () => this.getAISuggestions(tabs)
           );
       }
       
       async getAISuggestions(tabs) {
           // Call native extension
           const response = await browser.runtime.sendNativeMessage(
               "com.yourorg.tabcab.native",
               { action: "analyzeTabs", tabs }
           );
           
           this.showSuggestions(response.suggestions);
       }
       
       setupDragDrop() {
           // Modern HTML5 drag-drop
           document.querySelectorAll('.tab-card').forEach(card => {
               card.draggable = true;
               card.addEventListener('dragstart', this.onDragStart);
               card.addEventListener('drop', this.onDrop);
           });
       }
   }
   
   new TabOrganizerUI().init();
   ```

## Migration Checklist

### Pre-Migration
- [ ] Backup current codebase
- [ ] Document current functionality
- [ ] Test current app extension thoroughly

### Web Extension Setup
- [ ] Run safari-web-extension-converter
- [ ] Create manifest.json
- [ ] Build popup.html UI
- [ ] Implement popup.js logic
- [ ] Add icons and assets

### Native Extension
- [ ] Create Native Extension target
- [ ] Implement NSExtensionRequestHandling
- [ ] Set up message passing
- [ ] Test bidirectional communication

### Swift Package (TabOrganizerAI)
- [ ] Create Package.swift
- [ ] Implement TabAnalysisEngine
- [ ] Add CoreML model placeholder
- [ ] Create platform-specific controllers
- [ ] Write unit tests

### Accessibility API (macOS)
- [ ] Implement AXUIElementWrapper
- [ ] Request permissions flow
- [ ] Safari window detection
- [ ] Tab manipulation logic
- [ ] Error handling

### Testing
- [ ] Test on macOS Safari
- [ ] Test on iOS Safari
- [ ] Test AI engine performance
- [ ] Test accessibility permissions
- [ ] Test cross-device sync

### Documentation
- [ ] Update README
- [ ] API documentation
- [ ] User guide
- [ ] Privacy policy (accessibility)

## Timeline Estimate

- Phase 2A (Web Extension): 2-3 days
- Phase 2B (Native Messaging): 1-2 days
- Phase 2C (AI Package): 3-5 days (with CoreML placeholder)
- Phase 2D (Accessibility API): 2-3 days
- Phase 2E (UI Update): 1-2 days
- Testing & Polish: 2-3 days

**Total: ~2 weeks** for cross-platform foundation

## Benefits After Migration

1. ✅ Works on iPhone and iPad
2. ✅ AI features available on all platforms
3. ✅ macOS gets full tab control
4. ✅ Modern web extension architecture
5. ✅ Future-proof for Apple's direction
6. ✅ Better separation of concerns
7. ✅ Shared Swift AI codebase

---

**Next Step**: Start with Phase 2A - Web Extension creation
