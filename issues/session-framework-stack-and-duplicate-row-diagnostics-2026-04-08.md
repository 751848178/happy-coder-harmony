# Session Framework Stack And Duplicate Row Diagnostics

## Date
- 2026-04-08

## Why
- The remaining `child == _child` crash is still a framework-level assertion.
- Screenshot-level error text is not enough to identify the exact caller.
- Existing session perf logs were too noisy and hid the critical sequence.

## Diagnostic Changes
- `main.dart`
  - Added `FlutterError.onError` logging with full exception, context, and stack.
  - Added `PlatformDispatcher.instance.onError` logging for async crashes.
  - Added `ErrorWidget.builder` stack logging so render-failure screens still emit useful traces.
- `session_screen.dart`
  - Added duplicate message-id detection for the current resident window.
- `session_screen_view_messages.dart`
  - Added duplicate message-id detection for flat list items just before building the list.
- `session_screen_body_presenter.dart`
  - Disabled generic `SessionPerf` structure logs by default.
- `session_screen_state_sticky_prompt.dart`
  - Disabled sticky perf logs by default.
- `session_screen_viewport_controller.dart`
  - Disabled generic scroll perf logs by default.

## Goal
- Keep only high-signal logs:
  - `FlutterCrash`
  - `SessionArchive`
  - `SessionAnchor`
  - `SessionDuplicate`
- Use the next real-device reproduction to determine whether the crash is caused by:
  - duplicate message ids in the resident window
  - an illegal row subtree reparent
  - another framework-level child ownership conflict
