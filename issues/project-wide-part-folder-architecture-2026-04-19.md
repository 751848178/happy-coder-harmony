# 全项目 part 前缀文件目录化重构记录

日期：2026-04-19

## 背景

继会话详情页重构后，全项目扫描发现多个模块存在同类结构问题：

- 根文件同时承担公开入口、实现库根、业务代码和 part 索引。
- 同一目录下散落大量 `foo_bar_xxx.dart` 前缀文件，职责依赖文件名而非目录表达。
- 根文件 import 因 part 共享库命名空间而持续膨胀。
- 大量子文件只能通过 `part` 访问根文件私有成员，后续很难逐步提取普通 library。

## 本轮处理策略

采用“保留公开路径、移动实现库”的低风险方案：

```text
原结构：
foo_bar.dart
foo_bar_content.dart
foo_bar_actions.dart

新结构：
foo_bar.dart                 // facade，只 export 新实现
foo_bar/
  foo_bar.dart               // 实现库根
  content.dart               // 原 part，去掉父级前缀
  actions.dart               // 原 part，去掉父级前缀
```

这样外部 `import 'foo_bar.dart'` 不需要改变，但实现文件已经进入功能目录。

## 补充处理：目录内去前缀

第一轮迁移后仍残留 `foo_bar/foo_bar_content.dart` 这类命名。虽然文件已经进入功能目录，但父级前缀仍然重复，阅读和维护时依然需要靠长文件名表达职责，不符合“一个目录做一件事，子文件表达具体功能点”的规范。

本轮继续执行：

- `foo_bar/foo_bar_content.dart` 改为 `foo_bar/content.dart`。
- `foo_bar/foo_bar_actions.dart` 改为 `foo_bar/actions.dart`。
- 同步更新实现根文件中的 `part` 声明。
- 不重命名 `.g.dart` 生成文件，避免破坏 build_runner 约定。

## 本轮发现并修复的具体问题

- 批量移动实现库后，带 `show` / `hide` / `as` 的相对导入没有被第一轮脚本覆盖，导致部分实现根下沉一层后导入路径失效。已通过文件存在性校验补齐一层 `../`。
- 第一轮目录化后目录内仍有大量重复父级前缀文件名，已继续去除 435 个 part 子文件的重复前缀，让目录表达功能、文件表达具体职责。
- 发现少量 `part` 声明因批量替换后指向不存在文件，已基于同目录真实文件做存在性修复。
- 静态分析暴露 5 个历史 warning：底部 Tab 未使用 badge 参数、新建会话 action 未使用长按参数、会话列表 header 未使用 subtle 样式、账号设置设备信息卡未接入 UI、socket helper 中遗留未调用 JSON map 解码函数。已分别通过删除死参数、恢复设备信息卡、强类型化 credentials、移除死 helper 修复。
- 继续扫描发现会话详情页、会话归档、会话列表预览、消息组件仍存在 300 行以上的大文件。已按职责拆分为 controller、anchor、window、helper、presenter、builder 等小文件，避免新的“大 part 文件”继续沉淀。
- 全量测试发现 `SessionListItem` 走预计算预览分支时，`latestUsage.messageCount > 0` 且还没有 `previewText` 的会话会错误显示“等待第一条消息”。已在 `resolveSessionListActivitySnapshotFromPreview` 中补齐“最近消息待同步”分支，并增加域逻辑测试覆盖。

## 后续开发约束补充

- `lib` 下普通业务 Dart 文件应尽量控制在 300 行以内；超过该阈值时优先拆为同一功能目录下的子职责文件。
- 大文件拆分时不要只把内容搬到新的“大 helper”；应按用户行为、数据窗口、渲染构建、状态同步、诊断日志等稳定职责拆分。
- Extension 拆分私有方法时，静态成员必须使用定义类型限定访问，避免 Dart extension 中的未限定静态成员解析错误。

## 跳过规则

本轮跳过包含 `.g.dart` part 的库，例如 JSON/Hive 生成文件相关模型。原因：

- 生成文件路径由 build_runner 约定控制。
- 将生成 part 一起移动会影响后续生成命令。
- 这些库应在后续专门处理模型生成策略时重构。

本轮也跳过已经完成目录化的 `session_detail/`。

## 代码约束

- 新增 part 文件时必须放入对应功能目录，不再继续在父目录创建 `foo_bar_xxx.dart`。
- 旧入口文件只允许保留 `export 'foo_bar/foo_bar.dart';`。
- 若后续新增文件不需要访问根库私有成员，应优先使用普通 Dart library 和显式 import，不新增 part。
- 包含平台能力、网络、存储、加密等外部系统访问的逻辑，不应进入 UI screen part。

## 验证

- 批量迁移后运行 `dart format`。
- 运行 `flutter analyze` 确认无新增错误。
- 运行当前项目已有会话相关测试作为回归烟测。
