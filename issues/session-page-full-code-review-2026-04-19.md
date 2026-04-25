# 会话页面全量代码审查与修复记录

日期：2026-04-19

## 审查范围

- `lib/features/session/screens/session_screen.dart`
- `lib/features/session/screens/session_screen_*.dart`
- `lib/features/session/widgets/message/**`
- 会话页直接使用的平台常亮能力：`lib/app/platform/screen_awake_bridge.dart`

## 问题 1：消息行强制 KeepAlive 破坏虚拟列表

定位：

- `lib/features/session/screens/session_screen_view_messages.dart`
- `_BuildContextAnchorState extends State<_BuildContextAnchor> with AutomaticKeepAliveClientMixin`
- `wantKeepAlive => true`

问题：

会话页已经用 `ListView.builder` 做消息级虚拟化，但每个消息行又通过 `AutomaticKeepAliveClientMixin` 强制保活。长会话滚动时，曾经构建过的行不会及时释放，导致行上下文、富文本、代码块、工具块持续驻留内存，逐步削弱虚拟列表收益，并放大滚动卡顿和 GC 压力。

解决方案：

- 将 `_BuildContextAnchor` 改为轻量 `StatelessWidget`。
- 保留同步挂载/卸载的 `_RenderObjectAnchorElement` 注册机制。
- 让离屏消息行按 Flutter 虚拟列表生命周期正常释放。

## 问题 2：重复 message id 仍会导致列表 key 与锚点冲突

定位：

- `lib/features/session/screens/session_screen_view_messages.dart`
- `ValueKey<String>(item.message.id)`
- `_messageRowContexts` 以 `message.id` 为 key
- `findChildIndexCallback` 以 `message.id` 查找

问题：

代码仅记录重复 message id 日志，但渲染 key、行上下文注册和 `findChildIndexCallback` 仍继续使用原始 `message.id`。当归档窗口或远端异常数据出现重复 id 时，Flutter 子节点复用会混乱，锚点定位会互相覆盖，滚动恢复可能跳到错误行。

解决方案：

- 在 `_FlatMessageItem` 增加 `renderId`。
- 通过同一消息 id 的出现次数生成唯一渲染 id，例如 `id`、`id#2`。
- `ListView` key、`findChildIndexCallback` 和行上下文注册全部改用 `renderId`。
- 日志与业务行为继续保留原始 `message.id`，便于追踪数据源问题。

## 问题 3：Markdown 多段文本会提前 dispose 前面段落的链接 recognizer

定位：

- `lib/features/session/widgets/message/markdown/markdown_text.dart`
- `_buildRichText()` 内部每次调用都会 dispose 并清空 `_recognizers`

问题：

一个 Markdown 文本块可能包含多个 section。原实现每构建一个 section 都会清空 recognizer 列表，导致同一次 build 中前面 section 创建的链接点击 recognizer 被后续 section 提前 dispose。表现为多段文本中只有后面的链接可靠，前面段落链接点击可能失效或触发 disposed recognizer 风险。

解决方案：

- 在 `build()` 开始时统一释放上一轮 build 的 recognizer。
- `_buildRichText()` 只负责为当前 build 追加 recognizer。
- `dispose()` 复用统一清理函数。

## 问题 4：代码块缓存未感知消息操作回调变化

定位：

- `lib/features/session/widgets/message/inline_code_panel.dart`
- `_cachedCodeBodyKey` 只包含代码和语言

问题：

`InlineCodePanel` 缓存了 `SelectableText` / `HighlightView` widget。代码和语言不变但消息操作回调变化时，缓存体仍可能持有旧的 context menu builder，导致复制、转发、保存模板、插入输入框等操作绑定到旧消息动作上下文。

解决方案：

- `didUpdateWidget` 增加 `onMessageAction` 变化检测。
- 回调变化时清理 `_cachedCodeBody` 与 `_cachedCodeBodyKey`。

## 问题 5：会话页直接编排平台常亮能力且存在异步竞态

定位：

- `lib/features/session/screens/session_screen_state_screen_awake.dart`
- 原代码直接判断 `HarmonyPlatform.isHarmonyOS`，并直接调用 `ScreenAwakeBridge` / `WakelockPlus`

问题：

页面层承担了平台分支和外部能力编排，违反 UI 与平台服务解耦原则。另一个风险是异步常亮请求可能晚于页面退出完成：如果“开启常亮”的调用在 dispose 后才返回，可能覆盖释放请求，让屏幕保持常亮。

解决方案：

- 新增 `lib/app/platform/screen_awake_service.dart`，统一封装 HarmonyOS bridge 与普通平台 wakelock。
- 会话页只表达 `keepAwake` 意图，不直接依赖平台实现。
- 增加 `_screenAwakePolicyEpoch`，丢弃过期异步结果，并在 stale 开启请求晚到时补发 release。

## 验证要求

- 运行 `dart format` 格式化改动文件。
- 运行 `flutter analyze`，确保没有新增静态分析问题。
- 如后续复现滚动问题，优先观察 `renderId`、`rowId`、`messageId` 三者日志，而不是只看原始消息 id。
