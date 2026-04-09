# 消息渲染管线性能优化：Markdown 解析缓存与子代理工具预览

日期: 2026-04-03

## 问题

进入会话页面后仍然卡帧，用户反馈改善明显但仍存在丢帧。经深入审计发现根因：

1. **`_MarkdownTextBlock` 是 `StatelessWidget`** — 每次 build 都重新调用 `_MarkdownTextSection.parse()` 进行多轮正则分割（O(n × regex_count))，20264 条消息 × 20-30 个文本块，每次重建都重新解析

2. **`_MarkdownInlineParser.buildSpans()` 每次 build 都重新运行正则匹配 + 为每个链接创建新的 `TapGestureRecognizer`** — 不必要分配

3. **`_buildSubagentChildToolRow` 每次调用未缓存的 `_formatToolResult()`** — 对子代理的子工具行只需一行摘要标题，却运行昂贵的 jsonDecode + JsonEncoder.withIndent

4. **`_buildCollapsedTextPreview` 对 markdown 内容创建完整 `_MarkdownMessageContent` 控件树** — 折叠预览被 IgnorePointer + ClipRect 包裹，用户无法交互，但仍创建完整 markdown 渲染管线（代码面板、语法高亮、内联解析）

5. **`_ensureActionState()` 在 initState 中运行 `jsonEncode`** — 对每个工具消息调用 `resolveSessionMessageActionText()` → `_buildToolActionText()` → `jsonEncode(arguments)` + `jsonEncode(result)`，但操作文本仅在用户长按时才需要

6. **`HighlightView` 每次 build 都重新解析语法树** — `_buildCodeBody()` 每次 build 都创建新 `HighlightView`（无状态 widget），语法解析重复执行

## 修复

### P0: `_MarkdownTextBlock` → `StatefulWidget`

**文件:** `session_screen_markdown_text.dart`

- 转换为 `StatefulWidget`，在 `initState`/`didUpdateWidget` 中缓存 `_MarkdownTextSection.parse()` 结果
- 仅当 `content` 变化时重新解析
- `build()` 使用缓存的结果

### P1: `_MarkdownInlineParser` LRU 缓存

**文件:** `session_screen_markdown_inline_parser.dart`

- 拆分为 `_parse()` (cached) + `buildSpans()` (from cache)
- 添加 `_ParsedInlineSegment` 数据类，`_parse()` 使用静态 LRU Map 缓存（200 条）
- 缓存命中后跳过正则匹配，仅构建 `InlineSpan` 对象

### P2: 子代理工具行轻量预览

**文件:** `session_screen_message_bubble_tool_panel.dart`

- `_buildSubagentChildToolRow` 改用 `_plainTextPreview(tool.result ?? '')` 替代 `_formatToolResult(tool.result)`
- 子代理行只需一行摘要标题，不需要完整 JSON 格式化

### P3: 折叠 markdown 预览改为纯文本

**文件:** `session_screen_message_bubble_collapsed_text.dart`

- `_looksLikeMarkdownContent` 分支从创建 `_MarkdownMessageContent` 控件树改为 `Text` + `_plainTextPreview`
- 折叠预览被 IgnorePointer 包裹无法交互，完整 markdown 渲染管线是纯浪费

### P4: 延迟 `_ensureActionState()` 到首次使用

**文件:** `session_screen_message_bubble.dart`

- 移除 `initState()` 和 `didUpdateWidget()` 中的 `_ensureActionState()` 调用
- `onMessageAction` 和 `onLongPressMessage` getter 首次访问时触发
- `_actionTextComputed` guard 保证只计算一次

### P5: 缓存 `HighlightView` widget

**文件:** `session_screen_inline_code_panel.dart` + `session_screen_inline_code_panel_render.dart`

- `_InlineCodePanelState` 添加 `_cachedCodeBody` / `_cachedCodeBodyKey`
- `_buildCodeBody()` 检查缓存命中则直接返回
- `didUpdateWidget()` 中 invalidate 缓存
- 展开/折叠切换时 visibleCode 变化自动 invalidate（cache key 包含 code text）

## 修改文件

- `session_screen_markdown_text.dart` — StatelessWidget → StatefulWidget
- `session_screen_markdown_inline_parser.dart` — 添加 LRU 缓存
- `session_screen_message_bubble_tool_panel.dart` — 子代理行轻量预览
- `session_screen_message_bubble_collapsed_text.dart` — 折叠预览纯文本
- `session_screen_message_bubble.dart` — 延迟 action state
- `session_screen_inline_code_panel.dart` — 代码体缓存字段
- `session_screen_inline_code_panel_render.dart` — 代码体缓存逻辑
