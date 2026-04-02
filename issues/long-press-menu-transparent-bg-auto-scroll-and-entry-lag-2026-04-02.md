# 会话页面长按菜单透明背景 + 进入会话卡顿 + 自动滚动打断手动滚动

**日期**: 2026-04-02
**状态**: 已修复
**影响**: 三个 UI 问题影响会话页面体验

## 问题 1: 长按菜单透明背景

### 问题现象

长按消息气泡弹出的操作菜单背景完全透明，只能看到文字和图标漂浮在半透明遮罩上，看不清菜单内容。

### 根本原因

`showBottomPopupSheet` 使用 `Material(type: MaterialType.transparency)` 包裹内容，而 `_showMessageActionSheet` 提供的内容是一个 `Column` + `Padding`，没有包裹不透明背景容器。只有消息预览框有 `AppTheme.neutral100` 背景。

### 修复方案

给 `_showMessageActionSheet` 的 `Column` 内容外包一层 `Container`，使用 `AppTheme.surface` 背景色 + `AppTheme.radiusXl` 圆角 + 轻微阴影。

**文件**: `session_screen_message_actions.dart`

## 问题 2: 进入会话卡顿

### 问题现象

从会话列表点击进入有大量消息的会话时，页面在切换前和切换过程中有明显的卡顿和掉帧。

### 根本原因

1. **`initState` 触发 5 个 fire-and-forget 异步操作**：`_loadQueuedComposerMessages`、`_loadCustomInputTemplates`、`_loadSessionUiState`、`_loadSessionData`、`_subscribeToSocketEvents`。其中 `_loadCustomInputTemplates` 和 `_loadSessionUiState` 各自独立调用 `setState`，导致 2 次不必要的独立 rebuild。

2. **`_loadCustomInputTemplates` 已被 `_loadNonCriticalUiData` 替代但未删除**，残留的死代码。

3. **`_loadSessionUiState` 同样已被 `_loadNonCriticalUiData` 替代但未删除**。

### 修复方案

- 已存在的 `_loadNonCriticalUiData` 使用 `Future.wait` 并行加载模板 + UI 状态，在单个 `setState` 中更新所有数据
- 删除残留的 `_loadCustomInputTemplates` 和 `_loadSessionUiState` 死代码
- `_loadSessionData` 中使用 `forceLoadSessions: initialSession == null` 避免不必要的 force reload

**文件**: `session_screen_state_load.dart`

## 问题 3: 自动滚动打断手动滚动

### 问题现象

用户在会话页面手动向上滚动查看历史消息时，每隔几秒页面会自动滚动回最新消息，打断用户的浏览。

### 根本原因

1. **`_startMessagePolling`** 每 8 秒触发 `_scheduleMessageRefresh(autoScroll: _shouldStickToLatest)`。当用户在底部附近时 `_shouldStickToLatest` 为 true，即使用户已经开始向上滚动。

2. **`_scheduleMessageRefresh`** 在 `autoScroll: true` 时调用 `_scheduleScrollToLatest(animate: true, force: true)`，强制滚动到最新。

3. **`build()` 方法** 中 `if (messages.isNotEmpty && !_hasScrolledToLatest) { _scheduleScrollToLatest(); }` 在每次 rebuild 时检查，如果 `_hasScrolledToLatest` 未设置（例如滚动未成功 settle），会持续触发自动滚动。

4. **无用户滚动检测**：没有区分用户手动滚动和程序滚动。

### 修复方案

1. **添加 `_userHasScrolledUp` 标志**：在 `_handleScrollMetricsChanged` 中，当距离底部 > 72px 且已成功 settle 过时设置此标志。

2. **抑制自动滚动**：在以下位置检查 `_userHasScrolledUp`：
   - `build()` 中的 `_scheduleScrollToLatest()` 调用
   - `_startMessagePolling` 的 8 秒轮询
   - socket `connected` 事件
   - socket `messageReceived` 事件

3. **自动恢复**：当用户滚动回底部附近（distanceToBottom <= 8px）时自动清除 `_userHasScrolledUp`。

4. **显示新消息指示器**：当 `_userHasScrolledUp` 为 true 且有新消息到达时，显示 "有新消息" 按钮（已有的 `_hasUnreadMessagesN`），点击后滚动到底部并清除标志。

**文件**: `session_screen.dart`, `session_screen_state_build.dart`, `session_screen_state_socket.dart`, `session_screen_state_scroll.dart`

## 教训

1. **Bottom sheet 需要不透明背景容器** — `Material(type: MaterialType.transparency)` 不提供视觉背景，builder 内容必须自行包裹
2. **多个异步操作的结果应合并到单个 setState** — `_loadNonCriticalUiData` 模式（`Future.wait` + 单次 `setState`）应作为标准模式
3. **自动滚动必须尊重用户意图** — 添加 `_userHasScrolledUp` 标志检测用户手动滚动，抑制自动滚动并改为显示提示

## 相关文件

- `lib/features/session/screens/session_screen.dart`
- `lib/features/session/screens/session_screen_state_build.dart`
- `lib/features/session/screens/session_screen_state_socket.dart`
- `lib/features/session/screens/session_screen_state_scroll.dart`
- `lib/features/session/screens/session_screen_state_load.dart`
- `lib/features/session/screens/session_screen_message_actions.dart`
- `lib/core/widgets/bottom_popup_sheet.dart`
