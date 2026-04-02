# 会话模型与 PC 脱节：socket `update-session` 的 metadata 未按协议解密

> 创建日期: 2026-03-31

## 问题概述

移动端会话模型选项和 PC 当前实际可用模型没有对齐。

表面现象是：

- PC 端会话 metadata 已经更新了 `models/currentModelCode`
- 移动端仍停留在旧 metadata，继续显示旧模型列表或 fallback 列表

## 真正根因

- 文件：`lib/features/socketio/data/socket_repository_updates.dart`
- 旧逻辑在处理 `update-session` 时，对 `metadata.value` 和 `agentState.value` 只做了 `_decodeMaybeJsonMap(...)`
- 但协议里的 `update-session.body.metadata.value` / `agentState.value` 是**加密串**，不是普通 JSON
- 结果是：
  - socket 实时推送过来的 session metadata 更新没有真正落到本地 session
  - `metadata.models`、`metadata.currentModelCode`、`metadata.operatingModes` 等字段保持陈旧
  - UI 最终只能继续用旧值或 fallback

## 正确约束

1. `update-session` 必须和 session API 加载使用同一套解密语义。
2. 只要 session metadata 依赖 session data key，就必须有一个共享、可复用的 key store，不能让 socket 层“猜测 JSON”。
3. 模型/权限 UI 的正确性依赖 metadata 实时更新，不能只修 UI fallback，而不修 metadata 更新链。

## 本次修复

- 新增 `SessionDataKeyStore`
- session 远端解析成功后，把 session data key 同步进共享 key store
- socket `update-session` 改为：
  - 先尝试用 session data key 解密
  - 再回退到 account secret
  - 成功后再更新 session metadata / agentState

## 开发约束

1. 任何来自协议层的 `metadata.value` / `agentState.value`，都要先确认是否为加密载荷。
2. 如果 UI 依赖 `metadata.models/currentModelCode`，优先检查 metadata 更新链是否真实生效，不要先改 fallback 列表。
3. session 数据 key 的生命周期必须和 session 生命周期同步清理，避免旧 key 污染后续解密。
