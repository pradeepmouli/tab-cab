# TabCab Safari Extension - Testing Guide

This guide covers how to test the TabCab Safari extension, including the new drag-and-drop functionality.

## Prerequisites

1. **macOS 26.0+** (for Liquid Glass effects and latest Safari features)
2. **Safari 26.0+**
3. **Xcode 16.0+**

## Setup Instructions

### 1. Build and Run the App

```bash
# Build the app (already done if you just built)
# The app is located at:
# /Users/pmouli/Library/Developer/Xcode/DerivedData/TabCab-*/Build/Products/Debug/TabCab.app
```

### 2. Enable the Safari Extension

1. **Launch Safari** (if not already running)
2. Open **Safari → Settings** (⌘,)
3. Go to the **Extensions** tab
4. Look for **TabCab** in the list
5. **Check the box** to enable it
6. If you don't see TabCab:
   - Make sure the TabCab.app is running
   - Try quitting and relaunching Safari
   - Check Safari → Develop → Allow Unsigned Extensions (for development)

### 3. Grant Permissions

When you first enable the extension, Safari may ask for permissions:
- ✅ Allow "TabCab" to access browsing data
- ✅ Allow "TabCab" to modify web pages (if prompted)

### 4. Access the Extension

- Click the **TabCab icon** in Safari's toolbar (usually in the top-right)
- If you don't see the icon, check Safari → Settings → Extensions and ensure it's enabled
- The extension popover should appear showing your tab associations

## Testing Checklist

### Basic Functionality

- [ ] Extension popover opens when clicking the toolbar icon
- [ ] Current tabs are displayed in the "Ungrouped Tabs" section
- [ ] Extension UI uses Liquid Glass effects (macOS 26.0+)

### Manual Tab Association (T042 - Drag-and-Drop)

#### Creating New Associations

1. **Drag ungrouped tab onto another ungrouped tab**:
   - [ ] Naming dialog appears
   - [ ] Dialog suggests intelligent name based on domains
   - [ ] Can customize name
   - [ ] Can select color from palette
   - [ ] "Create" button creates the association
   - [ ] Both tabs appear under the new association
   - [ ] "Cancel" button dismisses dialog without creating

#### Adding to Existing Associations

2. **Drag ungrouped tab onto a tab in an existing association**:
   - [ ] Tab is added silently (NO dialog appears)
   - [ ] Tab appears in the association immediately
   - [ ] Tab is removed from "Ungrouped Tabs"

3. **Drag tab from one association to another**:
   - [ ] Tab is moved silently (NO dialog appears)
   - [ ] Tab is removed from source association
   - [ ] Tab is added to target association

#### Removing from Associations

4. **Drag tab to empty area**:
   - [ ] Tab is removed from its association
   - [ ] Tab appears in "Ungrouped Tabs" section
   - [ ] Association remains (even if empty)

### Association Merge (T042.1)

5. **Drag association header onto another association header**:
   - [ ] Merge confirmation dialog appears
   - [ ] Dialog shows both association names and tab counts
   - [ ] Dialog shows warning about source deletion
   - [ ] "Merge Associations" button combines them
   - [ ] All tabs from source are added to target
   - [ ] Source association is deleted
   - [ ] "Cancel" button dismisses without merging

### Association Management (Existing Functionality)

6. **Collapse/Expand**:
   - [ ] Clicking chevron toggles collapse state
   - [ ] Collapsed associations hide their tabs
   - [ ] State persists across popover open/close

7. **Edit Association**:
   - [ ] Clicking edit button opens edit dialog
   - [ ] Can change name
   - [ ] Can change color
   - [ ] Changes are saved and reflected immediately

8. **Delete Association**:
   - [ ] Clicking delete button shows confirmation
   - [ ] Confirmation dialog warns about not closing tabs
   - [ ] "Delete" button removes association
   - [ ] Tabs become ungrouped
   - [ ] "Cancel" button dismisses without deleting

9. **Search**:
   - [ ] Typing in search field filters associations
   - [ ] Search matches association names
   - [ ] Clear button (X) clears search

### Accessibility (T046 - Manual Testing Required)

10. **VoiceOver Support**:
    - [ ] Enable VoiceOver (⌘F5)
    - [ ] All interactive elements are announced
    - [ ] Tab cards announce title and domain
    - [ ] Association headers announce name and tab count
    - [ ] Drag gestures have accessible alternatives (edit dialogs)
    - [ ] All buttons have clear labels
    - [ ] Dialogs are properly announced

### Persistence

11. **Data Persistence**:
    - [ ] Create several associations
    - [ ] Close the extension popover
    - [ ] Reopen the popover - associations should persist
    - [ ] Quit Safari
    - [ ] Relaunch Safari - associations should persist
    - [ ] Quit TabCab.app
    - [ ] Relaunch TabCab.app and Safari - associations should persist

### Error Handling

12. **Edge Cases**:
    - [ ] Drag tab onto itself (should do nothing)
    - [ ] Drag association onto itself (should do nothing)
    - [ ] Create association with empty name (should be disabled)
    - [ ] Merge association with 0 tabs
    - [ ] Delete all associations (UI should show empty state)

## Debugging

### Extension Not Appearing

If the extension doesn't appear in Safari:

1. **Check Safari Settings**:
   - Safari → Settings → Extensions
   - Look for "TabCab" and ensure it's checked

2. **Enable Unsigned Extensions** (Development Only):
   - Safari → Develop → Allow Unsigned Extensions
   - Restart Safari

3. **Verify App is Running**:
   - The TabCab.app must be running for the extension to work
   - Check Activity Monitor for "TabCab"

4. **Clean and Rebuild**:
   ```bash
   # From Xcode or command line
   xcodebuild clean -workspace TabCab.xcworkspace -scheme TabCab
   xcodebuild build -workspace TabCab.xcworkspace -scheme TabCab
   ```

### Extension Crashes or Doesn't Load

1. **Check Console**:
   - Open Console.app
   - Filter for "TabCab" or "Safari"
   - Look for error messages

2. **Check Extension Logs**:
   - Safari → Develop → Web Extension Background Content → TabCab
   - Check the console for JavaScript errors

3. **Verify Entitlements**:
   - Check `Config/SwiftTemplateMacOS.entitlements`
   - Ensure Safari extension entitlements are present

### UI Not Updating

1. **Force Reload**:
   - Close the popover
   - Reopen the popover
   - Changes should be reflected

2. **Check UserDefaults**:
   - Extension stores data in UserDefaults
   - Open Terminal and check:
   ```bash
   defaults read com.yourorg.TabCab
   ```

## Known Limitations (Current Implementation)

1. **Tab Tracking**: The extension currently tracks tabs but doesn't actively monitor tab changes (Phase 2 - US2)
2. **AI Suggestions**: AI-powered tab organization is not yet implemented (Phase 3-5)
3. **Native Tab Groups**: Converting to Safari's native tab groups is not yet implemented (Phase 8 - US7)

## Next Steps

After manual testing, the following automated tests should be written:

- [ ] **T044**: UI component tests for drag-and-drop interactions
- [ ] **T045**: Integration tests for manual association workflows
- [ ] **T046**: Automated accessibility tests

## Reporting Issues

When reporting issues, please include:

1. **Steps to reproduce**
2. **Expected behavior**
3. **Actual behavior**
4. **Console logs** (from Console.app)
5. **Safari version** (`Safari → About Safari`)
6. **macOS version** (`About This Mac`)
7. **TabCab app version** (shown in About dialog)

## Tips for Effective Testing

- **Use multiple tabs**: Open 10-15 tabs from different domains for realistic testing
- **Test with real workflows**: Try organizing your actual browsing tabs
- **Test edge cases**: Empty associations, single-tab associations, many tabs
- **Test interactions**: Try various drag-and-drop combinations
- **Test persistence**: Verify data survives app/Safari restarts
- **Test accessibility**: Use VoiceOver to ensure all features are accessible

---

**Last Updated**: 2025-12-26
**Implemented Features**: T042 (Drag-and-Drop), T042.1 (Association Merge)
**Next Phase**: T044-T046 (Testing)
