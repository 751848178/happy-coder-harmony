# Message List Blank Space After Receiving New Messages — 2026-04-17

## Problem

After receiving new messages via socket, a blank space appears at the bottom of the message list. The list eventually scrolls to the bottom after a delay, but the blank space is visible for one or more frames.

## Root Cause

The scroll architecture has two mechanisms for maintaining scroll position when content changes:

1. **`_ChatScrollController.standbyForAppend()`** — records scroll state before content change, then `_ChatScrollPosition.applyContentDimensions()` corrects the scroll offset **synchronously during layout** (before paint). This is zero-flicker.

2. **`scheduleScrollToLatest()`** — schedules `_scrollToLatestUntilSettled()` via a **post-frame callback**. This fires AFTER the frame is painted, so the user sees the wrong position for at least one frame.

The `standbyForAppend()` mechanism was only used in edge-load functions (`_loadNewerArchivedMessages`, `_loadOlderArchivedMessages`), but NOT in the normal socket-triggered message update path.

**The socket message flow:**
1. Socket event → `_scheduleMessageRefresh(autoScroll: true)` (150ms debounce)
2. `loadSessionMessages()` → network request
3. `_syncMessagesFromRepository()` → updates `_messageViewStateN` → triggers rebuild
4. **Rebuild happens with no standby** → ListView adds new content below, scroll position unchanged → **blank space**
5. `_scheduleScrollToLatest(animate: true, force: true)` → post-frame callback → eventually corrects

The total delay before scroll correction: 150ms debounce + network time + post-frame delay + up to 8 settle iterations.

## Fix

Added `standbyForAppend()` call in `_syncMessagesFromRepository()` when the user is near the bottom or hasn't scrolled to latest yet. The synchronous correction in `_ChatScrollPosition.applyContentDimensions()` keeps the scroll position at the bottom during layout, eliminating the blank space.

```dart
if (nextState.hasLoadedMessages &&
    nextState.messages.isNotEmpty &&
    _scrollController.hasClients &&
    (_shouldStickToLatest || !_hasScrolledToLatest) &&
    !nextState.hasNewerMessages) {
  _scrollController.standbyForAppend();
}
```

The conditions ensure:
- `nextState.hasLoadedMessages && messages.isNotEmpty` — messages are actually available
- `_shouldStickToLatest || !_hasScrolledToLatest` — user is at bottom or hasn't scrolled yet
- `!nextState.hasNewerMessages` — not viewing an archived window (would interfere with archive scroll position)
- `_scrollController.hasClients` — controller is attached

The standby is consumed one-shot in `applyContentDimensions`, so it doesn't interfere with subsequent scroll operations.

### File

`lib/features/session/screens/session_screen.dart` — `_syncMessagesFromRepository()`

## How It Works With Existing Scroll System

- `scheduleScrollToLatest()` still runs as a fallback (for cases where the synchronous correction isn't enough, e.g., large content jumps)
- The synchronous correction handles the common case (new messages appended while at bottom)
- Edge-load functions already have their own `standbyForAppend()`/`standbyForPrepend()` calls, which take precedence since standby is one-shot
