# Session Chain Architecture Decoupling

日期: 2026-04-06

## 背景

在修复“点击会话 -> 页面滑入 -> 渲染消息列表”和“到顶/到底按钮动画卡顿”之后，继续审查发现这条链路仍有明显的架构债：

- `SessionScreen` 虽然被 `part` 拆散，但运行时几乎所有职责仍集中在 `_SessionScreenState`
- `build()` 里直接调度自动滚底、auto-approve、sticky 刷新、queue reconcile、亮屏策略
- `SessionsScreen` 自己维护 socket 订阅、自动同步定时器、预览刷新节流和尾批游标
- `SessionListItem` 在 UI 层直接从消息快照推导 preview/status/thinking
- `SessionServiceNotifier` 仍同时承担 catalog、machine、message、cache 四种 owner
- `_MessageBubbleState` 承担了大量 tool/text presenter 逻辑

这些问题的共同风险：

- 后续性能优化会不断回退，因为副作用和渲染边界混在一起
- 新需求很容易再次把重逻辑塞回 `build`、`State` 或大 notifier
- 局部修改需要理解整条链路，难以原子化验证

## 本次修复

### 1. SessionScreen 拆出运行时 owner

- 新增 `_SessionScreenLoadCoordinator`
  - 负责入口加载、转场等待、warm refresh、socket 订阅启动
- 新增 `_SessionScreenBodyPresenter`
  - 负责 turnGroups / thinking / sessionStats / body view state 推导与缓存
- 新增 `_SessionScreenBodyEffects`
  - 负责自动滚底、auto-approve、sticky 刷新、queue reconcile、亮屏策略的 post-frame 协调
- 新增 `_SessionScreenCommandController`
  - 负责发送、停止、自动审批、重命名等动作编排
- 新增 `_SessionViewportController`
  - 负责滚动调度、滚动边界状态、sticky 视口刷新、折叠后滚动位置恢复

结果：

- `build()` 不再直接触发业务副作用
- 大量缓存字段与滚动调度状态从 `_SessionScreenState` 移出
- 详情页的“渲染 owner / 副作用 owner / 动作 owner / 视口 owner”边界清晰

### 2. SessionsScreen 拆出刷新 owner 和展示模型

- 新增 `_SessionListRefreshController`
  - 接管 socket 订阅、自动同步、预览刷新节流、尾批轮询
- 新增 `sessions_screen_view_models.dart`
  - 抽出 `_SessionsScreenLayoutSelection`
  - 抽出 `_SessionListItemViewModel`
- `SessionListItem` 改为消费 view model，不再在 widget 内直接拼装 preview/status 推导

结果：

- 列表页 UI 不再直接承担后台刷新调度
- layout selection 和 item 展示模型不再散落在 widget 文件内部
- 后续如果继续做 provider selector 粒度优化，有明确的 view-model 落点

### 3. SessionServiceNotifier 拆出 domain 协作者

- 新增 `_SessionServiceCacheCoordinator`
  - 负责会话缓存恢复、单会话缓存落盘、消息缓存恢复
- 新增 `_SessionServiceCatalogCoordinator`
  - 负责 sessions / machines 加载与 catalog 同步编排
- 新增 `_SessionServiceMessageCoordinator`
  - 负责远端消息加载、全量同步、snapshot refresh

结果：

- `SessionServiceNotifier` 保留状态 owner，但不再亲自承载主要实现细节
- cache / catalog / message 的责任分层清晰，便于后续继续独立测试

### 4. MessageBubble 拆出 presenter

- 新增 `_SessionMessageBubblePresenter`
  - 接管 collapse 判定
  - 接管 tool presentation / title / category / icon / summary / diff 抽取
  - 接管 raw argument/result 的展示推导
- 原 `tool_helpers` 与 `_MessageBubbleState` 改为委托 presenter

结果：

- 气泡组件本身更接近“渲染容器”
- 纯展示推导逻辑有单独 owner，可继续独立扩展或测试

## 约束与原则

本次重构坚持以下原则：

- 不改现有 public API，先拆 owner，再保持行为不变
- 优先 runtime owner 解耦，而不是只做 `part` 文件移动
- 保持每一步都可独立 `analyze` 和定向 `test`
- 不把新逻辑重新塞回 `build`、大 `State`、大 notifier

## 后续建议

- 为 `SessionScreenBodyPresenter` 和 `SessionListRefreshController` 补独立单测
- 将 `SessionScreen` 剩余 UI state 继续收敛成更小的 leaf controller
- 为 message bubble presenter 补 collapse / diff / summary 的快照测试
