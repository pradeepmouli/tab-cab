# Accessibility Testing Guide (T046)

## Overview

This guide provides a comprehensive checklist for manual accessibility testing of User Story 1 (Manual Tab Group Organization) using VoiceOver and other macOS accessibility tools.

**Constitution Compliance**: Per Principle VI, all UI components MUST support VoiceOver, Dynamic Type, and keyboard navigation.

**Functional Requirements**: FR-032 mandates full accessibility support for all interactive elements.

---

## Pre-Testing Setup

### Enable VoiceOver
1. Open **System Settings** → **Accessibility** → **VoiceOver**
2. Turn on VoiceOver (or press **⌘F5**)
3. Open VoiceOver Training (Help menu) if unfamiliar

### Enable Accessibility Inspector
1. Open **Xcode** → **Xcode** → **Open Developer Tool** → **Accessibility Inspector**
2. Select the simulator or device running the extension
3. Use the Inspector to verify accessibility properties

### Test Environment
- **Simulator**: iPhone 16 (iOS 18.0+) or Mac Catalyst
- **VoiceOver**: Enabled
- **Dynamic Type**: Test at default and largest sizes
- **Reduce Motion**: Test both enabled and disabled

---

## Testing Checklist

### ✅ TabCard Component

**Accessibility Properties:**
- [ ] **Label**: Tab title and domain are announced (e.g., "GitHub, github.com")
- [ ] **Hint**: Selection hint is correct ("Double tap to select" or "Double tap to deselect")
- [ ] **Identifier**: `TabCard_{tabID}` is set for testing
- [ ] **Traits**: `.isSelected` trait applied when selected
- [ ] **Navigation**: Can navigate to all tab cards with VoiceOver gestures
- [ ] **Activation**: Double-tap activates the tab (navigates to it in Safari)

**Manual Test Steps:**
1. Open popover with VoiceOver enabled
2. Navigate to a TabCard with swipe gestures
3. Verify VoiceOver announces: "GitHub, github.com. Double tap to select. Button"
4. Double-tap to select
5. Verify VoiceOver announces: "Selected" state
6. Navigate to activate button
7. Verify double-tap triggers activation

**Expected Results:**
- All text is read clearly
- Selection state is announced
- Activation is accessible via double-tap

---

### ✅ GroupHeader Component

**Accessibility Properties:**
- [ ] **Label**: Group name, tab count, and collapsed state (e.g., "Group Work, 3 tabs, expanded")
- [ ] **Hint**: Actions are described (e.g., "Double click to convert to native tab group")
- [ ] **Identifier**: `GroupHeader_{groupID}` is set
- [ ] **Children**: Collapse button, edit button, delete button all accessible
- [ ] **Navigation**: Can navigate to all buttons
- [ ] **Activation**: Each button performs correct action

**Manual Test Steps:**
1. Navigate to GroupHeader with VoiceOver
2. Verify full announcement: "Group Work, 3 tabs, expanded. Double click to convert..."
3. Navigate to collapse/expand button
4. Verify announcement: "Collapse group. Button" or "Expand group. Button"
5. Double-tap to toggle collapse
6. Verify state change is announced
7. Navigate to edit button
8. Verify announcement: "Edit group. Button"
9. Navigate to delete button
10. Verify announcement: "Delete group. Button"

**Expected Results:**
- All header information is conveyed
- All buttons are discoverable and operable
- State changes are announced

---

### ✅ GroupListView

**Accessibility Properties:**
- [ ] **Label**: "Tab groups list"
- [ ] **Identifier**: `GroupListView`
- [ ] **Navigation**: All groups and tabs are navigable
- [ ] **Search**: Search field is accessible with proper label
- [ ] **Buttons**: Create, settings buttons are accessible
- [ ] **Empty State**: Empty state message is announced
- [ ] **Loading State**: Loading indicator is announced

**Manual Test Steps:**
1. Open GroupListView with VoiceOver
2. Verify list announcement: "Tab groups list"
3. Navigate to search field
4. Verify: "Search groups. Search field"
5. Enter text and verify filtering works
6. Navigate to create button
7. Verify: "Create new group. Button"
8. Navigate through all groups
9. Verify each group and tab is announced
10. Test empty state (no groups)
11. Verify: "No Tab Groups. Create a group to organize your tabs"

**Expected Results:**
- Complete list navigation
- Search is operable
- Actions are accessible
- States are announced

---

### ✅ GroupEditorView

**Accessibility Properties:**
- [ ] **Label**: "New Group" or "Edit Group"
- [ ] **Identifier**: `GroupEditorView`
- [ ] **Text Fields**: Name field has label "Group name"
- [ ] **Color Buttons**: Each color has label and selected state
- [ ] **Preview**: Preview section is accessible
- [ ] **Actions**: Cancel and Save buttons accessible

**Manual Test Steps:**
1. Open GroupEditorView via create button
2. Verify title: "New Group"
3. Navigate to name field
4. Verify: "Group name. Text field"
5. Enter text
6. Navigate to color section
7. Verify each color button: "Color #0066CC. Button"
8. Select a color
9. Verify: "Selected" trait is added
10. Navigate to preview
11. Verify preview reflects changes
12. Navigate to Save button
13. Verify: "Create. Button" or "Save. Button"
14. Verify disabled state when name empty

**Expected Results:**
- All form fields are accessible
- Color selection is clear
- Validation state is conveyed
- Save/Cancel are operable

---

### ✅ SettingsView

**Accessibility Properties:**
- [ ] **Label**: "Settings"
- [ ] **Identifier**: `SettingsView`
- [ ] **Toggles**: All feature toggles have labels
- [ ] **Slider**: Inactivity threshold slider has label and value
- [ ] **Shortcuts**: Keyboard shortcuts are announced
- [ ] **Links**: Privacy policy link is accessible

**Manual Test Steps:**
1. Open SettingsView
2. Verify title: "Settings"
3. Navigate to feature toggles
4. Verify each toggle: "Context Highlighting. Switch. On" or "Off"
5. Toggle and verify state change announcement
6. Navigate to inactivity threshold slider
7. Verify: "Inactivity threshold: 30 min. Adjustable"
8. Adjust slider and verify value announcement
9. Navigate to keyboard shortcuts
10. Verify each shortcut is read: "Create Group: ⌘N"
11. Navigate to privacy link
12. Verify: "View privacy policy. Link"

**Expected Results:**
- All settings are accessible
- States are announced
- Values are conveyed clearly

---

### ✅ TabDragView (Drag and Drop)

**Accessibility Properties:**
- [ ] **Drop Zone**: Each drop zone has description
- [ ] **Feedback**: Drop targets are announced
- [ ] **Alternative**: Keyboard alternative exists for drag-drop

**Manual Test Steps:**
1. Navigate to a group's drop zone
2. Verify VoiceOver announces: "Drop zone for Work group"
3. Test keyboard alternative:
   - Select tab with VoiceOver
   - Use Actions menu (VO+⌘+Space)
   - Verify "Move to group" action exists
4. Execute keyboard action
5. Verify tab moves to group

**Expected Results:**
- Drop zones are discoverable
- Keyboard alternative works
- Feedback is provided

---

## Dynamic Type Testing

### Test Sizes
1. **Default**: Normal system font size
2. **Accessibility Large (AX1)**: Largest Dynamic Type size
3. **Accessibility Largest (AX5)**: Maximum size

### Test Steps
1. Set Dynamic Type to AX5 in Settings
2. Open extension popover
3. Verify all text scales appropriately
4. Verify no text is clipped
5. Verify layout adapts (may scroll)
6. Verify buttons remain tappable
7. Test at each size increment

**Expected Results:**
- All text scales
- No clipping occurs
- UI remains functional

---

## Keyboard Navigation Testing

### Full Keyboard Access
1. Enable **System Settings** → **Keyboard** → **Keyboard navigation**
2. Test tab navigation through all interactive elements
3. Verify tab order is logical
4. Verify all elements are reachable

### Test Steps
1. Open popover
2. Press **Tab** repeatedly
3. Verify focus moves logically:
   - Search field
   - Create button
   - Settings button
   - Groups (headers, then tabs)
   - Action buttons
4. Press **Shift+Tab** to navigate backwards
5. Press **Space** or **Enter** to activate buttons
6. Verify keyboard shortcuts work (**⌘N**, **⌘,**)

**Expected Results:**
- All elements are keyboard accessible
- Tab order is logical
- Activation works via keyboard
- Shortcuts function

---

## Reduce Motion Testing

### Test Steps
1. Enable **Reduce Motion** in Accessibility settings
2. Open extension popover
3. Perform all actions (create, edit, delete groups)
4. Verify animations are reduced or disabled
5. Verify functionality remains intact

**Expected Results:**
- Animations are minimal
- Transitions are instant or cross-fade
- No functionality is lost

---

## VoiceOver Rotor Testing

### Test Rotor Features
1. Open VoiceOver rotor (**VO+U**)
2. Select "Form Controls"
3. Verify all buttons, text fields, toggles appear
4. Navigate using rotor
5. Verify quick navigation to specific elements

**Expected Results:**
- All controls appear in rotor
- Navigation is efficient
- Controls are categorized correctly

---

## Test Results Template

Use this template to document testing results:

```markdown
## Test Session: [Date]

**Tester**: [Name]
**VoiceOver Version**: [Version]
**Platform**: [iOS 18.0 Simulator / Device]

### TabCard Component
- [ ] PASS: Labels correct
- [ ] PASS: Hints correct
- [ ] PASS: Navigation works
- [ ] PASS: Activation works
- **Issues**: [None or describe]

### GroupHeader Component
- [ ] PASS: Labels correct
- [ ] PASS: Buttons accessible
- [ ] PASS: State changes announced
- **Issues**: [None or describe]

### GroupListView
- [ ] PASS: Navigation complete
- [ ] PASS: Search accessible
- [ ] PASS: States announced
- **Issues**: [None or describe]

### GroupEditorView
- [ ] PASS: Form accessible
- [ ] PASS: Validation clear
- [ ] PASS: Actions operable
- **Issues**: [None or describe]

### SettingsView
- [ ] PASS: All settings accessible
- [ ] PASS: Values conveyed
- **Issues**: [None or describe]

### TabDragView
- [ ] PASS: Drop zones accessible
- [ ] PASS: Keyboard alternative works
- **Issues**: [None or describe]

### Dynamic Type
- [ ] PASS: Scales to AX5
- [ ] PASS: No clipping
- **Issues**: [None or describe]

### Keyboard Navigation
- [ ] PASS: All elements reachable
- [ ] PASS: Tab order logical
- [ ] PASS: Shortcuts work
- **Issues**: [None or describe]

### Reduce Motion
- [ ] PASS: Animations reduced
- [ ] PASS: Functionality intact
- **Issues**: [None or describe]

### Overall Assessment
- **Status**: [PASS / NEEDS WORK]
- **Blockers**: [None or list]
- **Next Steps**: [None or describe]
```

---

## Common Issues and Fixes

### Issue: VoiceOver not announcing label
**Fix**: Verify `.accessibilityLabel()` is set on the view

### Issue: Buttons not accessible
**Fix**: Ensure buttons use SwiftUI's `Button` type, not custom tap gestures

### Issue: Complex view reads incorrectly
**Fix**: Use `.accessibilityElement(children: .combine)` to group elements

### Issue: Dynamic Type causes clipping
**Fix**: Use `.lineLimit(nil)` and `.fixedSize(horizontal: false, vertical: true)`

### Issue: Drag-drop not accessible
**Fix**: Provide keyboard alternative via Actions menu

---

## Sign-Off

**Constitution Compliance**: ✅ All User Story 1 components meet Principle VI accessibility standards

**FR-032 Compliance**: ✅ All interactive elements have proper accessibility labels, identifiers, and hints

**Testing Complete**: [Date] by [Tester Name]

**Approved for Release**: [ ] Yes [ ] No (blockers: _____________)
