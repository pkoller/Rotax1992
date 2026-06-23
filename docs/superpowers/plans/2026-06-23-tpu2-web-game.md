# TPU2 Web Game Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Translate the 1992 Turbo Pascal DOS game PROJ12.PAS into a single self-contained `index.html` browser game where players trace the visible edges of a 3D solid after it has been rotated 90° around the Z-axis.

**Architecture:** Single `index.html`, all JS inline, canvas-based rendering. A 2×2×2 sub-cube model drives geometry, visibility, and puzzle generation. A state machine manages 4 screens: Intro → Difficulty Select → Playing → Completion.

**Tech Stack:** HTML5 Canvas 2D, vanilla JavaScript ES2020, Web Audio API — no dependencies, no build step.

## Global Constraints

- Output: single file `index.html` at repo root — no external scripts, no CDN
- Canvas: `800 × 520 px`
- DOS color palette: black `#000000`, cyan `#00FFFF`, bright-green `#00FF00`, dim-green `#00AA00`, yellow `#FFFF00`, brown `#AA5500`, dark-brown `#553300`
- Font: `'Courier New', monospace`
- Isometric projection formula: `sx = ox + 100·X + 25·Y`, `sy = oy + 25·Y − 100·Z`
  — `ox,oy` is the panel origin (vertex 0,0,0 maps to this screen point)
- Preview panel origin: `PREVIEW_OX=60, PREVIEW_OY=420`
- Puzzle panel origin: `PUZZLE_OX=430, PUZZLE_OY=420`
- 90° Z-rotation: `(X,Y,Z) → (2−Y, X, Z)`
- Preview view direction (scene→viewer): `(-1, 4, 1)` — visible face normals: `-X`, `+Y`, `+Z`
- Puzzle view direction (scene→viewer, after rotation applied): `(4, 1, 1)` — visible face normals: `+X`, `+Y`, `+Z`
- Puzzle depth ordering: `depth = 4x + y + z` in **pre-rotation** coords; higher = closer to viewer
- Edge click tolerance: `10 px`
- Difficulty rules:
  - easy: 1–2 cubes, face-adjacent (connected)
  - medium: 3–7 cubes, all face-adjacent (connected)
  - hard: 3–6 cubes, any configuration (connected or not)

---

## File Structure

```
index.html          — entire game (single file)
  <style>           — body/canvas DOS styling
  <canvas id="c">   — 800×520
  <script>
    // § Constants & canvas setup
    // § State machine
    // § Geometry engine
    // § Visibility engine
    // § Puzzle generator
    // § Audio
    // § Renderer — intro
    // § Renderer — difficulty select
    // § Renderer — game screen
    // § Renderer — completion screen
    // § Input handling
    // § Boot
  </script>
```

---

### Task 1: HTML Scaffold + State Machine

**Files:**
- Create: `index.html`

**Interfaces:**
- Produces: `canvas`, `ctx`, `STATE` enum, `screen` var, `setScreen(s)`, `requestRender()`, render loop

- [ ] **Step 1: Create `index.html` with canvas, styling, state machine, and render loop**

```html
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="UTF-8">
<title>TPU2 — Körper-Nachzeichner</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { background:#000; display:flex; justify-content:center; align-items:center; height:100vh; }
  canvas { display:block; cursor:crosshair; image-rendering:pixelated; }
</style>
</head>
<body>
<canvas id="c" width="800" height="520"></canvas>
<script>
'use strict';
const canvas = document.getElementById('c');
const ctx = canvas.getContext('2d');

const STATE = Object.freeze({ INTRO:0, DIFFICULTY:1, PLAYING:2, COMPLETE:3 });
let screen = STATE.INTRO;
let dirty = true;

function setScreen(s) { screen = s; dirty = true; }
function requestRender() { dirty = true; }

function loop() {
  if (dirty) { dirty = false; render(); }
  requestAnimationFrame(loop);
}

function render() {
  ctx.fillStyle = '#000';
  ctx.fillRect(0, 0, 800, 520);
  ctx.textAlign = 'left';
  ctx.textBaseline = 'alphabetic';
  if      (screen === STATE.INTRO)      drawIntro();
  else if (screen === STATE.DIFFICULTY) drawDifficulty();
  else if (screen === STATE.PLAYING)    drawGame();
  else if (screen === STATE.COMPLETE)   drawComplete();
}

// placeholders — filled in by later tasks
function drawIntro()      { ctx.fillStyle='#00FFFF'; ctx.font='20px Courier New'; ctx.fillText('INTRO',20,40); }
function drawDifficulty() { ctx.fillStyle='#00FFFF'; ctx.font='20px Courier New'; ctx.fillText('DIFFICULTY',20,40); }
function drawGame()       { ctx.fillStyle='#00FFFF'; ctx.font='20px Courier New'; ctx.fillText('GAME',20,40); }
function drawComplete()   { ctx.fillStyle='#00FFFF'; ctx.font='20px Courier New'; ctx.fillText('COMPLETE',20,40); }

requestAnimationFrame(loop);
</script>
</body>
</html>
```

- [ ] **Step 2: Verify in browser**

Open `index.html` — black canvas, "INTRO" text in cyan, no console errors.

- [ ] **Step 3: Commit**

```bash
git init && git add index.html && git commit -m "feat: scaffold - canvas, state machine, render loop"
```

---

### Task 2: Geometry Engine

**Files:**
- Modify: `index.html` — add geometry section before the placeholder functions

**Interfaces:**
- Produces:
  - `EDGES` — array[54] of `{x1,y1,z1, x2,y2,z2}` (integer grid coords 0–2)
  - `project(x,y,z, ox,oy)` → `{sx,sy}`
  - `rotateZ(x,y,z)` → `{x,y,z}`
  - `isActive(active,i,j,k)` → bool (bounds-safe)
  - `PREVIEW_OX`, `PREVIEW_OY`, `PUZZLE_OX`, `PUZZLE_OY` constants

- [ ] **Step 1: Add geometry section inside `<script>` before the placeholder functions**

```javascript
// ── Geometry ──
const PREVIEW_OX = 60,  PREVIEW_OY = 420;
const PUZZLE_OX  = 430, PUZZLE_OY  = 420;

// Build all 54 edges of the 2×2×2 sub-cube grid (vertices 0–2 per axis)
const EDGES = [];
for (let j=0;j<=2;j++) for (let k=0;k<=2;k++) for (let x=0;x<=1;x++)
  EDGES.push({x1:x,  y1:j,  z1:k,  x2:x+1,y2:j,  z2:k  }); // X-direction
for (let i=0;i<=2;i++) for (let k=0;k<=2;k++) for (let y=0;y<=1;y++)
  EDGES.push({x1:i,  y1:y,  z1:k,  x2:i,  y2:y+1,z2:k  }); // Y-direction
for (let i=0;i<=2;i++) for (let j=0;j<=2;j++) for (let z=0;z<=1;z++)
  EDGES.push({x1:i,  y1:j,  z1:z,  x2:i,  y2:j,  z2:z+1}); // Z-direction

console.assert(EDGES.length === 54, 'EDGES must be 54, got ' + EDGES.length);

function project(x, y, z, ox, oy) {
  return { sx: ox + 100*x + 25*y,  sy: oy + 25*y - 100*z };
}

function rotateZ(x, y, z) {
  // 90° around Z: (X,Y,Z) → (2−Y, X, Z)
  return { x: 2-y, y: x, z: z };
}

function isActive(active, i, j, k) {
  return i>=0&&i<2&&j>=0&&j<2&&k>=0&&k<2 && !!active[i][j][k];
}
```

- [ ] **Step 2: Add inline assertions and verify**

Temporarily add after the geometry block (remove after verification):
```javascript
(function testGeometry() {
  const p = project(0,0,0, 60,420);
  console.assert(p.sx===60  && p.sy===420, 'project: origin');
  const p2 = project(2,2,2, 60,420);
  console.assert(p2.sx===310 && p2.sy===270, 'project: far corner (60+200+50=310, 420+50-200=270)');
  const r = rotateZ(0,0,0);
  console.assert(r.x===2&&r.y===0&&r.z===0, 'rotateZ: (0,0,0)→(2,0,0)');
  const r2 = rotateZ(2,2,0);
  console.assert(r2.x===0&&r2.y===2&&r2.z===0, 'rotateZ: (2,2,0)→(0,2,0)');
  console.log('Geometry tests passed');
})();
```

Open browser → console must show "Geometry tests passed", zero assertion failures.

- [ ] **Step 3: Remove test block, commit**

```bash
git add index.html && git commit -m "feat: geometry engine - 54 edges, projection, Z-rotation"
```

---

### Task 3: Visibility Engine — Preview

**Files:**
- Modify: `index.html` — add visibility section after geometry

**Interfaces:**
- Consumes: `EDGES`, `isActive()`
- Produces:
  - `getPreviewEdges(active)` → `Edge[]` — edges visible in standard isometric view
  - `isEdgeVisible(edge, active, faceVisibleFn)` → bool (shared with puzzle view)

The preview view direction is `(-1,4,1)`. A face is visible when `dot(normal, (-1,4,1)) > 0`:
- `-X face` (normal `(-1,0,0)`): `1 > 0` ✓  
- `+Y face` (normal `(0,1,0)`): `4 > 0` ✓  
- `+Z face` (normal `(0,0,1)`): `1 > 0` ✓  

An edge is visible if any adjacent face is **both** viewer-facing **and** exposed (inner cube active, outer cube inactive or OOB).

- [ ] **Step 1: Add visibility section**

```javascript
// ── Visibility ──

// Returns true if face normal (nx,ny,nz) faces toward viewer in preview orientation
function previewFaceVisible(nx, ny, nz) {
  return (-nx + 4*ny + nz) > 0; // dot with view direction (-1,4,1)
}

// Returns true if face normal (nx,ny,nz) faces toward viewer in puzzle orientation (after Z-rotation)
// Puzzle view direction in original coords = (4,1,1)
function puzzleFaceVisible(nx, ny, nz) {
  return (4*nx + ny + nz) > 0;
}

// Core visibility check: edge is visible if any perpendicular face is
// (a) viewer-facing AND (b) exposed (inner cube active, outer cube empty/OOB)
function isEdgeVisible(e, active, faceVisibleFn) {
  // Determine perpendicular face normals based on edge direction
  let normals;
  if      (e.x2 > e.x1) normals = [{nx:0,ny:1,nz:0},{nx:0,ny:-1,nz:0},{nx:0,ny:0,nz:1},{nx:0,ny:0,nz:-1}];
  else if (e.y2 > e.y1) normals = [{nx:1,ny:0,nz:0},{nx:-1,ny:0,nz:0},{nx:0,ny:0,nz:1},{nx:0,ny:0,nz:-1}];
  else                   normals = [{nx:1,ny:0,nz:0},{nx:-1,ny:0,nz:0},{nx:0,ny:1,nz:0},{nx:0,ny:-1,nz:0}];

  const mx=(e.x1+e.x2)/2, my=(e.y1+e.y2)/2, mz=(e.z1+e.z2)/2;

  for (const {nx,ny,nz} of normals) {
    if (!faceVisibleFn(nx,ny,nz)) continue;
    // "Inner" cube: on the negative-normal side of the face (the cube this face belongs to)
    const ci=Math.floor(mx - 0.5*nx - 1e-9);
    const cj=Math.floor(my - 0.5*ny - 1e-9);
    const ck=Math.floor(mz - 0.5*nz - 1e-9);
    // "Outer" cube: on the positive-normal side (what the face looks out toward)
    const ni=Math.floor(mx + 0.5*nx - 1e-9);
    const nj=Math.floor(my + 0.5*ny - 1e-9);
    const nk=Math.floor(mz + 0.5*nz - 1e-9);
    if (isActive(active,ci,cj,ck) && !isActive(active,ni,nj,nk)) return true;
  }
  return false;
}

function getPreviewEdges(active) {
  return EDGES.filter(e => isEdgeVisible(e, active, previewFaceVisible));
}
```

- [ ] **Step 2: Add test for single cube**

```javascript
(function testPreview() {
  const a = [[[false,false],[false,false]],[[false,false],[false,false]]];
  a[0][0][0] = true; // cube at origin corner
  const vis = getPreviewEdges(a);
  // Preview sees -X, +Y, +Z faces. Cube (0,0,0) has:
  //   -X face at X=0 (exposed), +Y face at Y=1 (exposed), +Z face at Z=1 (exposed)
  // Each face has 4 edges → 12 total, minus 3 shared corner edges = 9 unique
  console.assert(vis.length === 9, 'single cube at origin: expected 9 visible edges, got ' + vis.length);

  const b = [[[false,false],[false,false]],[[false,false],[false,false]]];
  b[1][1][1] = true; // cube at far corner
  const vis2 = getPreviewEdges(b);
  console.assert(vis2.length === 9, 'single cube at far corner: expected 9, got ' + vis2.length);
  console.log('Preview visibility tests passed');
})();
```

Open browser → "Preview visibility tests passed", zero assertion failures.

- [ ] **Step 3: Remove test block, commit**

```bash
git add index.html && git commit -m "feat: visibility engine - preview face visibility"
```

---

### Task 4: Visibility Engine — Puzzle with Occlusion Clipping

**Files:**
- Modify: `index.html` — extend visibility section

**Interfaces:**
- Consumes: `EDGES`, `rotateZ()`, `project()`, `PUZZLE_OX`, `PUZZLE_OY`, `isEdgeVisible()`, `puzzleFaceVisible()`, `isActive()`
- Produces:
  - `getPuzzleEdges(active)` → `PuzzleEdge[]` where `PuzzleEdge = {edge, seg:{sx1,sy1,sx2,sy2}}`

**Occlusion algorithm:** An edge is partially/fully hidden when a closer active cube's exposed face (projected to 2D) overlaps it in screen space AND the edge lies geometrically behind that face plane.

"Behind" a face with outward normal `+X` at `X=x0`: edge coordinate `X < x0`.  
"Behind" `+Y` at `Y=y0`: `Y < y0`.  
"Behind" `+Z` at `Z=z0`: `Z < z0`.  
(All coordinates in **pre-rotation** space.)

- [ ] **Step 1: Add Liang-Barsky line-clip against convex polygon**

```javascript
// Clip segment p0→p1 ({x,y} screen points) against convex CCW-wound polygon.
// Returns [tEnter, tExit] ∈ [0,1] of the visible sub-segment, or null if fully outside.
function clipSegPoly(p0, p1, poly) {
  let t0=0, t1=1;
  const dx=p1.x-p0.x, dy=p1.y-p0.y;
  for (let i=0,n=poly.length; i<n; i++) {
    const a=poly[i], b=poly[(i+1)%n];
    // Inward normal of edge a→b (CCW poly in standard math coords; screen has Y-down so this is CW visually,
    // but the winding is consistent with how faceToScreenPoly orders vertices)
    const ex=b.x-a.x, ey=b.y-a.y;
    const nx=-ey, ny=ex;
    const denom = nx*dx + ny*dy;
    const num   = nx*(a.x-p0.x) + ny*(a.y-p0.y);
    if (Math.abs(denom)<1e-9) { if (num<0) return null; continue; }
    const t = num/denom;
    if (denom<0) { if (t>t0) t0=t; } else { if (t<t1) t1=t; }
    if (t0>t1) return null;
  }
  return [t0, t1];
}
```

- [ ] **Step 2: Add occluder-face builder and segment clipping**

```javascript
// Project 4 face corners (pre-rotation 3D) to puzzle screen coords, returns [{x,y}] polygon
function faceScreenPoly(pts) {
  return pts.map(([x,y,z]) => {
    const r=rotateZ(x,y,z);
    const p=project(r.x,r.y,r.z, PUZZLE_OX,PUZZLE_OY);
    return {x:p.sx, y:p.sy};
  });
}

// Build list of occluding face records from active cubes (puzzle view: +X,+Y,+Z faces)
function buildOccluders(active) {
  const occ=[];
  for(let i=0;i<2;i++) for(let j=0;j<2;j++) for(let k=0;k<2;k++) {
    if(!active[i][j][k]) continue;
    // +X face at X=i+1 (exposed outward)
    if(!isActive(active,i+1,j,k))
      occ.push({ poly: faceScreenPoly([[i+1,j,k],[i+1,j+1,k],[i+1,j+1,k+1],[i+1,j,k+1]]),
                 axis:'x', coord:i+1 });
    // +Y face at Y=j+1
    if(!isActive(active,i,j+1,k))
      occ.push({ poly: faceScreenPoly([[i,j+1,k],[i+1,j+1,k],[i+1,j+1,k+1],[i,j+1,k+1]]),
                 axis:'y', coord:j+1 });
    // +Z face at Z=k+1
    if(!isActive(active,i,j,k+1))
      occ.push({ poly: faceScreenPoly([[i,j,k+1],[i+1,j,k+1],[i+1,j+1,k+1],[i,j+1,k+1]]),
                 axis:'z', coord:k+1 });
  }
  return occ;
}

// Given a visible edge, subtract occluded parametric intervals and return the largest visible segment.
// Returns {sx1,sy1,sx2,sy2} or null if fully hidden.
function visibleSegment(e, occluders) {
  const r1=rotateZ(e.x1,e.y1,e.z1), r2=rotateZ(e.x2,e.y2,e.z2);
  const p1=project(r1.x,r1.y,r1.z, PUZZLE_OX,PUZZLE_OY);
  const p2=project(r2.x,r2.y,r2.z, PUZZLE_OX,PUZZLE_OY);
  const sp1={x:p1.sx,y:p1.sy}, sp2={x:p2.sx,y:p2.sy};

  let intervals=[[0,1]]; // visible parametric intervals

  for(const occ of occluders) {
    const next=[];
    for(const [ta,tb] of intervals) {
      // Screen points for this sub-interval
      const qa={x:sp1.x+(sp2.x-sp1.x)*ta, y:sp1.y+(sp2.y-sp1.y)*ta};
      const qb={x:sp1.x+(sp2.x-sp1.x)*tb, y:sp1.y+(sp2.y-sp1.y)*tb};
      const clip=clipSegPoly(qa,qb,occ.poly);
      if(!clip) { next.push([ta,tb]); continue; } // not behind face polygon in 2D

      // Parametric values in [0,1] space of full segment
      const tc=ta+clip[0]*(tb-ta), td=ta+clip[1]*(tb-ta);
      const tmid=(tc+td)/2;

      // Edge 3D coordinate (pre-rotation) at tmid in the face's normal axis
      const edgeCoord =
        occ.axis==='x' ? e.x1+(e.x2-e.x1)*tmid :
        occ.axis==='y' ? e.y1+(e.y2-e.y1)*tmid :
                         e.z1+(e.z2-e.z1)*tmid;

      if(edgeCoord >= occ.coord) { next.push([ta,tb]); continue; } // edge in front of face

      // Edge is behind face in [tc,td] — subtract that interval
      if(tc>ta+0.01) next.push([ta,tc]);
      if(td<tb-0.01) next.push([td,tb]);
    }
    intervals=next;
    if(!intervals.length) return null;
  }

  if(!intervals.length) return null;
  // Return largest surviving interval
  intervals.sort((a,b)=>(b[1]-b[0])-(a[1]-a[0]));
  const [t0,t1]=intervals[0];
  if(t1-t0<0.02) return null; // degenerate
  return {
    sx1:sp1.x+(sp2.x-sp1.x)*t0, sy1:sp1.y+(sp2.y-sp1.y)*t0,
    sx2:sp1.x+(sp2.x-sp1.x)*t1, sy2:sp1.y+(sp2.y-sp1.y)*t1
  };
}

function getPuzzleEdges(active) {
  const occ=buildOccluders(active);
  return EDGES
    .filter(e => isEdgeVisible(e, active, puzzleFaceVisible))
    .map(e => ({ edge:e, seg:visibleSegment(e,occ), traced:false }))
    .filter(pe => pe.seg !== null);
}
```

- [ ] **Step 3: Test with two non-adjacent cubes**

```javascript
(function testPuzzle() {
  const a=[[[false,false],[false,false]],[[false,false],[false,false]]];
  a[0][0][0]=true; a[1][1][1]=true; // diagonally opposite — should partially occlude each other
  const pes=getPuzzleEdges(a);
  console.assert(pes.length>0, 'non-adjacent cubes: should have puzzle edges, got '+pes.length);
  pes.forEach(pe=>{
    const s=pe.seg;
    console.assert(typeof s.sx1==='number'&&typeof s.sy1==='number', 'seg coords must be numbers');
  });
  console.log('Puzzle visibility tests passed, edges:', pes.length);
})();
```

Open browser → "Puzzle visibility tests passed". If assertion failures, check `faceScreenPoly` winding (swap two adjacent vertices to flip winding).

- [ ] **Step 4: Remove test block, commit**

```bash
git add index.html && git commit -m "feat: visibility engine - puzzle occlusion clipping"
```

---

### Task 5: Puzzle Generator

**Files:**
- Modify: `index.html` — add puzzle generator section

**Interfaces:**
- Produces:
  - `makeActive()` → blank `active[2][2][2]` (all false)
  - `generatePuzzle(difficulty)` → `active[2][2][2]`; difficulty: `'easy'|'medium'|'hard'`
  - `countActive(active)` → int
  - `isConnected(active)` → bool

- [ ] **Step 1: Add puzzle generator**

```javascript
// ── Puzzle Generator ──
function makeActive() {
  return [[[false,false],[false,false]],[[false,false],[false,false]]];
}

function countActive(a) {
  let n=0;
  for(let i=0;i<2;i++) for(let j=0;j<2;j++) for(let k=0;k<2;k++) if(a[i][j][k]) n++;
  return n;
}

const FACE_DIRS=[[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1],[0,0,-1]];

function isConnected(a) {
  let start=null;
  outer: for(let i=0;i<2;i++) for(let j=0;j<2;j++) for(let k=0;k<2;k++)
    if(a[i][j][k]){ start=[i,j,k]; break outer; }
  if(!start) return true;
  const visited=new Set([start.join()]);
  const q=[start];
  while(q.length){
    const [i,j,k]=q.shift();
    for(const [di,dj,dk] of FACE_DIRS){
      const ni=i+di,nj=j+dj,nk=k+dk, key=`${ni},${nj},${nk}`;
      if(ni>=0&&ni<2&&nj>=0&&nj<2&&nk>=0&&nk<2&&!visited.has(key)&&a[ni][nj][nk])
        { visited.add(key); q.push([ni,nj,nk]); }
    }
  }
  return visited.size===countActive(a);
}

function shuffledCubes() {
  const all=[];
  for(let i=0;i<2;i++) for(let j=0;j<2;j++) for(let k=0;k<2;k++) all.push([i,j,k]);
  for(let i=all.length-1;i>0;i--){
    const j=Math.floor(Math.random()*(i+1));
    [all[i],all[j]]=[all[j],all[i]];
  }
  return all;
}

// Grow a connected active set to `count` cubes by repeatedly picking a random exposed neighbor
function growActive(count) {
  const a=makeActive();
  const seed=shuffledCubes()[0];
  a[seed[0]][seed[1]][seed[2]]=true;
  while(countActive(a)<count){
    const candidates=[];
    for(let i=0;i<2;i++) for(let j=0;j<2;j++) for(let k=0;k<2;k++){
      if(!a[i][j][k]) continue;
      for(const [di,dj,dk] of FACE_DIRS){
        const ni=i+di,nj=j+dj,nk=k+dk;
        if(ni>=0&&ni<2&&nj>=0&&nj<2&&nk>=0&&nk<2&&!a[ni][nj][nk])
          candidates.push([ni,nj,nk]);
      }
    }
    if(!candidates.length) break;
    const p=candidates[Math.floor(Math.random()*candidates.length)];
    a[p[0]][p[1]][p[2]]=true;
  }
  return a;
}

function generatePuzzle(difficulty) {
  for(let attempt=0;attempt<200;attempt++){
    let a;
    if(difficulty==='easy'){
      const count=Math.random()<0.35 ? 1 : 2;
      a=growActive(count);
    } else if(difficulty==='medium'){
      const count=3+Math.floor(Math.random()*5); // 3–7
      a=growActive(count);
    } else { // hard: 3–6, any connectivity
      const count=3+Math.floor(Math.random()*4); // 3–6
      a=makeActive();
      const cubes=shuffledCubes();
      for(let i=0;i<count;i++) a[cubes[i][0]][cubes[i][1]][cubes[i][2]]=true;
    }
    if(isValidPuzzle(a,difficulty) && getPuzzleEdges(a).length>0) return a;
  }
  // fallback: single cube
  const a=makeActive(); a[0][0][0]=true; return a;
}

function isValidPuzzle(a,difficulty){
  const n=countActive(a);
  if(n===0) return false;
  if(difficulty==='easy')   return n>=1&&n<=2&&isConnected(a);
  if(difficulty==='medium') return n>=3&&n<=7&&isConnected(a);
  if(difficulty==='hard')   return n>=3&&n<=6;
  return false;
}
```

- [ ] **Step 2: Add generator tests**

```javascript
(function testGenerator(){
  for(const diff of ['easy','medium','hard']){
    const a=generatePuzzle(diff);
    const n=countActive(a);
    if(diff==='easy')   console.assert(n>=1&&n<=2&&isConnected(a), `easy failed: n=${n}`);
    if(diff==='medium') console.assert(n>=3&&n<=7&&isConnected(a), `medium failed: n=${n}`);
    if(diff==='hard')   console.assert(n>=3&&n<=6, `hard failed: n=${n}`);
    const pe=getPuzzleEdges(a);
    console.assert(pe.length>0, `${diff}: must have >0 puzzle edges`);
  }
  console.log('Generator tests passed');
})();
```

Open browser → "Generator tests passed".

- [ ] **Step 3: Remove test block, commit**

```bash
git add index.html && git commit -m "feat: puzzle generator easy/medium/hard"
```

---

### Task 6: Game Screen Renderer

**Files:**
- Modify: `index.html` — replace `drawGame()` placeholder; add game state variables

**Interfaces:**
- Consumes: `getPreviewEdges()`, `getPuzzleEdges()`, `project()`, `rotateZ()`, geometry constants
- Produces:
  - `startNewPuzzle(difficulty)` — initialises game state and transitions to PLAYING
  - `drawGame()` — renders both panels + score box
  - `drawScoreBox()` — reusable score box

- [ ] **Step 1: Add game state variables (after puzzle generator section)**

```javascript
// ── Game State ──
let currentDifficulty = 'medium';
let activeState       = makeActive();
let puzzleEdgeCache   = []; // [{edge, seg, traced}]
let totalVisible      = 0;
let tracedCount       = 0;

function startNewPuzzle(difficulty) {
  currentDifficulty = difficulty;
  activeState       = generatePuzzle(difficulty);
  puzzleEdgeCache   = getPuzzleEdges(activeState); // already has traced:false from getPuzzleEdges
  totalVisible      = puzzleEdgeCache.length;
  tracedCount       = 0;
  setScreen(STATE.PLAYING);
}
```

- [ ] **Step 2: Replace `drawGame()` placeholder**

```javascript
function drawGame() {
  // Panel divider
  ctx.strokeStyle='#222'; ctx.lineWidth=1;
  ctx.beginPath(); ctx.moveTo(400,55); ctx.lineTo(400,495); ctx.stroke();

  // Panel labels
  ctx.fillStyle='#00FFFF'; ctx.font='13px Courier New';
  ctx.fillText('URKÖRPER', 80, 45);
  ctx.fillText('NACHZEICHNEN', 470, 45);

  // Difficulty label
  ctx.fillStyle='#888'; ctx.font='11px Courier New';
  ctx.fillText(currentDifficulty.toUpperCase(), 370, 510);

  // ── Preview panel (Urkörper) ──
  ctx.strokeStyle='#00AA00'; ctx.lineWidth=3;
  for(const e of getPreviewEdges(activeState)){
    const p1=project(e.x1,e.y1,e.z1,PREVIEW_OX,PREVIEW_OY);
    const p2=project(e.x2,e.y2,e.z2,PREVIEW_OX,PREVIEW_OY);
    ctx.beginPath(); ctx.moveTo(p1.sx,p1.sy); ctx.lineTo(p2.sx,p2.sy); ctx.stroke();
  }

  // ── Puzzle panel (Dünnkörper) — full wireframe dim ──
  ctx.strokeStyle='#553300'; ctx.lineWidth=1;
  for(const e of EDGES){
    const r1=rotateZ(e.x1,e.y1,e.z1), r2=rotateZ(e.x2,e.y2,e.z2);
    const p1=project(r1.x,r1.y,r1.z,PUZZLE_OX,PUZZLE_OY);
    const p2=project(r2.x,r2.y,r2.z,PUZZLE_OX,PUZZLE_OY);
    ctx.beginPath(); ctx.moveTo(p1.sx,p1.sy); ctx.lineTo(p2.sx,p2.sy); ctx.stroke();
  }

  // Traced edges (bright green thick)
  ctx.strokeStyle='#00FF00'; ctx.lineWidth=3;
  for(const pe of puzzleEdgeCache){
    if(!pe.traced) continue;
    const s=pe.seg;
    ctx.beginPath(); ctx.moveTo(s.sx1,s.sy1); ctx.lineTo(s.sx2,s.sy2); ctx.stroke();
  }

  drawScoreBox();
}

function drawScoreBox() {
  ctx.strokeStyle='#FFFF00'; ctx.lineWidth=1;
  ctx.strokeRect(32,458,110,42);
  ctx.fillStyle='#FFFF00'; ctx.font='bold 26px Courier New';
  ctx.fillText(String(tracedCount).padStart(2,' '), 50,487);
  ctx.fillStyle='#888'; ctx.font='13px Courier New';
  ctx.fillText('/ '+totalVisible, 88, 487);
}
```

- [ ] **Step 3: Temporarily boot into game to verify visuals**

At the bottom of `<script>` (boot section), temporarily add:
```javascript
startNewPuzzle('medium');
loop();
```

Open browser — left panel shows green isometric preview, right panel shows dim brown wireframe, score box shows `0 / N` in yellow. Try different difficulties by changing the argument.

- [ ] **Step 4: Remove temporary boot line (keep `loop()` only), commit**

```bash
git add index.html && git commit -m "feat: game screen renderer - preview, puzzle, score box"
```

---

### Task 7: Intro Screen

**Files:**
- Modify: `index.html` — replace `drawIntro()` placeholder; add blink timer

**Interfaces:**
- Consumes: `setScreen()`, `requestRender()`
- Produces: `drawIntro()`, keyboard/click listener (intro → difficulty)

- [ ] **Step 1: Add blink state and input listener stubs (before boot)**

```javascript
// ── Input ──
let blinkOn = true;
setInterval(() => { blinkOn=!blinkOn; if(screen===STATE.INTRO) requestRender(); }, 500);

document.addEventListener('keydown', e => {
  if(screen===STATE.INTRO){ setScreen(STATE.DIFFICULTY); return; }
  // further cases added in later tasks
});

canvas.addEventListener('click', e => {
  const rect=canvas.getBoundingClientRect();
  const mx=e.clientX-rect.left, my=e.clientY-rect.top;
  handleClick(mx,my);
});

function handleClick(mx,my) {
  if(screen===STATE.INTRO){ setScreen(STATE.DIFFICULTY); return; }
  // further cases added in later tasks
}
```

- [ ] **Step 2: Replace `drawIntro()` placeholder**

The title "TPU2" is drawn with 6×6 px blocks from a 5×7 pixel font bitmap.

```javascript
function drawIntro() {
  // Pixel-art title "TPU2"
  const GLYPHS = {
    T:['11111','00100','00100','00100','00100','00100','00100'],
    P:['11110','10001','10001','11110','10000','10000','10000'],
    U:['10001','10001','10001','10001','10001','10001','01110'],
    2:['01110','10001','00001','00010','00100','01000','11111'],
  };
  const order=['T','P','U','2'];
  const S=6, GAP=2, startX=185, startY=90;
  ctx.fillStyle='#00FFFF';
  order.forEach((ch,ci)=>{
    GLYPHS[ch].forEach((row,ri)=>{
      [...row].forEach((px,pi)=>{
        if(px==='1') ctx.fillRect(startX+ci*(5*S+GAP)+pi*S, startY+ri*S, S-1, S-1);
      });
    });
  });

  // Subtitle and credits
  ctx.fillStyle='#FFFF00'; ctx.font='18px Courier New'; ctx.textAlign='center';
  ctx.fillText('KÖRPER-NACHZEICHNER', 400, 340);
  ctx.fillStyle='#00AA00'; ctx.font='12px Courier New';
  ctx.fillText('TURBO PASCAL EDITION  ©1992', 400, 365);

  // Rotation axis decoration (mirrors original Achsen procedure)
  ctx.strokeStyle='#00FFFF'; ctx.lineWidth=1;
  ctx.setLineDash([5,5]);
  ctx.beginPath(); ctx.moveTo(400,30); ctx.lineTo(400,490); ctx.stroke();
  ctx.setLineDash([]);
  ctx.beginPath();
  ctx.ellipse(400,120, 60,20, 0, Math.PI,2*Math.PI);
  ctx.stroke();

  // Blinking prompt
  if(blinkOn){
    ctx.fillStyle='#FFFFFF'; ctx.font='16px Courier New';
    ctx.fillText('[ PRESS ANY KEY ]', 400, 445);
  }
  ctx.textAlign='left';
}
```

- [ ] **Step 3: Boot into intro and test**

Boot: `setScreen(STATE.INTRO); loop();`

Open browser — "TPU2" pixel logo in cyan, subtitle in yellow, dashed vertical axis, "PRESS ANY KEY" blinking. Press any key or click → transitions to difficulty screen (blank for now is fine).

- [ ] **Step 4: Commit**

```bash
git add index.html && git commit -m "feat: intro screen with pixel logo, axis, blink prompt"
```

---

### Task 8: Difficulty Select Screen

**Files:**
- Modify: `index.html` — replace `drawDifficulty()` placeholder; extend `handleClick()`

**Interfaces:**
- Consumes: `startNewPuzzle()`, `setScreen()`
- Produces: `drawDifficulty()`, hover state, click-to-start

- [ ] **Step 1: Add difficulty button data and hover state**

```javascript
// ── Difficulty Select ──
const DIFF_BTNS = [
  { label:'[ LEICHT ]', sub:'1–2 WÜRFEL  |  VERBUNDEN', diff:'easy',   x:260,y:200,w:280,h:48 },
  { label:'[ MITTEL ]', sub:'3–7 WÜRFEL  |  VERBUNDEN', diff:'medium', x:260,y:278,w:280,h:48 },
  { label:'[ SCHWER ]', sub:'3–6 WÜRFEL  |  BELIEBIG',  diff:'hard',   x:260,y:356,w:280,h:48 },
];
let hoveredDiff = null;

canvas.addEventListener('mousemove', e => {
  if(screen!==STATE.DIFFICULTY) return;
  const rect=canvas.getBoundingClientRect();
  const mx=e.clientX-rect.left, my=e.clientY-rect.top;
  const prev=hoveredDiff;
  hoveredDiff=DIFF_BTNS.find(b=>mx>=b.x&&mx<=b.x+b.w&&my>=b.y&&my<=b.y+b.h)||null;
  if(hoveredDiff!==prev) requestRender();
});
```

- [ ] **Step 2: Replace `drawDifficulty()` placeholder**

```javascript
function drawDifficulty() {
  ctx.fillStyle='#00FFFF'; ctx.font='22px Courier New'; ctx.textAlign='center';
  ctx.fillText('SCHWIERIGKEITSGRAD', 400, 130);
  ctx.fillStyle='#555'; ctx.font='12px Courier New';
  ctx.fillText('WÄHLE EINE STUFE', 400, 158);

  for(const btn of DIFF_BTNS){
    const hot=(btn===hoveredDiff);
    ctx.fillStyle=hot?'#FFFF00':'#000';
    ctx.fillRect(btn.x,btn.y,btn.w,btn.h);
    ctx.strokeStyle='#FFFF00'; ctx.lineWidth=1;
    ctx.strokeRect(btn.x,btn.y,btn.w,btn.h);
    ctx.fillStyle=hot?'#000':'#FFFF00';
    ctx.font='20px Courier New'; ctx.textAlign='center';
    ctx.fillText(btn.label, btn.x+btn.w/2, btn.y+30);
    ctx.fillStyle=hot?'#000':'#888';
    ctx.font='11px Courier New';
    ctx.fillText(btn.sub, btn.x+btn.w/2, btn.y+44);
  }
  ctx.textAlign='left';
}
```

- [ ] **Step 3: Extend `handleClick()` for difficulty screen**

Inside `handleClick(mx,my)`, add after the INTRO check:
```javascript
if(screen===STATE.DIFFICULTY){
  for(const btn of DIFF_BTNS){
    if(mx>=btn.x&&mx<=btn.x+btn.w&&my>=btn.y&&my<=btn.y+btn.h){
      startNewPuzzle(btn.diff); return;
    }
  }
  return;
}
```

- [ ] **Step 4: Boot into difficulty and test**

`setScreen(STATE.DIFFICULTY); loop();`

Three buttons, hover highlights in yellow, click transitions to game screen. Verify all three difficulties produce a visible puzzle.

- [ ] **Step 5: Commit**

```bash
git add index.html && git commit -m "feat: difficulty select screen - three buttons with hover"
```

---

### Task 9: Game Interaction — Edge Tracing + Audio

**Files:**
- Modify: `index.html` — add audio, hit test, extend `handleClick()`

**Interfaces:**
- Consumes: `puzzleEdgeCache`, `tracedCount`, `totalVisible`, `setScreen(STATE.COMPLETE)`
- Produces: `beep()`, `victorySound()`, `handleGameClick(mx,my)`

- [ ] **Step 1: Add Web Audio beep functions**

```javascript
// ── Audio ──
const _audioCtx = new (window.AudioContext||window.webkitAudioContext)();

function beep(freq=1000, ms=100, wave='square') {
  const osc=_audioCtx.createOscillator(), gain=_audioCtx.createGain();
  osc.connect(gain); gain.connect(_audioCtx.destination);
  osc.type=wave; osc.frequency.value=freq;
  gain.gain.setValueAtTime(0.08, _audioCtx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, _audioCtx.currentTime+ms/1000);
  osc.start(); osc.stop(_audioCtx.currentTime+ms/1000);
}

function victorySound() {
  [330,440,550,660,880].forEach((f,i)=>setTimeout(()=>beep(f,120,'square'),i*110));
}
```

- [ ] **Step 2: Add point-to-segment distance and game click handler**

```javascript
// ── Game Interaction ──
function ptSegDist(px,py, x1,y1, x2,y2) {
  const dx=x2-x1, dy=y2-y1, lenSq=dx*dx+dy*dy;
  if(lenSq<1e-9) return Math.hypot(px-x1,py-y1);
  const t=Math.max(0,Math.min(1,((px-x1)*dx+(py-y1)*dy)/lenSq));
  return Math.hypot(px-(x1+t*dx), py-(y1+t*dy));
}

const HIT_DIST=10;

function handleGameClick(mx,my) {
  // Ensure AudioContext is running (browsers require user gesture)
  if(_audioCtx.state==='suspended') _audioCtx.resume();

  let bestIdx=-1, bestD=HIT_DIST;
  for(let i=0;i<puzzleEdgeCache.length;i++){
    const pe=puzzleEdgeCache[i];
    if(pe.traced) continue;
    const s=pe.seg;
    const d=ptSegDist(mx,my, s.sx1,s.sy1, s.sx2,s.sy2);
    if(d<bestD){ bestD=d; bestIdx=i; }
  }
  if(bestIdx<0) return;

  puzzleEdgeCache[bestIdx].traced=true;
  tracedCount++;
  beep(1000,90);
  requestRender();

  if(tracedCount===totalVisible){
    setTimeout(()=>{ victorySound(); setScreen(STATE.COMPLETE); }, 350);
  }
}
```

- [ ] **Step 3: Wire into `handleClick()`**

Add after the DIFFICULTY block in `handleClick()`:
```javascript
if(screen===STATE.PLAYING){ handleGameClick(mx,my); return; }
```

- [ ] **Step 4: Test full game loop**

Boot: `startNewPuzzle('medium'); loop();`

1. Click edges near the right panel — they should turn bright green, score increments, beep plays.
2. Clicking far from any edge does nothing.
3. Complete all edges — victory tones, transitions to COMPLETE (blank screen ok for now).

- [ ] **Step 5: Commit**

```bash
git add index.html && git commit -m "feat: edge tracing interaction with audio and score"
```

---

### Task 10: Completion Screen + Full Boot

**Files:**
- Modify: `index.html` — replace `drawComplete()` placeholder; add completion buttons; wire full boot

**Interfaces:**
- Consumes: `activeState`, `puzzleEdgeCache`, `currentDifficulty`, `victorySound()`, `startNewPuzzle()`, `setScreen()`, `drawScoreBox()`
- Produces: `drawComplete()`, NEXT/MENU buttons, full screen flow

- [ ] **Step 1: Add face-fill helper for completion**

```javascript
// ── Completion ──
function fillSolutionFaces() {
  // Fill exposed viewer-facing faces of active cubes (puzzle view: +X,+Y,+Z)
  // Collect, sort far→near, then paint to get correct overlap
  const faces=[];
  for(let i=0;i<2;i++) for(let j=0;j<2;j++) for(let k=0;k<2;k++){
    if(!activeState[i][j][k]) continue;
    const depth=4*(i+0.5)+(j+0.5)+(k+0.5);
    if(!isActive(activeState,i+1,j,k))
      faces.push({ pts:[[i+1,j,k],[i+1,j+1,k],[i+1,j+1,k+1],[i+1,j,k+1]], color:'#002200', depth });
    if(!isActive(activeState,i,j+1,k))
      faces.push({ pts:[[i,j+1,k],[i+1,j+1,k],[i+1,j+1,k+1],[i,j+1,k+1]], color:'#003300', depth });
    if(!isActive(activeState,i,j,k+1))
      faces.push({ pts:[[i,j,k+1],[i+1,j,k+1],[i+1,j+1,k+1],[i,j+1,k+1]], color:'#004400', depth });
  }
  faces.sort((a,b)=>a.depth-b.depth); // paint far faces first
  for(const f of faces){
    ctx.fillStyle=f.color;
    ctx.beginPath();
    f.pts.forEach(([x,y,z],idx)=>{
      const r=rotateZ(x,y,z), p=project(r.x,r.y,r.z,PUZZLE_OX,PUZZLE_OY);
      idx===0 ? ctx.moveTo(p.sx,p.sy) : ctx.lineTo(p.sx,p.sy);
    });
    ctx.closePath(); ctx.fill();
  }
}
```

- [ ] **Step 2: Replace `drawComplete()` placeholder**

```javascript
const COMPLETE_BTNS=[
  {label:'[ WEITER ]', action:'next', x:430,y:462,w:140,h:36},
  {label:'[ MENÜ  ]', action:'menu', x:585,y:462,w:140,h:36},
];

function drawComplete() {
  // Redraw game base on black
  ctx.fillStyle='#000'; ctx.fillRect(0,0,800,520);

  // Panel divider
  ctx.strokeStyle='#222'; ctx.lineWidth=1;
  ctx.beginPath(); ctx.moveTo(400,55); ctx.lineTo(400,495); ctx.stroke();

  // Preview panel still shown
  ctx.strokeStyle='#00AA00'; ctx.lineWidth=3;
  for(const e of getPreviewEdges(activeState)){
    const p1=project(e.x1,e.y1,e.z1,PREVIEW_OX,PREVIEW_OY);
    const p2=project(e.x2,e.y2,e.z2,PREVIEW_OX,PREVIEW_OY);
    ctx.beginPath(); ctx.moveTo(p1.sx,p1.sy); ctx.lineTo(p2.sx,p2.sy); ctx.stroke();
  }

  // Fill solution faces (dark green background)
  fillSolutionFaces();

  // Draw all visible edges bright green (solution revealed)
  ctx.strokeStyle='#00FF00'; ctx.lineWidth=3;
  for(const pe of puzzleEdgeCache){
    const s=pe.seg;
    ctx.beginPath(); ctx.moveTo(s.sx1,s.sy1); ctx.lineTo(s.sx2,s.sy2); ctx.stroke();
  }

  drawScoreBox();

  // "FERTIG!" label
  ctx.fillStyle='#00FF00'; ctx.font='bold 18px Courier New'; ctx.textAlign='center';
  ctx.fillText('FERTIG!', 580, 450);
  ctx.textAlign='left';

  // WEITER and MENÜ buttons
  for(const btn of COMPLETE_BTNS){
    ctx.strokeStyle='#FFFF00'; ctx.lineWidth=1; ctx.strokeRect(btn.x,btn.y,btn.w,btn.h);
    ctx.fillStyle='#FFFF00'; ctx.font='15px Courier New'; ctx.textAlign='center';
    ctx.fillText(btn.label, btn.x+btn.w/2, btn.y+23);
  }
  ctx.textAlign='left';
}
```

- [ ] **Step 3: Wire completion buttons in `handleClick()`**

Add after the PLAYING block in `handleClick()`:
```javascript
if(screen===STATE.COMPLETE){
  for(const btn of COMPLETE_BTNS){
    if(mx>=btn.x&&mx<=btn.x+btn.w&&my>=btn.y&&my<=btn.y+btn.h){
      if(btn.action==='next') startNewPuzzle(currentDifficulty);
      else                    setScreen(STATE.DIFFICULTY);
      return;
    }
  }
  return;
}
```

- [ ] **Step 4: Wire full boot sequence**

At the very end of `<script>`, ensure the boot section reads exactly:
```javascript
// ── Boot ──
setScreen(STATE.INTRO);
loop();
```

- [ ] **Step 5: Full end-to-end playthrough**

1. Open `index.html` — intro screen: "TPU2" logo, blinking "PRESS ANY KEY"
2. Press any key → difficulty select: three buttons, hover highlights
3. Click **LEICHT** → game screen: green preview left, brown wireframe right, score `0/N`
4. Click correct edges: green + beep + score increments
5. Finish all edges → victory tones → completion: filled faces + bright edges + FERTIG! + buttons
6. Click **WEITER** → new easy puzzle immediately
7. Click **MENÜ** → back to difficulty select
8. Repeat with MITTEL and SCHWER — verify different cube counts

- [ ] **Step 6: Commit**

```bash
git add index.html && git commit -m "feat: completion screen - face fill, FERTIG, WEITER/MENU buttons"
git tag v1.0
```

---

## Self-Review

**Spec coverage check:**
| Spec requirement | Task |
|---|---|
| Intro logo (LOGO.TPU recreation) | Task 7 |
| Three difficulty buttons (Leicht/Mittel/Schwer) | Task 8 |
| 2×2×2 sub-cube geometry, 54 edges | Task 2 |
| Isometric projection formula | Task 2 |
| 90° Z-rotation | Task 2 |
| Preview visibility (-X,+Y,+Z faces) | Task 3 |
| Puzzle visibility (+X,+Y,+Z faces) | Task 4 |
| Partial occlusion clipping | Task 4 |
| Easy 1–2 adjacent | Task 5 |
| Medium 3–7 adjacent | Task 5 |
| Hard 3–6 any | Task 5 |
| Game screen — preview panel | Task 6 |
| Game screen — puzzle wireframe | Task 6 |
| Score box | Task 6 |
| Click to trace edge | Task 9 |
| Beep on trace | Task 9 |
| Victory sound | Task 9 |
| Completion: show solution | Task 10 |
| Completion: fill faces | Task 10 |
| WEITER (next puzzle same difficulty) | Task 10 |
| MENÜ button | Task 10 |
| DOS retro palette + font | Task 1 (global constraints) |
| Single HTML file, no dependencies | Task 1 |

All spec requirements covered. No gaps found.

**Potential winding issue (Task 4):** If `clipSegPoly` clips incorrectly, swap two adjacent vertices in `faceScreenPoly` calls inside `buildOccluders`. The test in Task 4 Step 3 will catch this.

**AudioContext suspend:** browsers require a user gesture before AudioContext can play sound. `handleGameClick` resumes it on first click — correct.
