# 会话消息列表再次出现上下双屏渲染异常

**日期**: 2026-04-25
**严重级别**: P0 Critical
**状态**: 已修复

## 现象

发送消息后，会话详情页偶发出现“消息列表被上下平分成两块”的异常。
视觉上像有两个正常消息列表同时存在，但预期始终应该只有一个常规消息列表。

## 审查范围

- `lib/features/session/screens/session_detail/state/build.dart`
- `lib/features/session/screens/session_detail/view/message_stage.dart`
- `lib/features/session/screens/session_detail/view/message_list.dart`
- `lib/features/session/screens/session_detail/view/message_scroll.dart`
- `lib/features/session/screens/session_detail/state/message_sync.dart`
- 已有问题记录：`issues/message-list-two-screen-artifact-2026-04-19.md`

## 已确认根因

### 根因 1：消息列表舞台仍然允许隐藏列表分支参与复合

`_buildMessageListStage()` 之前用的是：

- `Stack`
- `Positioned.fill`
- `Offstage`
- 常驻挂载的 `ListView`

这个实现的出发点是正确的：为了锚点恢复，列表在不可见阶段也不卸载。
但在 OHOS/HarmonyOS 上，发送消息后的重建和滚动校正会让滚动层快速 churn。
此时 `Offstage` 隐藏的 `ListView` 虽然逻辑上不应显示，渲染层仍可能保留旧的
scroll layer，结果就是用户看到上下两块消息区，像是两个列表同时在屏幕上。

### 根因 2：当前实现没有强约束“同一时刻只能有一个可见舞台分支”

旧实现虽然通过 `offstage` 和条件 `if (!shouldRevealList)` 控制内容，
但舞台本身不是“单可见分支”模型。对于 OHOS 这类在滚动列表和 layer 复用上
更敏感的平台，这种“挂载一个列表，再叠一个 loading/background 分支”的方式
仍然可能产生残影或分屏。

## 修复方案

将 `view/message_stage.dart` 改为：

- 外层 `ColoredBox + ClipRect`
- 中间 `SizedBox.expand`
- 核心舞台改成 `IndexedStack`
- 用 `stageIndex` 明确约束同一时刻只渲染一个可见分支
- 消息列表本体包一层 `RepaintBoundary`

这样做的效果：

1. 列表仍然保持挂载，锚点恢复能力不丢。
2. 同一时刻只会有一个舞台分支真正可见。
3. 移除 `Positioned.fill + Offstage` 这组在 OHOS 上更容易出现复合残影的组合。
4. 用 `ClipRect` 把消息区裁死，避免旧 layer 越界或半屏残留。

## 修改文件

- `lib/features/session/screens/session_detail/view/message_stage.dart`

## 架构结论

- “消息列表是否挂载” 与 “消息列表是否可见” 必须解耦。
- 但“不可见”不能再依赖会让滚动 layer 长时间悬空复合的实现。
- 对会话页这类高频重建、高频滚动校正的区域，舞台层要优先保证：
  - 单一可见分支
  - 明确裁剪
  - 主滚动区域不使用易产生平台差异的隐藏策略

## 后续开发约束

1. 会话主消息区不要再用 `Positioned.fill + Offstage` 或 `Opacity(0)` 隐藏主 `ListView`。
2. 如需保留列表挂载，优先使用“单可见分支舞台”模型，而不是叠多层隐藏分支。
3. 涉及滚动列表显隐的改动，真机必须覆盖发送消息、流式回复、折叠轮次、历史翻页四类场景。
