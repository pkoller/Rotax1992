# Training / Arcade Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a toggleable arcade mode where edges can be freely toggled without error feedback and FERTIG only triggers on an exact solution match.

**Architecture:** All changes are in the single `<script>` block of `index.html`. A global `arcadeMode` flag gates divergent behavior in `handleGameClick`, `drawScoreBox`, and rendering. A `wrongEdges` array (populated at puzzle start) tracks non-solution edges that can be toggled in arcade mode.

**Tech Stack:** Vanilla JS, HTML5 Canvas — no build step, no dependencies.

## Global Constraints

- Single file: `index.html` — all edits inside the `<script>` block
- No external dependencies introduced
- Existing training-mode behavior must remain byte-for-byte identical when `arcadeMode === false`
- Retro aesthetic preserved: monospace font, `#000` background, `[ ]`-bracket button labels

---

### Task 1: Add mode button — visual and click handling

**Files:**
- Modify: `index.html` (script block)

**Interfaces:**
- Produces: `arcadeMode` boolean global; `MODE_BTN` constant `{x,y,w,h}`; `drawModeBtn()` function

- [ ] **Step 1: Add `arcadeMode` global and `MODE_BTN` constant**

  Locate the block near line 795 where `SOUND_BTN` is defined:
  ```js
  const MENU_BTN = {x:600, y:480, w:140, h:36};
  const SOUND_BTN = {x:12, y:12, w:100, h:28};
  ```
  Add directly after it:
  ```js
  const MODE_BTN  = {x:12, y:44, w:100, h:28};
  let arcadeMode  = false;
  ```

- [ ] **Step 2: Brighten both button stroke/text colors**

  In `drawSoundBtn()` (around line 798), change:
  ```js
  ctx.strokeStyle = '#444'; ctx.lineWidth = 1;
  ctx.strokeRect(b.x, b.y, b.w, b.h);
  ctx.fillStyle = '#444'; ctx.font = '13px Courier New'; ctx.textAlign = 'center';
  ```
  To:
  ```js
  ctx.strokeStyle = '#888'; ctx.lineWidth = 1;
  ctx.strokeRect(b.x, b.y, b.w, b.h);
  ctx.fillStyle = '#888'; ctx.font = '13px Courier New'; ctx.textAlign = 'center';
  ```

- [ ] **Step 3: Add `drawModeBtn()` function**

  Add immediately after the closing `}` of `drawSoundBtn()`:
  ```js
  function drawModeBtn() {
    const b = MODE_BTN;
    ctx.strokeStyle = '#888'; ctx.lineWidth = 1;
    ctx.strokeRect(b.x, b.y, b.w, b.h);
    ctx.fillStyle = '#888'; ctx.font = '13px Courier New'; ctx.textAlign = 'center';
    ctx.fillText(arcadeMode ? '[ ARC    ]' : '[ TRN    ]', b.x + b.w/2, b.y + 19);
    ctx.textAlign = 'left';
  }
  ```

- [ ] **Step 4: Call `drawModeBtn()` from `render()`**

  In `render()`, find:
  ```js
  drawSoundBtn();
  ```
  Change to:
  ```js
  drawSoundBtn();
  drawModeBtn();
  ```

- [ ] **Step 5: Handle MODE_BTN click in `handleClick()`**

  In `handleClick(mx, my)`, find the sound button check:
  ```js
  const sb=SOUND_BTN;
  if(mx>=sb.x&&mx<=sb.x+sb.w&&my>=sb.y&&my<=sb.y+sb.h){
    soundEnabled=!soundEnabled; requestRender(); return;
  }
  ```
  Add directly after it (before the `if(screen===STATE.INTRO)` check):
  ```js
  const mb=MODE_BTN;
  if(mx>=mb.x&&mx<=mb.x+mb.w&&my>=mb.y&&my<=mb.y+mb.h){
    arcadeMode=!arcadeMode;
    if(screen===STATE.PLAYING||screen===STATE.COMPLETE) startNewPuzzle(currentDifficulty);
    else requestRender();
    return;
  }
  ```

- [ ] **Step 6: Verify visually**

  Open `index.html` in a browser. Confirm:
  - Sound button is visibly lighter than before (grey, not near-black)
  - A second `[ TRN    ]` button appears directly below it
  - Clicking it toggles between `[ TRN    ]` and `[ ARC    ]`
  - Clicking it while on the difficulty screen does NOT start a puzzle
  - Clicking it while in a game restarts the puzzle

- [ ] **Step 7: Commit**

  ```bash
  git add index.html
  git commit -m "feat: add arcade mode toggle button below sound button"
  ```

---

### Task 2: Populate `wrongEdges` at puzzle start

**Files:**
- Modify: `index.html` (script block)

**Interfaces:**
- Consumes: `arcadeMode` (Task 1); `puzzleEdgeCache` (existing); `getEdges()`, `rotateZ()`, `project()`, `PUZZLE_OX`, `PUZZLE_OY` (all existing)
- Produces: `wrongEdges` global — array of `{ seg:{sx1,sy1,sx2,sy2}, active:false }` for non-solution edges

- [ ] **Step 1: Add `wrongEdges` global**

  Near the other game-state globals (around line 487):
  ```js
  let currentDifficulty = 'medium';
  let activeState       = makeActive();
  let puzzleEdgeCache   = []; // [{edge, seg, traced}]
  let totalVisible      = 0;
  let tracedCount       = 0;
  ```
  Add `wrongEdges` after `tracedCount`:
  ```js
  let wrongEdges        = []; // [{seg, active}] — arcade mode only
  ```

- [ ] **Step 2: Populate `wrongEdges` inside `startNewPuzzle()`**

  In `startNewPuzzle()`, find:
  ```js
  puzzleEdgeCache   = getPuzzleEdges(activeState);
  totalVisible      = puzzleEdgeCache.length;
  tracedCount       = 0;
  setScreen(STATE.PLAYING);
  ```
  Replace with:
  ```js
  puzzleEdgeCache   = getPuzzleEdges(activeState);
  totalVisible      = puzzleEdgeCache.length;
  tracedCount       = 0;
  const solEdgeSet  = new Set(puzzleEdgeCache.map(pe => pe.edge));
  wrongEdges = getEdges()
    .filter(e => !solEdgeSet.has(e))
    .map(e => {
      const r1=rotateZ(e.x1,e.y1,e.z1), r2=rotateZ(e.x2,e.y2,e.z2);
      const p1=project(r1.x,r1.y,r1.z,PUZZLE_OX,PUZZLE_OY);
      const p2=project(r2.x,r2.y,r2.z,PUZZLE_OX,PUZZLE_OY);
      return { seg:{sx1:p1.sx,sy1:p1.sy,sx2:p2.sx,sy2:p2.sy}, active:false };
    });
  setScreen(STATE.PLAYING);
  ```

- [ ] **Step 3: Verify**

  Add a temporary `console.log(wrongEdges.length)` after the `wrongEdges` assignment, open the browser console, start a puzzle, and confirm a non-zero count is logged. Remove the log line afterward.

- [ ] **Step 4: Commit**

  ```bash
  git add index.html
  git commit -m "feat: populate wrongEdges array at puzzle start for arcade mode"
  ```

---

### Task 3: Arcade mode interaction and win condition

**Files:**
- Modify: `index.html` (script block)

**Interfaces:**
- Consumes: `arcadeMode` (Task 1); `wrongEdges` (Task 2); `puzzleEdgeCache`, `ptSegDist`, `HIT_DIST`, `totalVisible`, `tracedCount`, `victorySound`, `setScreen`, `STATE` (all existing)

- [ ] **Step 1: Replace `handleGameClick` with mode-aware version**

  Find the entire `handleGameClick` function (lines ~530–570) and replace it with:
  ```js
  function handleGameClick(mx,my) {
    if(_audioCtx.state==='suspended') _audioCtx.resume();

    if (arcadeMode) {
      // Try solution edges first
      let bestIdx=-1, bestD=HIT_DIST;
      for(let i=0;i<puzzleEdgeCache.length;i++){
        const s=puzzleEdgeCache[i].seg;
        const d=ptSegDist(mx,my, s.sx1,s.sy1, s.sx2,s.sy2);
        if(d<bestD){ bestD=d; bestIdx=i; }
      }
      if(bestIdx>=0){
        puzzleEdgeCache[bestIdx].traced = !puzzleEdgeCache[bestIdx].traced;
        tracedCount = puzzleEdgeCache.filter(pe=>pe.traced).length;
        requestRender();
        const allSol = puzzleEdgeCache.every(pe=>pe.traced);
        const noWrong = wrongEdges.every(we=>!we.active);
        if(allSol && noWrong){ setTimeout(()=>{ victorySound(); setScreen(STATE.COMPLETE); },350); }
        return;
      }
      // Try wrong edges
      let wIdx=-1, wD=HIT_DIST;
      for(let i=0;i<wrongEdges.length;i++){
        const s=wrongEdges[i].seg;
        const d=ptSegDist(mx,my, s.sx1,s.sy1, s.sx2,s.sy2);
        if(d<wD){ wD=d; wIdx=i; }
      }
      if(wIdx>=0){
        wrongEdges[wIdx].active = !wrongEdges[wIdx].active;
        requestRender();
        const allSol = puzzleEdgeCache.every(pe=>pe.traced);
        const noWrong = wrongEdges.every(we=>!we.active);
        if(allSol && noWrong){ setTimeout(()=>{ victorySound(); setScreen(STATE.COMPLETE); },350); }
      }
      return;
    }

    // ── Training mode (original behavior) ──
    let bestIdx=-1, bestD=HIT_DIST;
    for(let i=0;i<puzzleEdgeCache.length;i++){
      const pe=puzzleEdgeCache[i];
      if(pe.traced) continue;
      const s=pe.seg;
      const d=ptSegDist(mx,my, s.sx1,s.sy1, s.sx2,s.sy2);
      if(d<bestD){ bestD=d; bestIdx=i; }
    }
    if(bestIdx<0){
      const solEdgeSet=new Set(puzzleEdgeCache.map(pe=>pe.edge));
      let wrongSeg=null, wrongD=HIT_DIST;
      for(const e of getEdges()){
        if(solEdgeSet.has(e)) continue;
        const r1=rotateZ(e.x1,e.y1,e.z1), r2=rotateZ(e.x2,e.y2,e.z2);
        const p1=project(r1.x,r1.y,r1.z,PUZZLE_OX,PUZZLE_OY);
        const p2=project(r2.x,r2.y,r2.z,PUZZLE_OX,PUZZLE_OY);
        const d=ptSegDist(mx,my,p1.sx,p1.sy,p2.sx,p2.sy);
        if(d<wrongD){ wrongD=d; wrongSeg={sx1:p1.sx,sy1:p1.sy,sx2:p2.sx,sy2:p2.sy}; }
      }
      if(wrongSeg){
        errorSound();
        missFlash={seg:wrongSeg, t:performance.now()};
        requestRender();
      }
      return;
    }
    missFlash=null;
    puzzleEdgeCache[bestIdx].traced=true;
    tracedCount++;
    beep(1000,90);
    requestRender();
    if(tracedCount===totalVisible){
      setTimeout(()=>{ victorySound(); setScreen(STATE.COMPLETE); }, 350);
    }
  }
  ```

- [ ] **Step 2: Verify training mode unchanged**

  Set `arcadeMode = false`. Play a puzzle. Confirm:
  - Correct edge click: green trace + click beep
  - Wrong edge click: red flicker + error sound
  - Counter increments
  - FERTIG triggers on last correct edge

- [ ] **Step 3: Verify arcade mode interaction**

  Toggle to `[ ARC ]`. Play a puzzle. Confirm:
  - Clicking any edge (correct or wrong) lights it green — no sound, no flicker
  - Re-clicking a lit edge deactivates it
  - FERTIG does NOT appear while any wrong edge is active OR any correct edge is untraced
  - FERTIG appears + victory sound when all correct edges are on and all wrong edges are off

- [ ] **Step 4: Commit**

  ```bash
  git add index.html
  git commit -m "feat: arcade mode toggle interaction and exact-match win condition"
  ```

---

### Task 4: Hide score box and render activated wrong edges

**Files:**
- Modify: `index.html` (script block)

**Interfaces:**
- Consumes: `arcadeMode` (Task 1); `wrongEdges` (Task 2); `drawScoreBox`, `drawGame` (existing)

- [ ] **Step 1: Hide score box in arcade mode**

  In `drawGame()`, find:
  ```js
  drawRotationArms();
  drawScoreBox();
  drawMenuBtn();
  ```
  Change to:
  ```js
  drawRotationArms();
  if (!arcadeMode) drawScoreBox();
  drawMenuBtn();
  ```

  Also in `drawComplete()`, find:
  ```js
  drawRotationArms();
  drawScoreBox();
  ```
  Change to:
  ```js
  drawRotationArms();
  if (!arcadeMode) drawScoreBox();
  ```

- [ ] **Step 2: Draw activated wrong edges in arcade mode**

  In `drawGame()`, find the traced-edges rendering block:
  ```js
  // Traced edges (bright green thick)
  ctx.strokeStyle='#00FF00'; ctx.lineWidth=3; ctx.shadowColor='#00FF66'; ctx.shadowBlur=16;
  for(const pe of puzzleEdgeCache){
    if(!pe.traced) continue;
    const s=pe.seg;
    ctx.beginPath(); ctx.moveTo(s.sx1,s.sy1); ctx.lineTo(s.sx2,s.sy2); ctx.stroke();
  }
  ctx.shadowBlur=0;
  ```
  Replace with:
  ```js
  // Traced edges (bright green thick)
  ctx.strokeStyle='#00FF00'; ctx.lineWidth=3; ctx.shadowColor='#00FF66'; ctx.shadowBlur=16;
  for(const pe of puzzleEdgeCache){
    if(!pe.traced) continue;
    const s=pe.seg;
    ctx.beginPath(); ctx.moveTo(s.sx1,s.sy1); ctx.lineTo(s.sx2,s.sy2); ctx.stroke();
  }
  if (arcadeMode) {
    for(const we of wrongEdges){
      if(!we.active) continue;
      const s=we.seg;
      ctx.beginPath(); ctx.moveTo(s.sx1,s.sy1); ctx.lineTo(s.sx2,s.sy2); ctx.stroke();
    }
  }
  ctx.shadowBlur=0;
  ```

- [ ] **Step 3: Also draw activated wrong edges on the COMPLETE screen**

  In `drawComplete()`, find the all-traced rendering block:
  ```js
  ctx.strokeStyle='#00FF00'; ctx.lineWidth=3; ctx.shadowColor='#00FF66'; ctx.shadowBlur=16;
  for(const pe of puzzleEdgeCache){
    const s=pe.seg;
    ctx.beginPath(); ctx.moveTo(s.sx1,s.sy1); ctx.lineTo(s.sx2,s.sy2); ctx.stroke();
  }
  ctx.shadowBlur=0;
  ```
  Replace with:
  ```js
  ctx.strokeStyle='#00FF00'; ctx.lineWidth=3; ctx.shadowColor='#00FF66'; ctx.shadowBlur=16;
  for(const pe of puzzleEdgeCache){
    const s=pe.seg;
    ctx.beginPath(); ctx.moveTo(s.sx1,s.sy1); ctx.lineTo(s.sx2,s.sy2); ctx.stroke();
  }
  if (arcadeMode) {
    for(const we of wrongEdges){
      if(!we.active) continue;
      const s=we.seg;
      ctx.beginPath(); ctx.moveTo(s.sx1,s.sy1); ctx.lineTo(s.sx2,s.sy2); ctx.stroke();
    }
  }
  ctx.shadowBlur=0;
  ```

- [ ] **Step 4: Verify final behavior**

  Open browser. Test both modes end-to-end:

  **Training:**
  - Score box `0 / N` visible bottom-left ✓
  - Wrong click → red flicker + error sound ✓
  - Complete puzzle → FERTIG + score box shown ✓

  **Arcade:**
  - No score box anywhere ✓
  - Toggle any edge freely, no audio feedback ✓
  - Activated wrong edges render green like correct ones ✓
  - FERTIG only when exact solution matched ✓
  - Switching mode mid-game resets puzzle ✓

- [ ] **Step 5: Commit**

  ```bash
  git add index.html
  git commit -m "feat: hide score box in arcade mode, render activated wrong edges green"
  ```
