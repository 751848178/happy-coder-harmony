# 长按菜单功能导致消息列表卡顿

## 问题现象

加入长按菜单（转发/存模板/插入到输入框）能力后，会话消息列表在流式输出和滚动时变卡。

## 根因分析

### 1. `resolveSessionMessageActionText` 在每次 rebuild 时对所有可见消息执行

**位置:** `session_screen_view_messages.dart` `_buildMessageBubble()`

```dart
final actionText = resolveSessionMessageActionText(message);
```

对于 tool call 消息，此函数会调用 `jsonEncode(tool.arguments)` 和 `jsonEncode(tool.result)`，对大型工具输出（文件读取、命令执行结果等）开销很大。

流式输出时，每收到一个 token chunk，`sessionStateProvider` 更新 → `_buildSessionScreen` 全量 rebuild → `ListView.builder` 重建所有可见 item → 每条消息都调用 `resolveSessionMessageActionText`。

### 2. 每次重建为每条消息创建两个新闭包

```dart
onMessageAction: actionText == null
    ? null
    : (choice) => _handleMessageActionChoice(choice: choice, actionText: actionText),
onLongPressMessage: actionText == null
    ? null
    : () => _showMessageActionSheet(message: message, actionText: actionText),
```

- 10 条可见消息 × 2 个闭包 = 每帧 20 个闭包分配
- 闭包是新的对象实例，导致 `_MessageBubble` 的 `didUpdateWidget` 检测到属性变化
- 内容 widget（Markdown、工具面板等）的 `onMessageAction` 参数变化，触发无意义的子树 rebuild

### 3. 性能量化（流式输出场景）

| 指标 | 修复前（每帧） | 修复后（每帧） |
|------|---------------|---------------|
| `jsonEncode` 调用次数 | N（所有可见消息） | ≤1（仅流式消息） |
| 新闭包分配 | 2N | 0（非流式消息） |
| 内容 widget 无意义 rebuild | N | 0 |

## 修复方案

### 核心思路：将 actionText 计算和回调创建从父级 builder 移入 `_MessageBubbleState`

1. **`_MessageBubble` widget 移除 `onMessageAction` 和 `onLongPressMessage` 参数** — 不再从外部传入回调
2. **`_MessageBubbleState` 内部缓存 actionText** — 调用 `resolveSessionMessageActionText(message)`，仅在 `initState` 和消息对象变化时重新计算
3. **`_MessageBubbleState` 创建稳定回调引用** — 通过 `context.findAncestorStateOfType<_SessionScreenState>()` 延迟查找 screen state 并调用其扩展方法
4. **`_buildMessageBubble` 简化** — 不再调用 `resolveSessionMessageActionText`，不再创建闭包

### 涉及文件

| 文件 | 变更 |
|------|------|
| `session_screen_message_bubble.dart` | 移除 widget 回调参数；state 内缓存 actionText + 回调 |
| `session_screen_view_messages.dart` | 简化 `_buildMessageBubble` |
| 所有内容 widget（markdown、tool sections 等） | **不变** — 通过 state getter 获取回调，getter 实现变更对调用方透明 |

### 设计要点

- **回调稳定性**：`_onMessageAction` 和 `_onLongPressMessage` 在 `_MessageBubbleState` 中创建，仅在 `_actionText` 变化时重建。非流式消息的回调引用跨帧不变，子 widget 的 `didUpdateWidget` 检测不到变化。
- **延迟查找**：`findAncestorStateOfType<_SessionScreenState>()` 仅在用户实际触发操作（长按或菜单选择）时调用，不影响帧性能。
- **内容 widget 零改动**：所有 markdown、工具面板等 widget 仍通过 `_MessageBubbleState.onMessageAction` getter 获取回调，getter 实现从 `widget.onMessageAction` 改为 `_onMessageAction`，对下游完全透明。
