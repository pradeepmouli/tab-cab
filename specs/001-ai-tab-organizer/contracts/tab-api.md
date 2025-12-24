# Tab API Contract

**Purpose**: Define internal APIs for tab manipulation, querying, and tracking
**Implementation**: `TabOrganizerSafariAPI` and `TabOrganizerCore` libraries

---

## TabManaging Protocol

Provides abstraction over Safari Extension tab APIs for testability.

### getAllTabs()

**Signature**:
```swift
func getAllTabs() async throws -> [TabInfo]
```

**Description**: Retrieve all tabs in the active Safari window.

**Returns**: Array of `TabInfo` structures containing tab metadata.

**Throws**:
- `TabAPIError.permissionDenied` - User hasn't granted tab access permission
- `TabAPIError.noActiveWindow` - No Safari window is currently active
- `TabAPIError.safariUnavailable` - Safari Extension host is unavailable

**Behavior**:
- Filters out private browsing tabs automatically (never returned)
- Returns empty array if window has no tabs
- Tab order matches Safari's visual tab bar order (left to right)

**Performance**: Completes within 100ms for up to 200 tabs

**Example**:
```swift
let tabManager: TabManaging = SafariTabManager()
let tabs = try await tabManager.getAllTabs()
// tabs: [TabInfo(id: "tab-1", url: "https://github.com", ...)]
```

---

### activateTab(id:)

**Signature**:
```swift
func activateTab(id: String) async throws
```

**Description**: Make the specified tab active (bring to foreground).

**Parameters**:
- `id: String` - Safari tab identifier from `TabInfo.id`

**Throws**:
- `TabAPIError.tabNotFound` - Tab with given ID doesn't exist
- `TabAPIError.permissionDenied` - User hasn't granted tab access permission

**Behavior**:
- Switches to the tab's window if in different window
- Brings Safari to foreground if in background
- Triggers `lastViewedAt` timestamp update

**Performance**: Completes within 50ms

**Example**:
```swift
try await tabManager.activateTab(id: "tab-42")
```

---

### closeTab(id:)

**Signature**:
```swift
func closeTab(id: String) async throws
```

**Description**: Close the specified tab.

**Parameters**:
- `id: String` - Safari tab identifier from `TabInfo.id`

**Throws**:
- `TabAPIError.tabNotFound` - Tab with given ID doesn't exist
- `TabAPIError.cannotCloseLastTab` - Safari prevents closing the last tab in a window

**Behavior**:
- Removes tab from Safari immediately
- Triggers cleanup of associated data (group membership, context analysis)
- Safari may ask to save form data if present (system dialog)

**Performance**: Completes within 50ms

**Example**:
```swift
try await tabManager.closeTab(id: "tab-99")
```

---

### openTab(url:inBackground:)

**Signature**:
```swift
func openTab(url: URL, inBackground: Bool = false) async throws -> String
```

**Description**: Open a new tab with the specified URL.

**Parameters**:
- `url: URL` - URL to load in new tab
- `inBackground: Bool` - If true, don't activate the new tab (default: false)

**Returns**: New tab's identifier (String)

**Throws**:
- `TabAPIError.invalidURL` - URL scheme not supported by Safari
- `TabAPIError.permissionDenied` - User hasn't granted tab access permission

**Behavior**:
- Creates tab in active window
- Activates tab unless `inBackground` is true
- Newly created tabs have no group assignment (ungrouped)

**Performance**: Completes within 100ms

**Example**:
```swift
let newTabID = try await tabManager.openTab(
    url: URL(string: "https://example.com")!,
    inBackground: true
)
// newTabID: "tab-123"
```

---

### observeTabChanges(handler:)

**Signature**:
```swift
func observeTabChanges(handler: @escaping (TabChangeEvent) -> Void) async throws
```

**Description**: Register a handler for tab lifecycle events (open, close, navigate, activate).

**Parameters**:
- `handler: (TabChangeEvent) -> Void` - Closure called when tab changes occur

**Throws**:
- `TabAPIError.permissionDenied` - User hasn't granted tab access permission

**Behavior**:
- Handler called on main actor (@MainActor)
- Events are coalesced (multiple rapid changes batched within 100ms)
- Unsubscribe by canceling the returned Task

**TabChangeEvent Types**:
```swift
enum TabChangeEvent {
    case opened(id: String, url: URL)
    case closed(id: String)
    case navigated(id: String, newURL: URL)
    case activated(id: String)
    case moved(id: String, fromIndex: Int, toIndex: Int)
}
```

**Example**:
```swift
let observerTask = Task {
    try await tabManager.observeTabChanges { event in
        switch event {
        case .closed(let id):
            // Update local state
        case .navigated(let id, let url):
            // Re-analyze tab context
        default:
            break
        }
    }
}
// Later: observerTask.cancel()
```

---

## TabInfo Structure

Immutable snapshot of tab metadata at query time.

```swift
struct TabInfo: Identifiable, Codable, Sendable {
    let id: String              // Safari internal tab ID
    let url: URL                // Current URL
    let title: String           // Page title (or URL if title unavailable)
    let domain: String          // Extracted domain (e.g., "github.com")
    let faviconURL: URL?        // Optional favicon URL
    let isActive: Bool          // Is this tab currently selected
    let isPinned: Bool          // Is this tab pinned in Safari
    let lastViewedAt: Date      // Last user interaction timestamp
}
```

**Notes**:
- `isPrivate` is NOT included (private tabs filtered out before TabInfo creation)
- `lastViewedAt` tracked by extension, not from Safari (Safari doesn't provide this)
- `domain` extracted from `url.host` for convenience

---

## TabAPIError Enum

```swift
enum TabAPIError: Error, LocalizedError {
    case permissionDenied
    case tabNotFound(id: String)
    case noActiveWindow
    case safariUnavailable
    case cannotCloseLastTab
    case invalidURL(URL)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Tab access permission not granted. Enable in Safari Preferences."
        case .tabNotFound(let id):
            return "Tab with ID \(id) not found."
        case .noActiveWindow:
            return "No active Safari window."
        case .safariUnavailable:
            return "Cannot communicate with Safari."
        case .cannotCloseLastTab:
            return "Cannot close the last tab in a window."
        case .invalidURL(let url):
            return "URL \(url) is not valid or unsupported."
        }
    }
}
```

---

## Implementation Notes

**Production Implementation** (`SafariTabManager`):
- Wraps `SFSafariApplication`, `SFSafariWindow`, `SFSafariTab` APIs
- Filters private tabs using `SFSafariTab.isPrivate`
- Maintains local cache of tab metadata for `lastViewedAt` tracking

**Mock Implementation** (`MockTabManager`):
- Stores stubbed tabs in-memory array
- Returns deterministic results for tests
- Can simulate errors by setting `throwError` property

**Thread Safety**:
- All methods are `async` and safe to call from any context
- Results delivered on main actor for UI updates
- No shared mutable state in protocol implementations
