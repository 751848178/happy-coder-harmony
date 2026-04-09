## 问题

会话详情页此前虽然已经使用 `ListView.builder`，但消息数据层仍存在两个核心问题：

1. 驻内存窗口偏大，默认进入详情页会恢复或保留过多完整消息对象。
2. archive 的“历史翻页”是整窗替换，不是邻页追加，导致滚动接近边界时无法形成稳定的连续访问体验。

## 本次目标

1. 默认进入详情页只保留最新一小页消息在内存中。
2. 接近顶部时优先从本地 archive 邻接页补历史，而不是整窗跳转。
3. 内存里最多只保留 2 到 3 页 resident window，不把全部消息常驻内存。
4. 到顶按钮优先走真实历史边界逻辑，不再退化成单纯滚动动画。

## 根因

### 1. 页面层有 builder，但数据层不是按页 resident

`session_screen_view_messages.dart` 已经按单条消息做了 builder 渲染，但 `SessionMessages.messages` 仍是完整 resident window 列表，且每次窗口变更仍会整体替换或整体结构化。

### 2. archive 翻页是“整窗平移”

此前 `shiftSessionMessageArchiveWindowOlder/Newer()` 的行为是：

- 计算一个新的 `targetStartIndex`
- 直接读取一个完整 `residentWindowSize`
- 用新窗口替换旧窗口

这更像“跳窗”，不是真正的“邻页追加 + 保留附近消息”。

### 3. 详情页入口默认恢复窗口过大

本地 snapshot 和默认自动窗口之前都偏大，会让首次进入详情页时解码、结构化和绘制压力集中在首屏。

## 修复

### 1. resident window 大小收缩

调整默认窗口策略：

- 自动最新窗口：`160`
- resident 最大窗口：`480`
- archive 邻页大小：`160`

这样 resident window 默认最多常驻 3 页。

### 2. repository 新增前插/后追加窗口能力

新增：

- `prependMessageWindow()`
- `appendMessageWindow()`

语义为：

- 从顶部补历史时，把更早页插到前面，必要时裁掉尾部
- 从底部补较新页时，把较新页追加到后面，必要时裁掉头部

这样 resident window 会围绕用户当前位置滑动，而不是整窗替换。

### 3. archive 邻页加载改成页级追加

`shiftSessionMessageArchiveWindowOlder/Newer()` 改成：

- 只读取相邻一页 archive
- 调用 repository 的 prepend/append resident window
- 不再每次整窗重建

### 4. 详情页进入时优先恢复本地最新 archive 页

当：

- 本地没有 snapshot
- 但 archive 已完整

则优先从本地 archive 恢复最新一页 resident window，而不是直接走远端消息加载。

### 5. 详情页区分“本地可访问历史”和“完整归档历史”

新增两个层次的判断：

- 本地相邻页是否可直接读取
- 全量历史是否已完整归档

顶部预取和边界加载会先使用本地邻页；只有本地确实接不上时，才会继续等待 archive hydration。

## 经验约束

1. “列表虚拟渲染”不能只看 widget builder，还要看 resident 数据窗口是否按页管理。
2. 聊天记录浏览应优先实现“邻页追加 + 另一侧裁剪”，而不是“整窗平移替换”。
3. 聊天页首屏 resident window 应尽量小，后续靠预取扩展，而不是一开始把大窗口全部解码进内存。
4. 本地 archive 是否完整，与当前窗口周围是否已有可访问邻页，是两个不同维度，不能混用一个布尔值。
