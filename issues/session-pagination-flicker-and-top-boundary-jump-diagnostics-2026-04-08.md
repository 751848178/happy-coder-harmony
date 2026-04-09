# Session Pagination Flicker And Top Boundary Jump Diagnostics

## Date
- 2026-04-08

## Goal
- 诊断“滚动分页时消息闪动”和“到顶后仍跳到最老窗口末端附近”这两类问题。

## Instrumentation Added
- `SessionJumpDiag`
  - 顶部/底部边界为什么没有触发续页
  - 自动滚到最新消息的 effect 触发时机
  - prepend/append/load-earliest/load-latest 完成后，当前窗口、滚动位置、可视消息首尾
- `SessionArchive`
  - 保留原有边界装载和窗口切换日志，辅助对照

## Guardrail
- 长列表分页问题优先记录“触发条件 + 触发后窗口摘要 + 当前可视首尾消息”，不要只记录抽象状态，否则很难判断是触发没发生，还是触发后又被别的滚动逻辑覆盖。
