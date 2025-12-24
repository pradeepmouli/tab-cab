# Storage API Contract

**Purpose**: Define persistence layer APIs for tab groups, settings, and cleanup history  
**Implementation**: `TabOrganizerStorage` library

---

## TabGroupRepository Protocol

Manages persistence of TabGroup entities.

### saveGroup(_:)

**Signature**:
```swift
func saveGroup(_ group: TabGroup) async throws
```

**Description**: Create or update a tab group in persistent storage.

**Parameters**:
- `group: TabGroup` - Group to save (uses `id` for update vs. create)

**Throws**:
- `StorageError.duplicateName` - Group with same name already exists in window
- `StorageError.storageQuotaExceeded` - Safari storage limit reached
- `StorageError.permissionDenied` - Storage access denied by user

**Behavior**:
- If `group.id` exists, updates existing group
- If `group.id` not found, creates new group
- Validates name uniqueness before saving
- Updates `group.updatedAt` timestamp automatically

**Performance**: Completes within 50ms

**Example**:
```swift
let group = TabGroup(
    id: UUID(),
    name: "Work",
    color: "#007AFF",
    tabIDs: ["tab-1", "tab-2"]
)
try await repository.saveGroup(group)
```

---

### deleteGroup(id:)

**Signature**:
```swift
func deleteGroup(id: UUID) async throws
```

**Description**: Remove a tab group from storage.

**Parameters**:
- `id: UUID` - Group identifier to delete

**Throws**:
- `StorageError.notFound` - Group with given ID doesn't exist

**Behavior**:
- Removes group from storage
- Does NOT close tabs (tabs become ungrouped)
- Cascades to cleanup any references in other entities

**Performance**: Completes within 50ms

**Example**:
```swift
try await repository.deleteGroup(id: groupID)
```

---

### getAllGroups(windowID:)

**Signature**:
```swift
func getAllGroups(windowID: String) async throws -> [TabGroup]
```

**Description**: Retrieve all tab groups for a specific window.

**Parameters**:
- `windowID: String` - Safari window identifier (empty string for current window)

**Returns**: Array of `TabGroup` instances, sorted by `createdAt` ascending

**Throws**:
- `StorageError.permissionDenied` - Storage access denied by user

**Behavior**:
- Returns empty array if no groups exist
- Groups are isolated per window (multi-window support)
- Results cached in memory for 500ms to reduce I/O

**Performance**: Completes within 50ms (or instant if cached)

**Example**:
```swift
let groups = try await repository.getAllGroups(windowID: "")
// groups: [TabGroup(...), TabGroup(...)]
```

---

### observeGroups(windowID:handler:)

**Signature**:
```swift
func observeGroups(
    windowID: String,
    handler: @escaping ([TabGroup]) -> Void
) async throws -> ObservationToken
```

**Description**: Subscribe to real-time group changes for reactive UI updates.

**Parameters**:
- `windowID: String` - Window to observe
- `handler: ([TabGroup]) -> Void` - Closure called when groups change

**Returns**: `ObservationToken` - Cancel subscription by calling `token.cancel()`

**Throws**:
- `StorageError.permissionDenied` - Storage access denied by user

**Behavior**:
- Handler called immediately with current state
- Handler called on any saveGroup/deleteGroup operation
- Handler called on main actor (@MainActor)

**Example**:
```swift
let token = try await repository.observeGroups(windowID: "") { groups in
    // Update UI with latest groups
}
// Later: token.cancel()
```

---

## SettingsRepository Protocol

Manages persistence of UserSettings singleton.

### loadSettings()

**Signature**:
```swift
func loadSettings() async throws -> UserSettings
```

**Description**: Load user settings from storage (or create defaults if first launch).

**Returns**: `UserSettings` instance with current or default values

**Throws**:
- `StorageError.permissionDenied` - Storage access denied by user
- `StorageError.corruptedData` - Settings data corrupted (returns defaults with warning log)

**Behavior**:
- Returns cached settings if available (in-memory)
- Loads from storage on first call or after cache invalidation
- Creates default settings if none exist
- Runs migration if schema version mismatch

**Performance**: Completes within 50ms (or instant if cached)

**Example**:
```swift
let settings = try await repository.loadSettings()
// settings.inactivityThreshold: 1800 (30 min default)
```

---

### saveSettings(_:)

**Signature**:
```swift
func saveSettings(_ settings: UserSettings) async throws
```

**Description**: Persist user settings to storage.

**Parameters**:
- `settings: UserSettings` - Settings to save

**Throws**:
- `StorageError.validationFailed` - Settings validation failed (e.g., invalid threshold)
- `StorageError.permissionDenied` - Storage access denied by user

**Behavior**:
- Validates settings before saving (thresholds in range, dependencies met)
- Updates in-memory cache
- Writes to storage (debounced to 1 second to reduce I/O)

**Performance**: Completes within 50ms (async write)

**Example**:
```swift
var settings = try await repository.loadSettings()
settings.inactivityThreshold = 3600 // 1 hour
try await repository.saveSettings(settings)
```

---

### observeSettings(handler:)

**Signature**:
```swift
func observeSettings(
    handler: @escaping (UserSettings) -> Void
) async throws -> ObservationToken
```

**Description**: Subscribe to settings changes for reactive UI.

**Parameters**:
- `handler: (UserSettings) -> Void` - Closure called when settings change

**Returns**: `ObservationToken` - Cancel subscription by calling `token.cancel()`

**Throws**:
- `StorageError.permissionDenied` - Storage access denied by user

**Behavior**:
- Handler called immediately with current settings
- Handler called on any saveSettings operation
- Handler called on main actor (@MainActor)

**Example**:
```swift
let token = try await repository.observeSettings { settings in
    // Update UI toggles
}
```

---

## CleanupHistoryRepository Protocol

Manages cleanup suggestion history for undo functionality.

### saveCleanupSuggestion(_:)

**Signature**:
```swift
func saveCleanupSuggestion(_ suggestion: CleanupSuggestion) async throws
```

**Description**: Save a cleanup suggestion to history (for undo).

**Parameters**:
- `suggestion: CleanupSuggestion` - Suggestion to save

**Throws**:
- `StorageError.permissionDenied` - Storage access denied by user

**Behavior**:
- Appends to history array
- Keeps only last 10 suggestions (FIFO queue)
- Auto-prunes suggestions older than 24 hours

**Performance**: Completes within 50ms

**Example**:
```swift
let suggestion = CleanupSuggestion(
    id: UUID(),
    suggestedTabIDs: ["tab-5", "tab-9"],
    reason: "Inactive for 45 minutes"
)
try await repository.saveCleanupSuggestion(suggestion)
```

---

### getRecentCleanups(limit:)

**Signature**:
```swift
func getRecentCleanups(limit: Int = 10) async throws -> [CleanupSuggestion]
```

**Description**: Retrieve recent cleanup suggestions (for undo UI).

**Parameters**:
- `limit: Int` - Maximum number of suggestions to return (default: 10)

**Returns**: Array of `CleanupSuggestion`, sorted by `createdAt` descending (newest first)

**Throws**:
- `StorageError.permissionDenied` - Storage access denied by user

**Behavior**:
- Returns suggestions from last 24 hours only
- Empty array if no recent cleanups

**Performance**: Completes within 50ms

**Example**:
```swift
let recentCleanups = try await repository.getRecentCleanups(limit: 5)
// [CleanupSuggestion(...), ...]
```

---

## SafariStorageAdapter Protocol

Low-level wrapper over Safari's storage APIs (implementation detail).

### store(key:value:)

**Signature**:
```swift
func store<T: Codable>(key: String, value: T) async throws
```

**Description**: Store Codable value in Safari local storage.

**Parameters**:
- `key: String` - Storage key (namespaced automatically: `tabOrganizer.{key}`)
- `value: T` - Codable value to store

**Throws**:
- `StorageError.storageQuotaExceeded` - Safari storage limit reached (5MB typical)
- `StorageError.encodingFailed` - Value couldn't be encoded to JSON

**Example**:
```swift
try await adapter.store(key: "groups.main", value: groups)
```

---

### retrieve(key:)

**Signature**:
```swift
func retrieve<T: Codable>(key: String) async throws -> T?
```

**Description**: Retrieve Codable value from Safari local storage.

**Parameters**:
- `key: String` - Storage key

**Returns**: Decoded value or `nil` if key doesn't exist

**Throws**:
- `StorageError.decodingFailed` - Stored data couldn't be decoded (corrupt)

**Example**:
```swift
let groups: [TabGroup]? = try await adapter.retrieve(key: "groups.main")
```

---

### delete(key:)

**Signature**:
```swift
func delete(key: String) async throws
```

**Description**: Remove value from storage.

**Parameters**:
- `key: String` - Storage key to delete

**Example**:
```swift
try await adapter.delete(key: "groups.archived")
```

---

## StorageError Enum

```swift
enum StorageError: Error, LocalizedError {
    case permissionDenied
    case storageQuotaExceeded
    case notFound(id: UUID)
    case duplicateName(name: String)
    case validationFailed(reason: String)
    case encodingFailed
    case decodingFailed
    case corruptedData
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Storage access denied. Enable in Safari Preferences."
        case .storageQuotaExceeded:
            return "Storage limit exceeded. Delete unused groups."
        case .notFound(let id):
            return "Item with ID \(id) not found."
        case .duplicateName(let name):
            return "Group name '\(name)' already exists."
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        case .encodingFailed:
            return "Failed to encode data for storage."
        case .decodingFailed:
            return "Failed to decode data from storage."
        case .corruptedData:
            return "Storage data is corrupted. Using defaults."
        }
    }
}
```

---

## ObservationToken Protocol

```swift
protocol ObservationToken {
    func cancel()
}
```

**Usage**: Returned by `observe*` methods. Call `cancel()` to unsubscribe.

---

## Storage Schema

### Keys Used

- `tabOrganizer.groups.{windowID}` → `[TabGroup]`
- `tabOrganizer.settings` → `UserSettings`
- `tabOrganizer.cleanupHistory` → `[CleanupSuggestion]`
- `tabOrganizer.schemaVersion` → `Int`

### Storage Budget

**Safari Local Storage Limit**: ~5MB per extension

**Estimated Usage**:
- 100 groups @ 500 bytes each = 50KB
- 200 tabs @ 300 bytes each = 60KB
- Settings = 2KB
- Cleanup history (10 items) = 5KB
- **Total: ~120KB** (well within limit)

---

## Implementation Notes

**Production Implementation**:
- Uses `UserDefaults` with app group or Safari's `localStorage` equivalent
- JSON encoding/decoding via `Codable`
- Debounced writes to reduce I/O (500ms for groups, 1s for settings)
- In-memory cache with 5-minute TTL

**Mock Implementation**:
- In-memory dictionary storage
- Synchronous operations for test speed
- No debouncing (immediate writes)

**Thread Safety**:
- All methods are `async` and isolated to a storage actor
- No shared mutable state exposed to callers
