# 虚拟列表上翻闪跳到最老消息

**日期**: 2026-04-19
**严重性**: 高
**状态**: 已修复

## 现象

用户手动上翻查看历史消息时，翻到一定位置消息会闪一下，然后直接跳到最老的第一屏消息。之后上下滑动，中间的消息丢失。

## 根因

### Bug 1: `applyContentDimensions` 中 standby 状态被过早消耗（主因）

`_ChatScrollPosition.applyContentDimensions` 在 standby 激活时的第一次调用就消耗了 standby 状态。但 Flutter 在一次布局中可能多次调用 `applyContentDimensions`（随内容尺寸逐步精化）。第一次调用的 `max` 往往偏小（ListView 还在测量子项），导致 `delta` 计算错误，`forcePixels` 将视口跳到错误位置。后续调用 `max` 增大，但 standby 已消耗，无法再修正。

**修复**: 只在 `max` 稳定（与上一次调用相同）时才消耗 standby。

### Bug 2: `_syncMessagesFromRepository` 可能覆盖已有 standby

`_syncMessagesFromRepository` 在检测到 nearBottom 时会调用 `standbyForAppend()`。如果 edge load 已经设置了 `standbyForPrepend()`，但时序上 `_isLoadingOlderMessages` 守卫未生效，`standbyForAppend()` 会覆盖 prepend standby，导致修正方向错误。

**修复**: 增加 `_scrollController._standbyPixels == null` 守卫，只有无已有 standby 时才设置新的。

### Bug 3: warm refresh 在用户浏览历史时仍替换消息窗口

`scheduleWarmSessionEntryRefresh` 使用 `force: true` 全量替换消息。如果用户在 warm refresh 异步完成前已经上翻浏览历史，消息窗口被替换导致视口跳转到完全不同的内容。

**修复**: warm refresh 检测 `_userHasScrolledUp || _hasNewerMessages`，跳过消息替换。

## 修改文件

| 文件 | 修改 |
|------|------|
| `session_screen_view_messages.dart` | `_ChatScrollPosition.applyContentDimensions`: 延迟消耗 standby 直到 max 稳定 |
| `session_screen.dart` | `_syncMessagesFromRepository`: 增加 `_standbyPixels == null` 守卫 |
| `session_screen_load_coordinator.dart` | `scheduleWarmSessionEntryRefresh`: 用户浏览历史时跳过消息替换 |

## 经验教训

1. **Flutter 布局多轮调用**: `applyContentDimensions` 可能被调用多次，不可在第一次调用时消耗一次性状态
2. **Standby 保护**: 任何设置 standby 的地方都应先检查是否已有 standby，避免覆盖
3. **异步操作与用户交互竞争**: 异步刷新消息时必须检查用户是否已开始交互，避免覆盖用户正在查看的内容
