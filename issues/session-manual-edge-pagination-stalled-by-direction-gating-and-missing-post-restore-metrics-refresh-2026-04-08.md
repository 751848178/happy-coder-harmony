# Session Manual Edge Pagination Stalled By Direction Gating And Missing Post-Restore Metrics Refresh

## Date
- 2026-04-08

## Symptom
- 手动把会话消息列表向更早历史方向拖到顶部边界后，只能停在某一页，不会继续加载前面的消息。

## Root Cause
- 详情页边界续页逻辑把 `ScrollPosition.userScrollDirection` 当成了硬前置条件，真实设备在边界回弹、停顿和 anchor 恢复后，这个值并不稳定，导致“已经到边界但不触发续页”。
- prepend 历史消息并恢复 viewport anchor 后，只刷新了 sticky prompt 相关状态，没有重新评估完整的 scroll metrics，因此“仍然处于边界附近”的状态不会立刻触发下一次历史续页检查。

## Fix
- 移除顶部/底部自动续页对瞬时 `userScrollDirection` 的强依赖，改为只依据边界距离、程序化滚动状态、冷却状态和 viewport ready 状态决定是否触发。
- 在 prepend/append 后恢复 anchor 的收尾阶段，补做一次完整的 scroll metrics 刷新，让边界状态和按钮状态及时收敛。

## Guardrail
- 边界续页不要依赖单一帧的滚动方向信号，尤其是在带回弹、锚点恢复、程序化 jump/restore 的长列表里。
- 任何会改变消息窗口但不一定触发 offset 变化的流程，都必须主动重新评估滚动边界状态。
