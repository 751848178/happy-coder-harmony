# Session Tool Authorization Messages Should Not Flash Pending Before Auto Resolution

## Date
- 2026-04-08

## Symptom
- 操作授权类消息进入可视区时，会先渲染一版待确认或初始状态，然后很快切成自动处理/执行状态，导致消息高度变化和列表跳动。

## Root Cause
- 自动授权实际发生在消息首次渲染后的 effect 阶段，UI 首帧直接使用服务端 `pending` 状态渲染。
- 工具操作中的本地 in-flight 状态通过整页 `setState` 驱动，单条授权消息状态变化会带着整页消息列表一起重建。
- 授权消息的 footer 在 `pending -> approved/executing` 之间会切换甚至消失，造成行高收缩。

## Fix
- 把自动授权链路中的 `pending/approved/executing` 瞬时状态映射成统一的稳定视觉状态“自动处理中”。
- 把工具操作 in-flight 状态改成按 `toolId` 的细粒度 notifier，避免单条授权消息状态变化触发整页 rebuild。
- 给授权 footer 保留稳定的最小高度，减少刚进入可视区时的列表跳动。

## Guardrail
- 对会在首屏后立刻被 effect 改写的消息状态，不要直接把原始瞬时状态映射成完全不同的 UI 骨架。
- 长列表里的局部交互状态应尽量按行隔离，避免用整页 `setState` 驱动。
