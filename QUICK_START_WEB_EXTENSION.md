# TabCab Web Extension - Quick Start Guide

## Build & Run

### Option 1: Xcode (Recommended)
```bash
cd /Users/pmouli/GitHub.nosync/tab-cab/TabCabWebExtension/TabCab
open TabCab.xcodeproj
```
Press ⌘R to build and run.

### Option 2: Command Line
```bash
cd /Users/pmouli/GitHub.nosync/tab-cab/TabCabWebExtension/TabCab
xcodebuild -scheme TabCab -configuration Debug build
open /Users/pmouli/Library/Developer/Xcode/DerivedData/TabCab-*/Build/Products/Debug/TabCab.app
```

## Enable in Safari

1. Run the TabCab app (it registers the extension)
2. Open Safari
3. Safari → Settings → Extensions
4. Enable "TabCab Extension"
5. Click the toolbar icon to open the popup

## Testing the Extension

### Drag-Drop Scenarios

**Create New Association:**
1. Have 2+ ungrouped tabs
2. Drag one tab onto another ungrouped tab
3. You'll see a naming dialog
4. Enter name and color
5. New association appears

**Add to Existing Association:**
1. Drag an ungrouped tab onto an association card
2. Tab is added silently (no dialog)
3. Association updates immediately

**Remove from Association:**
1. Drag a tab from association to empty area
2. Tab moves to "Ungrouped Tabs" section

**Merge Associations:**
1. Drag one association header onto another
2. Confirmation dialog appears
3. Confirm to merge

### Storage Persistence
- Close popup and reopen → associations persist
- Close Safari and reopen → data still there
- Close tab → association automatically updates

### Search/Filter
- Type in search box to filter tabs and associations
- Filters by tab title and association name

## Debugging

### Safari Web Inspector
1. Right-click extension icon
2. "Inspect Web Extension"
3. Console shows logs from popup.js and background.js

### Xcode Console
- Shows logs from SafariWebExtensionHandler.swift
- Look for "Received message from browser.runtime.sendNativeMessage"

## Project Structure

```
TabCabWebExtension/TabCab/
├── TabCab.xcodeproj/              # Open this in Xcode
├── TabCab/                        # macOS host app
│   ├── AppDelegate.swift
│   ├── ViewController.swift
│   └── Assets.xcassets/
└── TabCab Extension/              # Safari extension
    ├── SafariWebExtensionHandler.swift
    └── Resources/
        ├── manifest.json          # Extension config
        ├── popup.html            # UI structure
        ├── popup.css             # Styling
        ├── popup.js              # Main logic
        └── background.js         # Service worker
```

## Making Changes

### Edit Web Extension Code
1. Modify files in `TabCab Extension/Resources/`
2. Rebuild in Xcode (⌘B)
3. Quit and relaunch TabCab app
4. Refresh popup in Safari

### Edit Native Handler
1. Modify `SafariWebExtensionHandler.swift`
2. Rebuild in Xcode
3. Quit and relaunch app

## Common Issues

**Extension doesn't appear in Safari:**
- Make sure TabCab.app is running
- Check Safari → Settings → Extensions
- Try quitting Safari completely and reopening

**Changes not showing:**
- Rebuild the project (⌘B)
- Quit and relaunch TabCab.app
- Hard refresh popup (⌘⇧R in Web Inspector)

**Drag-drop not working:**
- Check Web Inspector console for errors
- Verify icons are loading (check Network tab)

## Next Steps

Once you've tested the web extension and confirmed it works:
1. Verify drag-drop creates associations
2. Test storage persistence
3. Try search/filter functionality
4. Check dark mode appearance

Then we can proceed to **Phase 2B**:
- Native AI engine integration
- macOS Accessibility API for tab control
- CoreML model for intelligent grouping

## Documentation

- `WEB_EXTENSION_MIGRATION.md` - Detailed migration guide
- `PHASE_2_ARCHITECTURE.md` - Architecture overview
- `PHASE_2A_COMPLETION.md` - Completion report
- `PHASE_2A_SUMMARY.md` - Summary of changes

---

**Status**: Ready for testing ✅
**Platform**: macOS 26+ (for development)
**Safari**: Version 18+ required
