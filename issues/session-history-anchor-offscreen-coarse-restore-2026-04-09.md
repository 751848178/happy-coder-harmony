# Session History Anchor Offscreen Coarse Restore

## Problem

When older history was prepended near the top edge, the anchor message could
remain inside the resident window but move far enough down that the sliver had
not rebuilt its row yet. The existing restore logic then saw:

- `anchorStillInWindow=true`
- `hasContext=true`
- `hasRow=false`

and eventually gave up, leaving the list pinned at the edge.

## Root Cause

Anchor restore assumed the target row would be measurable within a few frames.
That is false for a virtualized list when the restored anchor is still offscreen
after window replacement.

## Fix

- If the anchor is still in the resident window but its render box is not yet
  available, perform a coarse jump using the anchor's current index ratio inside
  the resident window.
- After that coarse jump, retry the normal precise restore path.
- Added `RenderBox.hasSize` guards to row geometry reads so partially built rows
  are treated as unavailable instead of throwing render assertions.
