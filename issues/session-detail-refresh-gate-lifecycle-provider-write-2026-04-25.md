# 会话详情页进入即崩溃：生命周期内同步写 Riverpod provider

**日期**: 2026-04-25
**严重级别**: P0 Critical
**状态**: 已修复

## 现象

- 进入会话详情页后直接出现启动中断页面。
- 报错明确指出：
  - `Tried to modify a provider while the widget tree was building.`
- 触发对象是：
  - `StateController<String?>`

## 确认后的具体根因

上一轮为了尽早挂上会话详情页活跃门闩，把：

- `activeSessionDetailIdProvider = widget.sessionId`
- `activeSessionDetailIdProvider = null`

改成了在 `SessionScreen` 的 `initState` / `dispose` 中同步执行。

这虽然缩短了 post-frame 带来的竞态窗口，但直接违反了 Riverpod 对 widget
生命周期内写 provider 的限制，导致一进入详情页就抛异常。

## 修复方案

- 保留“尽量早生效”的目标，但不再在生命周期同步写 provider。
- 改为使用 `scheduleMicrotask`：
  - 进入详情页时在当前生命周期退出后立刻挂上活跃详情页标记
  - 退出详情页时在微任务中做带 sessionId 校验的清理
- 这样既避开 Riverpod 生命周期写保护，又比 post-frame 更早完成门闩切换。

## 修改文件

- `lib/features/session/screens/session_detail/state/screen_state.dart`

## 后续开发约束

1. Riverpod provider 的写操作不能直接放在 `initState`、`dispose`、`build` 这类 widget 生命周期里同步执行。
2. 如果需要比 post-frame 更早的门闩切换，应优先评估微任务、事件源外置或导航层协调，而不是直接在生命周期同步写状态。
3. 这类“为了修性能/竞态而提前状态写入”的改动，必须同时校验框架生命周期约束，避免修一个抖动又引入启动崩溃。
