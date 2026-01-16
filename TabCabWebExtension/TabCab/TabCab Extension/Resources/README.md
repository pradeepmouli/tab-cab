# TabCab Web Extension Source

This directory contains the source files for the TabCab Safari Web Extension.

## Structure

- `manifest.json` - Extension configuration and permissions
- `popup.html` - Main UI for the extension popup
- `popup.css` - Styling with light/dark mode support
- `popup.js` - UI logic and drag-drop functionality
- `background.js` - Background service worker for tab monitoring
- `icons/` - Extension icons (16x16, 32x32, 48x48, 96x96, 128x128)

## Features Implemented

### Phase 2A (Current)
- ✅ Web extension structure
- ✅ Modern manifest v3 format
- ✅ Drag-and-drop UI for tab associations
- ✅ Tab-on-tab → Create new association
- ✅ Tab-on-association → Add to association
- ✅ Association-on-association → Merge associations
- ✅ Search/filter functionality
- ✅ Light/dark mode support
- ✅ Storage for associations

### Phase 2B (Pending)
- ⏳ Native app integration via XPC
- ⏳ AI grouping with CoreML
- ⏳ macOS Accessibility API for tab control
- ⏳ CloudKit sync

## Converting to Xcode Project

To convert this web extension to an Xcode project:

```bash
xcrun safari-web-extension-converter \
    --app-name TabCab \
    --bundle-identifier com.yourorg.tabcab \
    --swift \
    --macos-only \
    --copy-resources \
    --project-location /Users/pmouli/GitHub.nosync/tab-cab/TabCabWebExtension \
    /Users/pmouli/GitHub.nosync/tab-cab/WebExtensionSource
```

## Icons

The extension requires the following icon sizes:
- 16x16 - Toolbar icon
- 32x32 - Retina toolbar icon
- 48x48 - Extension management
- 96x96 - Retina extension management
- 128x128 - Install confirmation

Currently using placeholder icons. Production icons should be added before release.
