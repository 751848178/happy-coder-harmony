# 会话详情页进入卡顿 & 滚动到顶/底边界卡顿

**Date**: 2026-04-05
**Status**: Fixed
**Impact**: 点击会话列表进入会话时页面渐入动画期间卡顿 1-3 秒；滚动到顶/底边界时卡顿 1-3 秒

## 症状

### 问题 1：页面渐入卡顿

用户从会话列表点击某个会话时，页面渐入（fade-in）动画期间明显卡顿 1-3 秒。动画不流畅，甚至可能出现短暂的冻结。

### 问题 2：滚动边界卡顿

在会话详情页滚动到列表顶部或底部边界时，UI 冻结 1-3 秒。触碰边界后才能恢复响应。

## 根因分析

### 问题 1：页面渐入卡顿

**根因：`_loadSessionData()` 在页面过渡动画期间同步执行重操作**

执行链：

```
initState()
  → _loadSessionData()             // async 但不 yield
    → restoreSessionMessagesFromCache()
      → restoreMessagesFromLocalSnapshot()   // 同步 O(n) JSON 反序列化
        → rawMessages.map(ReducerMessage.fromJson).toList()   // 264 条消息
        → sort((a, b) => a.createdAt.compareTo(b.createdAt))
      → _repository.replaceMessages()        // 同步 O(n) map 构建
    → _syncMessagesFromRepository()          // 更新 ValueNotifier → 触发 build()
  → build()
    → _resolveTurnGroups()                   // 同步 O(n) 遍历所有消息
    → resolveSessionThinkingSnapshot()       // 同步 O(n) 遍历所有消息
```

GoRouter 的默认页面过渡动画（`FadeUp` + `FadeOut`）持续 300ms。`initState()` 在动画开始时触发 `_loadSessionData()`，后者立即执行上述同步操作（总计约 50-200ms），阻塞了过渡动画的前几帧。

**为什么 `_loadSessionData()` 不 yield：**
- 它是 `async` 方法，但第一个 `await` 之前有大量同步工作
- `restoreSessionMessagesFromCache` 的 `await` 仅在 Hive 读取时 yield（~1ms）
- JSON 反序列化和 repository 操作在 `await` 恢复后的同步帧中执行

### 问题 2：滚动边界卡顿

**根因：`AutomaticKeepAliveClientMixin` 导致所有消息气泡永久存活**

`_MessageBubble` 使用 `AutomaticKeepAliveClientMixin`，`wantKeepAlive` 返回 `!_collapsed`。这意味着：

1. 用户滚动经过的每个未折叠气泡都会被标记为 `keepAlive`
2. 一旦标记，气泡永远保留在 widget tree 中（直到页面销毁）
3. 滚动完 264 条消息后，所有 264 个气泡 widget 都存活

**为什么边界处特别卡：**

- `ListView.builder` 的 sliver 系统在每次滚动帧中对所有 keepAlive 子项执行 layout
- 在边界处（overscroll），Flutter 触发额外的 layout pass（用于弹性回弹效果）
- 264 个气泡 × 每个 `Column` 包含 markdown 内容 × layout pass = 巨大的计算量
- `RepaintBoundary` 只隔离了 paint，不隔离 layout

**内存影响：**
- 264 个 `_MessageBubbleState` + 每个内部的 `_MarkdownMessageContentState`
- 每个气泡的 `_MarkdownBlock.parse()` 结果缓存在 `_blocks` 字段中
- `_ToolPresentationCache` 也保留在内存中

## 修复

### Fix 1：推迟加载到过渡动画完成之后

**文件**: `session_screen_state_load.dart`

在 `_loadSessionData()` 开头添加 `await SchedulerBinding.instance.endOfFrame`，让过渡动画先完成第一帧，再开始加载：

```dart
Future<void> _loadSessionData() async {
  // Let the page transition animation start before doing any heavy work.
  await SchedulerBinding.instance.endOfFrame;
  if (!mounted) return;
  // ... rest of loading
}
```

效果：过渡动画可以流畅开始，加载工作在下一帧执行。

### Fix 2：移除 AutomaticKeepAliveClientMixin

**文件**: `session_screen_message_bubble.dart`

将 `_MessageBubbleState` 从 `AutomaticKeepAliveClientMixin<_MessageBubble>` 改为普通 `State<_MessageBubble>`：

- 移除 `with AutomaticKeepAliveClientMixin<_MessageBubble>`
- 移除 `wantKeepAlive` getter
- 移除所有 `updateKeepAlive()` 调用
- 移除 `build()` 中的 `super.build(context)`

```dart
// Before:
class _MessageBubbleState extends State<_MessageBubble>
    with AutomaticKeepAliveClientMixin<_MessageBubble> {
  @override
  bool get wantKeepAlive => !_collapsed;
  // ...
  @override
  Widget build(BuildContext context) {
    super.build(context);  // required by AutomaticKeepAliveClientMixin
    // ...
  }
}

// After:
class _MessageBubbleState extends State<_MessageBubble> {
  // No wantKeepAlive, no updateKeepAlive, no super.build
  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

**为什么可以安全移除：**
- `RepaintBoundary` 已包裹每个气泡，提供 paint 隔离
- `ListView.builder` 的 `itemBuilder` 按需构建，不构建不可见项
- 消息内容不会频繁变化（仅在 WebSocket 推送新消息时）
- 失去的 keepAlive 效果（避免滚动回来时重建）是可接受的，因为：
  - 重建代价低（`_MarkdownBlock.parse` 有静态缓存，`_computeToolPresentation` 使用轻量级大小启发式）
  - 收益巨大（264 项的 layout 从 O(264) 降为 O(~10)，即视口中的项数）

## 验证

1. 点击大量消息的会话 → 页面渐入动画流畅，无卡顿
2. 滚动到顶部/底部 → 无卡顿，边界处回弹动画流畅
3. 来回快速滚动 → 重建的气泡渲染正确，无闪烁
4. `flutter analyze` 无错误

## 相关文件

- `lib/features/session/screens/session_screen_state_load.dart` — 推迟加载
- `lib/features/session/screens/session_screen_message_bubble.dart` — 移除 keepAlive

## 教训

1. **`AutomaticKeepAliveClientMixin` 是双刃剑** — 保持少量可见项存活可以提升滚动性能，但无差别地保持所有项存活会导致 layout 爆炸
2. **`async` 不等于非阻塞** — `async` 方法中第一个 `await` 之前的同步代码仍会阻塞当前帧
3. **页面过渡期间避免重操作** — 使用 `await endOfFrame` 或 `Future.delayed(Duration.zero)` 让过渡动画先开始
4. **`ListView.builder` 的性能优势依赖于项目回收** — keepAlive 破坏了项目回收机制
