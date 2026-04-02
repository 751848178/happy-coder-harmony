# 会话页面性能优化 — 进入会话、加载消息、滚动列表均卡顿

**日期**: 2026-04-01
**状态**: 已修复
**影响**: 会话页面三处性能问题：进入会话卡顿、消息加载后卡顿、滚动时逐帧卡顿

## 问题现象

1. **进入会话卡顿**: 从会话列表点击会话进入时，页面冻结几百毫秒
2. **消息加载卡顿**: 消息加载完成后 UI 明显卡顿
3. **滚动卡顿**: 滚动消息列表时逐帧卡顿，不流畅

## 根本原因

### 原因 1: `resolveSessionThinkingSnapshot` 每帧被调用 3 次

**文件**: `session_screen_state_build.dart`, `session_turn_status.dart`

`_buildSessionScreen` 通过以下调用链间接调用 `resolveSessionThinkingSnapshot` 3 次：

1. `_isConversationBusy` → `sessionConversationIsBusy` → `sessionTurnIsThinkingStillBlocking` → `resolveSessionThinkingSnapshot`
2. `_hasEffectiveActiveResponseMarker` → `_remoteAbortHasSettled` → `sessionAbortHasSettledRemotely` → `resolveSessionThinkingSnapshot`
3. `_isThinkingActive` → `sessionTurnIsThinkingStillBlocking` → `resolveSessionThinkingSnapshot`

每次 `resolveSessionThinkingSnapshot` 都执行 `List<ReducerMessage>.from(messages, growable: false)`（复制整个消息列表）并遍历所有消息。264 条消息时，每帧 3 次复制 + 3 次遍历 = 792 次消息复制和遍历。

**修复**: 在 `_buildSessionScreen` 中缓存一次 `resolveSessionThinkingSnapshot` 结果，通过参数传递给 `_isConversationBusy` 和 `_hasEffectiveActiveResponseMarker`，内联 `_isThinkingActive` 为 `thinkingSnapshot.isThinking`。

### 原因 2: 工具气泡每次 build 重复计算 8 个解析函数

**文件**: `session_screen_message_bubble.dart`, `session_screen_message_bubble_tool_panel.dart`

每个工具消息气泡的渲染路径：
1. `_shouldStartCollapsed`（initState）→ `_shouldCollapseToolMessage` → 调用 `_extractCommand`, `_extractDiff`, `_formatToolArguments`, `_formatToolResult`
2. `_buildToolCallMessage`（build）→ 再次调用相同的 4 个函数

这 4 个函数都涉及 JSON 解析和字符串处理。每个工具气泡计算 8 次，100 个工具气泡 = 800 次重复计算。

**修复**: 添加 `_ToolPresentationCache` 类，在 `initState` 和 `didUpdateWidget` 时计算一次，`_shouldCollapseToolMessage` 和 `_buildToolCallMessage` 都从缓存读取。

### 原因 3: `findAncestorStateOfType` O(depth) 树遍历

**文件**: `session_screen_message_bubble.dart`

`_updateActionState` 中调用 `context.findAncestorStateOfType<_SessionScreenState>()` 两次（action callback 和 long press callback）。每次调用从当前 widget 向上遍历整个 widget 树直到找到目标类型，O(depth) 复杂度。100 个气泡 = 200 次树遍历。

**修复**: 将 `_handleMessageActionChoice` 和 `_showMessageActionSheet` 作为构造函数回调传递给 `_MessageBubble`，避免 `findAncestorStateOfType` 调用。

### 原因 4: `loadSessions(force: true)` 阻塞消息加载

**文件**: `session_screen_state_load.dart`

`_ensureSessionContextLoaded` 在 session 已缓存的情况下仍调用 `loadSessions(force: true)`（强制网络请求），阻塞后续 `loadSessionMessages` 的执行。用户已访问过的 session 数据已在内存中，强制刷新是不必要的。

**修复**: 当 `initialSession != null` 时使用 `forceLoadSessions: false`（轻量级刷新），仅当 session 不在缓存中时才强制加载。

## 修复方案

### Fix 1: 缓存 thinking snapshot（减少 3 次列表复制 → 1 次）

**文件**: `session_screen_state_build.dart`, `session_screen_state_queue.dart`

### Fix 2: 缓存工具气泡解析结果（减少 8 次 JSON 解析 → 1 次）

**文件**: `session_screen_message_bubble.dart`, `session_screen_message_bubble_tool_panel.dart`

### Fix 3: 消除 `findAncestorStateOfType`（减少 O(n×depth) 树遍历 → O(1)）

**文件**: `session_screen_message_bubble.dart`, `session_screen_view_messages.dart`

### Fix 4: 跳过不必要的 `loadSessions(force: true)`

**文件**: `session_screen_state_load.dart`

## 性能改善预估

| 操作 | 修复前 | 修复后 |
|------|--------|--------|
| thinking snapshot | 3× List.from(264 msgs) | 1× List.from(264 msgs) |
| 工具气泡解析 | 8 函数/气泡 | 1 函数/气泡 |
| findAncestorStateOfType | 2×/气泡 × depth | 0 |
| session 加载 | force=true（网络） | force=false（缓存） |

## 教训

1. **昂贵计算不应在 build 路径中被重复调用** — 使用缓存或参数传递
2. **`findAncestorStateOfType` 是隐式性能陷阱** — 应通过构造函数回调传递
3. **JSON 解析结果应缓存** — `_extractCommand`、`_formatToolResult` 等函数在每次 build 中被调用是浪费
4. **区分首次加载和刷新场景** — 已缓存的数据不需要 force reload

## 相关文件

- `lib/features/session/screens/session_screen_state_build.dart`
- `lib/features/session/screens/session_screen_state_queue.dart`
- `lib/features/session/screens/session_screen_state_load.dart`
- `lib/features/session/screens/session_screen_message_bubble.dart`
- `lib/features/session/screens/session_screen_message_bubble_tool_panel.dart`
- `lib/features/session/screens/session_screen_view_messages.dart`
- `lib/features/session/presentation/session_turn_status.dart`
