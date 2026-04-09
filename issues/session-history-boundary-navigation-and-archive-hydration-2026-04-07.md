## 问题

会话详情页在“大量历史消息 + 窗口化驻内存”模式下，仍然出现两类问题：

1. 点击“到顶”时明显卡顿。
2. 即使点击“同步全部消息”，顶部手势续历史仍可能卡在当前窗口，无法继续访问更多历史消息。

## 根因

### 1. 边界按钮误走了“当前窗口长距离滚动”分支

`scrollToTop()` / `scrollToBottom()` 只在 `archive` 已被判定为完整时，才会走“切换到最早/最新历史窗口”的边界导航。

当页面明明知道窗口外还有历史，但 `archive` 尚未完成 hydration 时，按钮会：

- 先后台触发 `_ensureArchivedMessageHistoryAccessible()`
- 同时继续执行当前窗口的长距离 `animateTo()`

这会导致：

- 用户点击“到顶”时先卡一次长动画
- 动画结束后仍然停留在当前窗口顶部，而不是真正的全历史顶部

### 2. 归档同步存在多入口，缺少统一 in-flight 协调

历史归档有两条入口：

- 自动 hydration：`ensureSessionMessageArchiveHydrated()`
- 手动“同步全部消息”：`syncFullSessionMessagesFromRemote()`

此前只有自动 hydration 会加入 `_archiveHydrationInFlight`，手动同步会绕过它直接再开一次全量同步任务。这样会产生：

- 同一会话同时运行多次全量归档
- summary / archive chunk / UI 刷新状态互相覆盖
- 用户以为“同步全部消息”已完成，但实际可访问窗口并未稳定

### 3. summary 判定“完整”不代表任意窗口都真的可读

`archive summary` 之前只表示：

- `messageCount`
- `isComplete`

但 `_loadSessionMessageArchiveWindow()` 只要读到“非空窗口”就会当成成功，没有验证：

- 这个窗口是否读满了预期条数
- summary 虽然说完整，但该区间是否真的可恢复

因此会出现：

- summary 显示完整
- 但某个历史区间读出来条数不足
- UI 仍把它当成“可访问完整历史”，实际滚到边界就卡住

## 修复

### 1. 边界按钮改成“优先历史边界访问”，不再先滚当前窗口

现在只要检测到窗口外还有历史：

- `scrollToTop()` 会先等待历史可访问，再直接切到最早边界窗口
- `scrollToBottom()` 会先等待历史可访问，再直接切到最新边界窗口

如果历史暂时还不可访问，不会再先执行当前窗口的大距离动画。

### 2. 全量归档统一走单一 hydration task

新增统一的 archive hydration task 协调：

- 自动 hydration
- 手动“同步全部消息”

都会加入同一个 `_archiveHydrationInFlight`。

这样可以避免：

- 并发全量同步
- summary 被不同任务交错覆盖
- UI 判断状态漂移

### 3. 完整 summary 下，窗口读不满时自动判坏并修复

`_loadSessionMessageArchiveWindow()` 现在会校验：

- 目标窗口理论上应该读取多少条
- 实际读出来多少条

如果 summary 标记为完整，但实际窗口条数不足，就会触发 archive 修复重建，而不是继续把不完整窗口交给 UI。

### 4. 归档同步页大小下调

archive sync 从普通消息刷新页大小中解耦，改为更小的独立页大小，降低：

- 单次网络包体
- 单批解析峰值
- 大会话同步时的超时概率和内存抖动

## 经验约束

1. 只要 UI 已知“窗口外还有历史”，边界按钮就不能再走当前窗口滚动兜底。
2. 全量归档类任务必须统一走单一 in-flight owner，禁止多入口各自启动。
3. “summary 完整”只能作为候选条件，不能替代真实窗口可读性校验。
4. 大会话历史同步要有独立页大小和解析并发配置，不能直接复用普通增量刷新参数。
