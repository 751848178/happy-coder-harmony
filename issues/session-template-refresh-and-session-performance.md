# 模板刷新、会话列表卡顿与首条消息延迟问题记录

## 背景

本次排查覆盖了 4 个用户可见问题：

1. 设置页新增模板后，模板列表没有更新。
2. 会话列表页和规划消息列表滚动、展开时有卡顿。
3. 活动消息刚开始返回时也会出现卡顿。
4. 第一次发送消息后，经常等待较久才一次性返回大量消息。

## 根因定位

### 1. 模板新增后列表不更新

- 文件：`lib/features/session/data/session_input_template_service.dart`
- 根因：`loadTemplates()` 返回的是固定长度列表，`upsertTemplate()` / `deleteTemplate()` 又直接对返回值执行 `add` / `removeWhere`。
- 结果：新增或删除模板时会在运行时抛出 `Unsupported operation`，设置页中的 `setState()` 根本没有机会执行，所以看起来像“列表没刷新”。

### 2. 会话列表页卡顿

- 文件：`lib/features/session/screens/sessions_screen_content.dart`
- 根因：每次列表重建都会重新为所有会话计算 `SessionStats`，而 `SessionStatsCalculator` 会扫描消息、diff 和 metadata。
- 文件：`lib/features/session/data/session_repository_sessions.dart`
- 根因：`applySessions()` / `applyMachines()` 用 `jsonEncode(existing.toJson()) == jsonEncode(next.toJson())` 做深比较，活跃态更新频繁时会持续触发大对象序列化。
- 结果：会话活跃状态、thinking 状态或预热消息加载发生时，列表页容易出现主线程抖动。

### 3. 规划消息列表和活动消息初始阶段卡顿

- 文件：`lib/features/session/screens/session_screen_view_messages.dart`
- 根因：展开态消息列表使用 `ListView(children: [...])`，每次重建都会一次性构造整棵消息树。
- 文件：`lib/features/session/screens/session_screen_state_build.dart`
- 根因：每次 build 都重新执行 turn grouping。
- 文件：`lib/features/session/screens/session_screen_message_bubble.dart`
- 根因：消息气泡在 `didUpdateWidget` 中使用 `jsonEncode(message.toJson())` 判断内容是否变化。
- 文件：`lib/features/session/screens/session_screen_markdown_message.dart`
- 根因：Markdown 块在每次 rebuild 时重复解析。
- 结果：规划消息、长消息、工具消息较多时，首次活动输出和滚动过程都容易卡顿。

### 4. 第一次发送消息后长时间无增量更新

- 文件：`lib/features/session/domain/session_service_message_send.dart`
- 根因：发送逻辑原先会先等待 POST `/sessions/:id/messages` 完成，再触发 `loadSessionMessages()`。如果后端在请求生命周期内持续产出消息，前端就只能在请求结束后一次性拉到整批消息。
- 结果：用户会感知到“发送后沉默很久，然后一下子回来很多消息”。

## 本次修复

- 模板服务改为在写入前使用可变列表，保证新增、编辑、删除都能正常落库并触发界面更新。
- 会话列表增加 stats 缓存，避免无关状态变化时重复扫描消息和 diff。
- 仓库层去掉基于 `jsonEncode` 的深比较，改为结构比较，降低高频活跃更新的序列化成本。
- 消息页对 turn groups 做缓存，展开态列表改成 `ListView.builder`，避免每次重建都全量创建所有消息节点。
- 消息气泡去掉 `jsonEncode` 级别的内容对比，Markdown 内容改为按 widget 生命周期缓存解析结果。
- 发送消息时，在 POST 请求未完成前启动短周期增量拉取，确保服务端一旦开始写入消息，前端可以尽快拿到。

## 后续开发约束

- 不要对来自存储层的 `growable: false` 列表直接执行增删操作；如需修改，先复制成可变列表。
- 避免在热路径里使用 `jsonEncode(...toJson())` 作为对象相等判断，尤其是列表、消息、会话和 socket 高频更新路径。
- 长列表默认优先使用 `ListView.builder` / `SliverList`，只有在条目数很少且确定稳定时才使用 `children: []`。
- 对 markdown 解析、diff 统计、turn grouping 这类 O(n) 或正则密集逻辑，要优先考虑缓存和增量更新。
- 发送消息后如果服务端处理是异步的，前端不能把“首次刷新”绑定在发送请求完成之后。
