# 模型模式与 PC 不一致问题记录

## 背景

本次问题表现为移动端的模型列表、当前模型显示和实际发送时使用的模型，与 PC 端不一致；同时从 PC 创建或克隆过来的会话，在移动端也可能出现模型模式错位。

## 2026-03-31 当前生效规则

以下内容用于整理“现在 PC 支持的让移动端获取实际可用模型的方式”；如果和下文历史排查记录有冲突，以这一节为准。

### 1. PC 当前的模型候选来源是“metadata 优先，fallback 次之”

- 参考文件：
  - `/Users/zhaoxingbo/Workspace/ai-driven/happy/packages/happy-app/sources/components/modelModeOptions.ts`
  - `/Users/zhaoxingbo/Workspace/ai-driven/happy/packages/happy-cli/src/agent/acp/runAcp.ts`
  - `/Users/zhaoxingbo/Workspace/ai-driven/happy/packages/happy-cli/src/agent/acp/sessionConfigMetadata.ts`
- 规则：
  1. 有 `metadata.models`：直接使用这份真实列表
  2. 没有 `metadata.models`：按 agent 使用 PC 自己的硬编码 fallback 列表
- 说明：
  - Flutter 端之前一版把 fallback 全砍掉，错误地改成了“只允许 metadata”。
  - 这会让移动端在没有 metadata 时出现空态提示，和 PC 实际行为不一致。

### 2. `session.modelMode` 的默认语义和“UI 默认高亮项”不是一回事

- 参考文件：`/Users/zhaoxingbo/Workspace/ai-driven/happy/packages/happy-app/sources/-session/SessionView.tsx`
- 解析顺序：`session.modelMode -> metadata.currentModelCode -> defaultModelKey(flavor)`。
- 关键约束：
  - `session.modelMode` 里的默认语义仍然是 `default`
  - `defaultModelKey(flavor)` 只用于“当前高亮项/新建会话默认选项”的 UI fallback
  - 不能把 `gpt-5-codex-high / gemini-2.5-pro` 这类 UI fallback key 直接当成会话默认 `modelMode`
- 含义：如果把“UI 默认高亮 key”和“实际持久化的默认 mode”混成一个值，移动端会在模型展示、保存和发消息时一起跑偏。

### 3. PC 对“当前选中项”的要求也很明确

- 参考文件：`/Users/zhaoxingbo/Workspace/ai-driven/happy/packages/happy-app/sources/components/modelModeOptions.ts`
- 规则：`resolveCurrentOption(...)` 只会返回候选列表里真实命中的项；如果所有 key 都没命中，就返回 `null`。
- 含义：移动端不能把未知 key 塞回候选列表，也不能在未命中时偷偷改成第一项已选中。

### 4. 新建会话要继续对齐 PC 的历史选择逻辑

- 参考文件：`/Users/zhaoxingbo/Workspace/ai-driven/happy/packages/happy-app/sources/app/(app)/new/index.tsx`
- 规则：
  1. 新建会话候选列表沿用 PC fallback 列表
  2. 初始选中项继续读取 `lastUsedModelMode`
  3. 创建成功后继续写回 `lastUsedModelMode`
- 说明：Flutter 端之前一版把这条链路直接删掉了，导致新建会话页一边没有 PC fallback，一边还丢了最近使用模型。

## 2026-03-31 新增补充

### 6. 候选列表来源修对了，不代表当前模型状态恢复也自动正确

- 文件：`lib/features/session/domain/session_service_session_parsing.dart`
- 文件：`lib/features/session/domain/session_service.dart`
- 说明：即使移动端已经按 PC 规则拿到了正确的候选列表，如果远端会话刷新时仍直接用 `metadata.currentModelCode` 重建 `session.modelMode`，用户在移动端刚选好的模型依然会被冲回远端默认值。
- 含义：模型问题至少要拆成两层处理：
  1. 候选列表从哪里来
  2. 当前选中的本地模型如何跨刷新保留

### 7. `session.modelMode` 必须按“本地当前覆盖值”处理

- 参考文件：`/Users/zhaoxingbo/Workspace/ai-driven/happy/packages/happy-app/sources/-session/SessionView.tsx`
- 参考文件：`/Users/zhaoxingbo/Workspace/ai-driven/happy/packages/happy-app/sources/sync/messageMeta.ts`
- 规则：PC 当前展示和发消息都优先使用本地 `session.modelMode`，这说明它不是远端 metadata 的镜像字段，而是本地当前覆盖值。
- 约束：移动端在远端刷新、缓存恢复、冷启动恢复时，都必须先保留本地显式模型选择，再回退到远端 metadata 当前值。

## 根因定位

### 1. 新建会话流程没有接入模型模式

- 文件：`lib/features/session/screens/new_session_flow_screen.dart`
- 文件：`lib/features/session/screens/new_session_flow_screen_seed.dart`
- 文件：`lib/features/session/screens/new_session_flow_screen_pickers.dart`
- 文件：`lib/features/session/screens/new_session_flow_screen_create.dart`
- 根因：新建会话流程虽然已经接收了 `initialModelMode` 路由参数，也有 `SettingsState.lastUsedModelMode`，但页面本身没有模型状态、没有模型设置 UI，也没有把模型模式传给 `spawnSession()`。
- 结果：新建会话、克隆会话、复用上次选择时，模型模式会被直接丢失，表现和 PC 不一致。

### 2. 当前模型解析优先级与上游相反

- 文件：`lib/features/session/screens/session_screen_view_metadata.dart`
- 文件：`lib/features/session/domain/session_service_metadata.dart`
- 根因：Flutter 端以前优先使用 `metadata.currentModelCode`，再退回 `session.modelMode`。而上游项目的会话页逻辑是先看本地 `session.modelMode`，再看 `metadata.currentModelCode`。
- 结果：当本地已有模型覆盖值，但远端 metadata 仍是旧值时，移动端会把旧值显示出来，导致当前模型和 PC 端不一致。

### 3. 发送消息时仍然读取旧 metadata 模型

- 文件：`lib/features/session/domain/session_service_metadata.dart`
- 根因：发送消息组装 `meta.model` 时，Flutter 端以前优先读取 `metadata.currentModelCode`；上游项目 `messageMeta.ts` 明确只使用本地 `session.modelMode`。
- 结果：即使界面上用户刚切换了模型，首条消息也可能仍然按旧模型发出。

### 4. 克隆会话时模型参数来源错误

- 文件：`lib/features/session/screens/session_screen_state_clone.dart`
- 文件：`lib/features/session/screens/session_info_screen_actions.dart`
- 根因：克隆会话路由参数以前优先带 `metadata.currentModelCode`，不是 `session.modelMode`。
- 结果：从已有会话派生新会话时，模型选择可能回退到旧 metadata 值。

## 上游对齐原则

参考上游仓库 `/Users/zhaoxingbo/Workspace/ai-driven/happy`：

- `packages/happy-app/sources/components/modelModeOptions.ts`
  规则：模型列表优先使用 `metadata.models`，没有就使用 flavor 对应的硬编码默认列表。
- `packages/happy-app/sources/-session/SessionView.tsx`
  规则：当前模型解析优先级为 `session.modelMode -> metadata.currentModelCode -> defaultModelKey(flavor)`。
- `packages/happy-app/sources/sync/messageMeta.ts`
  规则：发送消息时只使用本地 `session.modelMode`，不回退到 `metadata.currentModelCode`。
- `packages/happy-app/sources/app/(app)/new/index.tsx`
  规则：新建会话流程维护独立 `modelMode` 状态，写入 `lastUsedModelMode`，成功创建后调用 `updateSessionModelMode()`。

## 本次修复

- 恢复 `modelOptionsForAgent(...)` 与 `newSessionModelOptionsForAgent(...)` 的 PC fallback 列表。
- 新增“UI 默认高亮 key”与“默认 `modelMode` 语义”的分离：
  - `defaultModelOptionKeyForAgent(...)` 只用于候选项选中态与新建会话默认项
  - `defaultModelModeForAgent(...)` 继续保留 `default` 语义
- 新建会话恢复 `lastUsedModelMode` 的读取与保存，不再显示“等待 PC/CLI 同步模型列表”的额外空态文案。
- 会话页当前模型解析继续遵守 `session.modelMode -> metadata.currentModelCode -> defaultModelKey(flavor)`。

## 后续开发约束

- 所有“当前模式”展示逻辑都要遵守相同优先级：本地 `session.xxxMode` 优先于 `metadata.current...Code`。
- 发送消息时不要从 metadata 回推模型模式，metadata 只能作为远端默认值，不能覆盖本地当前选择。
- 新建、克隆、重建会话这类入口，只要支持权限模式，就必须同步支持模型模式，并写入最近使用设置。
- 如果上游已经定义了模式解析规则，移动端必须直接对齐，不要自行重写另一套优先级。

## 2026-03-26 二次补充

### 5. 远端会话解析仍会把旧本地偏好倒灌回当前模式

- 文件：`lib/features/session/domain/session_service_session_parsing.dart`
- 根因：远端 session 解析链之前仍可能把本地缓存/偏好重新参与优先级计算，导致移动端显示出来的 mode 和 PC 当前会话状态不一致。
- 修复：远端解析改成只按 `metadata.current...Code -> session.xxxMode` 还原，不再把本地旧 preference 混入远端默认值解析。

### 6. 新建会话页会把未知但有效的当前模型强制改回 fallback

- 文件：`lib/features/session/domain/session_creation_options_modes.dart`
- 文件：`lib/features/session/screens/new_session_flow_screen_content.dart`
- 根因：当 PC 当前模型 key 暂时不在移动端 fallback 列表里时，Flutter 端以前会在页面构建时把它自动纠正成默认模型，导致显示值和真实值重新分叉。
- 修复：`resolveModeSelection(...)` 现在保留未知但有效的当前 key，`resolveCurrentModeOption(...)` 用于把这个 key 原样展示出来，不再强制回退。

### 新增约束

- 页面构建阶段不能把“未知 key”直接等价成“非法 key”；只要它来自已知会话状态，就应该优先展示真实值。
- 远端 session 解析不要再混入本地 preference；本地 preference 只属于“最近使用/默认选中”这类入口状态，不属于远端当前会话状态。

## 2026-03-26 三次补充

### 7. 新建会话的“可选模型列表”不应该继续跟随远端 metadata

- 文件：`lib/features/session/screens/new_session_flow_screen_logic.dart`
- 文件：`lib/features/session/domain/session_creation_options_modes.dart`
- 根因：Flutter 端此前把“当前会话显示逻辑”和“新建会话可选项逻辑”混在了一起。虽然上游通用组件支持 `metadata.models` 覆盖，但 PC 新建会话入口 `packages/happy-app/sources/app/(app)/new/index.tsx` 实际传入的是 `null metadata`，因此新建页展示的是按 agent 固定的 fallback 列表，不会被历史 session 或 machine metadata 改写。
- 修复：新增 `newSessionPermissionOptionsForAgent(...)` 与 `newSessionModelOptionsForAgent(...)`，新建会话页只按 agent 固定选项出列表，保留已有 mode metadata 解析能力给“当前会话状态还原”这类场景使用。

### 新增约束

- “当前值解析”和“可选项来源”必须分离处理：当前值可以来自远端 metadata，会话新建页的可选项则必须先对齐 PC 的入口规则。
- 不要因为某台机器最近上报过自定义模型，就让移动端新建会话页和 PC 展示出不同的可选模型集合。

## 2026-03-27 四次补充

### 8. 会话详情把“不在候选列表中的当前 key”硬塞回模型列表

- 文件：`lib/features/session/screens/session_screen_view_metadata.dart`
- 根因：移动端会话详情此前会把 `session.modelMode / metadata.currentModelCode` 里命中的未知 key 重新插入可选项列表；而上游 PC `packages/happy-app/sources/-session/SessionView.tsx` 只会用 `metadata.models` 或 fallback 列表作为候选集，不会把未知 key 注入候选项。
- 结果：当移动端本地还保留了历史 key，或者远端当前 key 暂时不在候选集里时，移动端会话详情弹出的模型列表会比 PC 多出一项，肉眼看起来就是“不一致”。
- 修复：会话详情里的模型/权限候选项现在只使用真实候选来源，不再把当前未知 key 注入列表；当前选中值单独按“列表内匹配”解析。

### 9. 会话详情在“当前 key 不在候选列表里”时仍然偷偷回退到第一项

- 文件：`lib/features/session/screens/session_screen_view_metadata.dart`
- 文件：`lib/features/session/screens/session_screen_view_command_logic.dart`
- 根因：Flutter 端虽然已经不再把未知 key 插回候选列表，但当前会话页仍然会在“没有任何候选命中”时，把当前选中项回退成 `options.first`。而上游 PC `packages/happy-app/sources/components/modelModeOptions.ts` 的 `resolveCurrentOption(...)` 明确是“只返回命中的候选项，否则返回 null”。
- 结果：当 `session.modelMode / metadata.currentModelCode` 已经过期、还没同步、或暂时不在当前候选集里时，Flutter 弹层会把第一项错误地显示成已选中；PC 则是不选中任何项。用户肉眼看到的就是“模型选择还是和 PC 不一致”。
- 修复：新增“只匹配候选集内 key”的 helper，会话详情里的模型/权限弹层改为仅在真实命中候选项时才显示选中态；控制条文案则优先显示命中的候选标签，否则显示真实当前 key 或“未设置”，不再伪造第一项选中。

### 新增约束

- 新建会话和会话详情要分别对齐上游入口语义，不能复用一套“当前值并入候选项”的逻辑。
- “展示当前 key”和“决定可选列表”是两个独立问题，不能因为需要展示当前值，就篡改候选项集合本身。
- 上游 `resolveCurrentOption(...)` 这类 helper 如果是“未命中返回 null”，Flutter 端不能擅自再加一层 `options.first` 兜底，否则视觉上的“已选中态”一定会和上游分叉。
