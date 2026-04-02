# 刷新按钮增量拉取与全量同步状态分离

日期: 2026-04-02

## 问题

1. **刷新按钮使用 `force: true` 全量拉取** — `_refreshSessionState` 调用 `loadSessionMessages(force: true)` 导致 `afterSeq = 0`，每次点击都重新拉取所有消息（可能 264+ 条，3 页网络请求），而非只拉取新消息。
2. **"同步全部消息"与刷新按钮共享同一状态** — 两者都用 `_isRefreshingSessionState`，无法区分用户看到的是哪种操作在进行。
3. **全量同步期间菜单项无禁用/加载提示** — 用户可能多次点击"同步全部消息"。

## 修复

### `_refreshSessionState` → 增量拉取
- 移除 `force: true`，改为 `force: false`（默认值），使用 `_sessionLastSeq` 作为 `afterSeq` 增量拉取。
- 添加 `_scheduleScrollToLatest` 和 `_scheduleViewportStateRefresh` 确保新消息可见。

### 状态分离
- 新增 `_isSyncingAllMessages` 字段，独立追踪全量同步状态。
- `_syncSessionMessagesFromRemote` 改为检查 `_isSyncingAllMessages` 而非 `_isRefreshingSessionState` 防止重入。
- "同步全部消息"菜单项在同步中显示 `CircularProgressIndicator` 和 "同步中..." 文本，并禁用点击。

### 行为对比

| 操作 | 触发方式 | API 参数 | 数据量 | 状态字段 |
|------|---------|---------|-------|---------|
| 刷新按钮 | AppBar 图标 | `force: false, afterSeq = lastSeq` | 仅新消息 | `_isRefreshingSessionState` |
| 同步全部消息 | 更多菜单 | `force: true, afterSeq = 0` | 全量消息 | `_isSyncingAllMessages` + `_isRefreshingSessionState` |

## 修改文件

- `lib/features/session/screens/session_screen_state_refresh.dart` — 刷新改为增量；同步增加独立状态
- `lib/features/session/screens/session_screen_state_appbar.dart` — 同步菜单项加载状态
- `lib/features/session/screens/session_screen.dart` — 新增 `_isSyncingAllMessages` 字段
