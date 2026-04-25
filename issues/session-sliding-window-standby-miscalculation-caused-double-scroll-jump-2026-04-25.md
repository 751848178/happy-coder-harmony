# 会话页历史滑动窗口跳动：standby 用 `maxScrollExtent` 净变化量校正是错误的

**日期**: 2026-04-25
**严重级别**: P0 Critical
**状态**: 已修复

## 现象

- 上翻或下翻历史消息时，消息列表会出现明显的二次跳动。
- 用户看到的效果通常是：
  - 先被推到一个错误位置
  - 紧接着又被拉回目标位置

## 这次确认的具体问题

会话页历史分页使用的是 resident sliding window，而不是纯追加列表：

- `load older`：头部插入一批消息，同时尾部裁掉一批消息
- `load newer`：尾部插入一批消息，同时头部裁掉一批消息

但 `refresh_older.dart` / `refresh_newer.dart` 仍然会在这两条链路里启用：

- `standbyForPrepend()`
- `standbyForAppend()`

`_ChatScrollPosition.applyContentDimensions()` 的 standby 校正依赖：

- `maxScrollExtent` 新旧差值 `delta`

这个 `delta` 只代表“整个窗口净高度变化”，并不代表：

- prepend 时“插入到视口上方的真实高度”
- append 时“插入到视口下方并从头部裁掉后的真实锚点位移”

所以在 sliding window 里，standby 同步校正会先把视口推到错误位置；
随后 `_restoreMessageViewportAnchorAfterFrame()` 再依据真实 anchor 做一次精确恢复，
最终就形成用户可见的二次跳动。

## 修复方案

- 对 sliding window 的 `load older` / `load newer`，不再启用 standby 同步校正。
- 只保留基于真实消息锚点的 `anchor restore` 作为唯一滚动恢复来源。
- 在 sync 到 anchor 恢复的过渡期间短暂启用内容抑制，避免把中间错误位置直接暴露给用户。

## 修改文件

- `lib/features/session/screens/session_detail/state/refresh_older.dart`
- `lib/features/session/screens/session_detail/state/refresh_newer.dart`

## 后续开发约束

1. `maxScrollExtent` 差值只适用于纯 prepend / 纯 append，不适用于对侧同时裁剪的 sliding window。
2. sliding window 的滚动保持必须以真实锚点为准，不能用净高度变化近似代替。
3. 同一条历史翻页链路里不能同时启用“错误近似的 standby”与“精确 anchor restore”，否则必然出现双重校正。
