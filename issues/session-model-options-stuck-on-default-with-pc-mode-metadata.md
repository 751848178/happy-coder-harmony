# 会话模型候选只剩 default 问题记录

## 背景

用户反馈移动端会话里的模型选择经常只看到 `default`，但 PC 端同类入口并不是这样工作的。排查后确认，问题不在“PC 没有模型来源”，而在 Flutter 端把 PC 的模型来源规则改错了。

## 根因定位

### 1. `modelOptionsForAgent(...)` 被错误改成了“无 metadata 就只剩 default”

- 文件：`lib/features/session/domain/session_creation_options_modes.dart`
- 上游事实：`/Users/zhaoxingbo/Workspace/ai-driven/happy/packages/happy-app/sources/components/modelModeOptions.ts` 里的 `getAvailableModels(...)` 明确是“优先 `metadata.models`，否则按 agent 使用 PC 的硬编码 fallback 列表”。
- Flutter 现状：`modelOptionsForAgent(...)` 在 `metadataOptions` 为空时只返回 `[default]`。
- 结果：只要当前会话 metadata 没带 `models`，移动端就会错误退回单一默认项；而 PC 同样场景下会展示 Claude / Codex / Gemini 各自的真实 fallback 列表。

### 2. 会话详情页和新建会话页都接错了 PC 的入口语义

- 文件：`lib/features/session/screens/session_screen_view_metadata.dart`
- 文件：`lib/features/session/screens/new_session_flow_screen_logic.dart`
- 上游事实：
  - 当前会话页 `SessionView.tsx` 只把“当前 session 的 `metadata`”传给 `getAvailableModels(...)`
  - 新建会话页 `app/(app)/new/index.tsx` 传的是 `null metadata`
- Flutter 现状：
  - 会话详情页把候选来源扩成了“当前 session -> 最近同机同 Agent session -> machine metadata”
  - 新建会话页也跟着走这条 metadata 回退链
- 结果：移动端模型候选的来源和 PC 本身已经不是一套规则，即使代码里新增了更多 metadata 提取能力，用户看到的列表仍然可能和 PC 不一致。

### 3. 默认模型 key 也被跟着改错了

- 文件：`lib/features/session/domain/session_creation_options_modes.dart`
- 上游事实：PC 的默认模型 key 是 `claude -> default`、`codex -> gpt-5-codex-high`、`gemini -> gemini-2.5-pro`。
- Flutter 现状：`defaultModelModeForAgent(...)` 之前随着错误 fallback 一起退成了 `default`。
- 结果：即使当前值解析优先级已经是 `session.modelMode -> metadata.currentModelCode -> defaultModelKey(flavor)`，最后一步默认值仍然会落错。

## PC 当前支持的真实模型来源

根据上游 `happy-app` 当前实现，PC 支持的模型候选来源只有这两类：

1. 当前会话 `metadata.models`
2. 当 `metadata.models` 为空时，按 agent 使用硬编码 fallback 列表

对应入口语义：

1. 当前会话页：`getAvailableModels(flavor, session.metadata, t)`
2. 新建会话页：`getAvailableModels(agentType, null, t)`

当前模型值解析规则：

1. `session.modelMode`
2. `metadata.currentModelCode`
3. `defaultModelKey(flavor)`

注意：

1. PC 当前并不会把“最近会话 metadata”或“machine metadata”当作模型候选来源
2. PC 的 `resolveCurrentOption(...)` 只会返回候选列表中真实命中的项，不会把未知 key 塞回列表，也不会自动选第一项

## 本次修复

- 恢复 `modelOptionsForAgent(...)` 的 PC fallback 列表，不再把无 metadata 场景压成单一 `default`
- 恢复 `defaultModelModeForAgent(...)` 对应的真实默认 key
- 会话详情页重新收回到“只看当前 session.metadata”的入口语义
- 新建会话页重新收回到“`null metadata` + 硬编码 fallback”的入口语义

## 后续约束

1. 只要是“模型候选列表”问题，第一步必须先对照上游 `modelModeOptions.ts`，不要再凭推测扩展来源
2. 不允许把“当前会话页”和“新建会话页”的模型来源混成一条链路，它们在 PC 上本来就是两个不同入口
3. 不允许再把“没有 `metadata.models`”误写成“PC 只能显示 default”
