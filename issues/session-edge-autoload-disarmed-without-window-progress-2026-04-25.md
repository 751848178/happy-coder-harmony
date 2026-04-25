# 会话页历史上翻卡死：edge autoload 在无窗口推进时被提前 disarm

**日期**: 2026-04-25
**严重级别**: P0 Critical
**状态**: 已修复

## 现象

- 消息列表上翻到某个位置后会突然无法继续上翻。
- 用户已经贴近顶部，但继续上翻不再触发更早历史加载。
- 同时伴随明显跳动，因为视口在顶部附近重复进入“准备加载但没有实际推进”的状态。

## 这次确认的具体问题

`viewport/edge_autoload.dart` 中，顶部/底部自动续页在刚进入 `eligible` 时，就会立刻：

- `_topEdgeAutoloadArmed = false`
- `_bottomEdgeAutoloadArmed = false`

但后续异步链路存在多种“没有真正推进窗口”的情况，例如：

- 历史尚未 ready
- ready 之后 `hasOlderMessages` / `hasNewerMessages` 已变化
- 加载链路走完但 resident window 实际没变化

原实现里，这些 no-op 路径不会把 armed 状态恢复。结果就是：

1. 用户仍然停留在边缘位置。
2. 由于 autoload 已被 disarm，不会再次触发续页。
3. 又因为用户没有足够空间滚回去跨过 rearm gap，于是列表就卡死在那个位置。

## 修复方案

- 在 top-edge / bottom-edge 自动续页中记录触发前的：
  - `windowStartIndex`
  - `loaded message count`
- 只要异步链路结束后发现消息窗口没有任何推进，就自动 rearm 对应边缘。
- 同时记录 rearm 原因，便于后续继续对真机日志核对。

## 修改文件

- `lib/features/session/screens/session_detail/viewport/edge_autoload.dart`

## 后续开发约束

1. edge autoload 只能在“确认窗口已经推进”后保持 disarm。
2. 任何异步续页链路只要最终没有改变 resident window，都必须恢复边缘 armed 状态。
3. 顶部/底部 edge load 的状态机不能只考虑成功路径，必须显式覆盖 no-op 和短路路径。
