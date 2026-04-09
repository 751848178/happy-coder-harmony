# 会话消息列表渲染性能审计

**Date**: 2026-04-05
**Status**: Fixed
**Impact**: 消息较多时（264条），会话页面整体性能差 — 进入卡顿、滚动卡顿、到顶/到底卡顿

## 审计方法

从用户点击会话列表开始，逐行追踪到消息渲染完成，识别所有 O(n) 计算、冗余重建和非原子状态变更。

## 发现的问题

### 问题 1（已修复）：`AutomaticKeepAliveClientMixin` 导致所有气泡永久存活

**位置**: `session_screen_message_bubble.dart`

**问题**: `_MessageBubbleState` 使用 `AutomaticKeepAliveClientMixin`，`wantKeepAlive => !_collapsed`。滚动过的未折叠气泡永远不会被回收。

**影响**: 滚动完 264 条消息后，所有 264 个 `_MessageBubbleState` + 264 个 `_MarkdownMessageContentState` + 264 个 `_MarkdownBlock.parse` 缓存全部存活。`ListView` sliver 系统在**每一帧**对所有 keepAlive 子项执行 layout。

**修复**: 移除 `AutomaticKeepAliveClientMixin`。`RepaintBoundary` 已提供 paint 隔离，`ListView.builder` 按需构建提供虚拟化。

### 问题 2（已修复）：页面过渡动画期间同步执行重操作

**位置**: `session_screen_state_load.dart`

**问题**: `_loadSessionData()` 在 `initState()` 中立即执行。虽然方法是 `async`，但第一个 `await` 之前的同步代码和后续微任务中的同步代码（JSON 反序列化、repository 操作）会阻塞过渡动画的前几帧。

**修复**: 在 `_loadSessionData()` 开头添加 `await SchedulerBinding.instance.endOfFrame`，让过渡动画先完成第一帧。

### 问题 3（已修复）：`_MarkdownTextSection.parse()` 无缓存

**位置**: `session_screen_markdown_text_parser.dart`

**问题**: `_MarkdownBlock.parse()` 和 `_MarkdownInlineParser._parse()` 都有静态缓存，但 `_MarkdownTextSection.parse()` 没有。每次 `_MarkdownTextBlock` 进入视口，都重新执行：字符串 split、regex 匹配（heading、bullet、numbered、quote）。

**影响**: 对于 264 条消息中有 ~80 个文本块，每次滚动进出视口都重新解析。

**修复**: 添加与 `_MarkdownBlock.parse()` 相同模式的静态 LRU 缓存（120 条上限）。

### 问题 4（已修复）：`_shouldCollapseTextMessage()` 在每次 build 时重复计算

**位置**: `session_screen_message_bubble_content.dart:12`

**问题**: `_shouldCollapseTextMessage(text)` 在 `initState()` 中计算一次（设置 `_collapsed`），然后在 `_buildTextMessage()` 的每次 `build()` 中又计算一次。该函数执行 `text.trimRight()` + `'\n'.allMatches(text).length` — O(n) 操作。

**影响**: 每个文本消息气泡在每次 build 时多一次 O(n) 操作。在滚动和状态更新期间 build 频繁触发。

**修复**: 将 `_shouldCollapseTextMessage` 的结果缓存到 `_canCollapse` 字段中，在 `initState` 和 `didUpdateWidget` 中计算一次，`build` 中直接读取。

### 问题 5（已修复）：`resolveSessionThinkingSnapshot()` 在每次 build 时遍历消息

**位置**: `session_screen_state_build.dart:90`

**问题**: `resolveSessionThinkingSnapshot()` 在 `_buildSessionScreen()` 的每次 `build()` 中调用。虽然内部已有一次缓存（局部变量 `thinkingSnapshot`），但每次 build 都重新执行。函数遍历 `messages.reversed` 直到找到第一个非用户文本消息。

**影响**: 对于 264 条消息，每次 build 至少遍历最后几条消息（fast path O(1~5)），但 `messages.reversed` 创建一个 reversed iterator 有分配开销。

**修复**: 在 `_SessionScreenState` 中添加实例级缓存，使用 `identical()` 检查 session 和 messages 引用是否变化。只有变化时才重新计算。

### 问题 6（已修复）：`_syncMessagesFromRepository()` 在初始加载时被调用 4-5 次

**位置**: `session_screen.dart` → `_subscribeToMessageChanges`

**问题**: 加载链中多个操作触发状态变更（`replaceMessages` → `applyMessages` → preview update），每次都通过 stream listener 调用 `_syncMessagesFromRepository()`，每次都更新 `_messagesN` ValueNotifier → 触发完整 build。

**修复**: 使用 `scheduleMicrotask` 去抖 — 多个快速状态变更合并为一次同步。

### 问题 7（已修复）：`applyMessages()` 的 `Map.from()` 全量复制

**位置**: `session_repository_messages.dart`

**问题**: `applyMessages()` 在有现有消息时，总是 `Map.from(existing.messagesMap)` 创建完整副本，然后对每个新消息执行 merge。对于增量更新（追加几条新消息），这是浪费的。

**修复**: 添加 fast path — 检查所有新消息是否都不在现有 map 中，如果是则直接 append + `Map.from(existing)` + 遍历新消息添加，跳过 re-sort。

### 问题 8（已修复）：`_SessionScreenSelection.==` 使用 `identical()` 导致全屏重建

**位置**: `session_screen.dart`

**问题**: `_SessionScreenSelection.==` 使用 `identical(session, other.session)` 比较 Session。`applyMessages()` → `_syncSessionPreviewFieldsFromMessages()` → `copyWith()` 在每次 preview 字段更新时创建新 Session 对象。preview 字段（`previewText`, `lastMessageAt`, `listStatusKind`）在每条新消息到达时都变化。这导致 `ref.watch(sessionStateProvider.select(...))` 每次都返回新值 → `_buildSessionScreen` 完全重新执行（AppBar、InputArea、所有 overlay、消息列表）。

**影响**: 流式响应期间，每个 chunk 都触发完整 `_buildSessionScreen` 重建。264 条消息的会话中，可见的 ~10 个 turn group 全部重建 widget 树。

**修复**: 将 `_SessionScreenSelection.==` 改为值相等比较，仅比较会话详情页实际使用的字段（`id`, `title`, `active`, `thinking`, `thinkingAt`, `draft`, `permissionMode`, `modelMode`, `path`, `metadata`, `presence`），忽略列表专用字段（`previewText`, `lastMessageAt`, `listStatusKind`, `latestUsage`）。

### 问题 9（已修复）：`_InlineCodePanel` 的 `AutomaticKeepAliveClientMixin` 导致代码面板永久存活

**位置**: `session_screen_inline_code_panel.dart`

**问题**: `_InlineCodePanelState` 使用 `AutomaticKeepAliveClientMixin`，`wantKeepAlive => _expanded`。展开过的代码面板永远不会被回收。264 条消息中可能包含 30-50 个代码块，展开后全部存活。`ListView` sliver 系统在每一帧对所有 keepAlive 子项执行 layout。

**修复**: 移除 `AutomaticKeepAliveClientMixin`。代码面板已有 `_cachedCodeBody` 缓存渲染结果，离开视口后可安全回收。

### 问题 10（已修复）：`_InlineCodePanel` 冗余 `split('\n')`

**位置**: `session_screen_inline_code_panel.dart`

**问题**: `build()` 中先 `normalizedCode.split('\n')` 得到 `lines`，然后对 `visibleCode`（由 `lines.take().join()` 或 `normalizedCode` 得到）再次执行 `visibleCode.split('\n')`。第二次 split 是冗余的 — `visibleLines` 可以直接从已有 `lines` 列表派生。

**修复**: 改用 `lines.take(widget.collapsedLines).toList()` 直接从已 split 的列表截取，避免第二次 O(n) split。

## 审计中确认的合理设计

以下设计经审计确认是合理的，不需要修改：

1. **`ListView.builder` 虚拟化**: 正确使用 `builder` 构造函数，只构建可见 + cacheExtent 范围内的 turn group。
2. **`RepaintBoundary` 隔离**: 每个气泡包裹在 `RepaintBoundary` 中，paint 互不影响。
3. **`_MarkdownBlock.parse` 和 `_MarkdownInlineParser._parse` 的缓存**: 已有静态 LRU 缓存。
4. **`ValueNotifier` 隔离重建**: 滚动状态（canScrollToTop/Bottom、isNearBottom、shouldStickToLatest）使用 ValueNotifier + ValueListenableBuilder，避免全屏 rebuild。
5. **`_scheduleViewportStateRefresh` 100ms 节流**: 限制 sticky turn 计算频率。
6. **`_refreshStickyTurnPrompt` 滑动窗口**: 只检查视口附近 ±4 个 turn group。
7. **`_MarkdownInlineParser.buildSpans()` 不缓存 InlineSpan**: 因为 `TapGestureRecognizer` 需要在 widget dispose 时释放，缓存有内存泄漏风险。span 创建本身很廉价（只是构造函数调用）。

## 未修改但值得关注的区域

1. **`_buildExpandedTurnSection` 使用 Column 而非 ListView**: 一个 turn group 内所有消息一次性构建。对于典型 2-5 条消息的 turn group，这可以接受。如果出现单 turn 10+ 条消息的场景，可以考虑虚拟化。
2. **`_MarkdownMessageContent` 和 `_MarkdownTextBlock` 是 StatefulWidget**: 各自缓存解析结果，这是正确的。
3. **`_handleScrollMetricsChanged` 每帧调用**: 但计算量极轻（4 次算术 + 4 次布尔比较），且使用 ValueNotifier 避免全屏 rebuild。

## 修改文件清单

| 文件 | 修改类型 |
|------|---------|
| `session_screen_message_bubble.dart` | 移除 KeepAlive mixin，缓存 `_canCollapse` |
| `session_screen_message_bubble_content.dart` | 使用缓存的 `_canCollapse` 替代每次 build 计算 |
| `session_screen_message_bubble_collapsed_text.dart` | 短文本快速路径跳过 markdown 解析 |
| `session_screen_markdown_text_parser.dart` | 添加静态 LRU 缓存 |
| `session_screen_state_build.dart` | 缓存 thinkingSnapshot |
| `session_screen_state_load.dart` | `await endOfFrame` 推迟加载 |
| `session_screen.dart` | 添加 thinking snapshot 缓存字段、消息同步去抖、稳定 Session 相等性比较 |
| `session_repository_messages.dart` | applyMessages fast path |
| `session_screen_inline_code_panel.dart` | 移除 KeepAlive mixin，消除冗余 split('\n') |
| `session_screen_view_messages.dart` | cacheExtent 调优 |
