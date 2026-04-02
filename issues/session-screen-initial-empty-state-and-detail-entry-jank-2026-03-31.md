# 会话详情首帧误判空态并阻塞式全量刷新导致掉帧

> 创建日期: 2026-03-31

## 问题概述

从会话列表进入会话详情时，出现了两个连锁问题：

1. 会话已有历史消息，但详情页首帧却显示“开始新的对话”空态，看起来像“没有消息列表”。
2. 进入详情的过渡阶段明显卡顿，掉帧严重。

## 根因 1：把“消息尚未加载”误判成“空会话”

- 文件：`lib/features/session/screens/session_screen_state_build.dart`
- 旧逻辑只看 `selection.messages ?? []`
- 当 `session` 已经存在、但 `sessionMessages[sessionId]` 还没加载完成时，`messages` 会变成空列表
- UI 直接进入 `_buildEmptyState()`，把“加载中”误显示成“没有消息”

### 修复原则

- 会话详情必须区分三种状态：
  - `session` 不存在：删除态 / 全局 loading
  - `session` 存在但消息未加载：消息 loading
  - `session` 存在且消息已加载但为空：真正空态

## 根因 2：详情页初始化时强制阻塞全量刷新 sessions/machines

- 文件：`lib/features/session/screens/session_screen_state_load.dart`
- 旧逻辑在 `initState -> _loadSessionData()` 里无条件执行：
  - `loadSessions(force: true)`
  - `loadMachines(force: true)`
  - 然后才开始加载当前 session 的 messages

这会在用户刚从列表点击进入详情时，把一次“打开单个会话”的操作放大成“全量刷新整个 session/machine 上下文”，在导航过渡期做了大量不必要的工作。

### 修复原则

- 详情页首帧只阻塞“当前会话真正缺失”或“当前消息快照不存在”的场景
- 已经在列表页拿到的 session/machine 上下文，进入详情时应直接复用
- 全量 session/machine 刷新只能后台补做，不能卡在详情首帧前

## 本次修复

- 为详情页选择器补充 `hasLoadedMessages`
- 只有在“消息已加载且确实为空”时才显示空态
- 进入详情时改成：
  - 必要时阻塞加载当前上下文
  - 已有缓存时优先显示缓存消息
  - session/machine 的全量同步转到后台刷新

## 开发约束

1. 详情页的首帧渲染必须围绕“当前 session”做局部加载，不能绑定全局 session 刷新。
2. 空态组件只能用于“真实空数据”，不能兼做 loading fallback。
3. 列表页和详情页的职责要解耦：
   - 列表页负责列表和预览
   - 详情页负责当前会话
   - 不要在详情页入口重跑整个列表上下文
