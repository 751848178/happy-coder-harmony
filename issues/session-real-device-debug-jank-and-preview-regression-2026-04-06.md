# 会话链路真机调试记录（2026-04-06）

## 背景

- 用户反馈进入会话页仍有严重卡顿。
- 用户反馈会话列表消息概览丢失，持续显示“最近消息待同步”。
- 本轮目标不是猜测性优化，而是补充真机 debug 埋点，结合设备日志继续收敛根因。

## 已确认问题

### 1. 会话列表预览回归

- `SessionServiceNotifier._emitReadyState()` 已不再向全局 `ready.sessionMessages` 暴露消息快照。
- 但列表项预览仍通过 `hasLoadedMessages == false` 直接走“最近消息待同步”分支。
- 结果是即使 `Session.previewText/lastMessageAt/listStatusKind` 已经由 repository 预计算完成，列表项仍然错误显示同步中。

### 2. 会话详情页卡顿仍需真机日志定位

- 现阶段无法再只靠静态阅读断定唯一瓶颈。
- 需要观察以下热路径的真实耗时：
  - 会话入场加载：缓存恢复、上下文加载、消息加载、warm refresh。
  - 消息结构推导：`turnGroups` 构建、`flatItems` 扁平化。
  - 程序化滚动：到顶、到底、首帧滚底。
  - Sticky prompt 刷新。

## 本轮修改

### 1. 修复列表预览错误降级

- 文件：`lib/features/session/domain/session_list_preview.dart`
- 调整：当 `hasLoadedMessages == false` 但 `Session` 已具备 `previewText` 或 `lastMessageAt` 时，优先使用预计算 preview，而不是错误显示“最近消息待同步”。
- 原则：不重新引入全局消息快照依赖，继续保持列表页只消费轻量 preview fields。

### 2. 补充真机 debug 埋点

- 入口加载日志：
  - `lib/features/session/screens/session_screen_load_coordinator.dart`
- 本地消息同步日志：
  - `lib/features/session/screens/session_screen.dart`
- turn group / flat list 构建耗时日志：
  - `lib/features/session/screens/session_screen_body_presenter.dart`
- 程序化滚动耗时日志：
  - `lib/features/session/screens/session_screen_viewport_controller.dart`
- sticky prompt 刷新耗时日志：
  - `lib/features/session/screens/session_screen_state_sticky_prompt.dart`
- session preview 字段更新日志：
  - `lib/features/session/data/session_repository_models.dart`

## 当前结论

- “最近消息待同步”持续显示是明确代码回归，不是真实同步状态。
- 详情页卡顿仍需要基于真机日志继续判断是“加载耗时”“结构计算耗时”还是“程序化滚动耗时”主导。

## 后续动作

- 安装 debug 包到真机。
- 保持一个持续输出的 debug 控制台。
- 让用户按“进入会话页 / 点击到顶 / 点击到底”复现。
- 依据日志热点继续做定点修复，而不是继续做猜测性大改。
