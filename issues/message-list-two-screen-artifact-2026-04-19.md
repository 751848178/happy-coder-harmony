# 消息列表"双屏"渲染异常

**日期**: 2026-04-19
**严重级别**: P0 Critical
**状态**: 已修复（2026-04-20 追加闭环）

## 现象

用户发送消息时，消息列表偶尔出现从中间分为上下两部分的视觉异常。两部分都显示正常的可交互消息。

## 已确认的相关错误

设备日志显示大量 `ScrollController attached to multiple scroll views` 断言错误，堆栈指向两个调用点：

1. `_ChatScrollController.standbyForAppend` → `_syncMessagesFromRepository`
2. `_refreshStickyTurnPrompt` → `scheduleViewportStateRefresh`

## 根因分析

### 根因 1: `_ChatScrollController` 多 position 断言失败（已修复）

`_ChatScrollController.standbyForAppend()` 内部调用 `position.pixels`，
而 `ScrollController.position` getter 要求 `_positions.length == 1`。
当 `_collapsedTurnSummariesN` ValueNotifier 异步更新触发
`ValueListenableBuilder` 重建内部 `ListView.builder` 时，
旧 `ScrollPosition` detach 和新 `ScrollPosition` attach 在同一帧中发生，
短暂出现两个 position，触发断言。

**修复**: 添加 `effectivePosition` getter，使用 `positions.last` 代替 `position`。
所有 `_scrollController.position` 调用已替换为 `effectivePosition`。

### 根因 2: `applyContentDimensions` standby 消耗时机（已修复）

原始实现在第一次 `applyContentDimensions` 调用时立即消耗 standby。
Flutter 可能多次调用 `applyContentDimensions`（随内容尺寸逐步精化），
第一次 max 可能偏小导致 delta 偏小，后续调用无法再修正。

**修复**: 改为 `max >= standbyMax && delta.abs() > 0.5` 时才消耗 standby。

### 根因 3: 滚动校正可能被旧 ScrollPosition 消耗（已修复）

发送消息时的事件序列：
1. `dispatchMessage` → `_updateState(setState)` → `_isSendingN.value = true`
2. Repository `sendMessage` 乐观插入
3. `_scheduleMessageSync` → microtask → `_syncMessagesFromRepository`
4. `standbyForAppend()` → `_messageViewStateN.value = nextState`
5. `ListenableBuilder` 重建 → `ListView.builder` 新 itemCount
6. 布局: `applyContentDimensions` 修正滚动
7. Post-frame: `_scrollToLatestUntilSettled` 动画

当 Flutter 在同一帧内切换/重建消息 `ListView` 时，旧 position 和新
position 会短暂同时挂到 `_ChatScrollController` 上。此前
`_ChatScrollPosition.applyContentDimensions()` 只检查 standby 是否存在，
没有检查当前调用者是不是最新有效 position，旧 position 可能先消费
standby，导致真正要显示的新列表错过同步滚动校正。

**修复**: `_ChatScrollController` 增加 `effectivePositionOrNull`、
`isEffectivePosition()`，`applyContentDimensions()` 只允许最新有效
position 消费 standby。`jumpTo()` / `animateTo()` 也改为只驱动最新有效
position，避免瞬态多 position 时把旧列表一起驱动。

### 根因 4: `Opacity(0)` 保留不可见但占位的列表（已修复）

`_buildSessionBody` 使用 `Opacity(opacity: 0)` + `IgnorePointer` 保留列表在
widget tree 中（用于 anchor 恢复）。在 OHOS/HarmonyOS Flutter 引擎上，
`Opacity(0)` 的 compositing layer 可能存在渲染差异。

**修复**: 保留消息列表挂载用于锚点恢复，但不再用 `Opacity(0)` 控制
核心 `ListView` 显隐；改为独立的 `_buildMessageListStage()`，内部使用
`Offstage` 隐藏列表绘制，并用 `ColoredBox(AppTheme.neutral50)` 显式清屏，
避免旧 opacity layer 被错误复用成“上下两屏都有消息列表”。

## 修改文件

| 文件 | 修改 |
|------|------|
| `view/message_scroll.dart` | `effectivePosition` getter；只允许最新有效 position 消费 standby；`jumpTo` / `animateTo` 只驱动最新有效 position |
| `view/message_stage.dart` | 新增消息列表显隐舞台，使用 `Offstage` + 显式背景清屏替代 `Opacity(0)` |
| `state/build.dart` | 消息区调用 `_buildMessageListStage()`，移除内联 opacity 隐藏逻辑 |
| `state/sticky_prompt.dart` | `position` → `effectivePosition` |
| `state/refresh.dart` | `position` → `effectivePosition` |
| `viewport/viewport_controller.dart` | `position` → `effectivePosition` |
| `state/screen_state.dart` | `position` → `effectivePosition` |

## 验证

- 2026-04-20: `flutter analyze` 通过，无 error
- 2026-04-20: `flutter test test/session_list_preview_test.dart test/session_service_state_test.dart test/session_creation_options_test.dart` 通过
- 2026-04-20: `flutter test` 全量通过
- 真机回归建议：发送消息、流式回复、折叠/展开轮次、上翻/下翻历史时确认不再出现上下双屏消息列表
