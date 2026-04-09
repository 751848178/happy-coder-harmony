# Session Opposite Edge Autoload And Sticky RenderBox Instability

## Problem

During fast manual history scrolling, the message list could get stuck and
flicker because:

- bottom-edge autoload still fired while the user was moving toward older
  history
- some archive "append/prepend" operations reported success without actually
  advancing the resident window
- sticky prompt refresh could read `getOffsetToReveal()` from a render object
  that had not completed layout yet

## Root Cause

The edge loader only checked proximity to the boundary and a few loading flags.
It did not respect the actual recent scroll trend inferred from scroll deltas,
so after viewport corrections it could trigger the opposite edge immediately.

At the same time, archive window operations could return `true` even when the
resident window start and visible range had not changed, which amplified the
oscillation.

Separately, sticky prompt refresh used render objects that were attached but not
yet laid out, which caused scheduler-time render assertions and left the list in
an unstable state.

## Fix

- Block top-edge autoload while the recent scroll trend is toward newer
  messages.
- Block bottom-edge autoload while the recent scroll trend is toward older
  messages.
- Treat archive prepend/append as failed if the resident window does not
  actually advance after the repository update.
- Guard sticky prompt and reply reveal logic so only laid-out `RenderBox`
  targets are passed into `getOffsetToReveal()`.
