# Session Scroll: Viewport Anchor Alignment & Edge Load State Corruption

Date: 2026-04-14
Status: In Progress
Severity: P0 — user-visible scroll breakage

## Symptoms

1. **Auto-jump to bottom**: Scrolling up from bottom, after a while the view snaps back to the latest message
2. **Message jumping**: Messages visually shift/jump during upward scrolling (edge loads prepend content)
3. **White screen flash**: Brief blank screen during edge load scroll correction
4. **Progressive lag**: After scrolling through many messages, the list becomes janky
5. **Stuck at position**: After edge loading, can't scroll further even though more messages exist

## Root Cause Analysis

### RC-1: Anchor captured from wrong viewport edge (causes #1, #2)

`_loadOlderArchivedMessages()` captures anchor with `alignToBottom: true` (bottom-most visible message).
`_loadNewerArchivedMessages()` captures anchor with `alignToBottom: false` (top-most visible message).

**This is backwards.** When `prependMessageWindow` trims from the tail to keep window ≤ 288, the bottom-most message is the one most likely to be trimmed. When `appendMessageWindow` trims from the head, the top-most message is most likely to be trimmed.

Correct alignment:
- **Load older** (prepend, trim tail): capture from **top** (`alignToBottom: false`)
- **Load newer** (append, trim head): capture from **bottom** (`alignToBottom: true`)

### RC-2: `_userHasScrolledUp` reset during edge loading (causes #1)

In `handleScrollMetricsChanged()`, the reset `if (nextShouldStickToLatest && _userHasScrolledUp)` fires during edge loading when content metrics change and the position happens to be near the bottom. Combined with `_hasScrolledToLatest = false` and `_hasNewerMessages = false`, the body effects check passes and triggers scroll-to-latest.

### RC-3: `_hasScrolledToLatest` incorrectly cleared during edge load (causes #1)

`_loadOlderArchivedMessages()` unconditionally sets `_hasScrolledToLatest = false`. This flag should only be cleared by initial load or jump-to-boundary operations, not by incremental edge loads.

### RC-4: Flicker suppression must keep ListView in widget tree (causes #2, #5)

**Critical lesson:** The `ListView.builder` MUST remain in the widget tree during flicker suppression so that `_BuildContextAnchor` widgets keep message-row `BuildContext`s registered. Without them, `_restoreMessageViewportAnchorAfterFrame` can't find the anchor message's render object and silently fails, causing both jumping and stuck-at-position.

Never replace the ListView with a spinner — always build the list and use `Opacity(opacity: 0)` to hide it.

### RC-5: Autoload not re-armed after edge load (causes #5)

After edge loading, `_topEdgeAutoloadArmed = false`. The re-arm requires `position.pixels > trigger + 180` (~680px). With `alignToBottom: false`, anchor restore places the user near the top, so re-arm can't happen. User gets stuck.

Fix: `recordEdgeLoadCompleted` re-arms autoload with a 200ms cooldown.

### RC-6: Sticky prompt refresh during edge load (causes #4)

`_refreshStickyTurnPrompt()` calls `getOffsetToReveal()` on the render tree. Skipping it during edge loading reduces overhead.

## Fixes

| Fix | Root Cause | Description |
|-----|-----------|-------------|
| Swap anchor alignment | RC-1 | older→alignToBottom:false, newer→alignToBottom:true |
| Guard `_userHasScrolledUp` reset | RC-2 | Skip reset when `_isLoadingOlder/NewerMessages` |
| Keep `_hasScrolledToLatest` during edge load | RC-3 | Remove `_hasScrolledToLatest = false` from `_loadOlderArchivedMessages` |
| Always build ListView (opacity hide only) | RC-4 | Never replace list with spinner during flicker suppression |
| Re-arm autoload after edge load | RC-5 | `recordEdgeLoadCompleted` re-arms with 200ms cooldown |
| Skip sticky prompt during edge loading | RC-6 | Check `_isLoadingOlder/NewerMessages` before scheduling refresh |
