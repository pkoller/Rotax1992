# Training / Arcade Mode — Design Spec

**Date:** 2026-06-25  
**Status:** Approved

---

## Overview

Add two gameplay modes to ROTAX — Körper-Nachzeichner:

- **Training mode** (default) — current behavior, unchanged
- **Arcade mode** — silent, no error feedback, full toggle freedom; FERTIG only on exact solution match

A mode-toggle button sits directly below the existing sound button. Both buttons get increased visibility.

---

## Mode Button

- Label: `[ TRN ]` in training mode, `[ ARC ]` in arcade mode
- Position: directly below `SOUND_BTN`, same x/w/h dimensions
- `MODE_BTN = { x:12, y:44, w:100, h:28 }` (SOUND_BTN is at y:12, h:28 → 12+28+4 = 44)
- Both `SOUND_BTN` and `MODE_BTN` stroke/text color raised from `#444` to `#888`
- Rendered on every screen via `drawSoundBtn()` + new `drawModeBtn()`, both called from `render()`
- Click handled in `handleClick()` before all other checks (same pattern as sound button)
- Switching modes resets the current puzzle (calls `startNewPuzzle(currentDifficulty)`) if currently on `STATE.PLAYING` or `STATE.COMPLETE`; on other screens the flag just flips

---

## State Changes

New global: `let arcadeMode = false;`

New per-puzzle state: `let wrongEdges = [];` — array of `{seg, active}` for edges not in the solution set, used only in arcade mode.

`wrongEdges` is populated in `startNewPuzzle()` alongside `puzzleEdgeCache`:  
all edges that have a visible screen segment in the dünnkörper wireframe but are NOT in `puzzleEdgeCache`.

---

## Training Mode (unchanged)

- Click on solution edge → traces it (green, click sound)
- Click on wrong edge → error sound + red flicker
- Counter `tracedCount / totalVisible` shown bottom-left
- FERTIG when `tracedCount === totalVisible`

---

## Arcade Mode

### Interaction — `handleGameClick`

1. Check if click hits a **solution edge** (within `HIT_DIST`): toggle `pe.traced` (on → off → on). Play no sound.
2. Else check if click hits a **wrong edge** in `wrongEdges`: toggle `we.active`. Play no sound.
3. No `errorSound()`, no `missFlash`.

### Win Condition

After any toggle, check:
```
allSolutionTraced = puzzleEdgeCache.every(pe => pe.traced)
noWrongActive     = wrongEdges.every(we => !we.active)
if (allSolutionTraced && noWrongActive) → victory
```

### Score Box

Hidden in arcade mode — `drawScoreBox()` is not called when `arcadeMode === true`.

### Rendering — wrong edges

In arcade mode, activated wrong edges are drawn in the dünnkörper panel with the same bright-green traced style so the player can see what they've toggled.

---

## Button Visibility

Both buttons: stroke and text color `#888` (up from `#444`).

---

## Reset on Mode Switch

If `screen === STATE.PLAYING || screen === STATE.COMPLETE` when the mode button is clicked:  
→ call `startNewPuzzle(currentDifficulty)` so the new mode takes effect immediately with a fresh puzzle.  
On `STATE.INTRO` or `STATE.DIFFICULTY`: just flip `arcadeMode`, no reset needed.

---

## Files Affected

`index.html` — only file in this project. All changes are within the `<script>` block.

---

## Out of Scope

- Per-difficulty arcade variants
- Persistent mode preference (localStorage)
- Visual distinction between "wrong-active" and "correct-active" edges in arcade mode
