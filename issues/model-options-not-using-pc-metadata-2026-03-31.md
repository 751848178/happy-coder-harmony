# 新建会话和会话详情的模型选项未使用 PC 元数据

> 创建日期: 2026-03-31

## 问题概述

新建会话和会话详情页面的模型选项列表未使用 PC 提供的元数据，始终回退到硬编码列表，导致与 PC 端显示不一致。

## 根因

### 根因 1：新建会话不读取 machine metadata

- 文件：`lib/features/session/screens/new_session_flow_screen_logic.dart`
- `_sessionFlowModelOptions()` 只调用 `newSessionModelOptionsForAgent(agent)` 不传 `metadataOptions`
- 导致 `modelOptionsForAgent()` 永远走硬编码分支

### 根因 2：模型模式 fallback 使用错误的默认函数

- 文件：`new_session_flow_screen_logic.dart`
- `_syncSessionFlowModeSelections()` 中 fallback 用了 `defaultModelOptionKeyForAgent()`
- 该函数返回硬编码第一个模型 key（如 Claude 的 "default"、Codex 的 "gpt-5-codex-high"）
- 应使用 `defaultModelModeForAgent()` 始终返回 "default"（即 "使用 CLI 设置"）

### 根因 3：会话详情模型 key 解析使用错误的默认函数

- 文件：`lib/features/session/screens/session_screen_view_metadata.dart`
- `_currentModelKeys()` 使用 `defaultModelOptionKeyForAgent(flavor)` 作为 fallback
- 应使用 `defaultModelModeForAgent(flavor)` 保持 "使用 CLI 设置" 语义

## 修复

1. `_sessionFlowModelOptions()` 现在从 `sessionStateProvider` 读取 machine metadata，提取 `operatingModes.models` 传给 `newSessionModelOptionsForAgent()`
2. `_syncSessionFlowModeSelections()` fallback 改为 `defaultModelModeForAgent()`
3. `_currentModelKeys()` fallback 改为 `defaultModelModeForAgent()`
