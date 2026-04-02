# 会话页面进入卡顿深度优化 — 渲染管线与状态管理冗余消除

**日期**: 2026-04-02
**状态**: 已修复
**影响**: 消息较多的会话（200+ 条）进入时页面切换卡顿、掉帧

## 问题现象

从会话列表点击进入消息较多的会话时，页面切换有 1-3 秒卡顿、掉帧现象。进入后正常。

## 根本原因

### 层级 1: 状态通知风暴（最大瓶颈）

**文件**: `session_service.dart`, `session_repository.dart`

进入会话时，`_loadSessionData()` 依次调用 `loadSessions()` + `loadMachines()` + `loadSessionMessages()`。
每个操作完成后修改 repository → 触发 `SessionStateChange` → `_handleStateChange` → `_emitReadyState()`。

每次 `_emitReadyState()`:
1. 调用 `_repository.sessionsMap`（`Map.from(_sessions)`）— 浅拷贝所有 session
2. 调用 `_repository.sessionMessagesMap`（`Map.from(_sessionMessages)`）— 浅拷贝所有 session messages
3. 调用 `_repository.machinesMap`（`Map.from(_machines)`）— 浅拷贝所有 machines
4. 创建新 `_SessionServiceReadyState` 对象
5. Riverpod 通知所有 watcher → `.select()` 创建新 `_SessionScreenSelection` → `SessionScreen` rebuild

在冷启动进入会话路径中，共触发 **5-6 次 `_emitReadyState()`**，加上 `_warmSessionPreviewData`
为其他未加载会话的 `loadSessionMessages` 触发更多。

此外 `loadSessions()` 中存在**双重 emit**: `_applyLoadedSessions()` 通过 repository 触发 `sessionsUpdated` → `_handleStateChange` → `_emitReadyState()`，然后紧接着又显式调用 `_emitReadyState()`。同一次数据变化触发 2 次完整 rebuild。

### 层级 2: 消息解密串行化

**文件**: `session_service_messages.dart`

`loadSessionMessages` 中，每条消息的 AES-GCM 解密通过 `await _parseServerMessages(...)` 串行执行。
264 条消息 → 264 次串行 `await`，每次都让出事件循环。

### 层级 3: 气泡初始化 JSON 编码

**文件**: `session_screen_message_bubble.dart`, `session_message_actions.dart`

每个 `_MessageBubble` 的 `initState` 调用 `_updateActionState()` → `resolveSessionMessageActionText(message)`。
对于工具消息，`_buildToolActionText(tool)` 对 `tool.arguments`、`tool.result`、`tool.error` 执行 `jsonEncode()`。

200+ 条消息中约有 100+ 条是工具调用 → 100+ 次同步 `jsonEncode()` 在首帧 widget 树构建期间执行。

### 层级 4: 渲染管线冗余计算（已在第一轮修复）

- `resolveSessionThinkingSnapshot` 3 遍遍历消息列表
- `_MessageTurnGroup._previewFor` 每次编译 RegExp
- `_buildExpandedTurnSection` sublist 拷贝
- 多处 `List.from()` 拷贝
- 初始加载期间运行非关键计算

## 修复方案

### Fix 1: 状态通知微任务合并

**文件**: `session_service.dart`

将 `_handleStateChange` 中的 `_emitReadyState()` 替换为 `_scheduleEmitReadyState()`。
后者通过 `scheduleMicrotask()` 合并同一事件循环迭代中的多次数据变更。

效果：5-6 次状态通知合并为 1 次，减少 4-5 次完整的 SessionScreen rebuild。

### Fix 2: 消除 Map.from() 拷贝

**文件**: `session_repository_sessions.dart`, `session_repository_models.dart`

将 `Map.from(_sessions)` / `Map.from(_sessionMessages)` / `Map.from(_machines)` 替换为
`UnmodifiableMapView(_sessions)` 等。

`UnmodifiableMapView` 是 O(1) 的轻量级包装，不拷贝任何数据。配合 `.select()` 中的
`identical()` 比较，当数据实际未变时可避免不必要的 rebuild。

### Fix 3: 消除 loadSessions 双重 emit

**文件**: `session_service_sessions.dart`

删除 `_applyLoadedSessions()` 后的显式 `_emitReadyState()` 调用。
`_applyLoadedSessions()` 已经通过 repository 事件触发了合并的 emit。

### Fix 4: 消息解密并行化

**文件**: `session_service_messages.dart`

将 `for` 循环中逐条 `await _parseServerMessages()` 改为 `Future.wait()` 并行解密。
同一页内的 100 条消息现在并行解密，wall-clock 时间从 ~264×单条 降至 ~页大小/并行度。

### Fix 5: 气泡操作文本延迟计算

**文件**: `session_screen_message_bubble.dart`

将 `resolveSessionMessageActionText()` 从 `initState()` 中移到按需计算。
添加 `_actionTextComputed` 标志，仅在用户实际长按时才执行 `jsonEncode()`。

效果：首帧 widget 树构建期间 0 次 `jsonEncode()`（此前 100+ 次）。

### Fix 6-10: 渲染管线优化（第一轮已修复）

- `resolveSessionThinkingSnapshot` 快速路径
- `_previewFor` RegExp 缓存
- `_buildExpandedTurnSection` 索引遍历
- `_scheduleQueuedMessageReconciliation` 初始加载跳过
- `_hasStickyTurnCandidates` 初始加载跳过
- 多处 `List.from()` 消除

## 性能改善

| 操作 | 修复前 | 修复后 |
|------|--------|--------|
| 状态通知次数 | 5-6 次 `_emitReadyState` | 1 次（微任务合并） |
| `Map.from()` 拷贝 | 每次 emit 3 个 Map × 5-6 次 = 15-18 次 | 0 次（UnmodifiableMapView） |
| SessionScreen rebuild | 5-6 次 | 1 次 |
| 消息解密 | 264 次串行 await | 3 页并行 Future.wait |
| 气泡 jsonEncode | 100+ 次（initState） | 0 次（延迟计算） |
| `resolveSessionThinkingSnapshot` | 3×264=792 迭代 | ~1-5 迭代 |
| `_previewFor` RegExp | 每 group 编译 | static final |
| sublist 拷贝 | 6 次 | 0 次 |

## 教训

1. **状态通知应合并** — 同一事件循环中的多次数据变更应通过 microtask 合并为一次通知
2. **`Map.from()` 不应用于 getter** — 作为 state 传递的 map 应使用 `UnmodifiableMapView` 包装
3. **`jsonEncode()` 不应在 initState 中** — 仅在用户交互时才需要的数据应延迟计算
4. **`Future.wait()` 替代串行 await** — 独立的异步操作应并行执行
5. **快速路径优先** — 常见情况下应尽量短路

## 相关文件

- `lib/features/session/domain/session_service.dart`
- `lib/features/session/domain/session_service_sessions.dart`
- `lib/features/session/domain/session_service_messages.dart`
- `lib/features/session/domain/session_service_session_parsing.dart`
- `lib/features/session/data/session_repository.dart`
- `lib/features/session/data/session_repository_sessions.dart`
- `lib/features/session/data/session_repository_models.dart`
- `lib/features/session/presentation/session_turn_status.dart`
- `lib/features/session/presentation/session_message_actions.dart`
- `lib/features/session/screens/session_screen_message_bubble.dart`
- `lib/features/session/screens/session_screen_turn_group.dart`
- `lib/features/session/screens/session_screen_view_messages.dart`
- `lib/features/session/screens/session_screen_state_build.dart`
- `lib/features/session/screens/session_screen_state_load.dart`
- `lib/features/session/screens/session_screen_state_scroll.dart`
