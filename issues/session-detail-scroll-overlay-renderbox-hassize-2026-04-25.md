# 会话详情页首帧闪现 `App failed to render`：构建期读取 `Scrollable` 视口 RenderBox 尺寸

**日期**: 2026-04-25
**严重级别**: P0 Critical
**状态**: 已修复

## 现象

- 进入会话详情页时会闪一下全局错误页。
- 真机错误文案为：
  - `RenderBox was not laid out`
  - `RenderSemanticsGestureHandler ...`
  - `Failed assertion: ... box.dart: 'hasSize'`

## 审查范围

- `lib/features/session/screens/session_detail/view/indicators.dart`
- `lib/features/session/screens/session_detail/state/refresh_anchor.dart`
- 会话详情页消息区、滚动按钮覆盖层、视口锚点恢复链路

## 确认后的具体根因

### 根因 1：滚动按钮覆盖层在 build 期间同步读取消息列表视口 `RenderBox.size`

`_buildScrollActionsOverlay(...)` 会在页面 build 阶段调用：

- `_resolveScrollActionsViewportHeight(context)`

原实现里这个函数优先走：

- `_messageListViewportRenderBox()`
- `context.notificationContext.findRenderObject() as RenderBox`
- `viewportBox.size.height`

而这个 `notificationContext` 对应的渲染对象正是 `Scrollable` 手势层的
`RenderSemanticsGestureHandler`。

在会话详情页首帧里，覆盖层已经开始 build，但消息列表所在的 `Scrollable`
还没有完成 layout。此时直接读取 `size`，就会命中 Flutter 的：

- `RenderBox was not laid out`
- `hasSize`

断言。

### 根因 2：视口 RenderBox helper 缺少 `hasSize` 防护

`_messageListViewportRenderBox()` 原先只判断了：

- `_scrollController.hasClients`
- `renderObject is RenderBox`

但没有检查：

- `renderObject.attached`
- `renderObject.hasSize`

这让它在首帧和窗口切换等敏感阶段，会把“已挂上但尚未完成布局”的
`RenderBox` 继续向上传递，放大构建期读取尺寸的风险。

## 修复方案

- `_resolveScrollActionsViewportHeight(context)` 改为：
  - 优先读取 `ScrollPosition.viewportDimension`
  - 只有在视口维度不可用时，才退回到 RenderBox / MediaQuery
- `_messageListViewportRenderBox()` 增加：
  - `attached`
  - `hasSize`
 保护，只返回已经完成布局的视口 RenderBox

这样滚动按钮覆盖层在首帧不再同步触碰未布局完成的
`RenderSemanticsGestureHandler`，错误消失，同时保留后续锚点恢复和几何计算能力。

## 修改文件

- `lib/features/session/screens/session_detail/view/indicators.dart`
- `lib/features/session/screens/session_detail/state/refresh_anchor.dart`

## 后续开发约束

1. 会话页 build 热路径里不要优先通过 `findRenderObject()` 读取滚动视口尺寸。
2. 需要视口高度时，优先使用 `ScrollPosition.viewportDimension` 这类布局后稳定数据。
3. 所有 RenderBox helper 都必须先校验：
   - `attached`
   - `hasSize`
4. 看到 `RenderSemanticsGestureHandler hasSize` 这类错误时，先排查：
   - Scrollable
   - RawGestureDetector / GestureDetector
   - 构建期直接读 render object 几何信息
