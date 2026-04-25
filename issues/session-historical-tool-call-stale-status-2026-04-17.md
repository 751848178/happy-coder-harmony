# Historical Tool Calls Stuck in Auto-Processing State — 2026-04-17

## Problem

Some historical messages show tool calls with an "auto-processing" spinner ("该调用正在自动处理") that never resolves. This happens for tool calls in sessions that are no longer active, where the tool-call-end event was never received (session interrupted, app killed, or server didn't store the end event).

## Root Cause

Tool call status flow:
1. `tool-call-start` → creates message with ID `tool:$toolId`, status `pending`
2. `tool-call-end` → creates message with SAME ID, status `completed`
3. They merge into one message — works correctly when both arrive

But when `tool-call-end` never arrives (interrupted session):
- The message stays at `pending` (or `approved` if auto-approved before interruption)
- `resolveSessionToolVisualState` maps `pending` + `autoApproveEnabled=true` → `showsAutoResolvingFooter=true`
- Result: permanent "auto-processing" spinner for historical tool calls

Cache restoration worsens this: messages cached with stale `pending`/`approved` status are restored as-is.

## Fix

Added `_resolveHistoricalToolCallStatuses` post-processing step in `session_service_sidechain_reducer.dart`. Called after `_nestSidechainMessages` in both:
- `loadSessionMessages` (server load path)
- `restoreSessionMessagesFromCache` (cache restoration path)

The method scans messages for tool calls with non-terminal status (`pending`/`approved`/`executing`) that appear before a `turn-close` event. If the enclosing turn has ended:
- Tool status is upgraded to `completed` (normal turn end)
- Tool status is upgraded to `failed` with error "Turn abandoned" (abandoned turn)

This only applies to messages in completed turns — active turns are untouched.

### Files Modified

- `lib/features/session/domain/session_service_sidechain_reducer.dart` — Added `_resolveHistoricalToolCallStatuses`
- `lib/features/session/domain/session_service_message_coordinator.dart` — Call after `_nestSidechainMessages`
- `lib/features/session/domain/session_service_cache_coordinator.dart` — Call after cache restore

## Testing

- Open a session that was interrupted during tool execution → tool calls should show completed/failed, not auto-processing
- Kill app during active tool execution → reopen → historical tools should resolve to terminal state
- Verify active session tool calls still show correct live status during execution
