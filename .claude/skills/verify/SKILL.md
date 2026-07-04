---
name: verify
description: Verify ROTAXIS changes by driving index.html in headless Chromium via Playwright.
---

# Verifying ROTAXIS changes

No build step — the surface is `index.html` opened directly via
`file:///home/user/Rotax1992/index.html` (no server needed).

## Launch

Playwright is not in the repo; install it in the scratchpad
(`npm init -y && npm install playwright` — browsers are pre-installed,
postinstall download is skipped). Launch with:

```js
const { chromium } = require('playwright');
const browser = await chromium.launch({
  executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome'
});
// Mobile: newContext({ viewport:{width:844,height:390}, hasTouch:true, isMobile:true, deviceScaleFactor:2 })
```

## Drive

- All top-level `let` globals of the inline script (`screen`, `gameScale`,
  `viewZoom`, `viewPanX/Y`, `tracedCount`, `totalVisible`, `DIFF_BTNS`,
  `MENU_BTN`, `puzzleEdgeCache`, …) are readable from `page.evaluate`.
- Game coords (800×530 design space) → client px:
  `rect.left + (gx*viewZoom + viewPanX) * gameScale` (rect from
  `canvas.getBoundingClientRect()`).
- Navigate: tap/click anywhere on INTRO → DIFFICULTY; tap the center of a
  `DIFF_BTNS` entry to start a puzzle (`screen` becomes 2 = PLAYING).
- To click an edge: take an untraced entry of `puzzleEdgeCache`, use the
  midpoint of its `seg` (`sx1,sy1,sx2,sy2`, design coords), convert, click,
  then assert `tracedCount` incremented.

## Gotchas

- `Input.synthesizePinchGesture` (CDP) does NOT produce real touch pinches
  here — synthesize pinch/pan manually with `Input.dispatchTouchEvent`
  (touchStart with two points, touchMove steps, touchEnd with `[]`).
- Taps fire on `touchend` (not touchstart) so a tap that moves >~9 CSS px
  becomes a pan, and two fingers become a pinch.
- Audio is Web Audio only; headless runs fine, no flags needed.
