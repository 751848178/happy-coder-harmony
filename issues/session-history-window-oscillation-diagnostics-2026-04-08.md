# Session History Window Oscillation Diagnostics

## Problem

Fast manual history scrolling can stall on a middle page, then oscillate between
older/newer windows when the user scrolls down and up repeatedly. The visible
symptom is message-page flashing before the list eventually lands on the oldest
window.

## What We Added

- Added focused `SessionEdgeDiag` state logs for:
  - current user scroll trend inferred from scroll delta
  - last completed edge-load direction
  - window start index after the last edge load
- Added the same edge-state summary to `SessionWindowDiag` logs for:
  - `load-older synced`
  - `load-newer synced`
  - `load-earliest synced`
  - `load-latest synced`

## Why

Previous logs showed window load results and anchor restore attempts, but they
did not show whether the list was oscillating because:

- the user had reversed scroll direction
- the opposite edge autoload was firing too early
- the same edge load had completed but the next gesture still reused stale edge
  state

These diagnostics make the scroll direction, edge load direction, and window
start transitions visible in a single log sequence so the oscillation source can
be isolated before changing behavior.
