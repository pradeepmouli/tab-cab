# Data Model: AI-Powered Safari Tab Organizer

**Phase**: 1 (Design & Contracts)
**Date**: 2025-12-24
**Input**: Feature spec requirements and research findings

## Entity Definitions

### TabAssociation

Represents a named collection of tabs created by the user or AI suggestions.

**Properties**:
- `id: UUID` - Unique identifier for the group
- `name: String` - User-defined or AI-suggested name (e.g., "Work", "Research")
- `color: String` - Hex color code for visual distinction (e.g., "#007AFF")
- `collapsed: Bool` - Whether the group is collapsed in UI (default: false)
- `createdAt: Date` - Creation timestamp
- `updatedAt: Date` - Last modification timestamp
- `tabIDs: [String]` - Array of tab identifiers belonging to this group
- `metadata: [String: String]` - Extensible key-value metadata (e.g., "aiSuggested": "true")

**Validation Rules**:
- `name` must be non-empty, max 50 characters
- `name` must be unique within the same window
- `color` must be valid hex format or predefined color name
- `tabIDs` can be empty (empty groups allowed for user flexibility)

**Relationships**:
- One-to-many with `Tab` (a group contains multiple tabs)
- Group membership is stored in `tabIDs` array for efficient lookup

**State Transitions**:
```
Created (empty) → Populated (tabs added) → Collapsed → Expanded → Deleted
                                         ↓
                                     Updated (name/color changed)
```

---

### Tab

Represents a Safari tab tracked by the extension.

**Properties**:
- `id: String` - Safari's internal tab identifier (from `SFSafariTab`)
- `url: URL` - Tab's current URL
- `title: String` - Page title
- `domain: String` - Extracted domain (e.g., "github.com" from "https://github.com/user/repo")
- `faviconURL: URL?` - Optional favicon URL for display
- `isActive: Bool` - Whether this tab is currently selected
- `isPinned: Bool` - Whether this tab is pinned (excludes from rearrangement)
- `isPrivate: Bool` - Whether this tab is in private browsing mode
- `lastViewedAt: Date` - Timestamp of last user interaction with this tab
- `groupID: UUID?` - Optional reference to parent TabAssociation

**Validation Rules**:
- `url` must be valid URL format
- `title` defaults to URL string if empty
- `domain` extracted automatically from `url`
- `isPrivate` tabs MUST NOT be stored (filtered at ingestion)

**Relationships**:
- Many-to-one with `TabAssociation` (multiple tabs belong to one group)
- Self-referential for similarity (tracked in ContextAnalysis)

**Lifecycle**:
- Created when Safari opens a new tab
- Updated on navigation (URL/title change)
- Updated on interaction (lastViewedAt timestamp)
- Removed when Safari closes the tab

---

### ContextAnalysis

Represents AI-generated understanding of tab relationships and similarity.

**Properties**:
- `id: UUID` - Unique identifier for the analysis
- `sourceTabID: String` - Reference to the tab being analyzed
- `relatedTabIDs: [String]` - Array of similar tab identifiers
- `similarityScores: [String: Double]` - Map of tab ID to similarity score (0.0-1.0)
- `matchingCriteria: [String: [String]]` - Map of tab ID to list of matching criteria (e.g., "domain", "keywords")
- `keywords: [String]` - Extracted keywords from tab content/title
- `category: String?` - Optional AI-classified category (e.g., "documentation", "news", "shopping")
- `confidence: Double` - Confidence score for the analysis (0.0-1.0)
- `analyzedAt: Date` - Analysis timestamp
- `expiresAt: Date` - When this analysis becomes stale (default: 5 minutes)

**Validation Rules**:
- `similarityScores` values must be between 0.0 and 1.0
- `confidence` must be between 0.0 and 1.0
- `relatedTabIDs` must exist in current window
- Analysis expires after 5 minutes (re-run on next selection if stale)

**Relationships**:
- One-to-one with source `Tab`
- Many-to-many with related `Tab` instances (via `relatedTabIDs`)

**Lifecycle**:
- Created on-demand when user selects a tab (context highlighting trigger)
- Cached for 5 minutes
- Invalidated when tabs are closed or navigated
- Regenerated on cache miss

---

### CleanupSuggestion

Represents a recommendation to close inactive tabs.

**Properties**:
- `id: UUID` - Unique identifier for the suggestion
- `suggestedTabIDs: [String]` - Array of tab identifiers recommended for closure
- `inactivityDurations: [String: TimeInterval]` - Map of tab ID to inactive duration in seconds
- `reason: String` - Human-readable explanation (e.g., "Inactive for 45 minutes")
- `createdAt: Date` - When this suggestion was generated
- `userDecision: UserDecision?` - Optional user response to this suggestion
- `appliedAt: Date?` - When the user accepted/rejected this suggestion

**Enum: UserDecision**:
```swift
enum UserDecision: String, Codable {
    case accepted   // User clicked "Close Tabs"
    case rejected   // User clicked "Keep All"
    case partial    // User kept some, closed others
    case ignored    // User dismissed without action
}
```

**Validation Rules**:
- `suggestedTabIDs` must not be empty
- `inactivityDurations` must have entries for all `suggestedTabIDs`
- Suggestions expire after 1 hour (show fresh suggestions)
- Cannot suggest pinned tabs or active tab

**Relationships**:
- Many-to-many with `Tab` (suggestion references multiple tabs)
- One-to-one with user decision history

**Lifecycle**:
```
Generated (on threshold trigger) → Presented → User Decision → Applied/Dismissed
                                             ↓
                                         Expired (after 1 hour)
```

---

### UserSettings

Represents user preferences and feature toggles.

**Properties**:
- `id: UUID` - Unique identifier (singleton per user)
- `inactivityThreshold: TimeInterval` - Cleanup threshold in seconds (default: 1800 = 30 min)
- `contextHighlightingEnabled: Bool` - Whether to highlight related tabs (default: true)
- `autoRearrangementEnabled: Bool` - Whether to auto-move related tabs (default: false)
- `autoCleanupEnabled: Bool` - Whether to auto-close inactive tabs (default: false)
- `autoCleanupCriteria: CleanupCriteria?` - Optional criteria for auto-cleanup
- `keyboardShortcuts: [String: String]` - Map of action to keyboard shortcut (default: empty)
- `privacyConsents: [String: Bool]` - Map of privacy consent types (e.g., "tabTracking": true)
- `lastBackupAt: Date?` - Last settings backup timestamp
- `version: Int` - Settings schema version (for future migrations)

**Enum: CleanupCriteria**:
```swift
enum CleanupCriteria: String, Codable {
    case ungroupedOnly       // Only close tabs not in any group
    case allInactive         // Close all inactive tabs
    case excludePinned       // Close inactive except pinned
    case excludeSpecificDomains // Close inactive except whitelisted domains
}
```

**Validation Rules**:
- `inactivityThreshold` must be between 900 (15 min) and 14400 (4 hours)
- `autoRearrangementEnabled` requires `contextHighlightingEnabled` (dependency)
- `autoCleanupEnabled` requires `autoCleanupCriteria` to be set

**Relationships**:
- Singleton entity (one per user)
- Referenced by all services for feature toggles

**Lifecycle**:
- Created with defaults on first extension launch
- Updated via settings UI
- Backed up to Safari local storage on change
- Migrated on version bump (if schema changes)

---

## Entity Relationships Diagram

```
┌─────────────┐         ┌─────────────┐
│  TabAssociation   │◄───────┤│     Tab     │
│             │ 1     * ││             │
│ - id        │         ││ - id        │
│ - name      │         ││ - url       │
│ - tabIDs    │         ││ - groupID   │
└─────────────┘         ││ - isPrivate │
                        └─────────────┘
                              ▲
                              │ 1
                              │
                         * ┌──┴──────────────┐
                           │ ContextAnalysis │
                           │                 │
                           │ - sourceTabID   │
                           │ - relatedTabIDs │
                           └─────────────────┘

┌──────────────────┐         ┌─────────────┐
│ CleanupSuggestion│───────*│     Tab     │
│                  │         │             │
│ - suggestedTabIDs│         │             │
└──────────────────┘         └─────────────┘

┌──────────────┐
│ UserSettings │ (Singleton)
│              │
│ - thresholds │
│ - toggles    │
└──────────────┘
```

---

## Storage Considerations

### Persistence Strategy

**TabAssociation & Tab**:
- Store in Safari local storage (JSON serialization)
- Key: `tabOrganizer.groups.{windowID}` → Array of TabAssociation
- Indexed by window to support multi-window
- Updated on any group/tab change (debounced to 500ms)

**ContextAnalysis**:
- In-memory cache only (short-lived, 5-minute TTL)
- No persistence needed (regenerated on demand)
- Reduces storage overhead

**CleanupSuggestion**:
- Store last 10 suggestions for undo history (24-hour retention)
- Key: `tabOrganizer.cleanupHistory` → Array of CleanupSuggestion
- Prune suggestions older than 24 hours on app launch

**UserSettings**:
- Store in Safari local storage (JSON serialization)
- Key: `tabOrganizer.settings` → UserSettings singleton
- Backed up to iCloud via Safari sync (if user enabled)

### Data Migration

**Version Handling**:
- Each entity has `version` field for schema versioning
- Migration function runs on app launch if version mismatch
- Backwards-compatible migrations only (never delete data without user consent)

---

## Validation Summary

| Entity | Required Fields | Unique Constraints | Indexes |
|--------|----------------|-------------------|---------|
| TabAssociation | id, name, tabIDs | name (per window) | id |
| Tab | id, url, domain | id | id, groupID |
| ContextAnalysis | id, sourceTabID | - | sourceTabID |
| CleanupSuggestion | id, suggestedTabIDs | - | id, createdAt |
| UserSettings | id | id (singleton) | id |

---

## Edge Case Handling

**Duplicate Group Names**: Append " (2)" to name on collision
**Orphaned Tabs**: Remove groupID if referenced group is deleted
**Private Tabs**: Filter at ingestion, never stored
**Tab Closure**: Remove from group's tabIDs array, cascade delete if last tab
**Window Closure**: Archive groups for potential restore (30-day retention)
**Concurrent Modifications**: Last-write-wins strategy (acceptable for single-user extension)

---

## Next Steps

✅ Data model complete - ready for contract generation
→ Proceed to generate API contracts in `contracts/` directory
