# Accessibility Testing Guide: US1 (Manual Tab Association)

**Task**: T046 - Manual accessibility testing with VoiceOver for all US1 UI components
**Purpose**: Ensure drag-and-drop tab association features are fully accessible to VoiceOver users
**Platform**: macOS Safari Extension

---

## Overview

This guide provides step-by-step instructions for manually testing the Tab Organizer extension's accessibility with VoiceOver. All US1 features must be fully accessible per **Constitution Principle VI**.

---

## Prerequisites

1. **Enable VoiceOver**: System Settings > Accessibility > VoiceOver > Enable (or press `Cmd + F5`)
2. **Build and run** TabCab extension in Safari
3. **Open Safari** with 10+ tabs across different domains
4. **Enable extension**: Safari > Settings > Extensions > TabCab

---

## Test Suite

### Test 1: Extension Popover Navigation

**Objective**: Verify VoiceOver users can navigate the main UI

**Steps**:
1. Click the TabCab extension toolbar button
2. Press `VO + Right Arrow` to navigate through elements
3. Verify each element is announced correctly:
   - Search field: "Search groups, text field"
   - Create button: "Create new group, button"
   - Settings button: "Settings, button"

**Expected Results**:
- ✅ All interactive elements have clear labels
- ✅ Focus order is logical (left-to-right, top-to-bottom)
- ✅ No unlabeled buttons or fields

---

### Test 2: Tab Cards Accessibility

**Objective**: Verify individual tab cards are accessible

**Steps**:
1. Navigate to an ungrouped tab card using `VO + Right Arrow`
2. Listen for the announcement
3. Activate the card with `VO + Space`

**Expected Announcements**:
- Tab title and domain (e.g., "GitHub, github.com")
- Selection state: "Selected" or "Not selected"
- Hint: "Double tap to select" or "Double tap to deselect"
- Navigate button: "Navigate to tab, button"

**Expected Results**:
- ✅ Tab title and domain are announced
- ✅ Selection state is clear
- ✅ All buttons within card are accessible
- ✅ accessibilityIdentifier includes tab ID (e.g., "TabCard_tab-1")

---

### Test 3: Association Header Accessibility

**Objective**: Verify group headers are accessible

**Steps**:
1. Create a group with 3+ tabs
2. Navigate to the group header using VoiceOver
3. Listen for the announcement
4. Activate collapse/expand button

**Expected Announcements**:
- Group name and tab count (e.g., "Group Work, 3 tabs, expanded")
- Collapse button: "Collapse group, button" or "Expand group, button"
- Edit button (on hover): "Edit group, button"
- Delete button (on hover): "Delete group, button"
- Hint: "Double click to convert to native tab association, or use buttons to edit or delete"

**Expected Results**:
- ✅ Group name, count, and state announced clearly
- ✅ All action buttons have labels
- ✅ Collapse/expand state changes are announced
- ✅ accessibilityIdentifier includes group ID (e.g., "GroupHeader_UUID")

---

### Test 4: Drag-and-Drop Accessibility (CRITICAL)

**Objective**: Verify drag-and-drop is accessible to VoiceOver users

**Note**: Standard drag-and-drop gestures may not work with VoiceOver. Verify alternative workflows exist.

#### Test 4a: Create New Association

**Steps (Alternative to Drag-and-Drop)**:
1. Select two ungrouped tabs by activating their selection circles
2. Use "Create Group" button
3. Enter group name in dialog
4. Verify new group is created with both tabs

**Expected Results**:
- ✅ Selection mechanism is accessible
- ✅ Multi-select is announced (e.g., "2 tabs selected")
- ✅ Dialog for naming group is accessible
- ✅ Confirmation is announced

#### Test 4b: Add Tab to Existing Association

**Steps**:
1. Select an ungrouped tab
2. Navigate to a group header
3. Activate "Add to Group" action (if available)
4. Verify tab is added to group

**Expected Results**:
- ✅ Action is discoverable via VoiceOver
- ✅ Confirmation is announced
- ✅ Group tab count updates

#### Test 4c: Remove Tab from Association

**Steps**:
1. Navigate to a tab within a group
2. Activate "Remove from Group" action
3. Verify tab becomes ungrouped

**Expected Results**:
- ✅ Removal action is accessible
- ✅ Confirmation is announced
- ✅ Tab moves to ungrouped section

---

### Test 5: Search Functionality

**Objective**: Verify search is accessible

**Steps**:
1. Navigate to search field
2. Type "Work" (for a group named "Work")
3. Verify filtered results are announced

**Expected Announcements**:
- "Search groups, text field"
- When typing: Results update dynamically
- Clear button appears: "Clear search, button"

**Expected Results**:
- ✅ Search field is labeled
- ✅ Filter updates are announced
- ✅ Clear button is accessible

---

### Test 6: Dialogs and Sheets

#### Test 6a: New Association Dialog

**Steps**:
1. Trigger new association creation
2. Navigate dialog fields with VoiceOver
3. Submit dialog

**Expected Announcements**:
- Dialog title: "Create New Association" or similar
- Name field: "Association name, text field"
- Color picker: "Association color, button" or similar
- Cancel button: "Cancel, button"
- Create button: "Create, button"

**Expected Results**:
- ✅ All form fields have labels
- ✅ Focus trap works (can't navigate outside dialog)
- ✅ Escape key closes dialog (announced)

#### Test 6b: Merge Associations Dialog (T042.1)

**Steps**:
1. Create two groups
2. Trigger merge (if accessible via keyboard/VoiceOver)
3. Navigate merge confirmation dialog

**Expected Announcements**:
- Dialog title: "Merge Associations"
- Source group: "From: [Group Name], [X] tabs"
- Target group: "Into: [Group Name], [Y] tabs"
- Warning: Deletion warning announced
- Cancel button: "Cancel, button"
- Merge button: "Merge Associations, button"

**Expected Results**:
- ✅ Merge intent is clear
- ✅ Warning is announced
- ✅ All controls are accessible

---

### Test 7: Empty States

**Objective**: Verify empty states are accessible

#### Test 7a: No Groups Exist

**Steps**:
1. Delete all groups
2. Navigate empty state with VoiceOver

**Expected Announcements**:
- "No Tab Groups"
- "Create a group to organize your tabs"
- "Create first group, button"

**Expected Results**:
- ✅ Empty state message is announced
- ✅ Call-to-action button is accessible

#### Test 7b: Empty Group

**Steps**:
1. Create a group with no tabs
2. Expand the group

**Expected Announcements**:
- "Empty group, drag tabs here to add"

**Expected Results**:
- ✅ Empty state is announced
- ✅ Instructions are clear

---

### Test 8: Error Handling

**Objective**: Verify errors are accessible

**Steps**:
1. Trigger an error (e.g., duplicate group name)
2. Listen for error announcement

**Expected Announcements**:
- Error message text (e.g., "A group with this name already exists")
- Alert type: "Alert" or "Error"

**Expected Results**:
- ✅ Errors are announced immediately
- ✅ Error text is descriptive
- ✅ Dismiss action is accessible

---

### Test 9: Loading States

**Objective**: Verify loading states are accessible

**Steps**:
1. Trigger extension load
2. Listen for loading announcement

**Expected Announcements**:
- "Loading groups..." with progress indicator

**Expected Results**:
- ✅ Loading state is announced
- ✅ Progress updates are communicated

---

### Test 10: Settings View

**Objective**: Verify settings are accessible

**Steps**:
1. Navigate to Settings
2. Navigate all controls with VoiceOver

**Expected Announcements**:
- All toggles have clear labels
- Current state is announced (e.g., "Context highlighting, on, checkbox")

**Expected Results**:
- ✅ All controls have labels
- ✅ States are announced
- ✅ Changes are confirmed

---

## Accessibility Checklist Summary

After completing all tests, verify:

- [ ] **Labels**: All interactive elements have `accessibilityLabel`
- [ ] **Hints**: Complex actions have `accessibilityHint`
- [ ] **Identifiers**: All components have `accessibilityIdentifier` for testing
- [ ] **Focus Order**: Logical tab order (left-to-right, top-to-bottom)
- [ ] **Announcements**: State changes are announced
- [ ] **Alternative Interactions**: Drag-and-drop has keyboard/VoiceOver alternatives
- [ ] **Error Messages**: Errors are announced clearly
- [ ] **Empty States**: Empty views have descriptive messages
- [ ] **Dialogs**: Focus traps work, dialogs are escapable
- [ ] **Dynamic Content**: Updates are announced (e.g., "X tabs selected")

---

## Known Limitations

### Drag-and-Drop Gestures

**Issue**: Standard SwiftUI drag-and-drop may not be fully accessible with VoiceOver.

**Mitigations**:
1. Provide selection-based workflow (select tabs, then "Add to Group")
2. Provide context menu actions (right-click on tab → "Add to [Group Name]")
3. Provide keyboard shortcuts (future enhancement)

**Action Required**: If drag-and-drop is not accessible during testing, file an issue and implement alternative workflows.

---

## Reporting Issues

If any test fails, document:

1. **Test ID** (e.g., Test 4a)
2. **Expected Behavior**: What should happen
3. **Actual Behavior**: What actually happens
4. **VoiceOver Announcement**: Exact text announced
5. **Screenshot/Video**: If possible
6. **Suggested Fix**: Accessibility modifier to add

---

## Filing the Issue

Create a GitHub issue with:

```markdown
## Accessibility Issue: [Component Name]

**Test**: [Test ID and Name]
**Component**: [File path]
**Priority**: High (Constitution Principle VI)

### Expected Behavior
[Clear description]

### Actual Behavior
[What VoiceOver announced or didn't announce]

### VoiceOver Announcement
> "[Exact text announced]"

### Suggested Fix
Add `.accessibilityLabel("...")` to [component] at [file]:[line]

### Constitution Reference
Principle VI: Accessibility & Internationalization Standards
```

---

## Completion Criteria

T046 is complete when:

1. ✅ All 10 tests pass
2. ✅ Accessibility checklist is 100% complete
3. ✅ Any issues are documented and filed
4. ✅ Alternative workflows exist for drag-and-drop (if needed)

---

## Resources

- [Apple VoiceOver User Guide](https://support.apple.com/guide/voiceover/welcome/mac)
- [SwiftUI Accessibility Modifiers](https://developer.apple.com/documentation/swiftui/view-accessibility)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- Project Constitution: `.specify/memory/constitution.md` (Principle VI)

---

**Next Steps**: Run through all 10 tests with VoiceOver enabled. Document results. File issues for any failures.
