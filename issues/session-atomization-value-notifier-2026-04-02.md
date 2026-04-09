# 会话页面与会话列表全屏 rebuild 原子化

日期: 2026-04-02

## 问题

1. **折叠的工具消息仍触发昂贵 JSON 格式化** — `_buildToolCallMessage` 在 collapsed/expanded 分支之前无条件计算 `argumentsPreview`（`_formatToolArguments`，JsonEncoder）和 `resultPreview`（`_formatToolResult`，jsonDecode + JsonEncoder.withIndent）。折叠视图只需要 `_plainTextPreview`（160 字符正则截断），完整 JSON 美化完全浪费。264 条消息中约 60% 是工具消息，大部分折叠，每次 build 浪费 50-500ms。

2. **5 个状态字段通过 `setState` 修改，每次改动触发整个 `_buildSessionScreen` 全量重建** — `_isSending`、`_isAborting`、`_isRefreshingSessionState`、`_isSyncingAllMessages`、`_sessionOverviewCollapsed` 仅影响 1-2 个小控件（图标按钮），但修改时重建整个消息列表、AppBar、输入区域。

3. **会话列表页 Riverpod selector 每次返回新 `List` 实例** — `sessions.values.toList(growable: false)` 导致 select 的 `==` 检查永远失败，每次 provider 发射都触发全列表重建。

4. **`_SessionListItem` 缺少 `ValueKey`** — 列表重建时 Flutter 无法正确识别元素身份，可能导致控件状态错乱。

## 修复

### P0 — 折叠工具消息延迟格式化

- `argumentsPreview` 和 `resultPreview` 的计算从 `_buildToolCallMessage` 方法顶部移到 `else`（展开）分支内部
- 新增 `_buildExpandedToolDetailSections` 方法，在展开路径内一次性计算 `argumentsPreview`/`resultPreview`
- `_buildCollapsedToolPreview` 参数从 `resultPreview` 改为 `resultRaw`，内部使用轻量 `_plainTextPreview` 处理
- 折叠路径不再调用 `_formatToolResult`（jsonDecode + JsonEncoder）或 `_formatToolArguments`

### P1 — 会话页面 ValueNotifier 原子化

| 字段 | 类型 | 影响控件 | 包裹方式 |
|------|------|---------|---------|
| `_isRefreshingSessionState` | `ValueNotifier<bool>` | AppBar 刷新图标 | `ValueListenableBuilder<bool>` |
| `_isSending` | `ValueNotifier<bool>` | 发送按钮 | `ValueListenableBuilder<bool>` |
| `_isAborting` | `ValueNotifier<bool>` | 停止按钮 | `ValueListenableBuilder<bool>` |
| `_isSyncingAllMessages` | `ValueNotifier<bool>` | 同步菜单项 | 读取 `.value`（PopupMenuItemBuilder 每次打开重建） |
| `_sessionOverviewCollapsed` | `ValueNotifier<bool>` | 概览 toggle + 面板 | `ValueListenableBuilder<bool>` |

- 保留 getter 便捷访问（`bool get _isSending => _isSendingN.value`），逻辑判断无需修改
- `_setSessionRefreshing` 移除 `setState`/`_updateState`，直接设 ValueNotifier
- 所有 ValueNotifier 在 `dispose()` 中正确释放

### P2 — 会话列表页修复

- Riverpod selector 改为返回 `Map<String, Session>?` 引用（而非 `.toList()` 新列表），避免不必要的重建
- 所有 `_SessionListItem` 添加 `key: ValueKey(session.id)`，确保列表元素身份稳定

## 修改文件

- `session_screen.dart` — 声明 5 个 ValueNotifier + getter + dispose
- `session_screen_state_appbar.dart` — 刷新图标/toggle/同步菜单包裹 ValueListenableBuilder
- `session_screen_state_build.dart` — 概览面板包裹 ValueListenableBuilder
- `session_screen_state_refresh.dart` — `_isSyncingAllMessages` 改用 ValueNotifier
- `session_screen_state_load.dart` — `_sessionOverviewCollapsed` 改用 ValueNotifier
- `session_screen_state_actions.dart` — `_isSending`/`_isAborting` 改用 ValueNotifier
- `session_screen_view_input.dart` — 发送/停止按钮包裹 ValueListenableBuilder
- `session_screen_message_bubble_tool_panel.dart` — 延迟计算 argumentsPreview/resultPreview
- `session_screen_message_bubble_collapsed_tool.dart` — resultPreview → resultRaw
- `sessions_screen_content.dart` — selector 稳定引用
- `sessions_screen_list_item.dart` — 添加 super.key
- `sessions_screen_default_group_list.dart` — 添加 ValueKey
- `sessions_screen_custom_group_list.dart` — 添加 ValueKey
