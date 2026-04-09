# 会话页 residual 崩溃：turn 锚点包装层与首屏边缘续历史抢跑

## 日期
- 2026-04-08

## 现象
- 点击“到顶”后，消息到顶时列表闪动，随后出现 Flutter `framework.dart` `child == _child` 断言。
- 报错后返回会话列表，又出现 `InheritedElement.debugDeactivated` 的 `_dependents.isEmpty` 断言。

## 这次确认的具体问题
- 消息行里仍然残留了 turn 级额外 anchor widget：
  每个消息行除了行级 row anchor，还会根据 `isFirstReply` 动态插入两个 turn anchor 包装层。这样同一条消息在 prepend 历史后，即便 key 没变，祖先树形状仍可能变化。
- 首屏进入详情页时，顶部自动续历史会抢在“滚到最新消息”之前触发：
  调试日志显示，详情页刚恢复 20 条缓存消息、尚未 pin 到底部时，就已经触发了 top-edge prepend，直接把窗口从 20 条扩到 116 条。这个 prepend 与首屏滚底互相打架，放大了列表重排抖动。

## 影响链路
- turn anchor 包装层导致消息行在窗口平移时无法保持稳定树形状，容易把 `SelectableText` / 选择容器等依赖链一起卷进 reparent。
- 首屏边缘续页抢跑会把“最新窗口首帧”变成“旧窗口 prepend + 再滚底”的复合路径，进一步提高 reparent 和闪动概率。
- 当详情页子树先因为前一个断言损坏后，返回会话列表时又可能在 inherited 依赖清理阶段触发第二个 `_dependents.isEmpty` 断言。

## 修复
- 去掉消息行里的 turn 级 anchor widget，turn 顶部/底部锚点不再依赖额外 widget，而是直接从“首条 reply 消息行 / 末条消息行”的 row context 派生。
- `_BuildContextAnchor` 增加 `activate()` re-attach，保证列表重排后 row context 会重新注册。
- 视口未 ready 前，禁止顶部/底部自动续历史，避免首屏滚底和边缘 prepend/append 抢跑。

## 原则
- 消息列表中每条消息只保留一种稳定祖先结构。
- turn 级定位信息尽量派生自已有消息行，不再为定位单独插入额外 widget。
- 首屏默认链路优先“恢复最新窗口并定位到最新”，历史分页属于后续交互，不得抢跑首帧。
