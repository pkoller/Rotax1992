# TPU2 Web Game Design
_Translated from Turbo Pascal DOS original (1992)_

## Overview

A retro DOS-aesthetic browser game translated from `PROJ12.PAS`. A 2×2×2 cube is subdivided into 8 sub-cubes. A subset ("activated") defines a 3D solid. The player sees a preview of the solid in standard isometric, then must identify and click the visible edges of the same solid rotated 90° around the Z-axis.

---

## Game Mechanics

### The 3D Structure

- A 2×2×2 grid of 8 unit sub-cubes at positions (i,j,k), i,j,k ∈ {0,1}
- Together they produce 54 edges (18 per axis: X, Y, Z)
- Sub-cube vertices at grid coordinates 0–2 per axis

### Isometric Projection

```
screenX = baseX + 100·X + 25·Y
screenY = baseY + 25·Y − 100·Z
```

Depth for occlusion ordering: `d = −X + 4Y + Z` (lower d = closer to viewer)

### Two Views

| Panel | Name | Description |
|-------|------|-------------|
| Left | Urkörper (preview) | Standard isometric. Active cubes shown with green thick lines. Shared interior faces removed. |
| Right | Dünnkörper (puzzle) | Same solid rotated 90° around Z-axis. All 54 edges drawn faint. Player must trace the visible ones. |

**90° Z-rotation mapping:** vertex `(X,Y,Z)` → `(2−Y, X, Z)`

### Visibility Engine (per edge, puzzle view)

1. **Outer surface check:** edge belongs to at least one active cube, and at least one adjacent face in its perpendicular directions is exposed (neighboring cube is inactive or out-of-bounds)
2. **Viewer-facing check:** the exposed face's normal has a positive dot product with the view direction `(1,−4,−1)`
3. **Occlusion clip:** project all visible faces of closer active cubes (lower `d`) to 2D screen polygons; clip the candidate edge against these polygons using Sutherland-Hodgman; the remaining segment(s) are traceable

Edge states: **fully visible**, **partially visible** (truncated endpoint), **fully hidden**

### Interaction

- **Click near an edge** (within 10px tolerance) → check if it's a visible/untraced edge
- **Correct click:** edge turns green + thick, score increments, beep (Web Audio oscillator ~1000Hz, 100ms)
- **Wrong click:** no reaction (hidden/interior edge)
- **Completion:** when all visible edges traced → erase hidden edges, flood-fill faces green

---

## Puzzle Generation

| Difficulty | Active cubes | Adjacency |
|------------|-------------|-----------|
| Easy | 1–2 | Adjacent only |
| Medium | 3–7 | Adjacent only |
| Hard | 3–6 | Any (adjacent, non-adjacent, or mixed) |

Two cubes are adjacent if they share a face (not just edge/corner).

A set is "connected/adjacent" if all active cubes form a single connected component via face-adjacency.

Puzzle is randomly generated per difficulty. New Game picks a new random config.

---

## Screens & Flow

```
[ Intro ] → [ Difficulty Select ] → [ Game ] → [ Completion ] → [ Game ]
                  ↑                                   |
                  └───────────── Next ────────────────┘
```

### Intro Screen
- Full-canvas retro DOS logo: "TPU2" in large pixel/block letters, cyan on black
- Axis decoration (mirroring original `Achsen` procedure: rotation axis line + ellipse arc)
- Subtitle: `"Körper-Nachzeichner"` or similar, in yellow
- `[ PRESS ANY KEY ]` blinking prompt
- Transitions to Difficulty Select on any key/click

### Difficulty Select Screen
- Three bordered buttons, DOS menu style:
  - `[ LEICHT ]` (Easy)
  - `[ MITTEL ]` (Medium)
  - `[ SCHWER ]` (Hard)
- Highlighted button shown with inverse colors (black text on yellow background)
- Clicking a button starts a new puzzle at that difficulty

### Game Screen
- Left panel: Urkörper preview (green)
- Right panel: Dünnkörper puzzle (brown wireframe, traceable)
- Score box bottom-left: yellow bordered rectangle, count of traced edges
- Difficulty label shown at top

### Completion Screen
- Triggered when all visible edges are traced
- **Show full solution:** reveal remaining hidden edges erased, all visible edges bright green, faces flood-filled green
- Victory sound (short ascending tone sequence)
- Two buttons appear:
  - `[ NEXT ]` — generate a new puzzle at the same difficulty level
  - `[ MENU ]` — return to Difficulty Select

---

## UI / Aesthetics

- **Background:** black (`#000000`)
- **Urkörper lines:** green (`#00AA00`), thick
- **Dünnkörper untraced:** brown/dark yellow (`#AA5500`), thin
- **Traced edges:** bright green (`#00FF00`), thick
- **Score box:** DOS-style yellow text (`#FFFF00`), monospace font, bordered rectangle
- **Buttons:** DOS menu style — white text on black border; active = black on yellow
- **Font:** `monospace` / `'Courier New'`
- **Cursor:** custom crosshair bitmap (16×16, from original `cursormuster`)

---

## Architecture

Single self-contained `index.html` file. No dependencies.

### Modules (inline JS)

| Module | Responsibility |
|--------|---------------|
| `geometry.js` (inline) | Edge definitions, sub-cube membership, isometric projection, depth calc |
| `visibility.js` (inline) | Outer surface, viewer-facing, Sutherland-Hodgman clip |
| `puzzle.js` (inline) | Puzzle generation per difficulty, adjacency check |
| `renderer.js` (inline) | Canvas draw: preview + puzzle panels, score box |
| `input.js` (inline) | Mouse click → nearest edge hit test, trace logic |
| `audio.js` (inline) | Web Audio beep |
| `game.js` (inline) | Game state, screen transitions, new game, completion detection |

---

## Data Model

```js
// 8 sub-cubes
activeCubes[i][j][k]  // bool, i,j,k ∈ {0,1}

// 54 edges
edges[n] = {
  x1, y1, z1,   // 3D start vertex (0–2)
  x2, y2, z2,   // 3D end vertex (0–2)
  visible,       // computed by visibility engine (rotated view)
  visibleSegment,// {x1s,y1s,x2s,y2s} screen coords of visible portion
  traced,        // bool, set on correct click
}
```

---

## Completion Sequence

- Track count of visible edges
- When `tracedCount === visibleCount`:
  1. Play victory tone sequence
  2. Erase hidden edges (draw over in black)
  3. Redraw all visible edges bright green
  4. Flood-fill face regions green
  5. Show `[ NEXT ]` and `[ MENU ]` buttons
- `[ NEXT ]` → generate new puzzle at same difficulty, return to Game Screen
- `[ MENU ]` → return to Difficulty Select Screen

---

## Out of Scope (v1)

- Multiple puzzle variants loaded from file
- High score persistence
- Mobile touch support
- Sound effects beyond beep
