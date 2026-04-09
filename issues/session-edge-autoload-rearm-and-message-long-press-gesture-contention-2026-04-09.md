# Session Edge Autoload Rearm And Message Long-Press Gesture Contention

## Problem

While manually scrolling older history at a normal speed, the session message
list could still jump or visibly flash page boundaries even after the earlier
anchor fixes landed.

At the same time, every message row still carried a custom long-press gesture
region, so slow drags had to compete with a per-row long-press recognizer in
the gesture arena.

## Root Cause

Two separate hot-path issues were overlapping:

- edge autoload was triggered too close to the boundary and could re-fire as
  soon as the cooldown expired, even if the user had not actually consumed the
  newly loaded headroom yet
- the message list still used `RangeMaintainingScrollPhysics` while the screen
  also performed explicit anchor-based viewport restoration, so history loads
  had two different mechanisms trying to compensate scroll offset
- each message bubble wrapped its child in `ImmediateLongPressRegion`, which is
  not just extra rendering work; it also adds gesture-arena contention during
  slow scrolls

## Fix

- Switched the message list back to plain `ClampingScrollPhysics()` so anchor
  restoration is the single owner of offset correction.
- Changed edge autoload to use a viewport-relative trigger and a re-arm rule.
  After one top/bottom autoload fires, it now stays disarmed until the user has
  actually moved away from that edge by a safe gap.
- Disabled message-level long-press action wrappers on the hot scrolling path
  so rows no longer attach a custom long-press recognizer while browsing large
  histories.
