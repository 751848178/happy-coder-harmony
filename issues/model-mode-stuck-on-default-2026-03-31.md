# 会话模型选择始终显示"Default"，PC 端实际使用的模型被忽略

**日期:** 2026-03-31
**严重程度:** 高
**影响范围:** 所有会话的模型选择控件

## 现象

在会话详情页，模型选择控件始终显示"Default"，即使 PC 端已经切换了模型（如 Sonnet、Opus），移动端也无法反映实际使用的模型。

## 根因

### Bug 1：`_persistSessionCreationModes` 持久化了 'default' 模型模式

**文件:** `lib/features/session/domain/session_service_session_bootstrap.dart:12-18`

创建会话时，`permissionMode` 正确地将 `'default'` 转为 `null` 再持久化，但 `modelMode` 直接持久化了 `'default'`：

```dart
permissionMode: normalizedPermissionMode == 'default'
    ? null
    : normalizedPermissionMode,   // ← 正确：'default' → null
modelMode: normalizedModelMode,     // ← BUG：'default' 直接持久化
```

### Bug 2：`resolveSessionModelMode` 让持久化的 'default' 具有绝对优先级

**文件:** `lib/features/session/domain/session_creation_options_mode_helpers.dart:180-182`

```dart
final persistedChoice = resolveModeKey([persistedValue]);
if (persistedChoice != null) {
  return persistedChoice;  // 'default' 也是非 null，直接返回
}
```

`resolveModeKey` 对任何非 null、非空的值都返回。一旦 'default' 被持久化，PC 的 `currentModelCode`（如 'sonnet'）永远不会被读取。

### Bug 3：`update-session` WebSocket 处理不更新 `modelMode` / `permissionMode`

**文件:** `lib/features/socketio/data/socket_repository_updates.dart:71-88`

当 PC 端更新了 metadata（含新的 `currentModelCode`），`update-session` 事件只更新了 `metadata` 字段，但没有重新解析 `modelMode` 和 `permissionMode`：

```dart
existing.copyWith(
  metadata: nextMetadata,   // 元数据更新了
  // modelMode 和 permissionMode 没有更新！保留旧值！
)
```

UI 在 `_currentModelKeys` 中优先使用 `session.modelMode`，导致 PC 的更新被忽略。

## Bug 链路

```
会话创建 → modelMode='default' → 持久化 'default'
       ↓
loadSessions → resolveSessionModelMode(persistedValue='default')
            → resolveModeKey(['default']) → 'default'（非 null）
            → 直接返回 'default'，跳过 metadataValue
       ↓
PC 更改模型 → update-session → metadata['currentModelCode'] 更新
           → 但 session.modelMode 不变（仍为 'default'）
       ↓
UI: _currentModelKeys = ['default', metadata['currentModelCode'], 'default']
  → findPreferredListedModeOption 先匹配 'default' → 永远显示 "Default"
```

## 修复方案

### Fix 1：`_persistSessionCreationModes` — 不持久化 'default'

与 `permissionMode` 保持一致，将 `'default'` 转为 `null` 再持久化：

```dart
modelMode: normalizedModelMode == 'default'
    ? null
    : normalizedModelMode,
```

### Fix 2：`resolveSessionModelMode` — 'default' 不具备绝对优先级

对 `persistedValue` 使用 `resolveNonDefaultModeValue` 而非 `resolveModeKey`，使 'default' 被视为"未选择"：

```dart
final persistedChoice = resolveNonDefaultModeValue([persistedValue]);
if (persistedChoice != null) {
  return persistedChoice;
}
```

### Fix 3：`update-session` 处理器 — 从更新后的 metadata 重新解析 mode

当 `session.modelMode` 为 `'default'` 或 `null` 时，使用 metadata 中的 `currentModelCode` 作为新值：

```dart
modelMode: existing.modelMode != null && existing.modelMode != 'default'
    ? existing.modelMode
    : (nextMetadata?['currentModelCode']?.toString() ?? existing.modelMode),
permissionMode: existing.permissionMode != null && existing.permissionMode != 'default'
    ? existing.permissionMode
    : (nextMetadata?['currentOperatingModeCode']?.toString() ?? existing.permissionMode),
```

## 预期效果

- 用户未显式选择模型时，UI 显示 PC 端当前实际使用的模型
- 用户显式选择非 'default' 模型后，该选择被尊重并持久化
- PC 端更改模型后，移动端在下次 `update-session` 或 `loadSessions` 时同步更新
- 权限模式（permissionMode）的行为不受影响（已正确处理 'default'）

## 经验教训

- 'default' 作为"使用远端默认值"的语义，不应被当作一个具体的用户选择来持久化
- 持久化层和解析层对同一语义值的处理必须保持一致
- WebSocket 实时更新路径必须和 REST API 加载路径走相同的字段解析逻辑
- 当有多个优先级来源（persisted > local > remote）时，必须确保 'default' 这类"无选择"语义不会错误地胜出
