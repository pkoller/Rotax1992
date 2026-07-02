# Profi-Mode Uncertainty + Settings Cluster — Design Spec

**Date:** 2026-07-02
**Status:** Approved

---

## Overview

Two related changes to ROTAXIS:

1. Make the existing "no hidden-cube ambiguity" puzzle-generation step ([activateInvisibleCubes](index.html:428)) conditional on game mode instead of always-on. Training mode keeps today's behavior (puzzles are always unambiguous); Profi mode skips it, allowing puzzles with genuinely invisible cubes — closer to the 1992 original.
2. Visually group the existing TON and MODUS buttons into a labeled "EINSTELLUNGEN" cluster, and document what each mode actually does on the ÜBER page.

No new buttons, no new global state beyond what already exists (`arcadeMode`).

---

## 1. Conditional `activateInvisibleCubes`

### Background

[generatePuzzle](index.html:402) currently always calls `activateInvisibleCubes(a)` before returning a puzzle. That function fills in any inactive cube whose activation wouldn't add visible edges to the rotated preview — i.e. it removes all cubes that are invisible-but-ambiguous, guaranteeing the puzzle's active-cube set is uniquely determined by what's visible.

### Change

```js
if(isValidPuzzle(a,difficulty) && getPuzzleEdges(a).length>0) {
  if (!arcadeMode) activateInvisibleCubes(a);
  return a;
}
```

- Training mode (`arcadeMode === false`, default): unchanged, puzzles remain unambiguous.
- Profi mode (`arcadeMode === true`): step is skipped. Randomly generated active-cube sets are used as-is, which may include cubes that are invisible from both the Urkörper and Dünnkörper views — the player can no longer be certain the shape they perceive is the full shape.

No change to `isValidPuzzle`, `getPuzzleEdges`, or `getPreviewEdges` — this only removes the extra fill-in pass, it doesn't touch puzzle validity or visibility logic.

Because mode switches already call `startNewPuzzle(currentDifficulty)` when on `STATE.PLAYING`/`STATE.COMPLETE` (see [applyModeSwitch](index.html:592)), this takes effect immediately on toggle — no extra wiring needed.

---

## 2. Settings Cluster (visual grouping)

### New function `drawSettingsGroup()`

Draws a bordered box behind/around the existing `SOUND_BTN` (12,44,100,28) and `MODE_BTN` (12,76,100,28):

- Box: `x:3, y:32, w:118, h:82`
- Stroke: `#444`, 1px
- Label tab: text `EINSTELLUNGEN`, color `#666`, `10px Courier New`, letter-spacing look (via individual char spacing or just tight font), positioned at roughly `x:11, y:36` sitting on the box's top edge with a small black backdrop so the stroke appears to break under it (match the "tab" look from the mockup: draw box first, then a filled black rect behind the label text, then the label, so the border looks interrupted).

### Render order

Called from `render()` immediately before `drawSoundBtn(); drawModeBtn();` so the box sits behind both buttons on every screen:

```js
drawSettingsGroup();
drawSoundBtn();
drawModeBtn();
```

No interaction — the box is decorative only, doesn't participate in `handleClick`.

---

## 3. ÜBER Page — Mode Explanation

Add a new block to the `lines` array in [drawAbout](index.html:1020), after the existing keyboard-shortcut list and before the historical-background paragraph (or after it — appended as its own labeled section):

```
['#FFFF00', 'MODI:'],
['#888',    'TRAINING — Falsche Klicks werden angezeigt. Richtige Kanten bleiben nach'],
['#888',    'dem Nachzeichnen fixiert. Rätsel sind stets eindeutig — jeder Würfel, der'],
['#888',    'unsichtbar bliebe, wird automatisch ergänzt.'],
['#888',    'PROFI — Klicks schalten Kanten ein/aus, auch falsche. Rätsel können'],
['#888',    'unsichtbare Würfel enthalten, die die Lösung uneindeutig machen — echte'],
['#888',    'Unsicherheit wie im Original von 1992.'],
```

Wrapping follows the existing pattern in that array (one array entry per rendered line, manual line breaks — no auto-wrap in this codebase). Exact break points can be adjusted during implementation to fit the 800px canvas width at `13px Courier New` starting at x=110, same as the rest of the ÜBER content.

---

## Files Affected

`index.html` only — all three changes are within the existing `<script>` block:
- `generatePuzzle` (behavior)
- new `drawSettingsGroup` + one-line addition to `render()` (visual)
- `drawAbout`'s `lines` array (copy)

---

## Out of Scope

- Any new button or toggle beyond the existing TON/MODUS
- Persisting mode preference across sessions (localStorage) — not part of this change, follows existing behavior
- Changing what counts as a "valid" puzzle (`isValidPuzzle`) for Profi mode
- Visual distinction in-game between "this cube might be hidden" — Profi mode's uncertainty is intentionally invisible to the player during play; it's only explained on the ÜBER page
