# 修正说明：此前“模型候选只能使用 metadata”这个结论不准确（2026-03-31）

## 背景

- 用户预期：移动端展示的模型候选，必须和 PC/CLI 当前真实可用模型一致。
- 这份记录里的早期结论有误：PC 实际不是“只能用 metadata”，而是“先用 metadata，没有就退回 PC 自己维护的 fallback 列表”。

## 修正后的结论

### 1. PC 实际规则

- `metadata.models` 是最高优先级的真实候选来源。
- 当 `metadata.models` 缺失时，PC 仍会按 agent 展示自己的 fallback 列表。
- 新建会话页也继续读取/写入 `lastUsedModelMode`，不是直接清空成空态。

## 本次修复

- 恢复 PC fallback 列表，而不是继续显示空态说明。
- 保留 `lastUsedModelMode` 的读取和写回，使新建会话行为和 PC 保持一致。
- 同时把“UI 默认高亮模型 key”和“会话默认 `modelMode=default` 语义”拆开，避免再把两层概念混成一个字段。

## 后续约束

- 以后遇到“PC 候选列表”和“移动端默认值”问题时，先区分：
  1. 候选列表从哪里来
  2. UI 默认高亮 key 是什么
  3. `session.modelMode` 的默认语义是什么
- 不允许再把这三层概念写进同一个 helper 里。
