# Virtual List Code Review — 2026-04-17

## Scope

Line-by-line review of the virtual message list implementation:

- `session_screen_view_messages.dart` — ListView builder, `_ChatScrollController`, `_ChatScrollPosition`, `_FlatMessageItem`, `_BuildContextAnchor`, `_RenderObjectAnchor`
- `session_screen_viewport_controller.dart` — Edge autoload, scroll-to-latest settle loop, scroll metrics handler
- `session_screen_body_presenter.dart` — Turn group → flat item resolution, append-mode caching
- `session_screen.dart` — `_syncMessagesFromRepository`, message change subscription
- `session_screen_state_refresh.dart` — Edge-load functions, anchor capture/restore
- `session_screen_body_effects.dart` — Post-frame effects

## Issues Found & Fixed

### 1. Standby Conflict Between `_syncMessagesFromRepository` and Edge Loads (Critical)

**Problem:** `_syncMessagesFromRepository` (session_screen.dart:505-511) unconditionally called `standbyForAppend()` when user was near bottom. Edge-load functions set their own standby mode (`standbyForPrepend` for older, `standbyForAppend` for newer) BEFORE calling `_syncMessagesFromRepository()`. Since standby is one-shot and gets consumed in the next layout pass, the edge-load's standby was overwritten by the generic one.

Specifically, `_loadOlderArchivedMessages` (line 306) called `standbyForPrepend()` then `_syncMessagesFromRepository()` which overwrote with `standbyForAppend()` — causing the scroll to correct in the wrong direction (shifting UP instead of DOWN when prepending messages).

**Fix:** Added `!_isLoadingOlderMessages && !_isLoadingNewerMessages` guard to the standby condition in `_syncMessagesFromRepository`. Edge loads already set their own standby before calling this method, so the generic standby should not interfere.

**File:** `lib/features/session/screens/session_screen.dart` — `_syncMessagesFromRepository()`

### 2. `_standbyAlignToBottom` Not Consumed After Correction (Code Quality)

**Problem:** `_ChatScrollPosition.applyContentDimensions()` consumed `_standbyPixels` and `_standbyMaxScrollExtent` by setting them to null, but `_standbyAlignToBottom` was left as stale state. While this doesn't cause logical errors (the bool is only read when `_standbyPixels != null`), it leaves the controller in a dirty state.

**Fix:** Capture `alignToBottom` into a local variable, then reset `_standbyAlignToBottom = false` alongside the other standby fields.

**File:** `lib/features/session/screens/session_screen_view_messages.dart` — `_ChatScrollPosition.applyContentDimensions()`

## Architecture Summary

### Data Flow

```
Socket/API → Repository → _subscribeToMessageChanges → _scheduleMessageSync (microtask)
  → _syncMessagesFromRepository → _messageViewStateN → build → _buildMessageList
  → _bodyPresenter.resolveFlatItems → ListView.builder (per-message virtualization)
```

### Scroll Correction System (Two Layers)

1. **Synchronous (zero-flicker):** `_ChatScrollController.standbyForAppend/Prepend` → records `pixels` + `maxScrollExtent` → `_ChatScrollPosition.applyContentDimensions` corrects `forcePixels()` during layout (before paint). Used by edge-load functions and near-bottom message updates.

2. **Asynchronous (fallback):** `scheduleScrollToLatest` → post-frame callback → `_scrollToLatestUntilSettled` → up to 8 settle iterations. Used for initial scroll-to-latest and cases where synchronous correction isn't sufficient.

### Edge Load System

- **Trigger:** `_maybeContinueHistoryFromTopEdge` / `_maybeContinueHistoryFromBottomEdge` — called from `handleScrollMetricsChanged` (scroll listener)
- **Arming:** `_topEdgeAutoloadArmed` / `_bottomEdgeAutoloadArmed` — disarmed on trigger, re-armed when user scrolls past `rearmGap` distance
- **Blocking:** `_topEdgeBlockReason` / `_bottomEdgeBlockReason` — checks in-flight, loading, programmatic scroll, suspension, viewport readiness, arming, scroll trend
- **Cooldown:** `_suspendEdgeAutoload` with configurable duration (default 480ms)
- **Scroll preservation:** anchor capture before load → standby for prepend/append → sync messages → anchor restore after frame

### Per-Message Virtualization

- `_FlatMessageItem` wraps each `ReducerMessage` with turn-group metadata
- `_SessionScreenBodyPresenter.resolveFlatItems` generates flat items from turn groups with append-mode caching (`identical` checks to avoid rebuilding unchanged turns)
- `ListView.builder` with `cacheExtent: 480`, `ClampingScrollPhysics`
- `_BuildContextAnchor` with `AutomaticKeepAliveClientMixin` registers message contexts synchronously via `_RenderObjectAnchorElement.mount`
- `findChildIndexCallback` maps `ValueKey<String>` (message ID) to flat item index for efficient key-based recycling
