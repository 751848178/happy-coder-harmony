# 会话页消息行结构、边界锚点方向与对话忙碌态误判

## 日期
- 2026-04-08

## 现象
- 进入会话页仍偶发 Flutter `framework.dart` `child == _child` 断言。
- 手势滚到顶部续历史时，消息列表会乱跳。
- 进入会话页会出现一段明显 loading 态。
- 会话页在回复完成后仍长期显示“AI 正在回复”。

## 根因
- 消息行结构不稳定：
  旧实现里同一条消息在 prepend 历史后，`startsNewTurn` 和 `isFirstReply` 会重新计算，导致该消息的祖先包装层级发生变化；同时 `_MessageBubble` 还带着与行相同的 key，Flutter 会尝试在不同单子节点父元素之间复用该 child element，最终触发 `SingleChildRenderObjectElement.forgetChild` 的 `child == _child` 断言。
- 边界续页锚点方向反了：
  prepend 更老消息时，旧实现固定抓顶部可视消息做锚点；append 更新消息时固定抓底部可视消息。对于“前插旧页 / 后追加新页”这两类操作，这正好会放大视口偏移，导致列表乱跳。
- 首屏阻塞了非首屏必需任务：
  在无缓存或冷启动链路里，首屏会等待 archive hydration，再去滚到最新消息；这让进入会话页时出现额外 loading。
- thinking 快路径漏看完成信号：
  当 `session.thinking != true` 时，快路径只检查“最后一条非用户文本是不是 thinking”，却没有先检查 turn 是否已经收到 `turn-close/ready/stop` 等完成信号，导致 UI 长时间误判为仍在对话中。

## 修复
- 把消息行改成稳定结构：
  每条消息始终走同一层 `Padding -> message-row anchor -> Column -> turn anchor slots -> bubble`，不再按 `isFirstReply` 动态更换消息 bubble 的祖先结构；同时移除 `_MessageBubble` 上的重复 key，只保留行级 key。
- 修正边界锚点策略：
  prepend 旧页时改为保留底部可视锚点；append 新页时改为保留顶部可视锚点。
- 首屏把 archive hydration 挪到后台：
  先完成最新窗口同步和滚到最新，再后台补全 archive。
- 修正 thinking 误判：
  `resolveSessionThinkingSnapshot` 在快路径里先检查 completion signal，再决定是否把最后一条 thinking 文本当作阻塞态。

## 约束
- 不回退 resident window / archive 分页方案。
- 不恢复任何 GlobalKey 或 widget 实例缓存做法。
- 首屏仍只加载小窗口，不允许重新回到全量驻内存。

## 后续建议
- 如果后面仍有列表 reparent 断言，优先抓 Flutter 堆栈并检查“同一条消息在窗口平移前后是否仍发生 turn 边界角色切换”。
- 如果边界续页仍有轻微位移，下一步优先考虑把锚点从“可视边缘消息”改成“可视中心消息”，降低 turn 边界变化对视口恢复的影响。
