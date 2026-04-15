# Message Bubble Coupling & Atomization Audit

Date: 2026-04-15
Scope: lib/features/session/screens/session_screen_message_bubble*.dart, session_screen_markdown_*.dart, session_screen_inline_code_panel*.dart, session_screen_tool_support.dart

## Issue 1: `_ToolPresentationCache` bidirectional coupling with `_MessageBubbleState`

**Severity:** Medium
**File:** session_screen_message_bubble.dart

`_ToolPresentationCache` holds a back-reference `_owner` to `_MessageBubbleState`. Its lazy getters (`argumentsPreview`, `resultPreview`) call back into `_owner` methods:
- `_owner!._shouldShowRawArguments()`
- `_owner!._shouldDisplayArguments()`
- `_owner!._formatToolArguments()`
- `_owner!._formatToolResult()`

This creates a bidirectional dependency: the cache is not a pure data object, it has behavioral coupling to its owner state. This prevents the cache from being tested independently and makes the ownership unclear.

**Fix applied:** Move formatting logic into `_SessionMessageBubblePresenter` (already stateless). Cache stores pre-computed data only. Remove `_owner` back-reference.

## Issue 2: `TapGestureRecognizer` leak in `_MarkdownInlineParse.buildSpans`

**Severity:** Medium (memory leak)
**File:** session_screen_markdown_inline_parser.dart

`TapGestureRecognizer` objects are created fresh in `_buildSpanFromSegment` for every link/file-path segment on every `build()` call. These recognizers are attached to `TextSpan` but never explicitly disposed. In Flutter, `TextSpan.recognizer` is not auto-disposed when the widget is removed from the tree.

**Fix applied:** Extract the inline parser + span builder into a dedicated `_MarkdownTextBlock` widget with proper lifecycle. Create recognizers once and dispose them in `dispose()`.

## Issue 3: Five independent global static parse caches, never bulk-cleared

**Severity:** Low (memory)
**Files:**
- `_MarkdownBlock._parseCache` (120 entries)
- `_MarkdownTextSection._parseCache` (120 entries)
- `_MarkdownInlineParse._parseCache` (200 entries)
- `_markdownContentCache` (120 entries)
- `_structuredLanguageCache` (120 entries)

Total: up to 680 entries, each keyed by raw content string. These are process-lifetime singletons with LRU eviction only. When a session is closed and a new one opened, old content stays cached.

**Fix applied:** Add `clearCaches()` static method to each cache-holding class. Call from session dispose.

## Issue 4: Extension-on-State pattern provides no encapsulation

**Severity:** Low (architectural)
**Files:** All session_screen_message_bubble_*.dart files

All part files use `extension on _MessageBubbleState`, giving every extension unrestricted access to all private fields. Changes to state variable semantics affect all extensions simultaneously. No extension can be tested in isolation.

**Status:** Documented. Not fixing in this round -- would require extracting to separate widget classes which is a larger refactor. The presenter extraction in Issue 1 addresses the most critical coupling.

## Issue 5: `isToolActionPending` passed through but unused in most paths

**Severity:** Low (dead coupling)
**File:** session_screen_view_messages.dart

`isToolActionPending` is threaded from screen state through `_MessageBubble` into `_MessageBubbleState`, but only consumed in the tool-call rendering path. For text, status, and other message types, it is received but never used. This creates unnecessary rebuild triggers.

**Fix applied:** Only pass `isToolActionPending` when `message.isToolCall`. Use a conditional constructor parameter.

## Issue 6: Callback pass-through chain (5 callbacks threaded through 3 layers)

**Severity:** Low (boilerplate coupling)
**File:** session_screen_view_messages.dart -> _MessageBubble -> sub-widgets

`onApproveTool`, `onRejectTool`, `onMessageActionChoice`, `onShowMessageActionSheet`, `onFilePathTap` are passed from `_SessionScreenState` through `_buildFlatMessageItem` -> `_MessageBubble` -> child widgets. Each layer passes all 5 even though no single child uses all 5.

**Status:** Documented. Not fixing in this round -- this is a design pattern choice, not a bug.

## Issue 7: `interactionsEnabled` redundant state in `_MessageBubble`

**Severity:** Low (dead state)
**File:** session_screen_message_bubble.dart

After the list-level `IgnorePointer` was added in the previous round, `interactionsEnabled` was still passed to `_MessageBubble` and used in `ImmediateLongPressRegion(enabled: interactionsEnabled)`. The widget always received `true`, making the parameter dead state — the list-level `IgnorePointer` already controls interactivity.

**Fix applied:** Remove `interactionsEnabled` from `_MessageBubble` constructor and `_MessageBubbleState`. `ImmediateLongPressRegion` now always uses `enabled: true`.

## Issue 8: `_createFilePathTapHandler()` allocates new closure per message per build

**Severity:** Low (unnecessary allocation)
**File:** session_screen_view_messages.dart

`_createFilePathTapHandler()` is called inside `_buildMessageBubble()` for every message on every build cycle. Since `widget.sessionId` is stable and `context` doesn't change, the closure can be cached.

**Fix applied:** Cache the handler in `_cachedFilePathTapHandler` on `_SessionScreenState`, keyed by `sessionId`. Reuse across builds until sessionId changes.

## Issue 9: 4 helper extension files are pure pass-through proxies

**Severity:** Low (architectural noise)
**Files:** session_screen_message_bubble_tool_helpers.dart, _helpers_2.dart, _helpers_3.dart

All 18 methods in these files are single-line delegations: `return _bubblePresenter.xxx(...)`. They exist only because Dart extension methods can't directly access static fields on the extended type without going through an extension method. The callers are already on `_MessageBubbleState` which holds `_bubblePresenter` as a static.

**Status:** Documented. Not fixing — the indirection is harmless and removing it would change ~30 call sites across 5 files for no functional benefit. A future refactor could make callers reference `_bubblePresenter` directly if the extension pattern is abandoned.
