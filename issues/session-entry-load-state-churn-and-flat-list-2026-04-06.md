# Session Entry Load State Churn And Flat List

日期: 2026-04-06

## 进入会话页时实际加载的内容

`SessionScreen.initState()` 进入后，会并行启动以下链路：

1. `_loadQueuedComposerMessages()`
   - 读取当前会话的待发送队列
2. `_loadNonCriticalUiData()`
   - 读取快捷模板
   - 读取会话 UI 状态
     - overview 折叠状态
     - 全部 turn 折叠状态
     - 已展开的 turn ids
3. `_loadSessionData()`
   - 等待首帧结束
   - 从 repository 读当前 session 和 message snapshot
   - 必要时从本地 cache 恢复消息
   - 必要时加载 sessions / machines 上下文
   - 加载远端消息或 warm refresh
   - 恢复 draft
   - 触发 auto-approve 检查
   - 调度滚到底部
   - 启动 socket session 订阅和 polling
4. `_subscribeToSocketEvents()`
   - 订阅 socket 重连 / messageReceived 事件
5. `_subscribeToMessageChanges()`
   - 订阅 repository 的 per-session message 变化

换句话说，进入页并不是只“加载消息列表”，而是同时在恢复：

- 会话核心数据
- 消息快照
- 设备上下文
- draft
- 队列
- 模板
- UI 折叠状态
- socket / polling 生命周期

## 审计到的问题

### 1. 消息同步会触发成对重建

原实现把会话消息拆成两个本地 notifier：

- `_messagesN`
- `_messagesLoadedN`

每次 `_syncMessagesFromRepository()` 都会依次写这两个 notifier。首次进入页恢复消息时，body 监听 `Listenable.merge([_messagesN, _messagesLoadedN])`，会被连续唤醒两次。

影响：

- 进入页首次恢复消息时，body / effect / 列表 flatten 都会多跑一轮
- refresh / warm refresh 时也会出现不必要的重复重建

### 2. 消息列表 flatten 是整表 O(n)

原实现 `_buildMessageList()` 在每次 body 重建时都执行：

- `turnGroups -> flatItems`

即使消息只是尾部 append 一个 chunk，也会重新遍历所有 turn group 和所有 message 生成新 `_FlatMessageItem` 列表。

影响：

- 进入页首次拿到大消息快照时会做一次整表展开
- 流式追加时，本该只处理尾部新增消息，却反复做全量 O(n) 展开
- 列表越长，进入页和首轮 refresh 越容易卡

### 3. 快捷模板加载触发整页 setState

原实现 `_loadNonCriticalUiData()` 和模板编辑/删除流程直接改 `_customInputTemplates`，并通过 `setState` 触发整个 `SessionScreen` 重建。

但模板只影响输入区：

- 输入模板面板
- 输入区底部提示文案

影响：

- 进入页读取模板时，整个详情页会额外重建一次
- 编辑模板时也会把消息区、AppBar、列表 overlay 一起带着重建

## 本次修复

### 1. 合并消息本地状态

新增 `_SessionMessageViewState`，将：

- `messages`
- `hasLoadedMessages`

合并进单个 notifier。

结果：

- `_syncMessagesFromRepository()` 每次只发出一次本地状态通知
- 进入页恢复缓存和远端 refresh 时，body 重建次数明显下降

### 2. flat list 改成增量 append

在 `_SessionScreenBodyPresenter` 中新增 `resolveFlatItems()` 缓存：

- 普通变更仍走全量构建
- 对于消息尾部 append 的常见路径，只补最后一个 turn 的新增消息和新增 turn

结果：

- 原先的整表 O(n) flatten，变成常见流式路径下近似 O(1) / O(delta)
- 大会话进入页首轮渲染和后续 streaming 更稳定

### 3. 模板状态下沉到输入区

新增 `_customInputTemplatesN`，让模板加载和编辑只驱动输入区相关 subtree。

结果：

- 进入页读取模板不再触发整页重建
- 模板编辑/删除不再拉着消息区一起重绘

## 本次涉及文件

- `lib/features/session/screens/session_screen.dart`
- `lib/features/session/screens/session_screen_message_view_state.dart`
- `lib/features/session/screens/session_screen_body_presenter.dart`
- `lib/features/session/screens/session_screen_state_build.dart`
- `lib/features/session/screens/session_screen_view_messages.dart`
- `lib/features/session/screens/session_screen_state_load.dart`
- `lib/features/session/screens/session_screen_view_command_template_editor.dart`
- `lib/features/session/screens/session_screen_view_input.dart`

## 仍需注意的非热点 O(n)

以下仍然可能是 O(n)，但不属于当前“进入页热路径”的首要瓶颈：

- `SessionStatsCalculator.fromSession()`
  - 只在 overview 展开时运行
- 全部 turn 折叠后的卡片列表
  - 是用户主动切换后的展示路径

这些路径如果后续也出现卡顿，再单独做增量统计或 presenter 级缓存。
