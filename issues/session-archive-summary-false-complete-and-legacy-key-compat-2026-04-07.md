# 会话消息 archive 出现“看似完整、实际不可访问”的回归

## 现象

大会话进入详情页后，页面只显示当前 resident window 的一段消息。继续上滑会停在当前窗口顶部，点击“到顶 / 到底”也没有实际效果，用户无法访问完整历史。

## 根因

本次回归由两个问题叠加造成：

1. 详情页把 archive 完整性判定简化成了 `archivedCount >= totalMessageCount`。
   这会把“summary 计数存在”误判成“完整历史可访问”，但实际上并没有验证 archive 是否真的完整可读。

2. archive 读取逻辑从“按前缀扫描 + 排序”切到“按索引 direct key 读取”后，没有兼容老版本 archive key。
   老版本 key 仍以 `sessionId::archive::<index>...` 开头，但 direct lookup 已经无法命中，导致：
   - summary 可能显示完整
   - 实际读取窗口为空
   - 页面状态判断还认为可以继续翻历史
   - 用户看到的结果就是“卡在一部分消息”

## 修复

1. archive 完整性改为联合判断：
   - `messageCount`
   - `isComplete`

2. `HiveRepository` 的 archive 读取增加老 key 兼容：
   - 优先走 direct key
   - direct miss 时回退到前缀扫描
   - 从 key 中解析 archive index，支持旧格式继续读取

3. summary 缺失或为 0 时，会回退根据现有 archive key 计算摘要并回写 metadata，避免老归档直接失效。

4. 如果 summary 非空但窗口实际读不出来，系统会把该 archive 视为损坏并触发自愈：
   - 本地 summary 失效时不再静默卡住
   - 有远端上下文时自动重建 archive

5. 详情页本地状态不再只看 `count`，而是同时跟踪 `count + isComplete`，避免 UI 继续被错误摘要带偏。

## 经验

- 任何窗口化历史方案里，“有多少条”不等于“能不能读出来”。
- 本地分页索引结构一旦升级，必须兼容老 key 或做明确迁移。
- “全量可访问”应该由真实窗口读取能力决定，而不是由 summary 数字决定。
