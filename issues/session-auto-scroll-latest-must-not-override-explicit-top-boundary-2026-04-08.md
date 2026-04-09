# Session Auto Scroll Latest Must Not Override Explicit Top Boundary

## Date
- 2026-04-08

## Symptom
- Real-device reproduction showed:
  1. Tap `到顶`
  2. Earliest window loads
  3. Message list immediately starts flashing / jumping
  4. Flutter framework assertions follow

## Confirmed Root Cause
- The detail body effect layer still had a generic auto-scroll rule:
  - when `messages.isNotEmpty`
  - and `!hasScrolledToLatest`
  - and `!userHasScrolledUp`
  - then schedule `scrollToLatest()`
- Explicit top-boundary navigation was loading the earliest window while `userHasScrolledUp` was still `false`, so the body effect misclassified that state as “initial entry still needs to pin to latest”.
- Real-device logs confirmed the sequence:
  - `load-earliest result ... start=0 loaded=30`
  - immediately followed by `scroll-latest`

## Fix
- Mark explicit `scrollToTop()` as a real leave-latest action:
  - `_userHasScrolledUp = true`
  - `_shouldStickToLatest = false`
- Narrow body auto-scroll eligibility:
  - auto-scroll to latest now only runs when the current window has no newer history (`hasNewerMessages == false`)

## Prevention Rule
- Any “auto pin to latest” behavior must be gated by “already on latest window”, not just by generic scroll booleans.
- Explicit boundary navigation must always override passive auto-scroll policies.
