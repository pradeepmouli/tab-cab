# Extension Icon Assets

## Required Icon Files

The Safari Extension requires icon assets in the following sizes:

### Toolbar Icon
- **icon.png**: 32x32px @ 1x (referenced in Info.plist)
- **icon@2x.png**: 64x64px @ 2x
- **icon@3x.png**: 96x96px @ 3x (optional)

### App Store Icon (if publishing)
- **AppIcon.png**: 512x512px
- **AppIcon@2x.png**: 1024x1024px

## Design Guidelines

### Visual Identity
- **Theme**: Tab organization, grouping, sorting
- **Colors**: Use macOS system colors or brand palette
- **Style**: Simple, recognizable, works in light/dark mode

### Suggested Icon Concepts
1. **Stacked Layers**: Three horizontal rectangles representing grouped tabs
2. **Folder with Tabs**: Folder icon with tab dividers
3. **Grid Organization**: 3x3 grid showing organized layout
4. **AI Brain + Tabs**: Abstract brain/sparkle + tab representation

### Technical Requirements
- **Format**: PNG with transparency
- **Color Mode**: RGB
- **Resolution**: 72 PPI
- **Background**: Transparent (Safari applies background)
- **Safe Area**: Leave 10% padding around edges
- **Light/Dark Mode**: Icon should work in both (use strokes/outlines)

### macOS Design Resources
- SF Symbols: Consider using `square.stack.3d.up.fill` or `rectangle.3.group` as inspiration
- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/safari-extensions

## Placeholder Status

**Current**: Placeholder files only - icons need to be designed and added.

**Action Required**: 
1. Design icon using Sketch, Figma, or SF Symbols app
2. Export at required sizes
3. Replace placeholder files with actual PNG assets
4. Test icon rendering in Safari toolbar

## Testing Icon

To test the icon in Safari:
1. Build the extension
2. Enable Safari Extensions in Preferences
3. Check toolbar item appearance in light/dark mode
4. Verify icon clarity at different sizes
