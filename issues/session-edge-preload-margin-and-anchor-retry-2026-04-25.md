# 会话虚拟列表预加载过晚与锚点恢复单帧化导致跳动

**日期**: 2026-04-25
**严重级别**: P0 Critical
**状态**: 已修复

## 现象

- 用户上翻历史时，往往要非常接近顶部才开始加载下一批消息。
- 历史批次切换后，消息列表仍会出现明显弹跳。

## 这次确认的具体问题

### 根因 1：边缘加载阈值还不够像 `rootMargin`

`viewport/viewport_controller.dart` 中的自动续页触发阈值只按：

- `viewport * 0.78`
- 或最小 `220`

来计算。

这虽然不是“贴边才触发”，但对历史列表仍然偏晚。用户已经进入明显靠近边缘的位置时，
续页才开始准备，渲染链路容易和当前滚动手势重叠，放大抖动感。

### 根因 2：锚点恢复仍然是“单帧假设”

`state/refresh_anchor.dart` 中 `_restoreMessageViewportAnchorAfterFrame()` 只等待一帧，
随后就假设：

- row context 已经重新注册
- render box 已经稳定

但实际历史窗口切换后，row context 常常会在后续一两帧才稳定回来。
单帧恢复要么直接 miss，要么在布局尚未稳定时过早 `jumpTo`，就会造成新的可见跳动。

这与既有问题记录 `session-anchor-restore-needs-multi-frame-retry-and-programmatic-guard-2026-04-08.md`
描述的根因是一致的，说明当时的多帧恢复没有完整落地。

## 修复方案

- 将边缘自动加载阈值改成更接近 `rootMargin` 语义：
  - `viewport * 1.0 + 180px lead margin`
- 锚点恢复改为最多跨 4 帧重试：
  - 优先等待真实 row anchor 可用
  - 只有多帧后仍拿不到 anchor，才退回 ratio fallback
  - 对齐误差进入容忍范围后立即停止

## 修改文件

- `lib/features/session/screens/session_detail/viewport/viewport_controller.dart`
- `lib/features/session/screens/session_detail/state/refresh_anchor.dart`

## 后续开发约束

1. 虚拟列表的历史分页触发阈值应按“预加载提前量”设计，而不是只按“接近可视边缘”设计。
2. 任何依赖行级 `BuildContext` 的视口恢复，都不能假设下一帧必然可用。
3. 锚点恢复要么多帧等待稳定，要么显式 fallback，不能继续维持单帧乐观假设。
