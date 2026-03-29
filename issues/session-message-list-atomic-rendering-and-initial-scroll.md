# 会话消息列表原子化渲染与初始定位问题记录

## 背景

本次问题表现为：

- 会话消息数量变多后，在消息列表里的操作会明显卡顿。
- 进入会话页后，消息列表经常没有停在最新消息位置。

这两个问题都出在 `SessionScreen` 的消息列表渲染和滚动链路。

## 根因定位

### 1. 会话页监听粒度过粗，导致大列表频繁整页重建

- 文件：`lib/features/session/screens/session_screen_state_build.dart`
- 文件：`lib/features/session/screens/session_screen_state_socket.dart`
- 根因：
  - 会话页以前直接 `ref.watch(sessionStateProvider)`，任何 session state 播发都会让整页重新 build。
  - 输入框内容变化时，`_handleComposerChanged()` 也会直接 `setState()`，把消息列表、turn 分组、会话统计、悬浮提示一起重建。
- 结果：
  - 即使只是当前会话之外的数据变化，或只是输入框文本变化，也会把大消息列表带着一起重建。

### 2. turn 分组与统计在大列表下缺少增量缓存

- 文件：`lib/features/session/screens/session_screen_state_turns.dart`
- 文件：`lib/features/session/screens/session_screen_state_build.dart`
- 文件：`lib/features/session/screens/session_screen_view_messages.dart`
- 根因：
  - turn group 以前只按 `List` 实例做缓存，消息新增时会直接整表重算。
  - 会话统计每次 build 都会重新扫描全部消息。
  - 展开态 turn section 还会反复创建中间列表。
- 结果：
  - 消息量一大，任何触发 build 的操作都会变成“全量分组 + 全量统计 + 重新组织消息结构”。

### 3. 队列协调逻辑挂在 build 后面，放大了无效计算

- 文件：`lib/features/session/screens/session_screen_state_build.dart`
- 文件：`lib/features/session/screens/session_screen_state_queue.dart`
- 根因：
  - 队列协调以前每次 build 后都会调度，即使消息、发送状态、队列状态都没有变化。
- 结果：
  - 在大列表场景下，会额外增加 build 后处理负担。

### 4. 初始滚动只尝试一次，使用的是未稳定的 `maxScrollExtent`

- 文件：`lib/features/session/screens/session_screen_state_scroll.dart`
- 文件：`lib/features/session/screens/session_screen_state_build.dart`
- 根因：
  - 进入会话页后，列表以前只在首个 post-frame 里执行一次 `jumpTo(maxScrollExtent)`。
  - 但消息项高度是可变的，Markdown、代码块、工具结果这些内容会让 `ListView.builder` 的真实滚动范围在后续 frame 继续增长。
  - 旧逻辑在第一次滚动后就把 `_hasScrolledToLatest` 设为 `true`，不会继续追到底部。
- 结果：
  - 初始进入会话时，经常停在“接近底部但不是最新消息”的位置。

## 本次修复

- 会话页改成只监听当前会话和当前消息列表，不再因其他 session 或 machine 状态变化而整页重建。
- 输入框变化不再触发整页 `setState()`，改为只在输入区域内根据 `TextEditingValue` 做局部刷新。
- turn group 解析补上了增量追加缓存；会话统计补上了基于当前 session/messages 引用的缓存。
- 展开态消息 section 去掉了不必要的中间列表创建。
- 队列协调改成只在 session/messages/发送状态/队列状态变化时调度。
- “滚动到最新消息”改成多帧收敛，直到 `maxScrollExtent` 稳定后再认为已到达最新位置。

## 后续开发约束

- 会话详情页禁止直接监听整个 `sessionStateProvider` 后再在 build 中手动取当前 session，必须使用当前 session 维度的细粒度选择。
- 输入区状态变化不能带着消息列表一起重建；输入框联动 UI 要限制在输入区域内部。
- 大消息列表上的派生数据必须优先做增量计算或引用级缓存，不能每次 build 都全量遍历。
- 对 `ListView.builder` 这类可变高度列表，初始滚动到底部不能依赖单次 `maxScrollExtent`，必须等待滚动范围稳定。
