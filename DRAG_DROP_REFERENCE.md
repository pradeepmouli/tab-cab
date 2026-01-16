# TabCab Drag-and-Drop Quick Reference

Visual guide to all drag-and-drop interactions in TabCab.

## Tab-to-Tab Interactions

### Create New Association
```
┌─────────────┐
│ Ungrouped   │
│   Tab A     │  ─┐
└─────────────┘   │
                  │  DRAG
┌─────────────┐   │
│ Ungrouped   │  ─┘
│   Tab B     │
└─────────────┘

         ↓

┌─────────────────────────┐
│  📝 Name Association    │  ← Dialog appears
│  Suggested: "GitHub"    │
│  Color: [🔴🟢🔵]        │
│  [Cancel] [Create]      │
└─────────────────────────┘

         ↓

┌─────────────────────────┐
│ ▼ GitHub (2)            │  ← New association
│   Tab A                 │
│   Tab B                 │
└─────────────────────────┘
```

### Add to Existing Association
```
┌─────────────┐
│ Ungrouped   │
│   Tab C     │  ─────┐
└─────────────┘       │
                      │  DRAG (no dialog!)
┌─────────────────────┤
│ ▼ GitHub (2)        │  ─┘
│   Tab A             │
│   Tab B             │
└─────────────────────┘

         ↓

┌─────────────────────────┐
│ ▼ GitHub (3)            │  ← Tab added silently
│   Tab A                 │
│   Tab B                 │
│   Tab C                 │  ← Added
└─────────────────────────┘
```

## Tab Movement

### Move Between Associations
```
┌─────────────────────────┐
│ ▼ Work (2)              │
│   Tab A                 │  ─┐
│   Tab B                 │   │ DRAG (no dialog!)
└─────────────────────────┘   │
                              │
┌─────────────────────────┐   │
│ ▼ Personal (1)          │  ─┘
│   Tab D                 │
└─────────────────────────┘

         ↓

┌─────────────────────────┐
│ ▼ Work (1)              │  ← Tab removed
│   Tab B                 │
└─────────────────────────┘

┌─────────────────────────┐
│ ▼ Personal (2)          │  ← Tab added
│   Tab D                 │
│   Tab A                 │  ← Added
└─────────────────────────┘
```

### Remove from Association
```
┌─────────────────────────┐
│ ▼ GitHub (3)            │
│   Tab A                 │  ─┐
│   Tab B                 │   │ DRAG to empty area
│   Tab C                 │   │
└─────────────────────────┘   │
                              │
        [empty space]    ←────┘

         ↓

┌─────────────────────────┐
│ ▼ GitHub (2)            │  ← Tab removed
│   Tab B                 │
│   Tab C                 │
└─────────────────────────┘

┌─────────────────────────┐
│ Ungrouped Tabs          │
│   Tab A                 │  ← Moved here
└─────────────────────────┘
```

## Association Merge

### Merge Two Associations
```
┌─────────────────────────┐
│ ▶ Work (3)              │  ─┐ DRAG header
└─────────────────────────┘   │
                              │
┌─────────────────────────┐   │
│ ▶ Projects (2)          │  ─┘
└─────────────────────────┘

         ↓

┌─────────────────────────────────┐
│  ⚠️  Merge Associations         │  ← Confirmation
│                                 │
│  From: Work (3 tabs)            │
│    ↓                            │
│  Into: Projects (2 tabs)        │
│                                 │
│  ⚠️  "Work" will be deleted    │
│                                 │
│  [Cancel] [Merge Associations]  │
└─────────────────────────────────┘

         ↓

┌─────────────────────────┐
│ ▼ Projects (5)          │  ← Merged!
│   [all 5 tabs]          │
└─────────────────────────┘

[Work association deleted]
```

## Invalid Operations

### ❌ Tab onto Itself
```
┌─────────────┐
│   Tab A     │  ←─┐
└─────────────┘    │ DRAG (does nothing)
                   │
              ─────┘
```

### ❌ Association onto Itself
```
┌─────────────────────────┐
│ ▶ GitHub (3)            │  ←─┐
└─────────────────────────┘    │ DRAG (does nothing)
                               │
                          ─────┘
```

## Visual Feedback (Planned Enhancement)

Future versions will include:
- 🎯 Drop zones highlight when valid target
- ⛔ Invalid targets show "no-drop" cursor
- ✨ Smooth animations during drag
- 🔄 Preview of result before drop

## Keyboard Shortcuts (Future)

Planned keyboard alternatives for accessibility:
- `⌘E` - Edit association
- `⌘M` - Move selected tab to association
- `⌘⇧N` - Create new association from selected tabs
- `⌘⇧M` - Merge associations

## Tips

1. **Hold and wait**: When dragging, hold for a moment to see the drag preview
2. **Cancel drag**: Press `Esc` to cancel an in-progress drag
3. **Precision**: Drop precisely on the target for best results
4. **Visual cues**: Watch for cursor changes indicating valid drop zones
5. **Undo**: Currently no undo - dialogs help prevent mistakes

---

**Legend**:
- `▼` = Expanded association
- `▶` = Collapsed association
- `─┐` = Drag gesture
- `↓` = Result
- `📝` = Dialog
- `⚠️` = Warning
- `❌` = Invalid operation
