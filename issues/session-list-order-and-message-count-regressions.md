# 会话列表顺序跳动与重启后消息数回退问题记录

## 背景

本次问题有两个直接可见的现象：

- 会话列表在不同行为触发后会出现顺序来回跳动。
- 已经显示过较大消息数的会话，重启 App 后消息数会变少，直到再次进入会话或触发消息快照刷新才慢慢恢复。

这两个问题都不是单点 UI bug，而是底层排序和缓存恢复逻辑不一致导致的状态回退。

## 根因定位

### 1. 会话列表顺序跳动

- 文件：`lib/features/session/data/session_repository_sessions.dart`
- 文件：`lib/features/session/screens/sessions_screen_content.dart`
- 文件：`lib/features/session/screens/sessions_screen_default_group_list.dart`
- 文件：`lib/features/session/screens/sessions_screen_custom_group_list.dart`
- 文件：`lib/features/chat/components/session_list.dart`
- 文件：`lib/features/socketio/data/socket_repository_updates.dart`

真实原因有两层：

1. 之前所有会话列表都只按 `updatedAt` 排序，没有任何稳定的二级排序键。  
   这会让同一批 `updatedAt` 相同的会话在不同 rebuild 中反复被 `List.sort()` 重新洗牌。
2. socket 的 `update-session` 事件以前直接把会话的 `updatedAt` 回写成事件 `createdAt`。  
   一旦事件时间比当前 `updatedAt` 更旧，列表顺序就会被旧时间戳拉回去，再次触发重排。

所以问题不是“某个页面渲染抖动”，而是排序本身不稳定，同时实时更新还会把排序主键写回旧值。

## 2. 重启后消息数变少

- 文件：`lib/features/session/domain/session_service.dart`
- 文件：`lib/features/storage/domain/storage_session_sync.dart`
- 文件：`lib/features/session/domain/session_stats_summary.dart`

真实原因是启动恢复链路里丢了“最后一次已知的本地消息统计”：

1. 会话缓存落盘时，只保存了 `active / permissionMode / modelMode / draft` 等本地快照，没有保存当前已加载消息数，也没有保存修正后的 `latestUsage.messageCount`。
2. 会话恢复时 `_sessionFromCache()` 固定使用 `messages: const []`，同时也没有从本地快照里恢复 `latestUsage`。
3. 列表页的消息数量优先级是：已加载消息 -> `latestUsage.messageCount` -> metadata/agentState 统计 -> `session.messages.length`。  
   重启后第一项和第二项都丢了，就会回退到更旧的远端摘要统计，甚至直接掉成 0。

所以问题不是“列表刷新慢”，而是启动时恢复的会话对象本身已经缺少了最近一次本地确认过的消息数。

## 本次修复

- 新增 `session_recency.dart`，统一会话排序规则：
  - `updatedAt` 倒序
  - `createdAt` 倒序
  - `seq` 倒序
  - `id` 正序
- `SessionRepository`、主会话列表、聊天侧边栏列表、最近会话页、机器详情页、模式元数据解析入口，统一改用同一套排序规则。
- 会话列表页去掉了重复排序，避免同一批数据在多层 rebuild 中被再次打乱。
- socket 的 `update-session` 事件现在优先使用真正的 `updatedAt`，并且禁止把当前会话的 `updatedAt` 回退到更旧时间。
- 新增 `session_local_snapshot.dart`，把会话本地快照扩展为可持久化：
  - 当前已知消息数
  - 修正后的 `latestUsage`
  - 原有的 `active / permission / model / draft`
- `messagesUpdated` 现在也会触发缓存持久化，确保用户已经看到的消息统计会落到本地。
- 启动恢复会话时，会先从本地快照恢复 `latestUsage.messageCount`，避免列表在重启后退回到旧统计。

## 后续开发约束

- 任何会话列表都不能再只按 `updatedAt` 单键排序，至少要有稳定二级排序键。
- 实时事件更新会话时间戳时，必须保证 `updatedAt` 只前进不后退。
- 只要列表展示过消息数，本地缓存就必须保存“最后一次已知值”，不能只依赖远端摘要字段。
- 如果消息数来源于 `sessionMessages`，对应的本地缓存刷新必须挂在 `messagesUpdated` 事件上，不能只在 `sessionsUpdated` 时落盘。
