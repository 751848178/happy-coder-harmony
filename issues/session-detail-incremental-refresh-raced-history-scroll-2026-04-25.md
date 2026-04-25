# 会话详情页上翻跳动：增量刷新与历史滚动窗口并发抢占

**日期**: 2026-04-25
**严重级别**: P0 Critical
**状态**: 已修复

## 现象

- 真机上会话页向上翻消息时，列表会出现明显跳动。
- 设备日志中可以看到同一会话在短时间内反复执行增量刷新，例如：
  - `Session messages loaded: ... (server=619, retained=0, local=22->22, total=619, pages=1, window=30)`
- 这些刷新发生时，用户正在浏览消息列表，而不是停留在最新消息底部。

## 这次确认的具体问题

会话页的增量刷新链路位于 `state/socket.dart`，来源包括：

- 8 秒一次的消息轮询
- socket `messageReceived`
- socket `connected` 后的补拉

但原实现只在 `hasNewerMessages == true` 时才停止刷新，没有在以下场景停掉：

- 用户已经手动上翻（`_userHasScrolledUp`）
- 正在加载更老/更新历史窗口
- 程序化滚动仍在执行
- 消息视口还未 ready

这意味着用户上翻历史时，后台增量刷新仍可能插入到同一个时间窗口里，和：

- 顶部历史窗口平移
- anchor 恢复
- 自动滚底/滚动状态刷新

发生并发竞争，最终表现成列表跳动。

## 修复方案

在会话详情页增加统一的“增量刷新延后”判定：

- `_userHasScrolledUp`
- `_isLoadingOlderMessages`
- `_isLoadingNewerMessages`
- `_viewportController.programmaticScrollActivity != 0`
- `!_messageViewportReady`

只要命中这些状态，轮询和 socket 增量刷新都不再主动拉取消息，而是仅保留未读提示。

## 修改文件

- `lib/features/session/screens/session_detail/state/socket.dart`

## 后续开发约束

1. 任何增量刷新都不能与“用户正在浏览历史窗口”并发执行。
2. 会话页的自动刷新必须服从视口状态，而不是只看 `hasNewerMessages`。
3. 涉及滚动恢复、边缘续页、程序化滚动的时段，后台刷新只能延后，不能抢跑。
