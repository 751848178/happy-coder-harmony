# Session Idle-Only Message Interactions To Keep Scroll Path Clean

## Problem

Even after disabling always-on message long-press, the detail page still needed
those actions eventually. The remaining architecture issue was that message
interaction wiring still belonged to the same hot path as history scrolling.

## Root Cause

Message rows originally attached long-press capability unconditionally, so the
scrolling path always paid for gesture recognizer setup and gesture-arena
competition even when the user was only browsing history.

Simply removing the long-press wrapper proved the diagnosis, but it also
removed a real feature.

## Fix

- Added a dedicated `messageInteractionsEnabled` leaf state for the detail
  page.
- While the list is scrolling or while programmatic boundary jumps are active,
  message-level long-press interactions are paused.
- After the viewport has been idle for a short debounce window, visible message
  rows re-enable long-press behavior.
- The long-press wrapper stays structurally stable and only enables its
  recognizer when interactions are allowed, so we avoid reintroducing previous
  list ownership issues.
- Action text remains lazily resolved on actual long press instead of during
  normal list builds.
