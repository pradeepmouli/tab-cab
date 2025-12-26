# Feature Specification: AI-Powered Safari Tab Organizer

**Feature Branch**: `001-ai-tab-organizer`
**Created**: 2025-12-24
**Status**: In Development
**Project Name**: TabCab (formerly SwiftTemplateMacOS)
**Input**: User description: "Create an AI-powered safari extension for organization (via tab associations) and cleanup of tabs. Support advanced features such as rearranging/highlighting tabs based on context, e.g. automatically moving/highlighting tabs with similar purpose and content when a tab is selected."

---

## Implementation Status (2025-12-25)

### ✅ Phase 0: Project Setup Complete
- **Project renamed** from SwiftTemplateMacOS to TabCab
- **Bundle ID**: `com.pmouli.TabCab`
- **Extension target**: TabCabExtension (Safari App Extension)
- **Build status**: ✅ Successful (TabCab.app + TabCabExtension.appex)
- **Architecture**: Swift Package Manager with 5 library targets + extension

### 🚧 Phase 1: Foundation (In Progress)
- Core models, storage layer, and Safari API wrappers implemented
- User Story 1 (Manual Tab Grouping) - Most tasks complete
- See [tasks.md](tasks.md) for detailed progress

### 📋 Upcoming
- Phase 2-6: User Stories 2-5 (AI features, context highlighting, auto-rearrange, cleanup)

---

## Clarifications

### Session 2025-12-25

- Q: How should AI grouping explanations (FR-008) be displayed in the UI? → A: Tooltip on hover over group name
- Q: What should happen when analyzing >50 tabs (FR-012 threshold)? → A: Disable AI suggestions, require manual grouping, prompt user to cleanup/consolidate tabs
- Q: What should happen if auto-rearrangement exceeds the 1-second timeout (FR-021)? → A: Cancel rearrangement, show notification, keep current state
- Q: How should users specify tab types for auto-closing (e.g., MFA popups)? → A: Predefined categories (Auth, Shopping, Social, etc.) determined by domain pattern matching + AI pattern recognition
- Q: How should dynamic groups be converted to Safari native tab associations? → A: "Convert to Native" button in group header + emoji prefix on first tab, triggered by double-click
- Q: How should duplicate native tab associations be handled during conversion? → A: Merge into existing native group if name/content is similar
- Q: How should new tabs be assigned to groups automatically? → A: Auto-assign based on domain + AI analysis (on-demand)
- Q: When should ML/AI be used vs cached domain mappings? → A: ML only for unknown domains; use cached domain→category mappings for known sites

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Manual Tab Group Organization (Priority: P1)

Users can manually organize open tabs into named groups (e.g., "Work", "Research", "Shopping") through the Safari extension's UI. Groups persist across browser sessions and can be collapsed/expanded for cleaner browsing.

**Why this priority**: Core MVP functionality that provides immediate value. Even without AI features, manual grouping significantly reduces tab clutter and improves navigation. This establishes the foundation for all advanced features.

**Independent Test**: Can be fully tested by creating 10+ tabs, manually organizing them into 2-3 groups, closing Safari, reopening, and verifying groups are intact with correct tabs.

**Acceptance Scenarios**:

1. **Given** I have 15 tabs open across different topics, **When** I open the extension and create a group named "Work" and drag 5 tabs into it, **Then** those tabs are visually grouped together and the group is labeled "Work"
2. **Given** I have created tab associations in my current session, **When** I close and reopen Safari, **Then** all tab associations and their contained tabs are restored in the same state
3. **Given** I have a tab association with 8 tabs, **When** I click the collapse button on the group, **Then** the tabs are hidden from view but remain accessible by expanding the group
4. **Given** I want to remove tabs from a group, **When** I drag a tab out of the group, **Then** the tab becomes ungrouped and remains open in the main tab bar

---

### User Story 2 - AI-Suggested Tab Grouping (Priority: P2)

The extension analyzes open tabs (title, URL, content preview) and suggests logical groupings. Users can accept suggestions with one click or customize before applying.

**Why this priority**: First AI-powered feature that provides significant time savings. Users with many tabs benefit from intelligent organization without manual effort. Builds on the foundation from P1.

**Independent Test**: Can be tested by opening 20+ tabs from different domains/topics (news, shopping, documentation, social media), triggering AI analysis, verifying suggested groups make semantic sense, and accepting suggestions.

**Acceptance Scenarios**:

1. **Given** I have 25 tabs open with mixed content (5 news sites, 10 documentation pages, 5 shopping sites, 5 social media), **When** I click "Suggest Groups" in the extension, **Then** I see 4 suggested groups with descriptive names and appropriate tab assignments
2. **Given** the AI has suggested groupings, **When** I review the suggestions, **Then** I can see a preview of which tabs will be in each group before accepting
3. **Given** I want to customize AI suggestions, **When** I edit group names or move tabs between suggested groups, **Then** my changes are preserved when I click "Apply Groups"
4. **Given** the AI suggestions don't match my mental model, **When** I click "Reject Suggestions", **Then** no changes are applied and I can manually organize or request new suggestions

---

### User Story 3 - Context-Aware Tab Highlighting (Priority: P3)

When a user selects a tab, the extension analyzes its content and highlights other open tabs with similar context (same domain, related topics, shared keywords). Highlighted tabs are visually distinct (border color, icon indicator).

**Why this priority**: Enhances discovery and navigation. Particularly useful for research sessions where related content is scattered across many tabs. Requires P1 foundation but is independently valuable.

**Independent Test**: Can be tested by opening 15 tabs (5 about "Swift programming", 5 about "cooking recipes", 5 about "travel destinations"), clicking a Swift-related tab, and verifying other Swift tabs are highlighted while cooking/travel tabs remain unhighlighted.

**Acceptance Scenarios**:

1. **Given** I have tabs about multiple topics, **When** I click on a tab about "Swift concurrency", **Then** other tabs containing Swift-related content are highlighted with a blue border
2. **Given** I have highlighted tabs from a previous selection, **When** I click on a tab about a different topic (e.g., "travel destinations"), **Then** the previous highlights are cleared and new relevant tabs are highlighted
3. **Given** I have tabs from the same domain (e.g., multiple GitHub pages), **When** I select one GitHub tab, **Then** other GitHub tabs are highlighted regardless of their specific content
4. **Given** I want to disable the highlighting feature, **When** I toggle "Context Highlighting" off in extension settings, **Then** no tabs are highlighted on selection

---

### User Story 4 - Automatic Tab Rearrangement (Priority: P4)

When context highlighting is active, users can enable automatic rearrangement to physically move highlighted tabs next to the selected tab. This creates dynamic, context-based tab organization.

**Why this priority**: Advanced feature building on P3. Provides ultimate convenience but requires careful UX design to avoid disorienting users. Most users will prefer highlighting alone.

**Independent Test**: Can be tested by enabling auto-rearrange, opening 20 mixed-topic tabs, selecting a tab about "Python", and verifying Python-related tabs automatically move adjacent to the selected tab while maintaining their relative order.

**Acceptance Scenarios**:

1. **Given** I have auto-rearrangement enabled and mixed-topic tabs open, **When** I select a tab about "machine learning", **Then** other ML-related tabs move to positions adjacent to my selected tab within 1 second
2. **Given** tabs have been automatically rearranged, **When** I select a different tab from a different context, **Then** tabs rearrange again to cluster around the new context
3. **Given** I want to prevent specific tabs from moving, **When** I "pin" certain tabs, **Then** pinned tabs remain in fixed positions and are excluded from auto-rearrangement
4. **Given** I find auto-rearrangement disorienting, **When** I disable the feature in settings, **Then** highlighting still works but tabs remain in their original positions

---

### User Story 5 - Intelligent Tab Cleanup (Priority: P5)

The extension identifies tabs that haven't been viewed in a configurable time period (default: 30 minutes) and suggests closing them. Users can review suggestions, mark exceptions, or enable auto-close for low-priority tabs.

**Why this priority**: Addresses tab overload problem directly. Complements organization features by reducing total tab count. Lower priority because it requires trust and careful UX to avoid data loss anxiety.

**Independent Test**: Can be tested by opening 30 tabs, interacting with only 10 of them over 30 minutes, triggering cleanup suggestions, and verifying the 20 inactive tabs are suggested for closure with options to keep specific ones.

**Acceptance Scenarios**:

1. **Given** I have 30 tabs open and haven't viewed 20 of them in 30+ minutes, **When** the extension runs cleanup analysis, **Then** I see a notification suggesting closure of 20 tabs with a preview list
2. **Given** I'm reviewing cleanup suggestions, **When** I see a tab I want to keep, **Then** I can mark it as "Keep" and it's excluded from closure and future suggestions for that session
3. **Given** I want to configure cleanup behavior, **When** I adjust the inactivity threshold to 60 minutes and enable auto-close for non-grouped tabs, **Then** future cleanup runs respect these settings
4. **Given** I accidentally accepted cleanup suggestions, **When** I click "Undo Last Cleanup", **Then** all recently closed tabs are restored to their previous positions

---

### User Story 6 - Category-Based Auto-Close (Priority: P6)

Users can configure automatic closure of specific tab categories (Auth/MFA, Shopping Confirmations, Social Media, etc.) based on predefined patterns and AI recognition. This provides hands-free cleanup of transient workflow tabs.

**Why this priority**: Reduces manual cleanup burden for known-transient tab types. MFA popups and confirmation pages typically have no long-term value. Complements P5's time-based cleanup with category-based intelligence.

**Independent Test**: Can be tested by enabling "Auth/MFA" auto-close, opening an authentication popup (e.g., Google Sign-In), completing authentication, and verifying the popup tab automatically closes within 5 seconds of workflow completion.

**Acceptance Scenarios**:

1. **Given** I have "Auth/MFA" category enabled for auto-close, **When** I complete a multi-factor authentication flow in a popup tab, **Then** the auth popup tab closes automatically within 5 seconds
2. **Given** I have "Shopping Confirmations" category enabled, **When** I complete a purchase and see an order confirmation page, **Then** the confirmation tab closes automatically after 10 seconds
3. **Given** I want to customize auto-close categories, **When** I open extension settings and enable/disable specific categories (Auth, Shopping, Social, Forms), **Then** only enabled categories trigger auto-close behavior
4. **Given** a tab matches multiple categories, **When** the system detects conflicting rules (e.g., "Keep Social" vs "Close Social after 30min"), **Then** the most specific/conservative rule takes precedence (Keep wins over Close)
5. **Given** I want to see what was auto-closed, **When** I check the cleanup history, **Then** I see category-based closures listed separately with category labels and restoration option

---

### User Story 7 - Native Tab Group Conversion (Priority: P7)

Users can convert extension-managed dynamic tab associations into Safari's native tab associations for permanent organization. Native groups display with emoji prefixes and persist independently of the extension.

**Why this priority**: Provides exit strategy and interoperability with Safari's native features. Users who find a stable grouping can "freeze" it into a native group. Lower priority as it's a convenience feature for power users.

**Independent Test**: Can be tested by creating a dynamic group "Work" with 5 tabs, double-clicking the group header to trigger conversion, and verifying Safari creates a native tab association with emoji prefix (e.g., 🔗 Work) and tabs are moved to native group.

**Acceptance Scenarios**:

1. **Given** I have a dynamic group "Research" with 8 tabs, **When** I double-click the group header, **Then** Safari creates a native tab association named "🔗 Research" and all 8 tabs are moved into it
2. **Given** I have a dynamic group "Work" and an existing native tab association "Work" with similar content, **When** I convert the dynamic group to native, **Then** the system merges tabs into the existing "Work" group rather than creating a duplicate
3. **Given** I have converted a group to native, **When** I view my tab bar, **Then** the first tab in the native group shows an emoji prefix (e.g., 🔗) indicating it was created by the extension
4. **Given** I have a native group created by the extension, **When** I close and reopen Safari, **Then** the native group persists independently (extension not required)
5. **Given** I want to manage native groups, **When** I add/remove tabs from a native group in Safari, **Then** the extension no longer manages that group (it's fully native)
6. **Given** I have many dynamic groups, **When** I use "Convert All to Native" option, **Then** all current dynamic groups are converted to native groups, merging into existing native groups where name/content is similar

---

### User Story 8 - Automatic Tab Assignment (Priority: P8)

When a new tab opens, the extension automatically assigns it to the most relevant existing group based on domain matching and cached AI category mappings. This provides seamless organization without manual intervention.

**Why this priority**: Reduces ongoing manual organization burden. Once groups are established, new tabs automatically flow into appropriate groups. Lower priority as it requires mature AI/domain mapping system.

**Independent Test**: Can be tested by creating groups "Development" (with GitHub, StackOverflow tabs) and "Shopping" (with Amazon, eBay tabs), then opening a new GitHub tab and verifying it auto-assigns to "Development" group.

**Acceptance Scenarios**:

1. **Given** I have a "Development" group containing github.com and stackoverflow.com tabs, **When** I open a new github.com tab, **Then** the new tab is automatically assigned to the "Development" group
2. **Given** I have established groups and open a tab from an unknown domain, **When** the AI analyzes the new tab's content, **Then** the tab is assigned to the most similar group based on category/keyword matching
3. **Given** a domain has been analyzed and mapped to a category (e.g., reddit.com → Social), **When** I open another reddit.com tab, **Then** the system uses the cached mapping without re-running AI analysis
4. **Given** I open a new tab that doesn't match any existing group, **When** the system cannot find a confident match (similarity < 70%), **Then** the tab remains ungrouped rather than being misassigned
5. **Given** I have both dynamic and native groups, **When** I open a new tab, **Then** the system assigns to dynamic groups only (native groups are user-managed)
6. **Given** I want to disable auto-assignment, **When** I toggle "Auto-assign new tabs" off in settings, **Then** new tabs remain ungrouped until manually organized

---

### Edge Cases

- What happens when a user has 200+ tabs open and triggers AI grouping? (Performance, timeout handling)
- How does the system handle tabs with identical titles but different URLs (e.g., multiple "Untitled" documents)?
- What happens when the AI fails to generate suggestions due to network issues or API limits?
- How does context highlighting work when a tab's content is still loading?
- What happens when auto-rearrangement conflicts with manually pinned tabs?
- How does the extension handle tabs with restricted content (e.g., `about:blank`, browser settings pages)?
- What happens when Safari crashes mid-rearrangement? (State recovery)
- How does the system handle tabs in private browsing mode differently?
- What happens when multiple tab associations have identical names?
- How does cleanup handle tabs with unsaved form data?
- What happens if a user tries to convert a group to native but Safari's native tab association API fails?
- How does the system handle category detection when a tab matches multiple categories with conflicting rules?
- What happens if workflow completion detection fails (e.g., auth popup doesn't close automatically)?
- How does the extension handle tabs that are part of native groups created outside the extension?
- What happens when a user manually closes a tab that was scheduled for category-based auto-close?

## Requirements *(mandatory)*

### Functional Requirements

#### Tab Grouping

- **FR-001**: System MUST allow users to create named tab associations with custom colors
- **FR-002**: System MUST persist tab associations and their membership across browser sessions
- **FR-003**: System MUST allow users to collapse/expand groups to show/hide contained tabs
- **FR-004**: System MUST support drag-and-drop to move tabs between groups or remove tabs from groups
- **FR-005**: System MUST allow users to rename or delete groups at any time
- **FR-006**: System MUST prevent duplicate group names within the same window

#### AI Analysis & Suggestions

- **FR-007**: System MUST analyze tab metadata (title, URL, domain) to generate grouping suggestions
- **FR-008**: System MUST provide explanations for why tabs were grouped together (e.g., "Same domain", "Similar keywords: Swift, iOS, development") displayed as a tooltip on hover over the group name
- **FR-009**: System MUST allow users to preview AI suggestions before applying them
- **FR-010**: System MUST support manual editing of AI-suggested groups before acceptance
- **FR-011**: System MUST handle analysis failures gracefully with fallback to manual grouping
- **FR-012**: System MUST complete analysis and suggestions within 5 seconds for up to 50 tabs. When >50 tabs are open, system MUST disable AI suggestions, display a prompt encouraging users to cleanup/consolidate tabs first, and require manual grouping

#### Context Highlighting

- **FR-013**: System MUST highlight tabs with similar content when a tab is selected
- **FR-014**: System MUST use multiple criteria for similarity: domain matching, keyword overlap, category classification
- **FR-015**: System MUST provide visual distinction (border color/style) for highlighted tabs
- **FR-016**: System MUST clear previous highlights when a new tab is selected
- **FR-017**: System MUST allow users to toggle context highlighting on/off via settings

#### Auto-Rearrangement

- **FR-018**: System MUST move highlighted tabs adjacent to the selected tab when auto-rearrange is enabled
- **FR-019**: System MUST respect pinned tabs by excluding them from rearrangement
- **FR-020**: System MUST preserve relative order of rearranged tabs (maintain their original sequence)
- **FR-021**: System MUST complete rearrangement within 1 second to avoid jarring UX. If timeout is exceeded, system MUST cancel the rearrangement operation, display a notification to the user, and maintain the current tab state
- **FR-022**: System MUST provide undo capability for recent rearrangements

#### Tab Cleanup

- **FR-023**: System MUST track tab view timestamps to identify inactive tabs
- **FR-024**: System MUST suggest cleanup for tabs inactive beyond the configured threshold (default: 30 minutes)
- **FR-025**: System MUST allow users to review and modify cleanup suggestions before execution
- **FR-026**: System MUST provide "Keep" marking to exclude specific tabs from cleanup suggestions
- **FR-027**: System MUST support configurable auto-close for tabs matching specific criteria (e.g., ungrouped tabs only)
- **FR-028**: System MUST maintain cleanup history for undo functionality (last 24 hours)

#### Category-Based Auto-Close

- **FR-038**: System MUST support predefined tab categories for auto-close: Auth/MFA, Shopping Confirmations, Social Media, Form Submissions
- **FR-039**: System MUST use domain pattern matching to identify tab categories (e.g., "*://accounts.*.com/signin*" for Auth)
- **FR-040**: System MUST use AI pattern recognition to supplement domain patterns for category detection
- **FR-041**: System MUST allow users to enable/disable auto-close per category independently in settings
- **FR-042**: System MUST detect workflow completion states (e.g., successful authentication, order confirmation) before triggering auto-close
- **FR-043**: System MUST auto-close Auth/MFA tabs within 5 seconds of workflow completion
- **FR-044**: System MUST auto-close Shopping Confirmation tabs within 10 seconds of detection
- **FR-045**: System MUST apply conservative precedence rules when tabs match multiple categories (Keep wins over Close)
- **FR-046**: System MUST log category-based auto-closures in cleanup history with category labels for restoration

#### Native Tab Group Integration

- **FR-047**: System MUST provide "Convert to Native" functionality triggered by double-clicking group header
- **FR-048**: System MUST create Safari native tab associations with emoji prefix (🔗) when converting dynamic groups
- **FR-049**: System MUST preserve group name and all tab memberships during native conversion
- **FR-050**: System MUST remove extension management from groups after native conversion (fully native thereafter)
- **FR-051**: System MUST provide "Convert All to Native" bulk operation for all dynamic groups
- **FR-052**: System MUST ensure native groups persist independently of extension (survive extension disable/uninstall)

#### Automatic Tab Assignment

- **FR-053**: System MUST automatically assign new tabs to existing dynamic groups based on domain matching
- **FR-054**: System MUST use cached domain→category mappings for known domains without re-running AI analysis
- **FR-055**: System MUST run AI analysis for unknown domains to determine category and group assignment
- **FR-056**: System MUST require minimum 70% similarity confidence before auto-assigning to a group
- **FR-057**: System MUST leave tabs ungrouped when no confident match exists (similarity < 70%)
- **FR-058**: System MUST assign to dynamic groups only (exclude native groups from auto-assignment)
- **FR-059**: System MUST provide user setting to enable/disable automatic tab assignment
- **FR-060**: System MUST cache domain→category mappings to improve performance and reduce AI computation

#### Privacy & Security

- **FR-029**: System MUST NOT transmit tab URLs or content to external servers without explicit user consent
- **FR-030**: System MUST store all data locally using Safari local storage (UserDefaults-backed, 5MB limit, JSON-encoded)
- **FR-031**: System MUST exclude private browsing tabs from AI analysis and cleanup suggestions
- **FR-032**: System MUST request only necessary Safari permissions (tabs, storage)
- **FR-033**: System MUST provide clear privacy policy explaining data usage and retention

#### Settings & Configuration

- **FR-034**: System MUST allow users to configure inactivity threshold for cleanup (15min to 4 hours)
- **FR-035**: System MUST allow users to enable/disable each feature independently (highlighting, auto-rearrange, cleanup)
- **FR-036**: System MUST support backup/restore of groups and settings
- **FR-037**: System MUST provide keyboard shortcuts for common actions (create group, trigger suggestions, toggle highlighting)

### Key Entities

- **TabAssociation**: Represents a named collection of tabs with properties (name, color, collapsed state, creation timestamp, isNative flag). Contains references to Tab IDs. Persists across sessions.
- **Tab**: Represents a Safari tab with properties (URL, title, domain, last viewed timestamp, pinned status, group membership, category). Tracked for context analysis and cleanup decisions.
- **ContextAnalysis**: Represents the AI's understanding of tab relationships with properties (similarity score, matching criteria, keywords, category). Generated on-demand for highlighting/grouping.
- **CleanupSuggestion**: Represents a recommendation to close tabs with properties (suggested tab IDs, inactivity duration, user decision history, closure reason - time-based or category-based). Used for cleanup workflow.
- **UserSettings**: Represents user preferences with properties (feature toggles, thresholds, keyboard shortcuts, privacy consents, auto-close category settings). Persists locally.
- **TabCategory**: Represents a predefined category for auto-close with properties (name, domain patterns, AI detection rules, auto-close delay, enabled status). Categories: Auth/MFA, Shopping, Social, Forms.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can organize 20 tabs into 3 groups in under 60 seconds using manual grouping
- **SC-002**: AI grouping suggestions achieve 80%+ user acceptance rate (measured by users clicking "Apply" vs "Reject")
- **SC-003**: Context highlighting identifies relevant tabs with 85%+ accuracy (user satisfaction survey: "Did highlights match your expectations?")
- **SC-004**: Average tab count per user decreases by 30% within first week of using cleanup features
- **SC-005**: System processes AI analysis for 50 tabs in under 5 seconds on standard hardware (2019+ MacBook)
- **SC-006**: 90%+ of users successfully create their first tab association without consulting documentation
- **SC-007**: Auto-rearrangement completes within 1 second for 100+ tab scenarios
- **SC-008**: Extension uses less than 100MB memory for managing 200 tabs
- **SC-009**: Zero data privacy incidents or unauthorized external transmissions (verified by audit)
- **SC-010**: Extension maintains 4.5+ star rating in Safari Extensions Gallery after 100+ reviews

## Assumptions *(optional)*

1. **Safari Extension APIs**: Assume Safari 15+ provides sufficient APIs for tab manipulation, group management, and content script injection. If limitations exist, features may need graceful degradation.

2. **AI/ML Processing**: Assume on-device processing using native Swift frameworks (CoreML, NaturalLanguage) for privacy compliance. External API calls (if needed) will require explicit user consent and fallback to rule-based heuristics.

3. **User Behavior**: Assume target users have 20-100+ tabs open regularly and struggle with tab management. Power users with 200+ tabs are secondary audience.

4. **Performance**: Assume users have 2019+ Mac hardware with sufficient resources. Older devices may experience slower AI analysis (acceptable with progress indicators).

5. **Privacy Expectations**: Assume users are privacy-conscious and will not accept cloud-based processing without clear benefits. Local-first architecture is non-negotiable per Safari Extension Constitution Principle II.

6. **Tab Content Access**: Assume Safari allows reading tab titles, URLs, and basic metadata without requiring broad "access your data" permissions. If full content access is needed for deep analysis, will implement as opt-in feature.

7. **Internationalization**: Assume initial release targets English-speaking users. AI analysis will use English keyword extraction. Subsequent releases will add i18n support per Constitution Principle VI.

## Out of Scope

- Cross-browser support (Chrome, Firefox) - Safari-only per project scope
- Cloud sync of tab associations across devices - privacy concerns, future enhancement
- Mobile Safari integration (iOS/iPadOS) - Phase 2 consideration
- Tab session history/timeline view - separate feature
- Integration with third-party services (Notion, Evernote for saving tabs) - future plugin system
- Tab preview thumbnails - performance/memory concerns
- Voice commands for tab organization - future enhancement
- Sharing tab associations with other users - privacy/security complexity
