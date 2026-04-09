# Session Fast History Scroll Stall And Window Flicker Diagnostics

## Date
- 2026-04-08

## Repro
- 手动快速滑动查看历史消息。
- 滑到某一条消息后无法继续向上翻。
- 先向下翻，再向上翻，多次重复后消息开始来回闪动。
- 最终才看到更早甚至最早的消息。

## Diagnostic Focus
- 边界自动续页在“卡住”当下为何没有继续触发。
- prepend/append 历史页后，窗口起点、已加载条数、scroll extent、offset 如何变化。
- anchor 恢复在闪动前后是否命中、是否仍在窗口内、是否仍有 row context。

## Added Logs
- `SessionEdgeDiag`
  - 近顶部/底部时的 scroll metrics、block reason、窗口状态、archive 可访问状态。
- `SessionWindowDiag`
  - `load-older/load-newer` 前后的窗口 delta、offset delta、max scroll delta。
- `SessionAnchorDiag`
  - anchor 捕获、等待恢复、恢复成功、恢复放弃时的消息索引、前后邻居、row context 数量。

## Goal
- 用最少噪音确认问题到底是：
  - 边界判断被错误拦截，
  - 窗口装载后 offset 恢复错误，
  - anchor 丢失导致的恢复失败，
  - 还是上下方向的自动续页互相打架。
