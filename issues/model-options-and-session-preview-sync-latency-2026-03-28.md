# 模型选项来源与会话列表消息同步延迟问题记录（2026-03-28）

## 2026-03-31 修正说明

- 本文里关于“模型候选只能来自 `metadata.models`”和“新建会话不再读取 `lastUsedModelMode`”的结论，已被 2026-03-31 的最新规则覆盖。
- 当前正确规则是：
  1. 模型候选：`metadata.models` 优先，没有时回退到 PC 自己的 fallback 列表
  2. 新建会话：继续读取/写回 `lastUsedModelMode`
  3. `session.modelMode` 的默认语义仍然是 `default`，不能和 UI 的默认高亮 key 混用
- 这份文档保留为 2026-03-28 当时的排查历史，不再代表当前实现。

## 背景
- 现象 A：模型选择和 PC 不一致。移动端在没有 PC `metadata.models` 时仍展示本地硬编码模型列表。
- 现象 B：新建会话会带入本地 `lastUsedModelMode`，即使该 key 不在当前可选项中。
- 现象 C：会话列表中消息预览更新慢，且在会话较多时刷新压力明显增大。

## 根因定位

### 1. 模型候选项仍然存在本地 fallback 列表
- 文件：`lib/features/session/domain/session_creation_options_modes.dart`
- 根因：`modelOptionsForAgent(...)` 在 `metadata.models` 为空时，仍返回 codex/gemini/claude 的本地硬编码多模型列表。
- 影响：只要 PC 没回传模型集合，移动端就会展示额外模型，和 PC 候选集不一致。

### 2. 新建会话仍读取本地“上次模型”
- 文件：`lib/features/session/screens/new_session_flow_screen_seed.dart`
- 根因：`initialModel` 解析把 `settings.lastUsedModelMode` 作为优先候选之一。
- 影响：会把历史本地模型 key 带回新会话，偏离“只按 PC 返回候选或默认项”的规则。

### 3. 会话列表后台刷新负载过大导致可见会话更新被拖慢
- 文件：
  - `lib/features/session/domain/session_service_messages.dart`
  - `lib/features/session/screens/sessions_screen.dart`
  - `lib/features/session/data/session_repository_messages.dart`
- 根因：
  - 列表后台刷新会按批次扫描大量 session，且每个 session 默认可能跑完整分页循环。
  - 刷新排序偏向稳定创建时间，不优先最近活跃会话。
  - `applyMessages(...)` 在已有缓存分支没有把 `isLoaded` 置为 `true`，会导致“已同步但仍显示待同步”的状态滞留风险。

## 修复方案

### A. 模型来源统一收敛
- `modelOptionsForAgent(...)` 规则改为：
  - 有 `metadata.models`：直接使用 PC 返回列表。
  - 无 `metadata.models`：只返回单一默认项 `default`。
- 新增 `resolveListedModeSelection(...)`，用于“只允许命中候选项，否则回退默认”的严格选择逻辑。

### B. 新建会话移除本地模型兜底
- 不再读取 `settings.lastUsedModelMode` 作为新建会话初始模型。
- 新建会话不再写入 `setLastUsedModelMode(...)`。
- 新建会话模型选择统一走 `resolveListedModeSelection(...)`，确保不出现候选外 key。

### C. 会话列表消息同步性能优化
- `loadSessionMessages(...)` 新增 `maxPages`（可选）用于受控分页。
- `refreshSessionMessageSnapshots(...)` 新增 `maxPagesPerSession`，并仅对“已加载过消息”的会话启用分页上限，避免首次加载截断。
- 列表后台同步优先按 `updatedAt`（recency）排序。
- 限制每轮尾部会话刷新数量，采用游标轮转，避免一次性扫全量尾部会话。
- 预览刷新路径对已加载会话启用小页数上限，降低实时事件场景的延迟抖动。
- `applyMessages(...)` 统一把更新后快照标记为 `isLoaded: true`，避免“已拉取但仍待同步”的错误状态。

## 本次修改文件
- `lib/features/session/domain/session_creation_options_modes.dart`
- `lib/features/session/screens/new_session_flow_screen_seed.dart`
- `lib/features/session/screens/new_session_flow_screen_logic.dart`
- `lib/features/session/screens/new_session_flow_screen_content.dart`
- `lib/features/session/screens/new_session_flow_screen_create.dart`
- `lib/features/session/domain/session_service_messages.dart`
- `lib/features/session/screens/sessions_screen.dart`
- `lib/features/session/data/session_repository_messages.dart`
- `lib/app/widgets/session_background_refresh_gate.dart`
- `lib/features/settings/screens/settings_screen_actions.dart`
- `lib/features/auth/presentation/terminal_connect_screen_actions.dart`
- `lib/features/home/screens/home_screen_refresh.dart`
- `test/session_creation_options_test.dart`

## 后续约束
- 模型候选项的“真实来源”只能是 PC `metadata.models`；移动端不得再维护本地多模型 fallback。
- 新建会话模型必须是候选集内 key，禁止把本地历史 key 当作有效候选。
- 列表层只能做增量预览同步；全量历史补齐应保留在显式“同步全部消息”链路中。
