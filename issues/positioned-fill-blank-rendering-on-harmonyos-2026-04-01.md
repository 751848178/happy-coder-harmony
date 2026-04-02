# 会话消息列表白屏 — `Positioned.fill` 在 HarmonyOS 上导致 Stack 内容不渲染

**日期**: 2026-04-01
**状态**: 已修复
**影响**: 会话页面消息列表区域完全白屏/空白，即使消息数据已加载

## 问题现象

打开任意一个有消息的会话时，消息列表区域完全空白。顶部导航栏和底部输入框正常显示，但中间的消息区域不渲染任何内容，包括加载指示器、空状态占位符和调试横幅。

## 根本原因

### `Positioned.fill` 在 HarmonyOS Flutter 上渲染为空白

`_buildSessionScreen()` 中使用 `Positioned.fill` 包裹消息列表：

```dart
// 原始代码
Stack(
  children: [
    Positioned.fill(           // ← 问题：在 HarmonyOS 上渲染为空白
      child: showMessageLoading
          ? CircularProgressIndicator()
          : messages.isEmpty
              ? _buildEmptyState()
              : _buildMessageList(...),
    ),
    Positioned(...),  // 调试横幅 — 同样不显示
    // ... 其他 overlay widgets
  ],
)
```

通过诊断横幅确认了数据完全正常：
- `s=true m=264 t=6 ld=true` — 264 条消息、6 个 turn groups、数据已加载
- `h=519 w=388` — LayoutBuilder 独立正常（519px 高度）

将 `Positioned.fill` 替换为 Stack 的非 positioned 子节点后，渲染正常：

```dart
Stack(
  children: [
    // 非 positioned 子节点 — 自然填充 Stack
    showMessageLoading
        ? CircularProgressIndicator()
        : messages.isEmpty
            ? _buildEmptyState()
            : _buildMessageList(...),
    Positioned(...),  // overlay widgets 正常渲染
  ],
)
```

### 为什么 `Positioned.fill` 在 HarmonyOS 上失败

**具体原因未完全确定**，但以下是最可能的解释：

1. HarmonyOS 的 Flutter 渲染引擎（Impeller 或 Skia 后端）对 `RenderPositionedBox` 的处理可能与标准 Flutter 不同
2. `Positioned.fill` 创建 `RenderConstrainedBox` 约束为 `BoxConstraints.tight(constraints.biggest)`，在 HarmonyOS 上可能产生零尺寸约束
3. Stack 内所有子节点都是 `Positioned` 时，Stack 的尺寸计算可能走了不同的分支路径

### 伴随性能问题

`_resolveSessionStats()` 在每次 `build()` 时遍历所有 264 条消息并解析文本中的 patch 信息（O(n) 复杂度）。在 overview 折叠（默认状态）时这些计算完全是浪费。

**修复**: 当 `_sessionOverviewCollapsed == true`（默认）时跳过 stats 计算：

```dart
final sessionStats = _sessionOverviewCollapsed
    ? null  // 折叠时不计算
    : _resolveSessionStats(session, messages);
```

## 修复方案

### Fix 1: 移除 `Positioned.fill`，使用非 positioned 子节点

**文件**: `lib/features/session/screens/session_screen_state_build.dart`

将消息列表从 `Positioned.fill(child: ...)` 改为直接作为 Stack 的非 positioned 子节点。

### Fix 2: 折叠时跳过 stats 计算

**文件**: `lib/features/session/screens/session_screen_state_build.dart`

## 教训

1. **避免在 Stack 中使用 `Positioned.fill` 包裹主要内容** — 在 HarmonyOS/OpenHarmony 平台上，优先使用非 positioned 子节点
2. **昂贵的计算不应在每次 build 中执行** — `SessionStatsCalculator.fromSession()` 在 264 条消息上的 O(n) 遍历应通过条件守卫或缓存来避免
3. **平台差异需要实机测试** — iOS/Android 上正常的布局模式在 HarmonyOS 上可能行为不同

## 相关文件

- `lib/features/session/screens/session_screen_state_build.dart`
- `lib/features/session/screens/session_screen_view_messages.dart`
- `lib/features/session/screens/session_screen_message_bubble.dart`
