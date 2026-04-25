# Session Cache Persist, Refresh Stuck, Sync Skip, and Preview Stale — 2026-04-17

## Summary

Four interrelated bugs in session message persistence, refresh UX, full sync, and session list preview updates.

## Issue 1: Messages not restored when app is closed during execution and reopened

### Root Cause

`session_service_cache_coordinator.dart` line 94-95: `canPersistLoadedWindow` required `hasNewerMessages != true`. During active execution, new messages arrive constantly via socket, so `hasNewerMessages` is almost always `true`. This prevented ANY messages from being persisted to local cache.

```dart
// BEFORE (broken)
final canPersistLoadedWindow = cachedMessages?.isLoaded == true &&
    cachedMessages?.hasNewerMessages != true;
```

When the app was killed and reopened, `restoreSessionMessagesFromCache` found no cached messages, resulting in a blank screen.

### Fix

Removed the `hasNewerMessages` gate. The snapshot already caps at 30 messages via `_tailSnapshotMessages`, so persisting a partial window is safe and always better than persisting nothing.

```dart
// AFTER (fixed)
final canPersistLoadedWindow = cachedMessages?.isLoaded == true;
```

### File

`lib/features/session/domain/session_service_cache_coordinator.dart`

---

## Issue 2: Refresh button stuck in loading state

### Root Cause

`session_screen_state_refresh.dart` line 615-624: `_refreshSessionState` uses `Future.wait` with 3 futures (loadSessions, loadMachines, socket initialize). If any future hangs (e.g., socket connection never completes), the `Future.wait` never resolves, and `_setSessionRefreshing(false)` in the `finally` block never runs.

### Fix

Added `.timeout(const Duration(seconds: 15))` to the `Future.wait` call. A `TimeoutException` triggers the `catch` block, which shows an error snackbar and clears the loading state via `finally`.

### File

`lib/features/session/screens/session_screen_state_refresh.dart`

---

## Issue 3: Full message sync not making actual requests

### Root Cause

`session_service_message_archive_coordinator.dart` line 541-551: `_syncFullSessionMessagesFromRemoteInternal` checks `_isArchiveSummaryCompleteForExpectedCount` using a locally computed `expectedMessageCount` derived from stale repository data. When the local `totalMessageCount` matches the archive summary's `messageCount`, the check returns `true` and sync is skipped — even though the server may have many more messages.

This was especially likely after the app restarted from cache with stale counts.

### Fix

Added a `forceSync` parameter through the call chain:
- `syncFullSessionMessagesFromRemote` passes `forceSync: true`
- `_runArchiveHydrationTask` forwards `forceSync`
- `_syncFullSessionMessagesFromRemoteInternal` skips the completeness check when `forceSync=true`

Automatic hydration (via `ensureSessionMessageArchiveHydrated`) still uses the completeness check to avoid redundant work.

### Files

`lib/features/session/domain/session_service_message_archive_coordinator.dart`

---

## Issue 4: Session list not continuously updating status and messages

### Root Cause

`session_service_message_coordinator.dart` line 32-38: `loadSessionMessages` with `force=false` skipped entirely when `hasNewerMessages==true`. The session list's preview refresh (`_refreshSessionPreviewNow` in `sessions_screen_refresh_controller.dart`) calls `loadSessionMessages` without force and with `maxPages` set. When a session had been scrolled back in archive view, `hasNewerMessages` was `true`, and the preview refresh was silently skipped.

This meant:
- Socket events triggered `_scheduleSessionPreviewRefresh`
- But `_refreshSessionPreviewNow` → `loadSessionMessages` was blocked
- Preview text, lastMessageAt, and listStatusKind never updated

### Fix

Changed the `hasNewerMessages` early-return guard to also check `maxPages`. When `maxPages` is set (indicating a bounded preview refresh), the check is bypassed. This is safe because:

1. Preview refresh only runs when session detail is NOT active (`_isSessionDetailActive` guard in `sessions_screen_refresh_controller.dart`)
2. After the refresh fetches latest messages, the window moves to the latest position, so `hasNewerMessages` becomes `false`
3. `_syncSessionPreviewFieldsFromMessages` correctly updates preview fields once the window is at the latest position

```dart
// BEFORE
if (!force && existing?.hasNewerMessages == true) {

// AFTER
if (!force && maxPages == null && existing?.hasNewerMessages == true) {
```

### Files

`lib/features/session/domain/session_service_message_coordinator.dart`

---

## Testing Notes

- **Issue 1**: Open session during active execution → force kill app → reopen → messages should restore from cache
- **Issue 2**: Disconnect network → tap refresh → should show error after 15s and clear loading state
- **Issue 3**: Open session with existing archive → tap "sync all messages" → network tab should show API requests
- **Issue 4**: Open session detail → scroll back in history → go back to session list → receive new messages → session list preview should update within 10 seconds
