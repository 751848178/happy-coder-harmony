# Happy Coder GitHub (slopus/happy) 功能对比分析

## 概述

- **GitHub 原项目**: slopus/happy (React Native / TypeScript)
- **本地项目**: happy-coder-flutter (Flutter / Dart)
- **分析日期**: 2026-03-04

---

## 一、页面路由对比

### GitHub slopus/happy 项目路由

| 路由 | 名称 | 功能描述 |
|------|------|---------|
| `/` | index | 首页/欢迎页 |
| `/inbox/index` | inbox | 收件箱 - 好友请求和通知 |
| `/settings/index` | settings | 主设置页面 |
| `/settings/account` | - | 账户设置 |
| `/settings/appearance` | - | 外观设置 |
| `/settings/features` | features | 功能设置 |
| `/settings/language` | - | 语言设置 |
| `/settings/profiles` | profiles | AI配置文件 |
| `/settings/usage` | usage | 使用统计 |
| `/settings/voice` | - | 语音设置 |
| `/settings/connect/claude` | - | 连接到Claude |
| `/session/[id]` | - | 会话详情页 |
| `/session/[id]/message/[messageId]` | - | 消息详情 |
| `/session/[id]/info` | - | 会话信息 |
| `/session/[id]/files` | - | 会话文件 |
| `/session/[id]/file` | - | 文件查看器 |
| `/session/recent` | - | 最近会话 |
| `/new/pick/machine` | - | 选择机器 |
| `/new/pick/path` | - | 选择路径 |
| `/new/pick/profile-edit` | - | 编辑配置文件 |
| `/new/index` | - | 新建会话向导 |
| `/machine/[id]` | - | 机器详情 |
| `/terminal/connect` | - | 连接终端 |
| `/terminal/index` | - | 终端列表 |
| `/terminal/terminal-approval` | - | 终端审批 |
| `/restore/index` | - | 链接新设备 |
| `/restore/manual` | - | 手动恢复密钥 |
| `/friends/index` | - | 好友列表 |
| `/friends/search` | - | 添加好友 |
| `/user/[id]` | - | 用户资料详情 |
| `/text-selection` | - | 文本选择 |
| `/artifacts/index` | - | 工件列表 |
| `/artifacts/[id]` | - | 工件详情 |
| `/artifacts/new` | - | 新建工件 |
| `/artifacts/edit/[id]` | - | 编辑工件 |
| `/changelog` | - | 更新日志 |
| `/dev/index` | - | 开发工具 |

### 本地 happy-coder-flutter 项目路由

| 路由 | 名称 | 状态 |
|------|------|------|
| `/auth` | QR 登录 | ✅ 已实现 |
| `/login` | 密钥备份 | ✅ 已实现 |
| `/backup-keys` | 备份密钥 | ✅ 已实现 |
| `/login-test` | 登录测试 | ✅ 已实现 |
| `/link-account` | 链接账户 | ✅ 已实现 |
| `/restore` | 手动恢复 | ✅ 已实现 |
| `/encryption` | 加密设置 | ✅ 已实现 |
| `/socket` | Socket 连接 | ✅ 已实现 |
| `/chat` | 聊天 | ✅ 已实现 |
| `/` | 首页 | ✅ 已实现 |
| `/sessions` | 会话列表 | ✅ 已实现 |
| `/session` | 会话详情 | ✅ 已实现 |
| `/session/new` | 新建会话 | ✅ 已实现 |
| `/settings` | 设置 | ✅ 已实现 |
| `/settings/account` | 账户设置 | ✅ 已实现 |
| `/settings/notifications` | 通知设置 | ✅ 已实现 |
| `/settings/appearance` | 外观设置 | ✅ 已实现 |
| `/settings/security` | 安全设置 | ✅ 已实现 |
| `/settings/about` | 关于 | ✅ 已实现 |
| `/profile` | 个人资料 | ✅ 已实现 |
| `/profiles` | 资料列表 | ✅ 已实现 |
| `/profile/detail` | 资料详情 | ✅ 已实现 |
| `/tools/bash` | Bash 工具 | ✅ 已实现 |
| `/tools/edit` | Edit 工具 | ✅ 已实现 |
| `/tools/write` | Write 工具 | ✅ 已实现 |
| `/tools/todo` | Todo 工具 | ✅ 已实现 |
| `/tools/mcp` | MCP 工具 | ✅ 已实现 |
| `/friends` | 好友 | ✅ 已实现 |
| `/user/profile` | 用户资料 | ✅ 已实现 |
| `/inbox` | 收件箱 | ✅ 已实现 |

---

## 二、缺失的页面/功能对比

### 本地项目缺失的功能

| 功能 | GitHub 路由 | 状态 | 优先级 |
|------|-------------|------|--------|
| **会话消息详情** | `/session/[id]/message/[messageId]` | ❌ 未实现 | 高 |
| **会话信息页面** | `/session/[id]/info` | ✅ 已实现 | 中 |
| **会话文件列表** | `/session/[id]/files` | ✅ 已实现 | 高 |
| **文件查看器** | `/session/[id]/file` | ✅ 已实现 | 高 |
| **最近会话** | `/session/recent` | ❌ 未实现 | 中 |
| **机器选择** | `/new/pick/machine` | ❌ 未实现 | 高 |
| **路径选择** | `/new/pick/path` | ❌ 未实现 | 高 |
| **配置文件编辑** | `/new/pick/profile-edit` | ❌ 未实现 | 高 |
| **增强的会话创建向导** | `/new/index` | ⚠️ 简化版 | 高 |
| **机器详情** | `/machine/[id]` | ❌ 未实现 | 中 |
| **终端连接** | `/terminal/connect` | ⚠️ 部分实现 | 中 |
| **终端审批** | `/terminal/terminal-approval` | ❌ 未实现 | 高 |
| **文本选择** | `/text-selection` | ❌ 未实现 | 低 |
| **工件列表** | `/artifacts/index` | ✅ 已实现 | 高 |
| **工件详情** | `/artifacts/[id]` | ✅ 已实现 | 高 |
| **新建工件** | `/artifacts/new` | ✅ 已实现 | 高 |
| **编辑工件** | `/artifacts/edit/[id]` | ✅ 已实现 | 高 |
| **更新日志** | `/changelog` | ❌ 未实现 | 低 |
| **功能设置** | `/settings/features` | ❌ 未实现 | 中 |
| **语言设置** | `/settings/language` | ✅ 已实现 | 中 |
| **AI配置文件** | `/settings/profiles` | ✅ 已实现 | 高 |
| **使用统计** | `/settings/usage` | ✅ 已实现 | 中 |
| **语音设置** | `/settings/voice` | ❌ 未实现 | 中 |
| **连接Claude** | `/settings/connect/claude` | ❌ 未实现 | 中 |
| **添加好友搜索** | `/friends/search` | ❌ 未实现 | 中 |

---

## 三、工具/功能对比

### GitHub slopus/happy 支持的工具

| 工具名称 | 功能描述 | 本地实现 |
|----------|----------|---------|
| Bash | 终端命令执行 | ⚠️ 简化模拟 |
| Edit | 文件编辑 | ⚠️ 简化版 |
| Write | 文件写入 | ⚠️ 简化版 |
| Todo | 待办事项管理 | ⚠️ 简化版 |
| Glob | 文件搜索 | ✅ 已实现 |
| Grep | 内容搜索 | ✅ 已实现 |
| LS | 目录列表 | ✅ 已实现 |
| Read | 文件读取 | ⚠️ 部分实现 |
| MultiEdit | 批量编辑 | ❌ 未实现 |
| WebFetch | 网页获取 | ❌ 未实现 |
| NotebookRead | 读取 Notebook | ❌ 未实现 |
| NotebookEdit | 编辑 Notebook | ❌ 未实现 |
| WebSearch | 网页搜索 | ❌ 未实现 |
| CodexBash | Codex Bash | ❌ 未实现 |
| CodexReasoning | Codex 推理 | ❌ 未实现 |
| CodexPatch | Codex 补丁应用 | ❌ 未实现 |
| CodexDiff | Codex 差异显示 | ❌ 未实现 |
| GeminiBash | Gemini Bash | ❌ 未实现 |
| GeminiReasoning | Gemini 推理 | ❌ 未实现 |
| GeminiPatch | Gemini 补丁应用 | ❌ 未实现 |
| GeminiDiff | Gemini 差异显示 | ❌ 未实现 |
| Task | 子任务/子代理 | ❌ 未实现 |
| ExitPlanMode | 退出计划模式 | ❌ 未实现 |
| AskUserQuestion | 询问用户问题 | ❌ 未实现 |

---

## 四、数据模型对比

### GitHub slopus/happy 数据模型

```typescript
// Session
interface Session {
  id: string;
  seq: number;
  createdAt: number;
  updatedAt: number;
  active: boolean;
  activeAt: number;
  metadata: Metadata | null;
  metadataVersion: number;
  agentState: AgentState | null;
  agentStateVersion: number;
  thinking: boolean;
  thinkingAt: number;
  presence: "online" | number;
  todos?: Todo[];
  draft?: string | null;
  permissionMode?: string | null;
  modelMode?: string | null;
  latestUsage?: LatestUsage | null;
}

// Metadata
interface Metadata {
  models: Model[];
  currentModelCode: string;
  operatingModes: OperatingMode[];
  currentOperatingModeCode: string;
  thoughtLevels: ThoughtLevel[];
  currentThoughtLevelCode: string;
  path: string;
  host: string;
  version: string;
  name: string;
  os: string;
  summary?: Summary;
  machineId?: string;
  claudeSessionId?: string;
  tools?: string[];
  slashCommands?: string[];
  homeDir?: string;
  happyHomeDir?: string;
  hostPid?: number;
  flavor?: string;
  sandbox?: any;
  dangerouslySkipPermissions?: boolean;
}

// AgentState
interface AgentState {
  controlledByUser: boolean | null;
  requests?: Record<string, Request>;
  completedRequests?: Record<string, CompletedRequest>;
}
```

### 本地 Flutter 数据模型

```dart
// Session
class Session {
  final String id;
  final String title;
  final List<dynamic> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool active;
  final String? tag;
  final String? path;
  final Map<String, dynamic>? metadata;
  final String? permissionMode;
  final String? draft;
  final Map<String, dynamic>? agentState;
}
```

### 差异分析

| 字段 | GitHub | 本地 | 状态 |
|------|--------|------|------|
| id | ✅ | ✅ | 一致 |
| seq | ✅ | ❌ | 本地缺失 |
| createdAt | ✅ | ✅ | 一致 |
| updatedAt | ✅ | ✅ | 一致 |
| active | ✅ | ✅ | 一致 |
| activeAt | ✅ | ❌ | 本地缺失 |
| metadata | ✅ | ✅ | 一致 |
| metadataVersion | ✅ | ❌ | 本地缺失 |
| agentState | ✅ | ✅ | 一致 |
| agentStateVersion | ✅ | ❌ | 本地缺失 |
| thinking | ✅ | ❌ | 本地缺失 |
| thinkingAt | ✅ | ❌ | 本地缺失 |
| presence | ✅ | ❌ | 本地缺失 |
| todos | ✅ | ❌ | 本地缺失 |
| draft | ✅ | ✅ | 一致 |
| permissionMode | ✅ | ✅ | 一致 |
| modelMode | ✅ | ❌ | 本地缺失 |
| latestUsage | ✅ | ❌ | 本地缺失 |

---

## 五、设置项对比

### GitHub slopus/happy 设置

```typescript
interface Settings {
  schemaVersion: number;
  viewInline: boolean;
  inferenceOpenAIKey: string | null;
  expandTodos: boolean;
  showLineNumbers: boolean;
  showLineNumbersInToolViews: boolean;
  wrapLinesInDiffs: boolean;
  analyticsOptOut: boolean;
  experiments: boolean;
  useEnhancedSessionWizard: boolean;
  alwaysShowContextSize: boolean;
  agentInputEnterToSend: boolean;
  avatarStyle: string;
  showFlavorIcons: boolean;
  compactSessionView: boolean;
  hideInactiveSessions: boolean;
  reviewPromptAnswered: boolean;
  reviewPromptLikedApp: boolean | null;
  voiceAssistantLanguage: string | null;
  preferredLanguage: string | null;
  recentMachinePaths: RecentMachinePath[];
  lastUsedAgent: string | null;
  lastUsedPermissionMode: string | null;
  lastUsedModelMode: string | null;
  profiles: AIBackendProfile[];
  lastUsedProfile: string | null;
  favoriteDirectories: string[];
  favoriteMachines: string[];
  dismissedCLIWarnings: DismissedWarnings;
}
```

### 本地 Flutter 设置

当前本地项目的设置实现较为简化，缺少以下配置：

| 设置项 | GitHub | 本地 | 状态 |
|--------|--------|------|------|
| viewInline | ✅ | ❌ | 缺失 |
| expandTodos | ✅ | ❌ | 缺失 |
| showLineNumbers | ✅ | ❌ | 缺失 |
| showLineNumbersInToolViews | ✅ | ❌ | 缺失 |
| wrapLinesInDiffs | ✅ | ❌ | 缺失 |
| analyticsOptOut | ✅ | ❌ | 缺失 |
| experiments | ✅ | ❌ | 缺失 |
| useEnhancedSessionWizard | ✅ | ❌ | 缺失 |
| alwaysShowContextSize | ✅ | ❌ | 缺失 |
| avatarStyle | ✅ | ❌ | 缺失 |
| showFlavorIcons | ✅ | ❌ | 缺失 |
| compactSessionView | ✅ | ❌ | 缺失 |
| hideInactiveSessions | ✅ | ❌ | 缺失 |
| voiceAssistantLanguage | ✅ | ❌ | 缺失 |
| preferredLanguage | ✅ | ❌ | 缺失 |
| recentMachinePaths | ✅ | ❌ | 缺失 |
| lastUsedAgent | ✅ | ❌ | 缺失 |
| lastUsedPermissionMode | ✅ | ❌ | 缺失 |
| lastUsedModelMode | ✅ | ❌ | 缺失 |
| profiles (AI配置) | ✅ | ❌ | 缺失 |
| lastUsedProfile | ✅ | ❌ | 缺失 |
| favoriteDirectories | ✅ | ❌ | 缺失 |
| favoriteMachines | ✅ | ❌ | 缺失 |
| dismissedCLIWarnings | ✅ | ❌ | 缺失 |

---

## 六、核心功能差异

### 1. 会话协议 (Session Protocol)

GitHub 项目支持会话协议，包括：
- Session Envelope (id, time, role, turn, subagent, ev)
- 事件类型: text, service, tool-call-start, tool-call-end, file, turn-start, turn-end, stop
- Turn 管理 (turn-start, turn-end)
- Subagent 支持 (子代理链)

本地项目：⚠️ 简化实现，缺少完整的会话协议支持

### 2. 实时功能

GitHub 项目：
- Socket.IO 集成
- 实时消息更新
- 活动状态同步 (presence)
- 使用统计实时更新
- 机器活动状态同步
- Voice Assistant (WebRTC/LiveKit)

本地项目：⚠️ Socket.IO 基础集成，缺少高级实时功能

### 3. 加密功能

GitHub 项目：
- Legacy NaCl 加密
- AES-256-GCM DataKey 加密
- Key Wrapping (密钥封装)
- 端到端加密 (E2E)
- DEK (数据加密密钥) 管理

本地项目：⚠️ 基础加密实现，缺少完整的密钥管理系统

### 4. Artifact 工件管理

GitHub 项目：
- Artifact CRUD 操作
- Header 和 Body 版本控制
- 加密存储
- S3 文件存储集成

本地项目：❌ 未实现 Artifact 管理

### 5. KV 存储

GitHub 项目：
- GET /v1/kv/:key
- GET /v1/kv
- POST /v1/kv (批量变更)
- 版本控制支持

本地项目：❌ 未实现 KV 存储

### 6. Git 状态

GitHub 项目：
- Git 状态同步
- Branch tracking
- Staged/Unstaged 文件
- Line changes 统计
- Ahead/Behind commits

本地项目：⚠️ 基础 Git 状态显示

### 7. 社交功能

GitHub 项目：
- 好友系统 (关系: created, updated, deleted)
- 收件箱 (friend requests, notifications)
- 用户搜索
- Feed (社交动态)

本地项目：⚠️ 基础好友和收件箱实现

### 8. Profile 管理

GitHub 项目：
- AI Backend Profile (配置文件)
- Anthropic/OpenAI/AzureOpenAI/TogetherAI 配置
- 环境变量映射
- Tmux 配置
- 兼容性设置 (claude, codex, gemini)

本地项目：❌ 未实现 AI Backend Profile 管理

### 9. 语音功能

GitHub 项目：
- 实时语音会话
- LiveKit 集成
- WebRTC 支持
- 语音状态显示

本地项目：⚠️ 基础语音功能

---

## 七、总结

### 优先级 1 (核心功能 - 必须实现)
- [x] Artifact 工件管理系统 (CRUD + 版本控制) - ✅ 已实现
- [x] KV 存储系统 - ✅ 已实现
- [ ] AI Backend Profile 管理 - 🔄 进行中
- [ ] 完整的会话协议支持
- [ ] 会话文件管理
- [ ] 文件查看器

### 优先级 2 (重要功能)
- [ ] 增强的会话创建向导
- [ ] 机器选择/路径选择
- [ ] 工具的完整实现 (Glob, Grep, LS, Read, MultiEdit, WebFetch, etc.)
- [ ] 使用统计
- [ ] Git 状态完整集成

### 优先级 3 (增强功能)
- [ ] 实时同步增强
- [ ] 语音功能完善
- [ ] 更新日志
- [ ] 开发工具
- [ ] 文本选择功能
- [x] 模拟器自动化测试方案 - ✅ 已完成

---

## 八、已实现的功能

### Artifact 工件管理系统
✅ 创建了 `artifact_models.dart` - 完整的 Artifact 数据模型
✅ 创建了 `artifact_repository.dart` - 包含完整的 CRUD API 集成
✅ 创建了 `artifacts_list_screen.dart` - 工件列表页面
✅ 创建了 `artifact_detail_screen.dart` - 工件详情/编辑页面
✅ 创建了 `new_artifact_screen.dart` - 新建工件页面
✅ 创建了 `artifact_provider.dart` - 状态管理 Provider
✅ 更新了路由配置 - 添加了工件相关的 4 个路由

### KV 存储系统
✅ 创建了 `kv_models.dart` - KV 数据模型 (KVItem, KVBatchUpdateRequest, 等)
✅ 创建了 `kv_storage_repository.dart` - 完整的 KV 存储操作
✅ 创建了 `kv_storage_provider.dart` - 状态管理 Provider

### 测试方案
✅ 创建了 `emulator-automation-test-plan.md` - 完整的测试方案文档
✅ 包含 Patrol 框架集成建议
✅ 定义了完整的测试用例结构
✅ 包含 Mock 策略和 CI/CD 配置
