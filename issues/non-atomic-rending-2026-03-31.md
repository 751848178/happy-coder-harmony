# 非原子化渲染导致页面大范围重绘问题

> 创建日期: 2026-03-31

## 问题概述

项目中多处使用了粗粒度的 `setState` 和 `ref.watch`，导致局部状态变化时触发整个页面重建，而非仅重建受影响的子组件。这在消息列表、语音通话、首页等场景下会造成明显的性能问题。

## 涉及文件和具体问题

### 1. 语音通话屏幕 — 50ms 周期性全屏重建 (严重)

**文件**: `lib/features/realtime/presentation/voice_call_screen.dart`

**问题**: 每 50ms 触发一次 `setState` 来更新音频可视化数据，但 `setState` 重建了整个页面（包括头像、通话时长、控制按钮），而非仅更新 `CustomPaint`。

**根因**: 音频级别数据和页面其他 UI 状态（静音、连接状态）共用一个 `State`，定时器直接调用外层 `setState`。

**修复方案**: 将音频可视化提取为独立的 `StatefulWidget`，其内部维护 `_audioLevels` 和 `Timer`，仅在自身范围内 `setState`。外层页面不需要 50ms 级别的重建。

### 2. 会话详情屏幕 — 超大 State 触发全屏重建 (严重)

**文件**: `lib/features/session/screens/session_screen.dart` 及 30+ 个 part 文件

**问题**: `_SessionScreenState` 持有 **60+ 个状态变量**（滚动状态、发送状态、折叠状态、粘性提示、队列状态、模板状态等），任何一个变量的 `setState` 都会导致整个 `_buildSessionScreen` 重建，包括消息列表、输入区域、AppBar 等所有子组件。

**根因**:
- 滚动位置变化（`_handleScrollMetricsChanged`）会 `_updateState` 更新 `_canScrollToTop`、`_shouldStickToLatest` 等，触发全屏重建
- 粘性提示刷新（`_refreshStickyTurnPrompt`）会 `_updateState` 更新 `_stickyTurnId`
- 队列消息变更会 `_updateState` 更新 `_queuedMessages`
- Socket 消息到达会通过 provider watch 触发重建，再叠加上述 setState

**修复方案**:
- **滚动/粘性/队列状态 → `ValueNotifier` + `ValueListenableBuilder`**: 这些高频变化的 UI 状态不应通过 `setState` 传播，而应使用 `ValueNotifier` 精准通知对应的 `Builder` 重建
- **将输入区域提取为独立 `StatefulWidget`**: 输入区域拥有自己的 `TextEditingController`、发送状态等，不需要跟随消息列表重建

### 3. 首页 — 多 Provider Watch 导致级联重建 (中等)

**文件**: `lib/features/home/screens/home_screen_content.dart`

**问题**: `_buildHomeScreen` 同时 `ref.watch` 了三个 provider：
- `authStateProvider` → 控制登录状态
- `sessionStateProvider` → 会话列表数据
- `socketStateProvider` → 连接状态

任何一个 provider 变化都会重建整个首页（包括 `Scaffold`、`IndexedStack`、底部导航栏）。

**根因**: 没有对不同的状态变化做细粒度的隔离。特别是 `socketStateProvider` 仅用于显示连接状态图标，却会触发整个页面重建。

**修复方案**:
- 将 Socket 连接状态指示器提取为独立的 `ConsumerWidget`，内部 `ref.watch(socketStateProvider)`
- `sessionStateProvider` 的 watch 已经在 `sessions_screen` 中存在，首页层面不应重复 watch
- 使用 `ref.listen` 处理只需要副作用的场景（如 `_ensureConnectedServices`）

### 4. 会话列表屏幕 — 宽泛 setState (中等)

**文件**: `lib/features/session/screens/sessions_screen.dart`

**问题**: 多个独立 UI 状态通过同一个 `setState` 更新：
- 搜索查询 `_searchQuery` → 仅影响搜索栏和列表过滤
- 分组状态 `_groupingState` → 仅影响分组工具栏和列表渲染
- 刷新状态 `_isRefreshingSessions` → 仅影响刷新指示器
- 每次变化都重建整个 `Column`（搜索栏 + 工具栏 + 列表）

**修复方案**:
- 将搜索栏提取为独立 `StatefulWidget`，内部管理 `_searchQuery`
- 将分组工具栏提取为独立 `ConsumerWidget`，通过回调通知状态变化
- 刷新状态使用 `ValueNotifier<bool>` + `ValueListenableBuilder`

### 5. 命令面板 — setState 包装器 (轻微)

**文件**: `lib/shared/widgets/command_palette.dart`

**问题**: `_updateView` 包装了 `setState`，用于搜索过滤和选中索引变化。每次输入字符都重建整个面板。

**修复方案**: 命令面板本身是覆盖层且已经足够轻量，暂不优先处理。如果后续面板内容变复杂，可以将过滤列表提取为独立组件。

## 已完成的修复

### Fix 1: 语音通话屏幕 — 音频可视化组件隔离 ✅

- **文件**: `voice_call_screen.dart`, `voice_call_screen_content.dart`
- **改动**: 提取 `_AudioVisualization` 为独立 `StatefulWidget`，内部维护 50ms 定时器和 `_audioLevels` 数据
- **效果**: 定时器仅重建 `CustomPaint`，不再触发整个通话页面重建

### Fix 2: 会话详情屏幕 — 滚动/覆盖层状态 ValueNotifier 化 ✅

- **文件**: `session_screen.dart`, `session_screen_state_socket.dart`, `session_screen_state_scroll.dart`, `session_screen_state_sticky_prompt.dart`, `session_screen_view_indicators.dart`, `session_screen_state_build.dart`
- **改动**:
  - 9 个滚动/覆盖层状态变量转为 `ValueNotifier`（`_canScrollToTopN`, `_canScrollToBottomN`, `_isNearBottomN`, `_shouldStickToLatestN`, `_hasUnreadMessagesN`, `_stickyTurnIdN`, `_scrollActionsCollapsedN`, `_scrollActionVerticalOffsetN`, `_scrollActionDragDxN`）
  - `_handleScrollMetricsChanged` 不再调用 `setState`，直接设置 ValueNotifier
  - `_refreshStickyTurnPrompt` 不再调用 `setState`
  - `_scrollToLatestUntilSettled` 仅对 `_hasScrolledToLatest` 调用 `setState`（该变量只变化一次）
  - 拖拽/折叠处理器直接设置 ValueNotifier
  - build 方法中：未读指示器用 `ValueListenableBuilder<bool>` 包裹，粘性提示用 `ValueListenableBuilder<String?>` 包裹，滚动操作覆盖层用 `ListenableBuilder` + `Listenable.merge` 包裹
- **效果**: 滚动事件不再触发消息列表、输入区域、AppBar 的重建

### Fix 2c: 会话详情屏幕 — 待发送队列 ValueNotifier 化 ✅

- **文件**: `session_screen.dart`, `session_screen_state_load.dart`, `session_screen_state_queue_management.dart`, `session_screen_view_input.dart`, `session_screen_view_queue_panel.dart`
- **改动**:
  - `_queuedMessages` 转为 `ValueNotifier<List<QueuedComposerMessage>>`（`_queuedMessagesN`）
  - `_loadQueuedComposerMessages` 和 `_storeQueuedComposerMessages` 直接设置 ValueNotifier，不再通过 `setState`
  - `_maybeSendNextQueuedMessage` 中的队列恢复直接设置 ValueNotifier
  - `_buildQueuedComposerPanel` 接受 `queuedMessages` 参数，不再从 state 读取
  - `_buildInputArea` 中待发送面板区域用 `ValueListenableBuilder<List<QueuedComposerMessage>>` 包裹
- **效果**: 待发送消息变化仅重建队列面板，不触发消息列表、AppBar 等重建

### Fix 3: 首页 — Socket 状态隔离 + Session 状态精准订阅 ✅

- **文件**: `home_screen_content.dart`, `home_screen_header.dart`
- **改动**:
  - `sessionStateProvider` 的 watch 改为 `.select()` 只监听 session/machine 数量和 ID 列表指纹，不再 watch 整个 state
  - Socket 连接状态指示器在 `_HomeHeader` 内部通过 `Consumer` watch `socketStateProvider`，不再由父组件传入
  - 移除了 `_HomeHeader` 的 `status` 参数
- **效果**: Socket 状态变化（重连、断开等）仅重建状态指示器，不触发整个首页重建

### Fix 4: 会话列表屏幕 — 搜索/分组/刷新状态隔离 ✅

- **文件**: `sessions_screen.dart`, `sessions_screen_content.dart`
- **改动**:
  - 5 个状态变量转为 `ValueNotifier`（`_searchQueryN`, `_showActiveOnlyN`, `_isRefreshingSessionsN`, `_groupingStateN`, `_groupingLoadedN`）
  - 搜索栏用 `ValueListenableBuilder<String>` 包裹，仅重建搜索栏（清除按钮可见性）
  - 分组工具栏 + 列表内容用 `ListenableBuilder` + `Listenable.merge` 包裹，仅重建工具栏和列表
  - Scaffold 用 `ListenableBuilder` 包裹（监听 `_isRefreshingSessionsN` + `_showActiveOnlyN`），仅 AppBar 随刷新/活跃过滤状态变化
  - 所有 setter 方法（`_updateSearchQuery`、`_toggleShowActiveOnly`、`_setRefreshingSessions`、`_loadGroupingState`、`_updateGroupingState`）直接设置 ValueNotifier，不再调用 `setState`
- **效果**: 搜索输入仅重建搜索栏和列表，不重建 AppBar；分组变化仅重建工具栏和列表；刷新状态仅重建 AppBar

### Fix 6: 会话详情 — settingsStateProvider 精准订阅 ✅

- **文件**: `session_screen_state_build.dart`, `session_screen_view_input.dart`, `sessions_screen_content.dart`
- **改动**:
  - `session_screen_state_build.dart`: `ref.watch(settingsStateProvider)` 改为 `.select((s) => (s.commandPaletteEnabled, s.agentInputEnterToSend))`，仅订阅 2 个相关字段（共 24 个）
  - `_buildInputArea` 参数从 `SettingsState settings` 改为独立的 `commandPaletteEnabled` 和 `agentInputEnterToSend` 布尔参数
  - `sessions_screen_content.dart`: `ref.watch(settingsStateProvider)` 改为 `.select((s) => s.hideInactiveSessions)`，仅订阅 1 个字段
- **效果**: 其他 22 个设置变更（主题、通知、权限模式等）不再触发会话详情页或会话列表页重建

### Fix 6b: 会话详情 — 待发送队列 ValueNotifier 化 ✅

- **文件**: `session_screen.dart`, `session_screen_state_load.dart`, `session_screen_state_queue_management.dart`, `session_screen_view_input.dart`, `session_screen_view_queue_panel.dart`
- **改动**:
  - `_queuedMessages` 转为 `ValueNotifier<List<QueuedComposerMessage>>`（`_queuedMessagesN`）
  - 所有队列变更方法直接设置 ValueNotifier，不再通过 `setState`
  - `_buildInputArea` 中队列面板区域用 `ValueListenableBuilder<List<QueuedComposerMessage>>` 包裹
- **效果**: 队列消息变化仅重建队列面板，不触发消息列表、AppBar 等重建

### Fix 7: Chat 屏幕 — provider 精准订阅 ✅

- **文件**: `chat_screen_messages.dart`, `chat_screen_layout.dart`
- **改动**:
  - `chat_screen_messages.dart`: `ref.watch(sessionStateProvider)` 改为 `.select()` 仅订阅 `sessionMessages[sessionId]`
  - `chat_screen_layout.dart`: `ref.watch(sessionStateProvider)` 改为 `.select()` 仅订阅 `sessions[sessionId]`
- **效果**: 其他会话的状态变化不再触发 chat 屏幕重建

### Fix 8: 8 个裸 ref.watch(sessionStateProvider) 文件 — 加 .select() ✅

- **改动文件**: `session_recent_screen.dart`, `machine_detail_screen.dart`, `session_machine_picker_screen.dart`, `session_message_detail_screen.dart`, `session_info_screen.dart`, `new_session_flow_screen_content.dart`, `settings_screen_content.dart`, `search_screen_body.dart`
- **改动**: 全部加 `.select()` 仅订阅各自需要的子状态（特定会话、会话列表、机器列表等）
- **效果**: 不相关的会话/消息/机器变更不再触发这些屏幕重建

### Fix 9: 其他屏幕宽泛 setState 修复 ✅

- **`session_git_diff_screen.dart`**: `_displayMode` 转为 `ValueNotifier`，模式切换栏和内容区用 `ValueListenableBuilder` 包裹，切换 diff/文件视图不再重建 AppBar
- **`bash_tool_screen.dart`**: `_isExecuting` 转为 `ValueNotifier`，输入栏用 `ValueListenableBuilder` 包裹，命令执行状态变化仅重建输入栏
- **`friends_search_screen.dart`**: 搜索栏清除按钮用 `ListenableBuilder`（监听 `_searchController`）包裹，每输入一个字符不再重建整个搜索结果列表
- **`file_viewer_screen.dart`**: 所有状态变量总是一起变化，无需拆分
- **`inbox_screen.dart`**: 所有状态变量总是一起变化，无需拆分

### Fix 5: 命令面板 — 已是独立组件，无需修改 ✅

- **文件**: `command_palette.dart`
- **分析**: 命令面板已是独立的 `ConsumerStatefulWidget`，`_updateView` 仅在其自身范围内触发 `setState`，不会影响父组件。覆盖层内容轻量，无需进一步优化

## 最佳实践总结（避免同类问题）

1. **一个 State 只管一个关注点**: 如果一个 StatefulWidget 有超过 10 个状态变量，说明需要拆分
2. **高频更新使用 ValueNotifier**: 滚动状态、动画数据、定时器数据等，使用 `ValueNotifier` + `ValueListenableBuilder` 精准重建
3. **Provider watch 要精准**: 使用 `ref.watch(provider.select(...))` 只订阅需要的子状态
4. **独立 UI 块用独立 Widget**: 输入区域、状态栏、控制按钮等应该各自是独立的 Widget，不要放在同一个 `build` 方法中
5. **能用 ref.listen 就不要 ref.watch**: 如果状态变化只需要执行副作用（如导航、服务初始化），使用 `ref.listen`
6. **RepaintBoundary**: 已经有消息气泡使用了 `RepaintBoundary`，这是正确的做法
