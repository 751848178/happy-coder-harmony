# 会话详情页目录化与 part 边界重构记录

日期：2026-04-19

## 背景

会话详情页原先集中在 `lib/features/session/screens/session_screen.dart` 及一组 `session_screen_*` 前缀文件中。文件名靠前缀表达职责，目录无法表达模块边界，导致：

- `session_screen.dart` 同时承担公开入口、实现库根、状态持有、生命周期、消息缓存、滚动锚点、工具动作等职责。
- 顶层文件集中维护大量 import 与 part，任何子模块新增依赖都要污染同一个库根。
- 同一目录混放状态、视图、消息、命令、控制器和辅助 widget，后续开发很难判断应该改哪个文件。
- `session_screen_*` 前缀命名不利于继续拆分多层子组件，也不符合“一个目录做一件事”的组织方式。

## 定位到的具体问题

### 问题 1：公开入口和实现库根耦合

定位：

- `lib/features/session/screens/session_screen.dart`

问题：

路由层需要的是 `SessionScreen` 公开入口，但该文件同时包含大量实现细节。外部引用一个屏幕组件时，被迫依赖整个会话详情实现库。

修复：

- `screens/session_screen.dart` 改为 facade，仅导出 `session_detail/session_detail.dart`。
- 公开路径保持不变，避免大面积修改路由和调用方。

### 问题 2：功能前缀文件堆在同一目录

定位：

- `lib/features/session/screens/session_screen_state_*.dart`
- `lib/features/session/screens/session_screen_view_*.dart`
- `lib/features/session/screens/session_screen_message_*.dart`

问题：

职责靠文件名前缀推断，目录没有表达架构边界。新增功能时容易继续制造 `session_screen_xxx` 文件，导致 screens 目录膨胀。

修复：

迁移为目录化结构：

- `session_detail/state/`：状态生命周期、加载、队列、刷新、socket、工具动作等。
- `session_detail/view/`：页面区域 UI，包括消息列表、输入区、元数据、状态指示器、队列面板。
- `session_detail/message/`：消息渲染、消息动作、转发、turn 分组、消息视图状态。
- `session_detail/command/`：命令面板、命令逻辑、模板编辑。
- `session_detail/controllers/`：页面协调器和命令控制器。
- `session_detail/presenter/`：页面展示状态与副作用协调。
- `session_detail/viewport/`：滚动视口、边界加载、锚点恢复。
- `session_detail/widgets/`：仅服务于会话详情页的小型叶子组件。

### 问题 3：库根 import 过多

定位：

- 原 `session_screen.dart`

问题：

Dart `part` 文件共享库根 import。只要任何 part 使用一个类型，库根就必须导入它，造成根文件 import 列表持续膨胀。

修复：

- 新增 `session_detail/dependencies.dart` 作为会话详情实现库的依赖聚合。
- `session_detail/session_detail.dart` 仅保留一个依赖聚合 import 和必要的 `storage_models` 前缀 import。
- `storage_models` 保持前缀导入，避免和领域层 `Session` 命名冲突。
- `dart:async` 导出时隐藏 `AsyncError`，避免和 Riverpod 命名碰撞。

### 问题 4：实现库根混有业务状态代码

定位：

- 原 `session_screen.dart` 中 `SessionScreen`、`_SessionScreenState`、常量、选择器、缓存与调试逻辑。

问题：

库根既负责 part 索引，又承载业务状态，修改导入/part 时容易误碰业务代码；修改状态逻辑时也会让库结构文件持续变大。

修复：

- 实现库根改为 `session_detail/session_detail.dart`，只负责 import 与 part 索引。
- 屏幕状态实现移动到 `session_detail/state/screen_state.dart`。
- 公开 facade、实现库根、状态实现三者分离。

## 后续约束

- 新增会话详情功能时，优先放入对应职责目录，不再创建 `session_screen_xxx.dart` 前缀文件。
- 只有必须访问 `_SessionScreenState` 私有字段的方法才继续使用 `part`。
- 可独立成为 widget、presenter、service、model 的代码，应逐步转成普通 Dart library，再通过明确 import 使用。
- 新增平台能力不得进入 screen/state part，应先落到 `app/platform` 或 feature service。

## 验证

- `dart format lib/features/session/screens/session_screen.dart lib/features/session/screens/session_detail`
- `flutter analyze`
- 会话相关单元测试
