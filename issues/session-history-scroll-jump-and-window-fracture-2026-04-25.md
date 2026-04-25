# 会话历史上翻跳动与窗口断裂问题

**日期**: 2026-04-25
**严重级别**: P0 Critical
**状态**: 已修复

## 现象

在会话详情页上翻历史消息时，列表会出现两类严重异常：

1. 上翻过程中消息列表突然跳动。
2. 中间历史窗口被打断，视觉上只剩“最旧一批”和“最新一批”消息，中间连续区间消失。

## 审查范围

- `lib/features/session/screens/session_detail/view/message_scroll.dart`
- `lib/features/session/domain/session_service/message_coordinator.dart`
- `lib/features/session/domain/session_service/message_send.dart`
- 关联链路：
  - `state/socket.dart`
  - `state/refresh_session_sync.dart`
  - `state/tool_actions.dart`
  - `domain/session_service/rpc.dart`

## 已确认根因

### 根因 1：滚动 standby 在内容尺寸未稳定时被过早消耗

`_ChatScrollPosition.applyContentDimensions()` 之前只要求：

- `max >= standbyMax`
- `delta.abs() > 0.5`

就会直接消费 standby。

但 Flutter 在一次 layout 内可能多次调用 `applyContentDimensions()`，
前几次的 `maxScrollExtent` 仍是粗略值。如果在这一步就提前 `forcePixels()`，
视口会被校正到错误位置，随后再触发顶部/底部自动续页，就会表现成列表跳动，
严重时还会把 resident window 推到错误的窗口状态。

### 根因 2：详情页刷新链路把已扩大的 resident window 错缩回默认 160 条

会话详情里的多条刷新路径都固定使用：

- `SessionServiceNotifier.sessionDetailAutomaticMessageWindowSize`

也就是默认 160 条窗口。

但用户上翻历史后，resident window 可能已经扩到 320 / 480 条。
这时如果 socket refresh、发送过程轮询、刷新按钮、工具操作回刷等链路再次调用
`loadSessionMessages(... messageWindowSize: 160)`，当前窗口会被直接缩回去。

这会导致：

1. 视口锚点瞬间失效，列表出现跳动。
2. 当前正在浏览的连续历史区间被截断，看起来像“中间消息丢了”。

### 根因 3：浏览旧历史时发送消息，会把“旧窗口 + 最新 optimistic 消息”拼成断裂窗口

`message_send.dart` 之前无论当前窗口是不是历史窗口，都会直接：

- `_repository.applyMessages(...)` 插入 optimistic 用户消息

如果用户正在浏览一个 `hasNewerMessages == true` 的旧历史窗口，
这条 optimistic 消息会落到当前 resident window 末尾，于是同一个列表里同时出现：

- 较旧历史片段
- 最新刚发送的一条 optimistic 消息

中间连续区间并不存在，于是视觉上就会变成“只剩最旧和最新两批消息”。

## 修复方案

### 修复 1：standby 必须等 `maxScrollExtent` 稳定后再消费

在 `_ChatScrollController` 增加：

- `_standbyLastObservedMaxScrollExtent`

并在 `applyContentDimensions()` 中要求：

- 当前 `max >= standbyMax`
- 且相邻两次观察到的 `max` 已稳定

才允许真正消费 standby。这样可以避免早期粗略布局把滚动位置校正错。

### 修复 2：增量刷新自动复用当前更大的 resident window

在 `message_coordinator.dart` 增加窗口尺寸收敛逻辑：

- 如果当前 session 已加载
- 且当前 loaded window 大于请求窗口
- 且用户正在浏览 partial/history window（`hasOlderMessages || hasNewerMessages`）

则刷新时自动复用当前更大的 resident window，不允许被 160 条默认窗口缩回去。

### 修复 3：浏览旧历史时不再把 optimistic 消息直接塞进历史窗口

在 `message_send.dart` 中：

- 如果当前窗口 `hasNewerMessages == true`
- 说明用户正在浏览旧历史

此时不再把 optimistic 消息直接插入当前 resident window。
发送成功后改为强制刷新最新窗口，配合详情页已有的“回到最新”逻辑，
避免把旧历史窗口拼成断裂的“两头消息”。

## 修改文件

- `lib/features/session/screens/session_detail/view/message_scroll.dart`
- `lib/features/session/domain/session_service/message_coordinator.dart`
- `lib/features/session/domain/session_service/message_send.dart`

## 后续开发约束

1. 任何会在滚动布局阶段消费一次性状态的逻辑，都必须确认布局尺寸已经稳定，不能依赖第一次 `applyContentDimensions()`。
2. 会话详情页一旦进入历史浏览状态，任何刷新链路都不能再用固定默认窗口覆盖当前 resident window。
3. optimistic 本地消息只能插入“最新窗口”语义的列表，不能直接拼接到 `hasNewerMessages == true` 的旧历史窗口里。
4. 详情页的“消息刷新”和“历史窗口管理”必须共享同一套窗口语义，不能一个按默认最新窗口，一个按 resident history window。
