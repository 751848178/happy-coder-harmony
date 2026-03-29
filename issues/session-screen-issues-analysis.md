# Session Screen 问题分析文档

> 本文档记录了会话页面相关的所有问题及其根本原因，为后续开发提供参考。
>
> 创建日期：2026-03-26

---

## 问题列表

### 1. PC连接后本地模型不更新

**问题描述**：当连接到 PC 后，新建会话时，模型选项列表不会显示 PC 端配置的实际模型，只显示硬编码的默认模型列表。

**根本原因**：`SocketIntegration` 类虽然存在，但从未被初始化。

**相关代码位置**：

| 文件 | 行号 | 问题 |
|------|------|------|
| `socket_integration.dart` | 38-47 | `_handleMessageReceived` 中 `_sessionService?.loadSessionMessages(socketMessage.sessionId!)` 永远不会执行，因为 `_sessionService` 始终为 `null` |
| `socket_integration.dart` | 整个文件 | 整个类从未被初始化（没有调用 `initialize()` 或 `setSessionService()`） |

**详细分析**：

1. `SocketIntegration` 类设计用于全局处理 socket 消息
2. 当服务器发送 `new-message` 事件时，应触发 `_handleMessageReceived`
3. `_handleMessageReceived` 会调用 `loadSessionMessages` 来加载新消息
4. 但由于 `_sessionService` 始终为 `null`，这个调用不会执行
5. 因此，PC 连接后的消息更新无法被处理

**解决方案**：
- 初始化 `SocketIntegration` 并设置 `SessionService`
- 或者在 Socket Repository 的 `new-message` 事件处理中直接调用 `loadSessionMessages`

---

### 2. AI 输出过程中点击折叠轮次，列表没有正确按照用户消息分组

**问题描述**：当 AI 正在输出过程中（非用户消息），用户点击"折叠所有轮次"，之后又有新消息到达时，列表没有正确按照用户消息分组。

**根本原因**：增量更新逻辑中，当用户消息到达时没有触发分组重建。

**相关代码位置**：

| 文件 | 行号 | 问题 |
|------|------|------|
| `session_screen_state_turns.dart` | 40-57 | `_appendTurnGroups` 方法在追加用户消息时没有检查是否应该新建分组 |
| `session_screen_state_turns.dart` | 48-50 | 只检查了 `groups.isEmpty` 和 `startsNewTurn(message)`，但增量追加时前几个消息可能不分组 |

**详细分析**：

1. `_resolveTurnGroups` 使用缓存机制，只有当消息引用变化或 `identical` 检查失败时才重新计算
2. `_canAppendTurnGroups` 检查前 N 个消息引用是否相同
3. `_appendTurnGroups` 中，只有当 `groups.isEmpty` 或 `startsNewTurn(message)` 时才新建分组
4. 当 AI 正在输出，用户点击折叠后，又有新 AI 消息到达时，`startsNewTurn` 返回 `false`，消息被追加到现有分组
5. 这导致用户消息没有正确触发分组重建

**解决方案**：
- 在 `_appendTurnGroups` 中增加检查，当检测到用户消息时，应该重建整个分组而非增量追加
- 或者在检测到用户消息到达时，调用 `_MessageTurnGroup.build(messages)` 而非增量追加

---

### 3. 进入会话列表后消息需要时间才能加载出来

**问题描述**：当会话有消息时，点击进入列表，列表消息需要一点时间才能加载出来。

**根本原因**：`_resolveSessionStatsMap` 方法在主线程上同步计算所有会话的统计数据，阻塞 UI 线程。

**相关代码位置**：

| 文件 | 行号 | 问题 |
|------|------|------|
| `sessions_screen_content.dart` | 62-95 | `_resolveSessionStatsMap` 遍历所有会话，同步计算统计 |
| `session_stats.dart` | 24-51 | `SessionStatsCalculator.fromSession` 在主线程上解析 Markdown 和 diff |
| `session_stats_summary.dart` | 63-98 | `_extractMessageChangeSummary` 遍历所有消息 |
| `session_stats_helpers.dart` | 3-32, 34-57 | `_extractPatchSummary` 和 `_extractReplacementSummary` 进行大量字符串操作 |
| `session_service_messages.dart` | 113-128 | `_warmSessionPreviewData` 只预加载前 3 个会话 |

**详细分析**：

1. 每次构建会话列表时，`_resolveSessionStatsMap` 被调用
2. `_resolveSessionStatsMap` 遍历所有会话，对每个会话调用 `SessionStatsCalculator.fromSession`
3. `fromSession` 调用 `_extractMessageChangeSummary(messages)`
4. `_extractMessageChangeSummary` 遍历所有消息，对每个消息调用：
   - `_extractPatchSummary(message.text)` - 解析 diff/patch
   - `_extractPatchSummary(tool.result)` - 解析工具结果
   - `_extractReplacementSummary(oldText, newText)` - 对比文本
5. `_extractPatchSummary` 使用 `split('\n')` 和 `RegExp.allMatches` 进行字符串操作
6. 这些操作都在主线程上执行，阻塞 UI
7. `_warmSessionPreviewData` 只预加载前 3 个会话，其他会话首次显示时需要同步计算

**解决方案**：
- 使用 `compute` 或 Isolate 将统计计算移到后台线程
- 增加 `_warmSessionPreviewData` 的预加载范围
- 缓存已计算的统计数据，避免重复计算
- 使用 `RegExp.cache` 缓存正则表达式

---

### 4. 消息数量增加后滑动列表卡顿

**问题描述**：当会话的消息数量增加后，滑动列表时变得卡顿。

**根本原因**：多个性能瓶颈叠加，导致主线程阻塞。

**相关代码位置**：

| 文件 | 行号 | 问题 |
|------|------|------|
| `session_screen_message_bubble.dart` | 42-48 | `didUpdateWidget` 每次都执行深度比较 |
| `session_screen_message_bubble.dart` | 95-119 | 4 次递归比较（`DeepCollectionEquality.equals`） |
| `session_screen_markdown_block.dart` | 20-115 | Markdown 解析使用循环和 RegExp |
| `session_screen_view_messages.dart` | 11, 32 | `GlobalKey` 导致整个 ListView 重建 |
| `session_screen_state_build.dart` | 4 | `ref.watch(sessionStateProvider)` 频繁触发 |
| `session_screen_content_detection.dart` | 3-15 | 正则表达式未使用缓存 |
| `session_screen_markdown_inline_parser.dart` | 4-6 | 内联解析使用正则表达式 |

**详细分析**：

1. **深度比较问题**：
   - 每条消息更新都执行 `didUpdateWidget`
   - `_shouldResetCollapsedState` 执行 4 次 `DeepCollectionEquality.equals`
   - 每次比较都进行递归的 Map 深度比较和 JSON 序列化
   - 这些深度比较在主线程上执行

2. **Markdown 解析问题**：
   - 每次构建消息气泡都调用 `_MarkdownBlock.parse(content)`
   - `parse` 方法使用 `replaceAll('\r\n', '\n')` 和 `split('\n')` 分割所有行
   - 使用 `RegExp.firstMatch` 在循环中匹配每一行
   - 这些操作在主线程上执行

3. **GlobalKey 问题**：
   - `_messageListViewportKey` 是 `GlobalKey`
   - 每次状态变化都导致整个 ListView 重新创建
   - 避免不了 Flutter 的 Element 重建机制

4. **频繁重建问题**：
   - `ref.watch(sessionStateProvider)` 监听所有 sessionStateProvider 变化
   - 每次消息更新都触发整个 `_SessionScreenSelection` 重建

5. **正则表达式未缓存**：
   - `_extractPatchSummary` 等方法中的正则表达式没有使用 `RegExp.cache`
   - 每次调用都重新编译正则表达式

**解决方案**：
- 减少深度比较的次数，使用简单的 `==` 比较
- 缓存 Markdown 解析结果
- 使用 `RegExp.cache` 缓存正则表达式
- 将 `GlobalKey` 改为 `ValueKey` 或使用 `ListView.separated` 替代嵌套
- 使用 `RepaintBoundary` 限制重绘范围
- 使用 `addAutomaticKeepAlives` 缓存 Widget

---

### 5. 折叠轮次时白屏

**问题描述**：点击"折叠所有轮次"时，闪一下折叠后的分组然后就白屏了。

**根本原因**：`_messageListViewportKey` 使用 `GlobalKey`，当 `_collapseAllTurns` 状态变化触发 `build()` 时，ListView 被重新创建，重建期间短暂白屏。

**相关代码位置**：

| 文件 | 行号 | 问题 |
|------|------|------|
| `session_screen.dart` | 150 | `_messageListViewportKey = GlobalKey()` |
| `session_screen_view_messages.dart` | 11, 32 | `ListView.builder(key: _messageListViewportKey, ...)` |
| `session_screen_state_turns.dart` | 59-72 | `_toggleAllTurns` 触发 rebuild 和滚动 |
| `session_screen_state_build.dart` | 75 | `_visibleTurnGroups = turnGroups` 每次 build 都设置 |

**详细分析**：

**问题触发链**：
```
点击折叠/展开轮次
  ↓
_toggleAllTurns() 被调用
  ↓
setState(() { _collapseAllTurns = ...; _expandedTurnIds.clear(); ... })
  ↓
build() 被重新执行
  ↓
_visibleTurnGroups = turnGroups
  ↓
_scheduleScrollToLatest(force: true)
  ↓
_scrollController.jumpTo/animateTo()
  ↓
ListView.builder(key: _messageListViewportKey, ...)
  ↓
⚠️ GlobalKey 变化，ListView 重新创建
  ↓
⚠️ 重建期间短暂白屏
```

**解决方案**：
- 将 `_messageListViewportKey` 从 `GlobalKey` 改为 `ValueKey` 或移除
- 使用 `const ValueKey('message-list')` 而非 `GlobalKey`
- 或者移除 key 参数，让 Flutter 自己管理 Element 复用

---

### 6. 会话页面整体卡顿

**问题描述**：会话页面在各种操作时都存在卡顿现象。

**根本原因**：多个性能问题叠加，包括深度比较、Markdown 解析、ListView 重建、频繁的 rebuild 等。

**性能瓶颈汇总**：

| # | 问题 | 严重程度 | 影响 |
|---|------|---------|------|
| 1 | 深度比较（4 次/消息） | ⭐⭐⭐⭐⭐ | 每条消息更新都执行 |
| 2 | Markdown 解析（每条消息） | ⭐⭐⭐⭐ | 每次构建都执行 |
| 3 | GlobalKey 导致 ListView 重建 | ⭐⭐⭐⭐ | 整个 ListView 重新创建 |
| 4 | KeyedSubtree 保持大量 Widget | ⭐⭐⭐ | 未折叠消息占用内存 |
| 5 | 工具调用复杂解析 | ⭐⭐⭐ | 多个字符串操作和长度计算 |
| 6 | ref.watch(sessionStateProvider) 频繁触发 | ⭐⭐⭐ | 整个选择重建 |
| 7 | 正则表达式未缓存 | ⭐⭐ | 每次都重新编译 |

## 2026-03-27 四次补充

### 7. 后台持续更新开关已经实现，但主设置页没有入口

**实际根因**：

- `lib/features/settings/screens/features_settings_screen.dart` 已经有“后台持续更新消息”开关。
- 但 `lib/app/routes/app_router_settings_routes.dart` 没有注册 `/settings/features` 路由。
- `lib/features/settings/screens/settings_screen_feature_group.dart` 也没有任何入口跳到功能设置页。

**修复**：

- 补上 `settingsFeatures` 路由。
- 在设置页“会话”分组增加“功能设置”入口，把后台持续更新、实验功能和交互偏好真正暴露给用户。

### 8. 会话页顶部按钮和底部控制条职责冲突

**实际根因**：

- `lib/features/session/screens/session_screen_state_appbar.dart` 同时放了“会话详情”和“折叠轮次”按钮。
- `lib/features/session/screens/session_screen_view_controls.dart` 底部控制条里又放了一套“刷新/折叠轮次/模型/权限”。
- 结果是同一类动作在两个位置重复出现，且顶部“折叠轮次”和底部控制条的反馈不一致。

**修复**：

- 顶部移除“会话详情”快捷图标，保留更多操作里的“会话详情”。
- 顶部移除“折叠轮次”按钮。
- 把“刷新”移到右上角，底部控制条只保留连接状态、权限、模型和轮次折叠。

### 9. 右侧悬浮轨道缺少“思考状态兜底”交互

**实际根因**：

- 当前会话是否忙碌依赖 `session.thinking`、工具状态和消息推断。
- 一旦上游事件缺失或消息链不完整，发送按钮可能一直认为 AI 仍在思考。
- 页面上此前没有任何“人工订正当前状态”的兜底入口。

**修复**：

- 在右侧可收起的滚动轨道中增加“AI 思考状态”按钮，和“到顶/到底”放在一起。
- 点击后提供三个动作：标记为思考中、标记为已结束、恢复自动判断。
- 手动标记为“已结束”时会同步清掉本地 `activeResponseLocalId`，确保能继续发送。

### 10. AI 思考状态来回跳的一条真实根因是上游 `event` 消息被直接丢弃

**实际根因**：

- `lib/features/session/domain/session_service_message_parser.dart` 之前只处理 `output / codex / acp / session`，直接忽略了 `agent.content.type == 'event'`。
- 上游 PC `packages/happy-app/sources/sync/typesRaw.ts` 会把这类消息归一化成 `ready / message / switch / limit-reached` 等事件，并交给 reducer 参与忙闲状态判断。
- Flutter 端把这类事件丢掉后，`ready` 无法解除阻塞，`switch/message` 也无法反映到 UI，容易出现“思考态来回跳”或“忙碌状态一直不消失”。

**修复**：

- 新增 `session_service_event_message_reducer.dart`，把 `agent event` 消息纳入归一化链。
- `ready` 事件现在会参与 completion signal 判断，不再被直接丢弃。
- 会话协议里的 `service` 事件改为按可见文本处理，和 PC 的可见内容对齐。

### 11. 会话列表仍然会被整页级消息更新拖着重建

**实际根因**：

- `lib/features/session/screens/sessions_screen_content.dart` 之前直接 `watch(sessionStateProvider)`，任何消息变化都会让整个列表页重建。
- `lib/features/chat/components/session_list.dart` 也会因为整棵 `sessionState` 变化而整体刷新。

**修复**：

- 会话列表页和聊天侧边栏都改为按“会话集合/顺序”进行选择订阅，不再盯整棵状态树。
- 单个会话项自身再去订阅自己的消息和思考状态，实现“父级定顺序，子项定内容”的原子更新。

### 12. 会话消息数不真实有两条底层根因

**实际根因 A：已加载消息数没有压过旧持久化计数**

- `lib/features/session/domain/session_local_snapshot.dart` 之前会在“已加载消息数”和“持久化计数”之间取更大值。
- 一旦本地旧快照比当前真实消息数更大，就会出现“列表里明明只有 104 条，角标却还显示 149 条”的错觉。

**修复 A**：

- 现在只要消息已经加载，就直接使用 `loadedMessageCount` 作为展示值；只有未加载时才回退到持久化计数。

**实际根因 B：`LatestUsage.fromJson()` 会把 token 数误读成消息数**

- 文件：`lib/features/session/domain/session_model_presence.dart`
- 上游 PC 的 `latestUsage` 本来没有 `messageCount` 字段。
- Flutter 端此前在没有 `messageCount` 时会把 `outputTokens` 回填进 `messageCount`，导致消息数可能直接跳成 token 数。

**修复 B**：

- `LatestUsage.fromJson()` 现在只接受真正的 `messageCount / message_count` 字段，不再把 `outputTokens` 当消息数。

### 13. `output.type == user` 的结构化内容此前被错误当成用户消息

**实际根因**：

- `lib/features/session/domain/session_service_output_message_reducer.dart` 之前会把 `output.type == user` 的所有结构化内容都按 `role=user` 处理。
- 上游 PC 在这类消息包含工具结果时，会把它当作 agent 结果来归一化。

**修复**：

- 纯字符串内容仍按用户文本处理。
- 工具结果等结构化内容改为按 agent 内容归一化，只保留 `sourceRole=user` 作为来源标记，避免分组和可见消息内容继续跑偏。

### 14. “移动到分组”弹层黄黑条的真实原因是底部弹层高度溢出

**实际根因**：

- `lib/features/session/screens/sessions_screen_session_move_sheet.dart` 使用 `Column(mainAxisSize: min)` 直接堆所有分组项。
- 分组较多时底部弹层超过可用高度，就会出现 Flutter 的黄黑溢出警告条。

**修复**：

- 改为 `isScrollControlled + ConstrainedBox + SingleChildScrollView`，让弹层在高分组数下滚动显示，不再溢出。

### 15. 分组标签和目录标签换行、且自定义分组里重复展示当前分组

**实际根因**：

- `lib/features/session/screens/sessions_screen_list_item_content.dart` 之前用 `Wrap` 渲染分组标签和目录标签，容易掉到两行。
- `lib/features/session/screens/sessions_screen_custom_group_list.dart` 在“自定义分组视图”里还继续把当前分组名作为 badge 传给 item，造成“标题里已经有分组名，卡片里再重复一次”。

**修复**：

- 标签行改成单行优先布局，badge 文本支持省略，不再优先换行。
- 自定义分组和过期分组列表里不再展示当前分组 badge，只保留目录标签。

### 16. 会话标签改成单行后被拉伸成整行宽度

**实际根因**：

- 文件：`lib/features/session/screens/sessions_screen_list_item_badges.dart`
- 为了让分组标签和目录标签尽量保持单行，之前把 badge 容器从 `Wrap` 链路改到了 `Row + Flexible`。
- 但 `_SessionBadge` 内部的 `Row` 仍然保持 `mainAxisSize.max`，在 `Flexible(loose)` 约束下会吃满可用宽度，结果视觉上就是“标签自己占了一整行”。

**本次修复**：

- `_SessionBadge` 内部改为 `mainAxisSize.min`，让 badge 宽度按实际内容收缩，而不是跟着父级可用宽度被拉满。
- 保留文本省略能力，这样短标签按内容宽度显示，长标签仍能在受限宽度下被截断，而不会重新撑回整行。

### 新增约束

- 只要上游已经把某类消息定义成 reducer/event 语义，Flutter 端不能在 parser 层直接丢掉。
- 消息已加载后，任何“展示用消息数”都必须以已加载消息为准，不能继续拿历史缓存做放大。
- 列表页的父级只负责顺序和分组；单项内容订阅必须下沉到 item，避免消息变更触发整页刷新。
| 8 | ListView 缺少优化配置 | ⭐⭐ | 无法预测 item 高度 |
| 9 | 消息气泡多重嵌套 | ⭐⭐ | 增加布局和渲染开销 |

**详细代码分析**：

```dart
// 1. 深度比较问题 - session_screen_message_bubble.dart:95-119
 bool _shouldResetCollapsedState(ReducerMessage previous, ReducerMessage next) {
  return previous.id != next.id ||
      previous.kind != next.kind ||
      previous.createdAt != next.createdAt ||
      previous.text != next.text ||
      !_SessionScreenState._deepCollectionEquality.equals(  // ⚠️ 递归比较 Map
        previous.metadata, next.metadata,
      ) ||
      !_SessionScreenState._deepCollectionEquality.equals(  // ⚠️ 递归比较 JSON
        previous.tool?.toJson(), next.tool?.toJson(),
      ) ||
      !_SessionScreenState._deepCollectionEquality.equals(  // ⚠️ 递归比较 JSON
        previous.permission?.toJson(), next.permission?.toJson(),
      ) ||
      !_SessionScreenState._deepCollectionEquality.equals(  // ⚠️ 递归比较 JSON
        previous.turnClose?.toJson(), next.turnClose?.toJson(),
      );
}

// 2. Markdown 解析问题 - session_screen_markdown_block.dart:20-115
static List<_MarkdownBlock> parse(String input) {
  final normalized = input.replaceAll('\r\n', '\n');  // ⚠️ 字符串替换
  final lines = normalized.split('\n');  // ⚠️ 分割所有行
  final blocks = <_MarkdownBlock>[];
  var index = 0;
  while (index < lines.length) {  // ⚠️ 循环遍历所有行
    final line = lines[index];
    final fence = RegExp(r'^\s*```([^\n`]*)\s*$').firstMatch(line);  // ⚠️ RegExp 匹配
    ...
  }
  ...
}

// 3. GlobalKey 问题 - session_screen.dart:150, session_screen_view_messages.dart:32
final GlobalKey _messageListViewportKey = GlobalKey();
return ListView.builder(
  key: _messageListViewportKey,  // ⚠️ GlobalKey 变化导致重建
  controller: _scrollController,
  ...
);
```

**解决方案**：

1. **减少深度比较**：
   - 使用简单的 `==` 比较替代 `DeepCollectionEquality.equals`
   - 只在必要时进行深度比较

2. **缓存 Markdown 解析结果**：
   - 对相同内容返回缓存的 `_blocks`

3. **移除 GlobalKey**：
   - 使用 `const ValueKey('message-list')` 而非 `GlobalKey`
   - 或移除 key 参数

4. **缓存正则表达式**：
   - 使用 `static const pattern = RegExp(...)` 创建编译好的正则表达式

5. **添加 ListView 优化配置**：
   - 使用 `addAutomaticKeepAlives`
   - 使用 `cacheExtent` 和 `itemExtent`

6. **使用 RepaintBoundary**：
   - 将 `_MessageBubble` 等组件包裹在 `RepaintBoundary` 中

7. **预计算可折叠状态**：
   - 在构建前确定是否需要折叠

---

## 2026-03-26 三次补充

### 7. 新建会话页的模型列表仍然和 PC 不一致

**问题描述**：虽然当前会话的模型显示优先级已经修正，但“新建会话”底部设置里的可选模型列表仍然和 PC 不一致。

**真实根因**：

- 文件：`lib/features/session/screens/new_session_flow_screen_logic.dart`
- 文件：`lib/features/session/domain/session_creation_options_modes.dart`
- 根因：移动端此前仍然用 `resolveModeMetadataForSessions(...) / resolveModeMetadataForMachines(...)` 动态生成新建会话的可选模型和权限模式。
- 但 PC 新建会话入口 `packages/happy-app/sources/app/(app)/new/index.tsx` 调用的是 `getAvailableModels(agentType, null, t)` 与 `getAvailablePermissionModes(agentType, null, t)`，也就是新建页根本不拿 session/machine metadata 来改写选项列表。
- 结果：移动端在某些机器上会看到被 metadata 覆盖过的列表，PC 却还是固定 fallback 列表，导致“可选项”本身就不一致。

**本次修复**：

- 新建会话页新增专用的 `newSessionPermissionOptionsForAgent(...)` / `newSessionModelOptionsForAgent(...)`。
- `_sessionFlowPermissionOptions(...)` 与 `_sessionFlowModelOptions(...)` 改为只按当前 agent 返回固定 fallback 列表，不再读取 session/machine metadata。
- metadata 解析能力保留给“当前会话状态恢复”和“未知 key 展示”场景，不再混入新建会话的选项来源。

### 8. 会话消息数会来回跳

**问题描述**：列表里的消息数在后台刷新、进入会话、返回列表等时机会在不同数字之间跳动。

**真实根因**：

- 文件：`lib/features/session/data/session_repository_messages.dart`
- 文件：`lib/features/session/data/session_repository_models.dart`
- 文件：`lib/features/session/domain/session_local_snapshot.dart`
- 根因：列表显示逻辑已经统一成“优先展示已加载消息数，否则回退持久化统计”，但仓库在 `applyMessages(...) / replaceMessages(...) / clearSessionMessages(...) / removeMessage(...)` 时只更新了 `SessionMessages`，没有把新的消息数同步写回所属 `Session.latestUsage.messageCount`。
- 结果：UI 一边拿到 `sessionMessages.length`，一边又保留着旧的 `session.latestUsage.messageCount`，刷新顺序不同就会出现数字来回切换。

**本次修复**：

- 在消息仓库层新增 `_syncSessionLatestUsageWithLoadedCount(...)`。
- 所有会改动消息集合的方法在更新 `SessionMessages` 后，都会把最新 `loadedMessageCount` 回写到 `Session.latestUsage`。
- 这样列表、缓存快照和后续远端 session 解析都围绕同一套消息数来源工作，不再在“旧快照”和“新消息数组”之间来回摇摆。

### 9. 后台持续更新消息需要用户可控，并且必须说明锁屏边界

**问题描述**：用户需要自己决定是否在后台持续刷新消息，并希望锁屏后也尽可能继续获取。

**真实根因**：

- 文件：`lib/app/services/settings_service.dart`
- 文件：`lib/app/widgets/session_background_refresh_gate.dart`
- 文件：`lib/features/settings/screens/features_settings_screen.dart`
- 之前应用没有独立的后台刷新开关，也没有应用级生命周期协调器去在后台定时刷新远端会话和消息。
- 同时当前工程的 OHOS 工程只有 `EntryAbility`，`ohos/entry/src/main/module.json5` 中没有 `ExtensionAbility` 或 `WorkSchedulerExtensionAbility`；而 HarmonyOS Stage 官方文档明确说明“应用程序不能随意驻留在后台”，普通应用需要依赖特定 `ExtensionAbility` 派生类处理受支持的后台场景。

**本次修复**：

- 新增设置项 `enableBackgroundSessionRefresh`，允许用户显式开启/关闭后台持续刷新。
- 新增应用级 `SessionBackgroundRefreshGate`：
- 前台恢复时立即强制刷新会话与消息，并在必要时补拉 socket。
- 应用进入后台后，如果用户开启了开关，则按固定间隔尽力刷新远端会话与消息。
- 设置页直接展示锁屏边界说明，避免把“系统可能回收后台进程”的能力误写成“保证锁屏常驻”。

**技术边界说明**：

- 官方文档：`https://developer.huawei.com/consumer/cn/arkui/arkui-stage/`
- 其中明确写到：Stage 模型下“应用程序不能随意驻留在后台”，普通应用不能自定义长期后台服务，只能依赖特定场景的 `ExtensionAbility`。
- 因此当前实现是“进程仍存活时的尽力后台刷新 + 恢复前台后的立即补刷”，不是“锁屏后无限期常驻拉消息”。

### 新增约束

- 新建会话页的“可选项”必须单独对齐 PC 入口，不要和当前会话 metadata 恢复逻辑复用同一条动态链路。
- 只要消息数组发生变化，就必须同步更新 `Session.latestUsage.messageCount`，否则任何列表层缓存都会重新出现跳数问题。
- 后台刷新必须由用户显式开启，并且在 UI 和文档中同步写明 HarmonyOS 普通 UIAbility 的后台运行边界。
- 行内 badge 如果要“按内容宽度撑开”，除了父级布局要避免强制扩展，badge 自身的内部 `Row/Flex` 也必须显式使用 `mainAxisSize.min`，否则仍会被松约束拉满。

## 总结

| 问题 | 根本原因 | 优先级 |
|------|---------|-------|
| PC连接后模型不更新 | SocketIntegration 未被初始化 | P0 |
| AI输出中点击折叠轮次分组错误 | 增量更新未处理用户消息 | P0 |
| 会话列表加载延迟 | 同步计算统计数据阻塞 UI | P0 |
| 消息多时滑动卡顿 | 多个性能瓶颈叠加 | P0 |
| 折叠轮次时白屏 | GlobalKey 导致 ListView 重建 | P1 |
| 会话中断后思考状态无法清除 | 会话思考状态超时机制缺失 | P1 |
| 会话中断后思考状态无法清除 | 会话思考状态超时机制缺失 | P1 |

---

## 开发注意事项

1. 避免在主线程上执行耗时操作（如 JSON 序列化、字符串分割、正则匹配等）
2. 避免使用 `GlobalKey` 除非必要
3. 避免频繁的深度比较
4. 缓存计算结果避免重复计算
5. 使用 `compute` 或 Isolate 将耗时操作移到后台线程
6. 使用 `RepaintBoundary` 限制重绘范围

---

## 修复复盘（基于实际代码）

> 下面这部分是本次修复后确认过的“真实根因”和“实际落地方式”。  
> 旧分析里有一些推断能解释现象，但并不是最终导致问题的代码路径，后续排查请以这里为准。

### 1. PC 连接后模型列表不更新

**最终根因**：

- 新建会话页的模型/权限选项一直直接调用 `modelOptionsForAgent()` / `permissionOptionsForAgent()` 的 fallback 列表。
- 页面没有优先读取已加载远端会话中的 `metadata.models` / `metadata.operatingModes`。
- 如果页面是在 socket 已经连好之后才打开，`initState()` 里只会调用非强制版 `loadSessions()`，命中 2 秒缓存窗口时会直接跳过远端刷新；这时页面既拿不到最新 session metadata，也不会再收到一次新的 `connected` 事件来补刷。
- 同时模式来源之前只看 session metadata，不会回退读取 machine metadata 里的模式信息；没有历史 session 的机器更容易直接退回硬编码选项。

**本次修复**：

- 在 `session_creation_options_modes.dart` 新增 `resolveModeMetadataForSessions(...)`，按“机器 + Agent + 最新会话”的优先级提取真实模式元数据。
- 新增 `resolveModeMetadataForMachines(...)`，当 session 侧没有可用模式信息时，继续回退读取 machine metadata。
- 新建会话流的初始化、Agent 切换、机器切换、设置面板和页面构建全部改为优先使用远端 metadata 里的 `models` / `operatingModes`。
- 新建会话页进入时改成主动强制刷新 sessions/machines；socket 连接成功或重连时也继续轻量刷新，让“先连上机器、后打开页面”和“页面已打开、再重连”两条路径都能更新。

**后续约束**：

- 新建会话页不能直接只看硬编码 fallback；只要本地已经有远端 session metadata，就必须优先使用远端模式列表。
- 页面上凡是“模式选项”相关 UI，都必须共用同一套模式来源解析逻辑，不能一处读 metadata，一处读 fallback。

### 2. 折叠轮次时分组错误

**最终根因**：

- 问题不在 `_appendTurnGroups()` 自身，而在“哪些消息被识别为用户消息”。
- `session_service_output_message_reducer.dart` 里 `output.type == user` 的消息以前被标成了 `role=agent`。
- `session_service_session_message_reducer.dart` 里 session envelope 的 `role=user + ev.t=text` 以前也被强行归成了 agent。
- 会话页的分组、忙闲状态判断、消息气泡样式都直接依赖 `metadata.role == user`，于是这类消息会被错误归进 AI 回复分组。

**本次修复**：

- 新增统一 helper：`sessionMessageIsUserAuthored(...)`。
- `output.type == user` 和 `session envelope role=user + text` 现在都会正确落成用户消息。
- 轮次分组、消息渲染、会话忙闲判断全部切到统一 helper，避免再次出现“解析和 UI 判断不一致”。

**后续约束**：

- 只要服务端语义上是用户消息，reducer 必须直接产出用户角色；不要只塞一个 `sourceRole=user` 再让 UI 猜。
- 分组、气泡样式、会话状态这些判断必须共享统一 helper，不能各写一套。

### 3. 进入会话列表后内容延迟出现

**最终根因**：

- 会话列表构建时同步遍历全部 session，并对每个 session 做消息级 diff/patch 统计。
- 这些字符串分割、逐行扫描、工具结果汇总都跑在主线程，导致列表首屏被阻塞。
- 同时预热消息快照只覆盖前 3 个会话，很多条目首次显示时还要现场拉消息。
- `loadSessions()` 之前还会等待 `loadMachines()` 完成后才发出第一次 `ready`，机器接口慢时会把会话列表首屏一起拖住。
- 聊天侧边栏的 `SessionsList` 也保留了一条独立的同步统计路径：每个 item 都会在 build 里调用 `SessionStatsCalculator.fromSession(...)`，但实际只用到了消息数量。

**本次修复**：

- 会话列表改成两阶段统计：
  - 首屏先用轻量 preview stats 立刻渲染；
  - 完整消息级统计改到后台 isolate 里通过 `computeSessionStatsBatch(...)` 异步回填缓存。
- 解析完 session 后立即先发一次 `ready`，不再让机器接口阻塞首屏会话列表出现。
- 聊天侧边栏会话列表不再同步计算完整 stats，只直接读取 `sessionMessages.length` / `session.messages.length` 作为消息数。
- `_warmSessionPreviewData(...)` 预热范围从 3 提升到 8，并按批次并行拉取。

**后续约束**：

- 列表页 build 里不要做全量消息级重计算；这类工作默认要走缓存、批处理或 isolate。
- preview 数据的预热范围不要过小，否则列表滚动时仍会出现“边进边加载”的抖动感。

### 4. 折叠轮次时白屏

**问题描述**：点击"折叠所有轮次"时，闪一下折叠后的分组然后就白屏了。

**最终根因**：
- 问题不在 `_appendTurnGroups()` 自身，而在"哪些消息被识别为用户消息"。

**相关代码位置**：
| 文件 | 行号 | 问题 |
|------|------|------|
| `session_screen_state_turns.dart` | 40-57 | `_appendTurnGroups` 方法在追加用户消息时没有检查是否应该新建分组 |

### 4. 消息多时滑动卡顿

**最终根因**：

- `_MessageBubble.didUpdateWidget()` 以前会做多轮深比较，消息越多、更新越频繁，主线程负担越重。
- Markdown block 解析没有全局缓存，长消息在重建/回收后会重复解析。
- 内容识别相关正则表达式在高频路径里重复执行，没有复用结果。
- 另外会话页 sticky prompt 之前会在每次滚动后都扫描全部 turn group 的 render object，即使当前根本没有“用户消息 + 回复”这种 sticky 候选轮次。
- 工具消息的折叠签名虽然不再做深比较，但仍会把整段 arguments/result/error 拼成大字符串，高频更新时依然会产生额外开销。

**本次修复**：

- 折叠态重置判断改成轻量签名比较，不再对 metadata/tool/permission/turnClose 做递归深比较。
- `_MarkdownBlock.parse(...)` 增加全局缓存和预编译正则。
- 内容识别逻辑增加结果缓存与预编译正则。
- 单条消息气泡增加 `RepaintBoundary`，降低局部更新时的重绘扩散。
- sticky prompt 刷新改成只有存在候选轮次时才调度，并且只给“真的有回复锚点”的 turn section 挂定位 key，减少滚动过程里的 renderObject 扫描和 GlobalKey 数量。
- 工具折叠签名进一步收敛成长度/hash 摘要，不再在 `didUpdateWidget()` 里反复拼接整段长文本。

**后续约束**：

- 在消息列表的高频更新路径里，优先用轻量签名或稳定字段比较，避免递归深比较。
- Markdown / diff / 结构化内容识别只要可能重复命中，就应该缓存解析结果。

### 5. 折叠轮次时白屏

**最终根因**：

- 实际问题不是 `GlobalKey` 每次变化；当前 key 是稳定实例。
- 第一轮修复只补到了 `_toggleAllTurns()`，但折叠态里点击单个轮次卡片走的是 `_toggleTurnGroup()`，这条路径之前没有做 scroll offset 校正。
- 当某个已展开轮次在靠近底部的位置被收起时，列表总高度会瞬间缩短，旧的 `pixels` 仍可能停留在新的 `maxScrollExtent` 之外，viewport 会直接落到空白区域。
- 另外，消息列表之前还被 `messageViewportReady = messages.isEmpty || _hasScrolledToLatest` 直接控制显隐；而 `_hasScrolledToLatest` 又依赖异步滚动任务完成。只要折叠期间 scroll-to-latest 请求被打断或延后，整块消息区就会被 `Opacity(0)` 隐藏成白板。

**本次修复**：

- 消息列表启用 `RangeMaintainingScrollPhysics`，在内容高度变化时尽量维持有效滚动范围。
- `折叠全部/展开全部` 和 `折叠态里展开/收起单个轮次` 两条路径现在都会在布局变更后做一次滚动偏移 clamp，确保 offset 不会落在新的合法范围之外。
- 如果用户原本就在底部附近，单轮次切换和全量折叠都会继续 pin 到最新消息；否则只做合法性修正，不强行把视角拽走。
- 消息列表不再被 `_hasScrolledToLatest` 控制显隐，滚动任务只负责定位，不再决定”列表能不能显示”。
- `scrollToLatest` 增加调度去重，避免 build 抖动时重复排队多个滚动请求，减少”先闪一下再继续重排”的时序干扰。
- 引入比例滚动位置恢复机制：在折叠/展开前捕获当前滚动位置的比例，布局变更后按比例恢复，确保视口不会落在无效区域。

**后续约束**：

- 只要列表项支持”局部展开/收起”，就不能只修全局折叠按钮；所有会改变内容总高度的入口都要走同一套 scroll offset 修正逻辑。
- 视口显隐不能绑定到异步滚动完成状态；滚动失败最多影响定位，不能让消息区整体消失。
- 对”内容高度会骤变”的列表，优先先处理 scroll offset 合法性，再考虑自动滚动。
- 不要把所有白屏都归因为 `GlobalKey`；先确认是不是 viewport 落入了失效滚动区间，或者显隐状态被错误绑定到了异步流程。

---

### 6. 会话中断后思考状态无法清除，新消息无法发送

**问题描述**：一些会话因为某些原因（如网络断开、服务端异常、超时等）中断后，会话会一直处于”思考中”状态，导致新的消息无法发出。

**根本原因**：

- 当会话中断时，如果服务端没有发送明确的完成信号（`turn-close`、`stop`、`turn_aborted` 等），`session.thinking` 状态不会被清除
- `sessionTurnIsThinkingStillBlocking` 函数中，只要 `session?.thinking == true` 就直接返回 `true`，不会考虑会话是否可能已经中断
- `_activeResponseLocalId` 也依赖 `sessionActiveResponseHasCompleted` 返回 `true` 才会被清除
- 当用户尝试发送新消息时，`_isConversationBusy` 会调用 `sessionTurnIsThinkingStillBlocking`，返回 `true`，导致新消息只能加入待发送队列

**相关代码位置**：

| 文件 | 行号 | 问题 |
|------|------|------|
| `session_turn_status.dart` | 59-80 | `sessionTurnIsThinkingStillBlocking` 中 `session?.thinking == true` 直接返回 `true`，未考虑超时情况 |
| `session_screen_state_queue.dart` | 47-58 | `_reconcileQueuedMessageState` 只在 `sessionActiveResponseHasCompleted` 返回 `true` 时才清除 `_activeResponseLocalId` |

**问题触发链**：
```
用户发送消息
  ↓
设置 _activeResponseLocalId = localId
  ↓
服务端发送 session.thinking = true
  ↓
会话中断（网络断开、服务端异常等）
  ↓
服务端没有发送完成信号
  ↓
session.thinking 仍然为 true
  ↓
sessionTurnIsThinkingStillBlocking 返回 true
  ↓
_isConversationBusy 返回 true
  ↓
用户无法发送新消息
```

**本次修复**：

- 在 `session_turn_status.dart` 中新增 `_isThinkingTimedOut()` 函数，检查会话思考时间是否超过阈值（2 分钟）
- 在 `sessionTurnIsThinkingStillBlocking` 中，如果 `session?.thinking == true` 但已经超时，返回 `false`，不再阻塞新消息
- 在 `session_screen_state_queue.dart` 中新增 `_isResponseLocalIdTimedOut()` 函数，检查 activeResponseLocalId 对应的会话是否已超时
- 在 `_reconcileQueuedMessageState()` 中，如果检测到超时，直接清除 `_activeResponseLocalId`

**后续约束**：

- 只要会话思考状态可能因为服务端问题导致无法正常清除，就必须引入超时机制
- 超时阈值应该根据实际业务场景调整，避免误判正常的长响应
- 超时后清除状态应该是一个 fallback 机制，不能替代正常的完成信号处理

---

## 2026-03-26 补充复盘

> 这一轮是按最新代码重新逐条排查，下面这些才是当前 5 个问题的实际根因和落地修复。文档前面较早的部分结论里有些已经过时，后续请以本节为准。

### A. 消息列表仍然出现空白消息气泡

**实际根因**：

- 服务端消息里存在只包含空格、换行或空字符串的文本片段。
- `session_service_message_parser.dart`、`session_service_output_message_reducer.dart`、`session_service_session_message_reducer.dart`、`session_service_agent_message_reducer.dart`、`session_service_acp_message_reducer.dart`、`session_service_agent_content_reducer.dart` 之前会把这些空白文本照常还原成 `ReducerMessage(kind=text)`。
- 会话页气泡组件之前默认认为“只要是 text message 就渲染气泡”，因此会留下空白气泡。

**本次修复**：

- 在 reducer helper 层增加统一的 `_isBlankReducerText(...)` 判断。
- 所有文本消息入口在落成 `ReducerMessage` 之前都先过滤空白文本。
- `session_screen_message_bubble_content.dart` 额外加了 UI 兜底，文本为空白时直接返回 `SizedBox.shrink()`，避免未来别的解析链再漏进来。
- 错误消息也改成先 trim，再回退到明确文案，避免“空错误气泡”。

**后续约束**：

- 任何服务端文本还原逻辑都必须先做空白过滤，不能把“语义为空”的消息交给 UI 再判断。
- UI 组件仍应保留一次轻量兜底，保证单条异常数据不会污染整个消息列表。

### B. 模型仍然和 PC 不对齐

**实际根因**：

- 远端 session 解析时，Flutter 端仍可能把本地旧偏好重新覆盖到远端会话模式上，和 PC 的“远端默认值优先、本地当前值单独维护”规则不一致。
- 新建会话页之前还会把 PC 已经在用、但当前选项列表里暂时不存在的 mode key 强行纠正回 fallback，导致界面显示和真实值再次分叉。

**本次修复**：

- `session_service_session_parsing.dart` 改成远端会话只按 `metadata.current...Code -> explicit session field` 解析，不再把本地旧 preference 倒灌回去。
- `session_creation_options_modes.dart` 的 `resolveModeSelection(...)` 改为保留未知但有效的当前 key。
- `new_session_flow_screen_content.dart` 改为通过 `resolveCurrentModeOption(...)` 展示当前值，即使它暂时不在 fallback 列表里，也会按真实 key 显示出来。

**后续约束**：

- “远端默认模式”和“本地当前覆盖值”必须是两条不同语义，不能在 session 解析时混成一套优先级。
- 只要 PC 传来的当前 key 仍然有效，就不要在 UI 构建阶段偷偷改写它。

### C. 列表顺序来回跳，自定义分组也不稳定

**实际根因**：

- 自定义分组列表之前仍然按 `updatedAt` 排序，而不是按分组里保存的 `sessionIds` 顺序渲染。
- 未分组列表和聊天侧边栏 `SessionsList` 也都还在走 `compareSessionsByRecency`，新消息一到就会因为 `updatedAt` 变化重排。

**本次修复**：

- `session_recency.dart` 增加 `orderSessionsByStoredIds(...)`，自定义分组严格按存储顺序渲染。
- `sessions_screen_custom_group_list.dart` 的自定义分组改成使用保存顺序；未分组和不可用分组改成走稳定排序 `compareSessionsByStableListOrder(...)`。
- `chat/components/session_list.dart` 也切到稳定排序，避免侧边栏会话条目随着实时消息反复跳位。

**后续约束**：

- 只要用户已经明确做了“分组/归类/拖动”这类列表结构操作，就不能再用实时活跃度去打乱顺序。
- 如果某个列表需要稳定顺序，排序依据必须显式写成稳定字段组合，不能继续偷用 `updatedAt`。

### D. 会话列表里也应该更新每个会话的消息，但不渲染

**实际根因**：

- `sessions_screen.dart` 之前的后台刷新只覆盖“当前可见/当前筛选命中的 session”，不满足“在列表页把全部远端会话消息都预热”的要求。
- `session_service_messages.dart` 的 `_warmSessionPreviewData(...)` 也只预热了前几个会话，导致很多 session 只有进入详情后才会真正拉消息。

**本次修复**：

- `sessions_screen.dart` 改成在列表页后台刷新全部远端 session 的消息快照，而不是只刷当前可见部分。
- `sessions_screen_session_actions.dart` 的手动刷新入口也同步改成刷新全部远端 session。
- `session_service_messages.dart` 的预热逻辑从“前几个 preview”改成分批预热全部 session，但只更新仓库中的 `sessionMessages`，不主动渲染详情页。

**后续约束**：

- 列表页如果依赖消息数量、忙闲状态、摘要等二级数据，就必须在后台把这些 session 的消息快照保持新鲜。
- “不渲染详情”不等于“不更新数据”；数据预热和页面渲染要分层处理。

### E. 会话消息数仍然来回跳

**实际根因**：

- 列表里的消息数之前混用了 `session.messages.length`、`loaded sessionMessages.length`、`latestUsage.messageCount`、metadata summary 等多套来源。
- 远端重新加载 session 时，如果服务端没有返回 `latestUsage`，Flutter 端会把本地已经知道的消息统计直接覆盖掉，计数先掉回 0 或旧值，等消息列表重新拉完再跳回去。

**本次修复**：

- 新增统一 helper：`resolveDisplaySessionMessageCount(...)`，所有列表消息数统一走这一套显示口径。
- 聊天侧边栏和会话列表统计都改成使用统一 helper，不再各自拼一套 fallback。
- `session_service_session_parsing.dart` 现在会在远端 session 缺少 `latestUsage` 时保留本地已有统计，并结合已加载消息数生成稳定的 usage/count，避免远端刷新把数字冲掉。

**后续约束**：

- 列表展示层只能使用统一的消息数解析 helper，不能在不同页面各写各的 fallback。
- 远端 session summary 缺失时，必须保留本地已经确认过的 usage/count，避免数字在“远端摘要”和“本地快照”之间反复横跳。

### F. 会话列表展示修改落到了错误组件，看起来像“设备缓存没更新”

**实际根因**：

- 项目里同时存在“主会话列表” `sessions_screen_list_item_content.dart` 和“聊天侧边栏列表” `chat/components/session_list_item_body.dart` 两套列表项实现，之前的展示调整只落到了其中一处。
- 主会话列表项一直没有自己的摘要/预览逻辑，消息未加载时只能显示标题、标签和统计信息，因此用户会感觉“下午改过的展示没有生效”。
- 侧边栏列表也没有和主列表复用同一套预览解析逻辑，导致两边展示内容继续分叉。

**本次修复**：

- 新增统一 helper：`session_list_preview.dart`，主会话列表和聊天侧边栏都改为共用一套“消息预览 -> 描述 -> 摘要 -> 路径 -> 历史消息占位”的解析逻辑。
- `sessions_screen_list_item_content.dart` 现在补上了会话摘要/预览行，并保留时间、消息数、改动数统计。
- `chat/components/session_list_item_body.dart` 也恢复了消息数展示，并和主列表保持同一套预览来源，避免“改了一边、另一边没变”。

**后续约束**：

- 只要两个页面展示的是同一类 session 列表项，预览和占位文案就必须复用同一套 helper，不能各自维护。
- 以后如果用户反馈“像缓存没刷新”，要先确认是否存在多套渲染链，而不是默认归因到构建缓存或真机安装问题。

### G. 会话列表信息过多，标题和头像语义不准确

**实际根因**：

- 主会话列表之前同时展示了分组标签、目录标签、消息数、改动数等多种元信息，列表层级过高，用户真正需要的“状态 / 标题 / 描述 / 时间 / agent 类型”被淹没了。
- 标题解析长期复用了 `session.title`，而 `session.title` 在远端解析时可能来自 summary，因此列表经常把摘要句子当成标题展示，和“工作目录或手动命名”这条需求不一致。
- 手动重命名会话时，本地仓库之前只立即更新了 `Session.title`，没有同步更新本地 metadata 的 `name/title`，导致列表标题规则一旦改成“目录优先”，重命名后的标题会在本地短暂回退。
- 列表头像之前只按 `session.tag` 画通用 chat/work 图标，没有根据真实 `metadata.flavor` 区分 Claude Code 和 Codex。

**本次修复**：

- 主会话列表和聊天侧边栏统一收敛成同一套最小展示模型：状态角标、标题、缩略消息描述、最后一条消息时间、agent 头像。
- 新增 `resolveSessionListTitle(...) / resolveSessionListLastActivityAt(...) / resolveSessionListAgent(...)`，标题改成“手动命名优先，否则工作目录 basename，再回退其他来源”；时间改成“最后一条已加载消息时间优先”。
- 新增 `SessionAgentAvatar`，根据 `metadata.flavor` 显示 Claude Code / Codex / Gemini 对应头像，状态则通过头像角标表达，不再额外堆叠多组 badge。
- `renameSession(...)` 现在会先把 alias 同步写入本地 metadata 的 `name/title`，保证重命名后列表标题立刻稳定，不必等服务端同步回包。

**后续约束**：

- 列表标题和详情标题不能继续共用同一个“宽泛标题”语义；列表标题必须优先表达“这个会话在哪个工作目录 / 被用户改成了什么名字”。
- 只要会话支持本地即时重命名，本地 metadata 就必须一起更新，不能只改 `session.title` 字段。
- agent 头像必须根据真实 flavor 解析，不能再退回 `tag -> 通用图标` 这种弱语义映射。

### H. 会话列表时间和缩略内容混用了 `updatedAt` / metadata 回退，导致展示看起来有值但不真实

**实际根因**：

- 会话列表之前在拿不到消息快照时，会直接把 `session.updatedAt` 当成“最后一条消息时间”显示；但 `updatedAt` 只是会话记录更新时间，不等于最后一条真实消息的 `createdAt`。
- 缩略内容之前也会回退到 `description / summary / path / tag`，列表在消息还没同步下来时看起来“已经有内容”，但那并不是会话里的真实最近消息。
- 主会话列表和聊天侧边栏都依赖同一个 helper，所以一旦这个 helper 把“假的回退值”当成正常数据，两边都会同时误导用户。

**本次修复**：

- 新增统一的 `SessionListActivitySnapshot` 展示模型，明确区分三种状态：`syncing / ready / empty`。
- 列表时间现在只认真实消息的 `createdAt`；在消息快照未加载前不再回退到 `session.updatedAt`，而是显示 `待同步` 中间态。
- 列表描述现在只认真实消息缩略；在消息快照未加载前统一显示 `最近消息待同步`，加载后如果会话仍然为空，再落到 `等待第一条消息`。
- 主会话列表和聊天侧边栏都改成消费同一套 `ActivitySnapshot`，避免一边显示真实消息、一边继续显示 metadata 回退文案。

**后续约束**：

- 只要产品语义是“最后一条消息时间”，就不能继续拿 `updatedAt`、`latestUsage.timestamp` 这类会话级字段冒充。
- 只要产品语义是“会话缩略消息”，就不能继续把 `description / summary / path` 这类静态元数据塞进消息预览位。
- 列表拿不到真实消息时，必须显式呈现“待同步 / 空会话”这种中间态，不能伪造一个看起来像真实数据的回退值。

### I. 手动“标记为已结束”之前只改了 thinking 判定，没有真正解除会话 busy 状态

**实际根因**：

- `session_screen_view_indicators.dart` 里的手动订正入口之前只会更新 `_manualThinkingOverride`，并在“已结束”时清掉 `_activeResponseLocalId`。
- 但发送区真正依赖的是 `sessionConversationIsBusy(...)`，这条链除了 thinking 之外还会继续检查 `pending tool work / optimistic prompt / activeResponseLocalId`。
- 结果就是 UI 上已经手动标成“已结束”，但发送按钮、待发送队列和其他依赖 busy 状态的组件仍然可能继续被旧的阻塞信号卡住。
- 另外，队列协调器 `_scheduleQueuedMessageReconciliation(...)` 之前没有把 `_manualThinkingOverride` 纳入调度签名，所以手动订正后不一定会立刻触发一次新的协调。

**本次修复**：

- `manualThinkingOverride == false` 现在被提升为明确的“解除卡住 busy 状态”语义；只要当前本地没有真正处于发送中，就不再让旧的 `pending tool / optimistic prompt / stale local id` 继续阻塞会话。
- 队列协调调度签名现在纳入 `_manualThinkingOverride`，并且手动订正后会立即重新调度一次协调，保证发送区、待发送队列和其他依赖状态的组件一起刷新。

**后续约束**：

- 任何“人工解除卡住状态”的入口，都不能只改视觉上的 thinking 标志，必须同步覆盖真正决定发送能力的 busy 判定链。
- 只要某个局部状态会影响发送区、队列或自动续发，就必须纳入对应的调度签名，不能只让主 build 看到变化。

### J. 消息丢失的真实根因是“只缓存计数不缓存消息”叠加“强制刷新分页兜底不够”

**实际根因 A：本地快照之前只记了消息数，没有记消息内容**

- `buildLocalSessionSnapshot(...)` 之前只会缓存 `messageCount / latestUsage / draft / mode`，不会缓存真实 `ReducerMessage` 列表。
- 应用重启后，`_restoreCachedSessions()` 只能恢复会话壳和消息数，消息列表本身是空的；如果这时网络刷新失败、延迟或返回不完整，用户看到的就会像“历史消息丢了”。

**实际根因 B：强制刷新整包替换时，分页循环只信任显式 `hasMore`**

- `loadSessionMessages(force: true)` 会在拿到服务端结果后走 `replaceMessages(...)`，直接用新快照覆盖本地消息。
- 之前分页循环只在响应里显式出现 `hasMore/has_more` 时才继续；如果旧接口或异常响应没有给这个字段，但一页刚好打满 100 条，本地就会把“这一页”误当成“全量”，从而把更早的历史消息截掉。

**本次修复**：

- 本地会话快照现在会把“已加载的 reducer 消息列表 + messagesLoaded 标记 + lastSeq”一起持久化。
- `SessionService` 启动恢复缓存时，不再只恢复 session 列表，也会一起恢复消息快照和已知 `lastSeq`，让重启后的消息列表先回到最近一次本地已知状态。
- `loadSessionMessages(...)` 的分页逻辑现在除了显式 `hasMore` 之外，还会在“本页打满 page size 且 seq 持续前进”时继续拉下一页，避免整包替换时把历史截短。

**后续约束**：

- 只要 UI 允许离线、重启后立即查看历史消息，本地快照就必须缓存真实消息快照，不能只缓存消息数。
- 任何 `force reload + replaceMessages(...)` 的链路都必须有可靠的“分页未结束”判定，不能只假设服务端一定会给 `hasMore`。

### K. 进入会话列表时没有稳定触发“自动同步”，而且列表同步链路把全量消息重载误用到了预览场景

**实际根因**：

- `SessionsScreen._initializeSessionListContext()` 之前把 `loadSessions()`、`loadMachines()`、分组状态加载放在同一个 `Future.wait` 里，列表页要等这些都返回后才会继续安排后续预览刷新；这会把“进入列表即同步”的感知拉长。
- socket `connected / reconnecting` 事件之前只会触发 `_refreshVisibleSessionSnapshotsInBackground(force: true)`，不会先检查 session 列表本身是否已经过期，也不会补一次新的 `loadSessions(force: true)`。
- 更重的问题在于，列表页的“背景预览刷新”之前走的是 `refreshSessionMessageSnapshots(... force: true)`，而 `force: true` 会让 `loadSessionMessages()` 从 `after_seq = 0` 开始重新翻完整历史；列表其实只需要最新消息时间和缩略预览，却为每个远端会话都重拉了整段消息历史。

**本次修复**：

- 列表初始化现在先加载 `sessions + grouping`，不再等待 `machines` 完成后才继续后续链路；`machines` 改成后台补刷，不阻塞会话列表进入同步阶段。
- 新增 `SessionServiceNotifier.syncSessionsIfStale(...)`，进入列表、socket 连接恢复时都会触发“如果 session 元数据已过期就补一次远端刷新”，而不是只刷新消息快照。
- 列表页的背景消息刷新改成“优先最近和当前可见的会话、按稳定顺序分批增量刷新”，默认不再对所有会话做 `force` 全量历史重载；手动刷新列表时也只强制刷新 session 元数据，消息快照仍走预览友好的增量链路。

**后续约束**：

- 列表场景只能做“会话元数据同步 + 预览消息增量刷新”，不能再复用详情页那条“整段历史强刷”的链路。
- 任何“进入页面自动同步”的逻辑都不能被机器列表、分组状态这类非关键依赖阻塞。
- 只要 socket 重新连上，列表页就必须先判断 session 元数据是否过期，再决定是否补刷，而不是只刷新单个预览。

### L. 会话列表之前把状态做成无说明圆点，学习成本高且语义混杂

**实际根因**：

- 列表头像之前同时承担了 agent 类型和状态展示两件事，又把 `thinking` 和 `active` 画成了两个不同的角标，但界面里没有文字说明，用户很难知道它们分别代表什么。
- 这两个状态本身也不是同一层语义：`thinking` 是“AI 仍在处理中”，而 `active` 只是“当前活跃会话”，并不表示用户需要关注。
- 列表预览行在 `syncing` 时还额外放了一个蓝色圆点，界面里同时存在多种“圆点状态”，进一步加重理解成本。

**本次修复**：

- 会话头像现在只负责表达 agent 类型，改为直接使用上游 PC 端同源的 `Claude / GPT / Gemini` 图标资源，不再混入状态圆点。
- 列表状态收敛成显式文字芯片：`思考中`、`等待权限`。只有当状态对用户有动作意义时才展示，默认不再显示 `active` 绿点。
- `syncing` 预览行移除了无说明圆点，只保留“待同步 / 最近消息待同步”这类明确文案，避免和会话状态混淆。

**后续约束**：

- 列表状态必须是用户能直接读懂的文案或图标组合，不能再依赖“看颜色/看圆点猜语义”。
- `active` 这类对列表决策价值不高的内部状态，不应该再和 `thinking / waiting permission` 一起并列展示。
- agent 图标和状态标识必须分层：头像只表达 agent，状态单独表达。

### M. 会话页刷新中之前只是换成了 `sync` 图标，但没有真正的动态反馈

**实际根因**：

- 会话页右上角刷新按钮之前只是根据 `_isRefreshingSessionState` 在 `refresh` 和 `sync` 两个静态 icon 间切换，视觉上仍然像一个不动的普通按钮。
- 用户在网络慢或消息刷新时间长的时候，很难判断“现在是否真的还在刷新”。

**本次修复**：

- 会话页新增独立的刷新动画控制器；只要 `_isRefreshingSessionState == true`，右上角图标就持续旋转，刷新结束后再停止并复位。
- 首次进入详情页加载和用户主动点击刷新，现在共用同一套刷新状态开关，避免一个会转、一个不转的割裂行为。

**后续约束**：

- 任何显式“刷新中”的图标，都应该提供动态反馈，不能只靠静态 icon 名称暗示。
- 首次加载和手动刷新如果共用同一个刷新状态，就必须共用同一种视觉反馈。

### N. Codex 头像看起来不对，真实原因不是资源错了，而是我们把上游的 flavor 图标用了错误的版式和着色

**实际根因**：

- 上游 PC `components/Avatar.tsx` 确实使用 `icon-gpt.png` 作为 codex 的 flavor 图标，但它只是一个小型标识，并且会对 codex 单独做 `tintColor` 处理。
- Flutter 端之前把这张资源直接当成整个主头像铺在彩色底板上，没有复用上游的 codex tint 语义，导致视觉上既不像 Codex，也和 Claude / Gemini 的风格不一致。

**本次修复**：

- `SessionAgentAvatar` 现在改成统一的中性卡片底板，agent 资源只负责表达工具品牌本身。
- Codex 图标新增单独 tint，Claude / Gemini 保持原资源颜色；同时按 agent 调整图标尺度和内边距，避免 codex 图标被放得过大、过满。

**后续约束**：

- flavor 图标如果来自上游，就要连同上游的 tint 和尺寸语义一起对齐，不能只拷资源文件。
- agent 头像和会话状态必须继续分层，不要再把状态色直接灌进品牌图标本身。

### O. 会话详情初始化之前仍然强制全量重拉消息，抵消了本地全量持久化和 `lastSeq` 增量同步能力

**实际根因**：

- 本地缓存层已经支持把已加载消息快照和 `lastSeq` 一起持久化，并在启动时恢复。
- 但 `session_screen_state_load.dart` 在进入会话详情时仍然无条件 `loadSessionMessages(force: true)`，会把 `after_seq` 重置为 `0`，每次都重新拉完整历史。
- 这让“本地全量持久化 + 打开后只拉增量”的能力在列表页可用、在详情页却被主动绕开，所以用户会感觉每次进会话都还是很重。

**本次修复**：

- 会话详情初始化现在会先判断本地是否已经有已加载的消息快照；如果有，就直接走增量 `loadSessionMessages(force: false)`，让服务端只返回本地最新消息之后的后续消息。
- 只有在本地还没有任何消息基线时，才会继续走一次全量加载，把该会话的完整历史建立到本地缓存里。

**后续约束**：

- 只要本地已经恢复出消息快照，就不能在页面初始化时再无条件 `force: true`。
- “全量补齐历史”应该只发生在没有本地基线或用户明确要求强制重建快照的时候；普通进入页面和自动刷新都应优先走增量同步。

### P. 早期消息一旦本地基线被截断，普通增量同步无法自愈，必须提供“全量替换本地快照”的恢复入口

**实际根因**：

- 现在的普通消息同步链路基于 `lastSeq` 做增量拉取，只会请求“本地最后一条已知消息之后”的新消息。
- 这条链路对性能是对的，但一旦本地持久化快照本身已经缺了较早的历史，后续所有增量同步都只会继续往后追加，永远不会把更早丢掉的消息补回来。
- 此前界面里没有明确的“从 PC 端重新全量拉取并替换本地消息快照”的恢复入口，用户只能依赖普通刷新，而普通刷新并不会清掉残留本地消息，也不会保证立刻把全量结果写回本地持久化。

**本次修复**：

- 在会话更多操作中新增“同步全部消息”入口，直接触发 `force: true` 的全量远端拉取。
- 这条链路会关闭 `preserveOptimisticMessages`，使用远端全量结果完整替换本地消息列表，避免把旧的残留本地消息继续混进新的全量快照里。
- 全量同步完成后，会立即把新的消息快照和 `lastSeq` 落回本地持久化，而不是只等待常规 debounce 持久化。

**后续约束**：

- 增量同步只负责“追新”，不能假设它具备“修复本地缺历史”的能力。
- 只要产品允许本地缓存消息，就必须同时提供一个明确的“以服务端全量为准重建本地快照”的恢复入口。
- 真正的“全量同步”不能继续保留残留 optimistic 消息，否则它就不是严格意义上的远端替换。

### Q. 删除会话时，本地持久化不应该只删会话壳，还要连带删除附属消息缓存

**实际根因**：

- 当前本地已生效的消息快照主要是挂在 `SessionStorageModel.metadata.__happyLocalSessionState.messages` 里的，所以删除 session 记录时理论上会一并删除这部分缓存。
- 但底层 Hive 里仍然保留了独立的 `messages` box 结构；即使目前这条存储链没有作为主读取来源，删除会话时如果不一并清理，后续演进或统计口径就会留下脏数据和误导。

**本次修复**：

- `HiveRepository.deleteSession(...)` 现在会同时删除该 session 的主记录和 `messages` box 中 `sessionId` 对应的附属消息缓存。
- 会话服务侧在删除会话或清空会话消息后，也会同步刷新本地持久化，确保本地缓存内容和当前内存态一致。

**后续约束**：

- 任何会话删除动作都必须当成“级联删除”，不能只删会话主表。
- 只要某类本地消息缓存还有可能被统计、恢复或迁移用到，就必须在删除会话时一起清理，避免留下不可见的脏状态。
