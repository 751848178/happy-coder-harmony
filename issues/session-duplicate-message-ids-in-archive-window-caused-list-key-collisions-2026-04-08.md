# Session Duplicate Message IDs In Archive Window Caused List Key Collisions

## Date
- 2026-04-08

## Symptom
- Manual scroll after `到顶` could still trigger:
  - `child == _child`
  - `Duplicate GlobalKey detected in widget tree`
  - repeated row rebind / stale detach logs

## Confirmed Root Cause
- Real-device diagnostic logs showed `SessionDuplicate` before the framework crash.
- The duplicate ids were not coming from the widget tree first; they were already present in the resident message window loaded from archive.
- Tool messages are especially vulnerable because multiple raw reducer records can share the same logical row id such as `tool:<callId>`.
- Archive window writes and window shifts previously trusted the incoming list as-is:
  - `replaceMessageWindow`
  - `prependMessageWindow`
  - `appendMessageWindow`
- Those paths built `messagesMap` from ids but still kept the raw `messages` list unchanged, so the UI ended up with multiple rows using the same `ValueKey(message.id)`.

## Fix
- Canonicalize resident windows before storing them:
  - merge duplicate ids using the existing reducer merge rules
  - preserve stable order
- Derive window boundaries from archived `archiveIndex` metadata instead of deduped list length where possible.
- Archive range restore now sorts by `archiveIndex` first to preserve stable page order.

## Prevention Rule
- Any message list that can be rendered with keyed rows must be canonicalized before entering UI state.
- Do not assume archive page records are already one-to-one with visible rows.
