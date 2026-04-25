# 会话详情页闪动与新消息生硬跳动：后台预览刷新抢占 + 同步校正后重复滚底

**日期**: 2026-04-25
**严重级别**: P0 Critical
**状态**: 已修复

## 现象

- 真机日志在详情页期间仍出现大量：
  - `Refreshing session message snapshots for ... sessions`
  - `Session messages loaded: ...`
- 与此同时设备持续上报：
  - `Hiappevent ReportJANKEvent`
- 新消息进入当前虚拟列表时，列表不是平滑跟随，而是会有明显“再滚一轮”的生硬跳动。

## 这次确认的具体问题

### 根因 1：详情页激活标记设置过晚、清理过晚

`state/screen_state.dart` 原来通过 post-frame 才把：

- `activeSessionDetailIdProvider = widget.sessionId`

挂上，退出时也通过 post-frame 才清掉。

这给了列表页后台刷新和全局 background refresh 一个竞态窗口，导致详情页已经进入，
但“当前有激活详情页”的信号还未及时生效，于是可见会话快照刷新继续跑，
抢占 IO、解密、解析和渲染预算。

### 根因 2：新消息同步 standby 校正之后，又无条件触发一轮 settle 滚底

当前增量消息链路里：

1. `_syncMessagesFromRepository()` 已经会在 near-bottom 场景下设置 `standbyForAppend()`
2. `_ChatScrollPosition.applyContentDimensions()` 会在布局期同步把列表校正到底部
3. 但 `state/socket.dart` 在同步完之后，又无条件执行：
   - `_scheduleScrollToLatest(animate: true, force: true)`

这相当于在“已经同步落位”之后，再强制跑一轮多帧 settle/jump/animate，
于是就形成用户看到的生硬二次跳动。

## 修复方案

- 详情页激活标记改为同步设置 / 同步清理，不再等 post-frame。
- socket 增量刷新在 `autoScroll && didMessagesAdvance` 后，先读取当前到底部距离：
  - 若 standby 已让列表基本落位，则不再重复滚底
  - 只有仍明显偏离底部时，才做一次非动画的强制纠偏

## 修改文件

- `lib/features/session/screens/session_detail/state/screen_state.dart`
- `lib/features/session/screens/session_detail/state/socket.dart`

## 后续开发约束

1. “详情页已激活”这类全局门闩状态不能依赖 post-frame 才生效。
2. 同一条消息追加链路里，不能在同步滚动校正成功后再无条件跑异步 settle 滚底。
3. 真机上出现连续 `Hiappevent ReportJANKEvent` 时，要优先排查是否有后台刷新与前台详情页抢占资源。
