# Session Entry Latest Window And Collapsed Turn Archive Summaries

## Problems

1. Re-entering a session could reopen the last archived resident window instead
   of defaulting to the latest messages.
2. Collapsing turns only reflected the current resident window, so older turns
   disappeared from the collapsed list even when full archive history already
   existed locally.

## Root Cause

- Session entry restored cached `SessionMessages` as-is. If the user had
  previously browsed history, the cached window start index was reused and the
  detail page opened in the middle of history.
- Turn collapsing was driven entirely by the in-memory message window, with no
  lightweight archive-backed summary layer for older user prompts.

## Fix

- On entry, if the restored cached window is not the latest window and local
  archive history is complete, the detail page now swaps to the latest archive
  window before revealing the message list.
- Added lightweight archive-backed turn summaries that scan local message
  archive records and extract only user-authored prompt previews.
- Collapsed turn mode now renders those archive summaries, while still using the
  resident message window only for expanded turn content.
- Tapping an unloaded collapsed turn summary now loads a resident archive window
  around that prompt before expanding.
