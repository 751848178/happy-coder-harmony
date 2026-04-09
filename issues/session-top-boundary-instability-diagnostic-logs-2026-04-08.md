# Session Top Boundary Instability Diagnostic Logs

## Date
- 2026-04-08

## Context
- Real device reproduction still shows this chain:
  1. Click `到顶`
  2. Message list reaches top
  3. List starts flashing / jumping
  4. Flutter hits framework assertions and the app fails to render

## Why Extra Logs Were Added
- Existing logs already showed message window transitions, but they were still too coarse to prove:
  - which boundary action ran first
  - whether top-edge / bottom-edge autoload overlapped after an explicit boundary jump
  - whether viewport anchor capture / restore targeted the wrong row
  - whether a message row context was rebound or detached unexpectedly during the jump

## Diagnostic Scope Added
- `session_screen.dart`
  - message row context `rebind` / `stale-detach`
  - reusable helpers for window and scroll summaries
- `session_screen_state_refresh.dart`
  - viewport anchor capture / restore
  - older/newer/earliest/latest archive window load start/result/end
- `session_screen_viewport_controller.dart`
  - explicit top/bottom boundary requests
  - edge-autoload suspension
  - explicit boundary jump start/fallback/end
  - top-edge / bottom-edge trigger + ready state with live scroll metrics

## Goal
- Capture a single real-device reproduction log stream that makes the failure sequence obvious enough to fix the exact conflicting state transition, instead of continuing to infer from symptoms.
