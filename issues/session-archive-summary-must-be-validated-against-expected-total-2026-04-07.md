## 问题

大会话详情页里，存在一种“本地归档 summary 看起来完整，但实际历史并不完整”的状态：

- 详情页当前窗口：`252 / 5189`
- 本地 archive summary：`2868` 条，`isComplete = true`

此时页面表现为：

1. 点击“到顶”无响应。
2. 手势滚到边界也不会继续加载更早历史。
3. 即使点击“同步全部消息”，仍然可能不继续补历史。

## 根因

服务层此前把 `summary.isComplete == true` 直接当成“完整历史已可访问”，但没有再拿它去对比该会话的**期望总消息数**。

结果是：

- `2868` 条 contiguous 本地归档
- 被错误视为 `5189` 条历史已完整
- `ensureSessionMessageArchiveHydrated()` 直接返回
- `syncFullSessionMessagesFromRemote()` 也直接跳过

最终导致：

- 顶部按钮等待“完整历史可访问”时永远拿到 `false`
- 边界续历史逻辑永远进不去
- 用户看到的就是“卡在当前窗口”

## 修复

### 1. summary 完整性必须对比 expected total

新增“期望归档消息总数”判断，来源优先级：

1. 当前 repository 中的 `SessionMessages.totalMessageCount`
2. 会话模型中已持久化的消息总数（如 `latestUsage.messageCount`）

只有满足以下条件，才允许把 archive summary 视为完整：

- `summary.isComplete == true`
- `summary.messageCount >= expectedTotalCount`

### 2. 对“假完整 summary”不再跳过同步

当出现：

- `summary.isComplete == true`
- 但 `summary.messageCount < expectedTotalCount`

系统现在会把它视为“归档不足”，继续执行 hydration / full sync，而不是提前返回。

### 3. 详情页本地 complete 状态同步改成“有效完整”

详情页的 `_archivedMessageHistoryCompleteN` 现在不再直接照抄 summary，而是使用“是否达到 expected total”的有效结果，避免 UI 层继续把 partial archive 当成完整历史。

## 经验约束

1. 本地 summary 的 `isComplete` 只能表示“本地索引连续”，不能直接等价成“完整远端历史都已归档”。
2. 任何“同步是否可跳过”的判断，都必须和 expected total count 一起校验。
3. 历史分页/窗口化场景里，bool 型 summary 绝不能脱离 count 单独使用。
