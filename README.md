# AMT Extended

> [!NOTE]
> This is a **derivative work** based on the original AMT. Full credit to the original authors below.

**AMT Extended** is a refactored version of Arezu's Mapping Toolbox. It works exactly like the original, but with cleaner code and some nice extras.

## What Changed

The original AMT was completely refactored to be easier to maintain. Here's what's different:

### The Refactor

The original AMT was 3 files with almost 2,000 lines of code. A lot of it was duplicated - the same geometry calculations appeared twice (once for preview, once for generation). This made it hard to fix bugs because you had to change things in two places.

Everything got split into 14 smaller files with shared code moved into modules that both client and server can use. The result:
- **-568 lines** of duplicated code gone
- **-17%** total code size (1,979 → 1,650 lines)
- **Much easier** to find and fix things

### File Organization

```
amt_extended/
├── client/          # 7 modules for GUI, preview, events, etc.
├── server/          # 2 modules for generation and duplication
├── shared/          # 4 utilities used by both client and server
├── record/          # Recording system (unchanged)
├── original_amt/    # Kept the original for reference
└── meta.xml
```

All the global variables are now properly namespaced under `AMT.*` instead of floating around. This prevents conflicts with other resources.

### New Features

Things that weren't in the original:

- **Curved Loop Mode** - New "Twist Rotation" controls for making banked loops and curved tracks
- **Preview Limits** - Shows a warning when you're generating >500 objects, with a "Show All" button if you really want to see them
- **Workflow Highlighting** - UI changes color to show what mode you're in
- **Version Number** - Shows in the bottom-left corner
- **Bug Fixes** - Fixed some preview/generation mismatch issues

### Everything Else Still Works

All the original features work exactly the same:
- F7 to toggle, /des to undo
- Generator and Duplicator modes
- Recording system (n/m keys)
- Real-time preview
- 3D directional arrows
- Autocount, rotation controls, etc.

## Installation

1. Drop the `amt_extended` folder into `server/mods/deathmatch/resources/`
2. Start it with `start amt_extended`
3. Press F7 in the editor

Requires MTA:SA 1.5+, Editor, and EDF resource.

## Credits

### Original AMT
*   **~pS|Arezu** - Created the original AMT that made all this possible
*   **~pS|Rextox** - Made the UI graphics

### gute_amt
*   **Zeet** - Added preview features and improvements (didn't want credit but too bad)

### AMT Extended
*   **farlezz** - this (vibecoded with my LLM homies - told them what to do, they did the heavy lifting)

## License

As per the original author (Arezu): *"You are free to edit this 'spaghetti' code if you include credits."*

AMT Extended follows the same terms - free to use and modify as long as you keep the credits chain intact:
- Original AMT by ~pS|Arezu and ~pS|Rextox
- gute_amt improvements by Zeet
- AMT Extended refactor by farlezz

If you fork this, just mention it's based on AMT Extended → gute_amt → original AMT.
