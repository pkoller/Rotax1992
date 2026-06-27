# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

ROTAX — Körper-Nachzeichner. A retro DOS-aesthetic 3D puzzle game, translated/ported from a 1992 Turbo Pascal original (`original_rotax/PROJ12.PAS`). The player sees a 3D solid ("Urkörper") on the left and must trace the visible edges of the same solid rotated 90° around the Z-axis ("Dünnkörper") on the right.

## Running / developing

Everything lives in a single self-contained [index.html](index.html) — no build step, no package manager, no dependencies. Open the file directly in a browser to run the game. There is no test suite or lint config.

To preview changes, just reload `index.html` in a browser (or use the project's preview tooling if available).

## Architecture

All code is inline JS inside `index.html`'s `<script>` block, organized into informal sections (not actual modules/files):

- **Geometry** — `buildEdges`, `project` (isometric projection), `rotateZ` (90° Z-axis rotation: `(X,Y,Z) → (2−Y, X, Z)`), `isActive`
- **Visibility engine** — `isEdgeVisible`, `buildOccluders`/`buildPreviewOccluders`, `visibleSegment`/`visiblePreviewSegment`, `clipSegPoly` (Sutherland-Hodgman polygon clipping), `getPuzzleEdges`/`getPreviewEdges`. Determines which edges of the rotated solid are visible to the player and computes the visible sub-segment when partially occluded.
- **Puzzle generation** — `makeActive`, `growActive`, `generatePuzzle`, `isValidPuzzle`, `isConnected`. Generates a random active-cube configuration per difficulty.
- **Input handling** — `handleClick` (screen-level routing), `handleGameClick` (edge hit-testing via `ptSegDist`), `getHitDist`
- **Audio** — `beep`, `victorySound`, `errorSound`, `clickSound` (Web Audio oscillator beeps)
- **Rendering** — `render`, `drawIntro`, `drawDifficulty`, `drawGame`, `drawComplete`, `drawScoreBox`, `drawSoundBtn`, `drawModeBtn`, `drawMenuBtn`, `drawHitZones`, `drawRotaxLogo`, `drawAxisDecoration`, `drawRotationArms`
- **Game loop / state** — `startNewPuzzle`, `loop`, `setScreen`, `requestRender`. Render-on-dirty pattern: state mutations set `dirty = true`; `loop()` only redraws when dirty.

### Screen state machine

```
STATE.INTRO → STATE.DIFFICULTY → STATE.PLAYING → STATE.COMPLETE
                    ↑                                  |
                    └──────────── (Menu / Next) ───────┘
```

`screen` (global) holds the current `STATE.*` value; `setScreen()` transitions and marks dirty.

### Cube grid sizing

The grid size `G` (2 for easy/medium/hard, 3 for "wahnsinn") determines which edge set is active: `getEdges()` returns `EDGES_2` or `EDGES_3` built by `buildEdges(G)`. Sub-cube membership is `active[i][j][k]` (boolean 3D array), `i,j,k ∈ [0, G)`.

### Two modes (Training vs Arcade)

- **Training mode** (default): wrong clicks trigger error sound + red flicker, correct clicks are one-way (trace only), score box shown.
- **Arcade mode** (`arcadeMode` flag): clicks toggle edges on/off (both solution edges via `puzzleEdgeCache` and decoy edges via `wrongEdges`), no audio feedback on click, win requires every solution edge traced AND every wrong edge inactive, score box hidden.

Switching modes via `drawModeBtn`'s button resets the current puzzle if on `STATE.PLAYING`/`STATE.COMPLETE`.

### Difficulty levels

| Difficulty | Grid | Active cubes | Adjacency |
|---|---|---|---|
| `easy` | 2×2×2 | 1–2 | connected only |
| `medium` | 2×2×2 | 3–7 | connected only |
| `hard` | 2×2×2 | 3–6 | any |
| `wahnsinn` | 3×3×3 | random | fully random |

## Design docs

`docs/superpowers/specs/` and `docs/superpowers/plans/` contain the original design specs for the web port and the training/arcade mode addition — useful background if extending game mechanics, but the code in `index.html` is the source of truth (some details, like button labels, have since diverged from the specs).

## Original source

`original_rotax/` contains the 1992 Turbo Pascal source (`PROJ12.PAS` plus `.TPU`/`.PAS` units) that this game is ported from. Useful for cross-checking original game logic, projection math, or visual style.
