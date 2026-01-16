---
name: safari-extension-dev
description: Safari App Extension development for macOS with Swift, SFSafariExtensionHandler, and SwiftUI popovers
user-invocable: true
---

# Safari Extension Development

Use this skill when building Safari App Extensions for macOS, implementing browser automation, tab management, or content manipulation with SafariServices.

## Safari Extension Types

### Safari App Extension (Recommended)
- Native Swift/SwiftUI implementation
- Full macOS app sandbox integration
- App Store distribution
- SPM package support

### Web Extension
- Cross-browser compatibility (Chrome, Firefox, Safari)
- JavaScript-based
- Manifest v3 support

## Project Structure

```
MyExtension/
├── MyExtension.xcworkspace          # Workspace container
├── MyExtension.xcodeproj            # App shell
├── Config/                          # Build settings
│   ├── Shared.xcconfig
│   ├── Debug.xcconfig
│   └── Release.xcconfig
├── MyExtension/                     # Containing app
│   ├── MyExtensionApp.swift
│   ├── ContentView.swift
│   └── Assets.xcassets
├── MyExtensionExtension/            # Safari Extension target
│   ├── SafariExtensionHandler.swift
│   ├── SafariExtensionViewController.swift
│   ├── script.js                    # Content script
│   ├── Info.plist
│   └── Extension.html               # Popover HTML (optional)
├── Package.swift                    # SPM libraries
└── Sources/                         # Business logic (SPM)
    ├── MyExtensionCore/
    ├── MyExtensionStorage/
    └── MyExtensionUI/
```

## Safari App Extension Setup

### 1. Extension Handler (SafariExtensionHandler.swift)

```swift
import SafariServices
import os.log

@MainActor
final class SafariExtensionHandler: SFSafariExtensionHandler {

    private let logger = Logger(subsystem: "com.myapp.extension", category: "handler")

    // MARK: - Lifecycle

    override init() {
        super.init()
        logger.info("Safari Extension initialized")
    }

    // MARK: - Message Handling

    /// Called when content script sends a message
    override func messageReceived(
        withName messageName: String,
        from page: SFSafariPage,
        userInfo: [String: Any]?
    ) {
        logger.debug("Message received: \(messageName)")

        Task {
            await handleMessage(messageName, from: page, userInfo: userInfo)
        }
    }

    private func handleMessage(
        _ name: String,
        from page: SFSafariPage,
        userInfo: [String: Any]?
    ) async {
        switch name {
        case "getData":
            // Respond to content script
            let response = ["items": ["a", "b", "c"]]
            page.dispatchMessageToScript(withName: "dataResponse", userInfo: response)

        case "saveData":
            guard let data = userInfo?["data"] as? [String: Any] else { return }
            await saveData(data)

        default:
            logger.warning("Unknown message: \(name)")
        }
    }

    // MARK: - Toolbar Actions

    override func toolbarItemClicked(in window: SFSafariWindow) {
        logger.debug("Toolbar clicked")
        // Popover is shown automatically if configured in Info.plist
    }

    override func validateToolbarItem(
        in window: SFSafariWindow,
        validationHandler: @escaping (Bool, String) -> Void
    ) {
        Task {
            let enabled = await shouldEnableExtension(in: window)
            validationHandler(enabled, "My Extension")
        }
    }

    // MARK: - Page Navigation

    override func page(
        _ page: SFSafariPage,
        willNavigateTo url: URL?
    ) {
        guard let url else { return }
        logger.debug("Navigating to: \(url.absoluteString)")

        Task {
            await handleNavigation(page: page, url: url)
        }
    }

    // MARK: - Window Events

    override func windowOpened(_ window: SFSafariWindow) {
        Task {
            await handleWindowOpened(window)
        }
    }

    override func windowClosed(_ window: SFSafariWindow) {
        Task {
            await handleWindowClosed(window)
        }
    }

    // MARK: - Private Helpers

    private func shouldEnableExtension(in window: SFSafariWindow) async -> Bool {
        // Disable for private browsing
        let isPrivate = await isPrivateBrowsing(window: window)
        return !isPrivate
    }

    private func isPrivateBrowsing(window: SFSafariWindow) async -> Bool {
        // Safari doesn't expose private browsing directly
        // Use heuristics or localStorage detection
        return false
    }
}

// MARK: - Async Extensions

extension SFSafariWindow {
    func getActiveTab() async throws -> SFSafariTab? {
        await withCheckedContinuation { continuation in
            self.getActiveTab { tab in
                continuation.resume(returning: tab)
            }
        }
    }

    func getAllTabs() async throws -> [SFSafariTab] {
        await withCheckedContinuation { continuation in
            self.getAllTabs { tabs in
                continuation.resume(returning: tabs)
            }
        }
    }
}

extension SFSafariTab {
    func getActivePage() async throws -> SFSafariPage? {
        await withCheckedContinuation { continuation in
            self.getActivePage { page in
                continuation.resume(returning: page)
            }
        }
    }
}

extension SFSafariPage {
    func getPageProperties() async throws -> SFSafariPageProperties? {
        await withCheckedContinuation { continuation in
            self.getPropertiesWithCompletionHandler { properties in
                continuation.resume(returning: properties)
            }
        }
    }
}
```

### 2. SwiftUI Popover (SafariExtensionViewController.swift)

```swift
import SafariServices
import SwiftUI

final class SafariExtensionViewController: SFSafariExtensionViewController {

    static let shared = SafariExtensionViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set preferred popover size
        preferredContentSize = NSSize(width: 320, height: 400)

        // Host SwiftUI view
        let hostingView = NSHostingView(rootView: PopoverContentView())
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func popoverWillShow() {
        // Refresh data when popover opens
    }

    override func popoverDidClose() {
        // Clean up when popover closes
    }
}

// MARK: - SwiftUI Content

struct PopoverContentView: View {
    @State private var items: [String] = []
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Extension")
                    .font(.headline)
                Spacer()
                Button("Refresh") {
                    Task { await loadData() }
                }
                .buttonStyle(.plain)
            }

            Divider()

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                List(items, id: \.self) { item in
                    Text(item)
                }
            }
        }
        .padding()
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Load data from your services
    }
}
```

### 3. Content Script (script.js)

```javascript
// Injected into web pages

(function() {
    "use strict";

    // Send message to extension
    function sendMessage(name, data) {
        safari.extension.dispatchMessage(name, data);
    }

    // Receive message from extension
    safari.self.addEventListener("message", function(event) {
        if (event.name === "dataResponse") {
            handleDataResponse(event.message);
        }
    });

    // Example: Get data from extension
    function requestData() {
        sendMessage("getData", {});
    }

    // Example: Save data to extension
    function saveData(data) {
        sendMessage("saveData", { data: data });
    }

    // Example: Handle response
    function handleDataResponse(data) {
        console.log("Received data:", data);
    }

    // Initialize
    document.addEventListener("DOMContentLoaded", function() {
        console.log("Extension content script loaded");
        requestData();
    });

    // DOM manipulation example
    function highlightLinks() {
        const links = document.querySelectorAll("a");
        links.forEach(link => {
            link.style.backgroundColor = "yellow";
        });
    }
})();
```

## Info.plist Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.Safari.extension</string>

        <key>NSExtensionPrincipalClass</key>
        <string>$(PRODUCT_MODULE_NAME).SafariExtensionHandler</string>

        <key>SFSafariToolbarItem</key>
        <dict>
            <key>Identifier</key>
            <string>com.myapp.extension.toolbar</string>
            <key>Image</key>
            <string>ToolbarIcon.pdf</string>
            <key>Label</key>
            <string>My Extension</string>
        </dict>

        <key>SFSafariWebsiteAccess</key>
        <dict>
            <key>Level</key>
            <string>All</string>
            <!-- Or use specific domains -->
            <!--
            <key>Level</key>
            <string>Some</string>
            <key>Allowed Domains</key>
            <array>
                <string>*.example.com</string>
            </array>
            -->
        </dict>

        <key>SFSafariContentScript</key>
        <array>
            <dict>
                <key>Script</key>
                <string>script.js</string>
                <key>Run At</key>
                <string>document-end</string>
                <key>Allowed URLs</key>
                <array>
                    <string>*://*/*</string>
                </array>
            </dict>
        </array>
    </dict>
</dict>
</plist>
```

## Tab Management APIs

### Get All Tabs

```swift
func getAllOpenTabs() async throws -> [TabInfo] {
    var allTabs: [TabInfo] = []

    let application = SFSafariApplication.self
    let windows = await withCheckedContinuation { continuation in
        application.getAllWindows { windows in
            continuation.resume(returning: windows)
        }
    }

    for window in windows {
        let tabs = try await window.getAllTabs()
        for tab in tabs {
            if let page = try await tab.getActivePage(),
               let props = try await page.getPageProperties() {
                allTabs.append(TabInfo(
                    url: props.url,
                    title: props.title ?? "Untitled"
                ))
            }
        }
    }

    return allTabs
}

struct TabInfo: Identifiable {
    let id = UUID()
    let url: URL?
    let title: String
}
```

### Activate Tab

```swift
func activateTab(_ tab: SFSafariTab) {
    tab.activate()
}
```

### Close Tab

```swift
func closeTab(_ tab: SFSafariTab) {
    tab.close()
}
```

### Open New Tab

```swift
func openNewTab(url: URL, in window: SFSafariWindow) {
    window.openTab(with: url, makeActiveIfPossible: true)
}
```

## Storage Options

### UserDefaults (Shared Container)

```swift
// App Group for sharing between app and extension
let appGroup = "group.com.myapp"
let sharedDefaults = UserDefaults(suiteName: appGroup)

// Save data
sharedDefaults?.set(["item1", "item2"], forKey: "savedItems")

// Read data
let items = sharedDefaults?.array(forKey: "savedItems") as? [String] ?? []
```

### File-Based Storage

```swift
// Shared container URL
let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.com.myapp"
)

func saveToSharedStorage(_ data: Codable) throws {
    let fileURL = containerURL!.appendingPathComponent("data.json")
    let encoded = try JSONEncoder().encode(data)
    try encoded.write(to: fileURL)
}

func loadFromSharedStorage<T: Codable>(_ type: T.Type) throws -> T {
    let fileURL = containerURL!.appendingPathComponent("data.json")
    let data = try Data(contentsOf: fileURL)
    return try JSONDecoder().decode(type, from: data)
}
```

## Testing Safari Extensions

### Unit Tests

```swift
import Testing

@Test func tabInfoParsing() {
    let info = TabInfo(url: URL(string: "https://example.com"), title: "Test")
    #expect(info.title == "Test")
    #expect(info.url?.host == "example.com")
}
```

### Integration Testing

1. Build and run the containing app
2. Enable extension in Safari > Settings > Extensions
3. Visit test pages and verify behavior
4. Use Safari's Develop menu for debugging

### Debug Console

1. Safari > Develop > Web Extension Background Pages
2. Or: Develop > [Your Device] > [Extension Name]

## Entitlements

### Extension Entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.myapp</string>
    </array>
</dict>
</plist>
```

## Common Patterns

### Privacy: Disable in Private Browsing

```swift
override func validateToolbarItem(
    in window: SFSafariWindow,
    validationHandler: @escaping (Bool, String) -> Void
) {
    // Safari doesn't directly expose private browsing
    // Best practice: Check if storage is accessible
    let isEnabled = UserDefaults(suiteName: "group.com.myapp") != nil
    validationHandler(isEnabled, isEnabled ? "My Extension" : "Disabled")
}
```

### Context Menu Items

```swift
override func contextMenuItemSelected(
    withCommand command: String,
    in page: SFSafariPage,
    userInfo: [String: Any]?
) {
    switch command {
    case "saveLink":
        // Handle context menu action
        break
    default:
        break
    }
}
```

### Badge Updates

```swift
func updateBadge(count: Int, in window: SFSafariWindow) {
    SFSafariApplication.getActiveWindow { window in
        window?.getToolbarItem { item in
            item?.setBadgeText(count > 0 ? "\(count)" : nil)
        }
    }
}
```

## Quick Reference

| Task | API |
|------|-----|
| Handle toolbar click | `toolbarItemClicked(in:)` |
| Validate toolbar state | `validateToolbarItem(in:validationHandler:)` |
| Receive content script message | `messageReceived(withName:from:userInfo:)` |
| Send message to content script | `page.dispatchMessageToScript(withName:userInfo:)` |
| Get all windows | `SFSafariApplication.getAllWindows(_:)` |
| Get all tabs | `window.getAllTabs(_:)` |
| Get active tab | `window.getActiveTab(_:)` |
| Open new tab | `window.openTab(with:makeActiveIfPossible:)` |
| Activate tab | `tab.activate()` |
| Close tab | `tab.close()` |
| Get page URL/title | `page.getPropertiesWithCompletionHandler(_:)` |

## Resources

- **Safari App Extensions**: https://developer.apple.com/documentation/safariservices/safari_app_extensions
- **Web Extensions**: https://developer.apple.com/documentation/safariservices/safari_web_extensions
- **WWDC Sessions**: Safari Extensions sessions from 2020-2024
- **Sample Code**: https://developer.apple.com/documentation/safariservices/safari_app_extensions/building_a_safari_app_extension
