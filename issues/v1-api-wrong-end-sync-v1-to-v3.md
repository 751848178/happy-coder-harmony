# "Sync All Messages" Only Returns Latest 150 Messages Instead of Complete History

**Date**: 2026-04-04
**Status**: Fixed
**Impact**: "Sync all messages" (全量同步) silently truncates to the latest 150 messages; older messages are permanently lost from the client

## Symptom

When a user triggers "Sync all messages" from the session screen menu, the client receives only the latest 150 messages from the server instead of the full conversation history. The UI displays "已从 PC 全量同步消息，共 150 条" (synced 150 messages from PC) regardless of how many messages the session actually contains. This happens silently -- there is no error message or user-visible indication that data was truncated.

## Root Cause

### The two API versions behave fundamentally differently

| Aspect | V1 Endpoint | V3 Endpoint |
|--------|-------------|-------------|
| Path | `/v1/sessions/{id}/messages` | `/v3/sessions/{id}/messages` |
| Response ordering | Descending (newest first) | Ascending (oldest first) |
| Pagination | None -- fixed 150-message window | Cursor-based (`after_seq` + `hasMore`) |
| `hasMore` field | Not returned | Returned, supports full traversal |

### `_sessionMessagesApiPrefix` caches the wrong endpoint

The field `_sessionMessagesApiPrefix` (in `SessionServiceNotifier`) caches whichever endpoint responded successfully on the **first** call. The original code tried `/v1` first and cached it:

```dart
// BEFORE (broken order):
final prefixes = ['/v1', _sessionMessagesApiPrefix].toSet().toList();
```

When the first message request hits V1, `_sessionMessagesApiPrefix` is set to `'/v1'`. All subsequent requests -- including `syncFullSessionMessagesFromRemote` -- go through V1 and are capped at 150 messages.

### V1 returns messages in descending order, breaking the pagination loop

`loadSessionMessages` paginates by advancing `afterSeq` to `maxSeq` from each page, expecting messages in ascending order. V1 returns messages in **descending** order (newest first), so:

1. Page 1 returns the 100 newest messages (seq 201-300, but in desc order).
2. `maxSeq` is computed from the parsed messages and happens to be the highest seq.
3. The `inferredHasMore` heuristic checks `messageItems.length >= _sessionMessagesPageSize && maxSeq > afterSeq`. With V1, after the first page, `maxSeq` (from the desc-ordered batch) may already equal the server's maximum seq, causing the loop to terminate after just 1-2 pages.
4. Even if the loop continues, V1 has no `hasMore` field, and the total message cap is 150.

The net result: the pagination loop fetches at most 150 messages and then stops, even though `afterSeq` started at 0 (force mode).

## Data Flow

```
Intended flow (V3):
  syncFullSessionMessagesFromRemote()
    -> loadSessionMessages(force: true, afterSeq = 0)
    -> _requestSessionMessages() -> /v3/sessions/{id}/messages?after_seq=0&limit=100
    -> response: messages[0..99], hasMore=true
    -> _requestSessionMessages() -> /v3/sessions/{id}/messages?after_seq=100&limit=100
    -> response: messages[100..199], hasMore=true
    -> _requestSessionMessages() -> /v3/sessions/{id}/messages?after_seq=200&limit=100
    -> response: messages[200..263], hasMore=false
    -> loop ends, 264 messages loaded
    -> _repository.replaceMessages(sessionId, 264 messages)
    -> UI: "已从 PC 全量同步消息，共 264 条"

Broken flow (V1):
  syncFullSessionMessagesFromRemote()
    -> loadSessionMessages(force: true, afterSeq = 0)
    -> _requestSessionMessages() -> /v1/sessions/{id}/messages?after_seq=0&limit=100
    -> response: 100 messages (desc order, capped at 150 total), no hasMore
    -> inferredHasMore = false (messageItems < 100 or maxSeq not advancing)
    -> loop ends, ~100-150 messages loaded
    -> _repository.replaceMessages(sessionId, 150 messages)  // older messages silently dropped
    -> UI: "已从 PC 全量同步消息，共 150 条"
```

## Fix

### Change endpoint priority: try `/v3` first

**File**: `lib/features/session/domain/session_service_message_send.dart`

The `_requestSessionMessages` method now tries `/v3` first and only falls back to the cached prefix (which may be `/v1`) if V3 returns 404:

```dart
Future<T> _requestSessionMessages<T>({
  required String sessionId,
  required Future<T> Function(String path) action,
}) async {
  // Always prefer /v3 over /v1: /v3 supports cursor-based pagination
  // (after_seq + hasMore) which is required for complete message sync.
  // /v1 returns a fixed 150-message window in desc order with no pagination.
  final prefixes = <String>[
    '/v3',
    if (_sessionMessagesApiPrefix != null &&
        _sessionMessagesApiPrefix != '/v3')
      _sessionMessagesApiPrefix!,
  ].toSet().toList(growable: false);
  Object? lastError;

  for (final prefix in prefixes) {
    final path = '$prefix/sessions/$sessionId/messages';
    try {
      final response = await action(path);
      if (_sessionMessagesApiPrefix != prefix) {
        Logger.info('Resolved session messages endpoint: $prefix');
      }
      _sessionMessagesApiPrefix = prefix;
      return response;
    } catch (error) {
      lastError = error;
      if (_isMissingSessionMessagesEndpoint(error)) {
        Logger.warning(
            'Session messages endpoint unavailable at $path: $error');
        continue;
      }
      rethrow;
    }
  }

  throw lastError ?? Exception('No session messages endpoint available');
}
```

Key changes:
1. `/v3` is always tried first, regardless of what `_sessionMessagesApiPrefix` was cached to.
2. The cached prefix is only used as a fallback (and only if it is not `/v3`, to avoid duplicates).
3. On successful V3 response, `_sessionMessagesApiPrefix` is updated to `/v3`.
4. If V3 returns 404 (server does not support it), the fallback to V1 kicks in.

### Guard against `maxSeq == afterSeq` infinite loop in V3

**File**: `lib/features/session/domain/session_service_messages.dart`

The pagination loop already includes a termination guard:

```dart
if (maxSeq == afterSeq) {
  hasMore = false;
}
```

This prevents an infinite loop if V3 returns the same max seq on successive pages (which should not happen with correct V3 behavior, but the guard is important for robustness).

## Verification

After the fix:
- "Sync all messages" on a session with 264 messages should display "已从 PC 全量同步消息，共 264 条".
- The DIAG logs should show multiple pages being fetched with `responseHasMore=true` until all messages are retrieved.
- `_sessionMessagesApiPrefix` should be resolved to `/v3` on the first successful request.

## Affected Files

- `lib/features/session/domain/session_service_message_send.dart` -- `_requestSessionMessages` endpoint priority
- `lib/features/session/domain/session_service_messages.dart` -- pagination loop and `syncFullSessionMessagesFromRemote`
- `lib/features/session/domain/session_service.dart` -- `_sessionMessagesApiPrefix` field declaration
- `lib/features/session/screens/session_screen_state_refresh.dart` -- UI entry point for sync-all

## Lessons

1. **API version differences must be documented and tested** -- V1 and V3 have fundamentally different pagination semantics; assuming they are interchangeable is dangerous.
2. **Cached endpoint preferences can cause silent data loss** -- once `/v1` is cached, every subsequent "sync all" is silently truncated.
3. **Descending order + ascending pagination = truncated results** -- the pagination loop assumes ascending seq order; V1's descending order causes premature termination.
4. **"Force" mode is not enough** -- `force: true` resets `afterSeq` to 0, but if the endpoint itself caps results, the full reload is still incomplete.
