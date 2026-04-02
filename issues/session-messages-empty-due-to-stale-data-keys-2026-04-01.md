# 会话消息列表显示为空 — session data key 未就绪导致消息解密静默失败

**日期**: 2026-04-01
**状态**: 已修复
**影响**: 会话页面消息列表可能显示"开始新的对话"空白状态，即使消息实际存在于服务端

## 问题现象

打开一个已有消息的会话时，消息列表偶尔会显示为空（显示"开始新的对话"占位符），而不是展示实际的消息内容。下拉刷新后消息可能恢复正常。

## 根本原因

### 原因 1: `_ensureSessionContextLoaded` 跳过了 `loadSessions`

`_loadSessionData()` 中调用 `_ensureSessionContextLoaded` 时传入 `requireSession: initialSession == null`。
当 session 已经在缓存中时（`initialSession != null`），`loadSessions()` 不会被调用，导致
`_sessionDataKeys` 没有被重建。后续 `loadSessionMessages()` 使用 stale 或缺失的 data key
解密消息时，所有消息静默解密失败，返回空列表。

```dart
// 问题代码
await _ensureSessionContextLoaded(
  sessionNotifier,
  requireSession: initialSession == null, // ← 缓存中存在时为 false，跳过 loadSessions
);
```

### 原因 2: `_refreshSessionContextInBackground` 与消息加载竞态

`_refreshSessionContextInBackground()` 立即调用 `loadSessions()`，这会执行 `_sessionDataKeys.clear()`。
如果此时 `loadSessionMessages()`（通过 `unawaited` 在后台运行）正在解密消息，data keys 会被清空，
导致后续消息解密全部失败。

```dart
// 问题代码 — 立即调用 loadSessions 可能与 in-flight 的 loadSessionMessages 产生竞态
void _refreshSessionContextInBackground(sessionNotifier) {
  unawaited(sessionNotifier.loadSessions()); // ← 可能清空正在使用的 data keys
}
```

### 原因 3: `replaceMessages` 在解密失败时不保护现有数据

`loadSessionMessages` 的 force 模式下，即使解析结果为空（所有消息解密失败），
`_repository.replaceMessages()` 仍然会以 `isLoaded: true` 存储空消息列表。
UI 检测到 `hasLoadedMessages == true && messages.isEmpty`，于是显示空状态占位符而非重试。

```dart
// 问题代码 — 解密失败产生空列表，但 isLoaded 被设为 true
if (force) {
  _repository.replaceMessages(sessionId, nestedMessages); // nestedMessages 为空！
}
```

## 修复方案

### Fix 1: 始终加载 sessions 以确保 data keys 可用

**文件**: `lib/features/session/screens/session_screen_state_load.dart`

将 `_ensureSessionContextLoaded` 的 `requireSession` 参数始终设为 `true`，
确保 `_sessionDataKeys` 在加载消息之前被重建：

```dart
await _ensureSessionContextLoaded(
  sessionNotifier,
  requireSession: true, // ← 始终为 true
);
```

### Fix 2: 延迟后台刷新以避免竞态

**文件**: `lib/features/session/screens/session_screen_state_load.dart`

将 `_refreshSessionContextInBackground` 中的 `loadSessions` 延迟 2 秒执行，
确保 in-flight 的消息加载完成后再刷新 session 上下文：

```dart
void _refreshSessionContextInBackground(sessionNotifier) {
  Future.delayed(const Duration(seconds: 2), () {
    if (!mounted) return;
    unawaited(sessionNotifier.loadSessions());
    unawaited(sessionNotifier.loadMachines(force: false, allowFailure: true));
  });
}
```

### Fix 3: force 重载空结果时保留现有消息

**文件**: `lib/features/session/domain/session_service_messages.dart`

在 `loadSessionMessages` 的 force 路径中，当解析结果为空但已有消息存在时，
保留现有消息而不是替换为空列表：

```dart
if (force) {
  if (nestedMessages.isEmpty &&
      existing != null &&
      existing.messages.isNotEmpty) {
    Logger.warning(
      'Session messages force-reload produced empty result for $sessionId; '
      'keeping ${existing.messages.length} existing messages to avoid data loss',
    );
  } else {
    _repository.replaceMessages(sessionId, nestedMessages,
        preserveOptimisticMessages: preserveOptimisticMessages);
  }
}
```

## 数据流图

```
正常流程:
  loadSessions() → _sessionDataKeys 填充 → loadSessionMessages() → 解密成功 → 显示消息 ✅

问题流程 1 (缓存命中):
  _ensureSessionContextLoaded(requireSession: false)
    → loadSessions 被跳过 → _sessionDataKeys 未填充
    → loadSessionMessages() → 解密失败 → 空消息 + isLoaded: true → 显示空白 ❌

问题流程 2 (竞态):
  loadSessionMessages() 开始（异步解密）
  → _refreshSessionContextInBackground() → loadSessions() → _sessionDataKeys.clear()
  → 解密失败 → 空消息 + isLoaded: true → 显示空白 ❌
```

## 教训

1. **加密密钥的生命周期必须独立于缓存状态** — 即使 session 已缓存，data key 仍可能需要重建
2. **异步操作的竞态条件** — `unawaited` 调用与后续操作之间需要考虑时序关系
3. **静默失败是危险的** — `_parseServerMessages` 在解密失败时返回空列表而非抛出异常，
   导致上层代码无法区分"真的没有消息"和"消息解密失败"
4. **`isLoaded: true` 不应伴随空结果** — 当 force reload 产生空结果但已有数据存在时，
   应保留现有数据而非用空列表替换

## 相关文件

- `lib/features/session/screens/session_screen_state_load.dart`
- `lib/features/session/domain/session_service_messages.dart`
- `lib/features/session/domain/session_service_session_parsing.dart` (data keys 重建逻辑)
- `lib/features/session/domain/session_service_message_parser.dart` (解密逻辑)
- `lib/features/session/data/session_repository_messages.dart` (replaceMessages/applyMessages)
- `lib/features/session/data/session_repository_models.dart` (SessionMessages.isLoaded)
