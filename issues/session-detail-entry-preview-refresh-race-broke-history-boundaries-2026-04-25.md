# 会话详情页历史边界失效：详情页门闩挂载晚于列表预览刷新

**日期**: 2026-04-25
**严重级别**: P0 Critical
**状态**: 已修复

## 现象

- 进入会话详情页后：
  - 到顶失效
  - 到底失效
  - 消息上翻一部分后无法继续翻
- 表现上像是虚拟列表边界状态错乱，历史窗口被中途重置。

## 确认后的具体根因

上一轮为避免 Riverpod 生命周期写入异常，把详情页活跃门闩改成了在
`SessionScreen.initState()` 中通过 `scheduleMicrotask` 写入
`activeSessionDetailIdProvider`。

这个改动虽然修掉了崩溃，但门闩生效时机仍晚于“点击列表项进入详情页”这一用户动作。
在详情页 push 期间，来源页面上的这些刷新链路仍可能先跑一步：

- `sessions_screen/refresh_controller.dart`
- `sessions_screen/visible_snapshot_refresh.dart`
- 以及后台会话快照刷新链路

它们会对当前会话继续执行预览消息刷新，把详情页本应使用的历史窗口重新裁成预览窗口。
一旦窗口起点、已加载数量和 `hasOlder/hasNewer` 标记被这条链路重写，
详情页里的到顶/到底和边界自动加载就会失效，继续上翻也会卡住。

## 修复方案

- 不再只依赖详情页自身在进入后补挂门闩。
- 新增统一的 `openSessionDetail(...)` 导航助手：
  - 在用户点击打开会话详情时，先同步设置 `activeSessionDetailIdProvider`
  - 再执行 `context.push(...)`
- 详情页内保留原有的微任务兜底挂载，兼容非列表入口或直达路由。

## 修改文件

- `lib/features/session/presentation/session_detail_navigation.dart`
- `lib/features/session/screens/sessions_screen/session_actions.dart`
- `lib/features/session/presentation/search_screen/body.dart`
- `lib/features/session/screens/session_recent_screen.dart`
- `lib/features/session/screens/machine_detail_screen.dart`

## 后续开发约束

1. 会影响详情页 resident window 的“预览刷新/后台刷新”必须在导航动作发起前就被门闩拦住，不能等详情页 build 之后再补救。
2. 会话详情页的活跃态属于跨页面协调状态，优先在事件源头设置，而不是完全依赖目标页生命周期。
3. 任何会对 `loadSessionMessages(sessionId, maxPages: ...)` 产生调用的预览逻辑，都必须评估是否会和详情页历史浏览发生窗口覆盖冲突。
