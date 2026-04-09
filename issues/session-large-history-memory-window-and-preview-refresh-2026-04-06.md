# 大会话内存崩溃与后台全量消息加载复盘（2026-04-06）

## 问题现象

- 打开历史消息很多的会话，进入页面后一段时间应用崩溃。
- 会话列表后台运行一段时间后，内存持续增长，可能在未主动进入某些会话的情况下也被拉高。

## 已确认根因

### 1. 会话列表后台“预览刷新”会对未加载会话触发全量消息加载

- 文件：`lib/features/session/screens/sessions_screen_refresh_controller.dart`
- 文件：`lib/features/session/domain/session_service_message_coordinator.dart`
- 之前逻辑：
  - 列表页收到 socket 消息后会刷新会话预览。
  - 若某个 session 从未加载过消息，`refreshSessionMessageSnapshots()` 会把 `maxPagesPerSession` 退化成 `null`。
  - 最终走到 `loadSessionMessages()` 的全量分页，直接把整条历史拉进内存。
- 结果：
  - 仅仅为了更新列表 preview，就会把几千条消息的会话完整持有在内存里。

### 2. 详情页默认会恢复并持有整份历史消息

- 文件：`lib/features/session/domain/session_service_cache_coordinator.dart`
- 文件：`lib/features/session/domain/session_local_snapshot.dart`
- 文件：`lib/features/session/domain/session_service_message_coordinator.dart`
- 之前逻辑：
  - 本地缓存快照会把“当前已加载的全部消息”完整存入 snapshot。
  - 详情页进入时会把这些消息整包恢复进内存。
  - 远端加载也会把所有分页结果先累计到一个大 List，再交给 repository。
- 结果：
  - 大会话进入页时，容易同时持有：
    - 本地恢复后的完整消息模型
    - 远端加载累计中的完整消息列表
    - repository 内的消息 map/list
    - turn group / flat list 派生结构

### 3. 默认链路缺少“内存窗口”概念

- 当前实现默认把“完整历史”当成详情页常驻内存模型。
- 这对几千条甚至更大的消息历史，在移动端并不安全。
- 真正合理的默认策略应该是：
  - 默认只保留最近一段消息用于进入页、滚动和实时对话。
  - 总消息数单独记录。
  - 完整历史改为显式操作，例如“同步全部消息”。

## 本轮修复

### 1. 列表/后台不再为未加载会话拉取整份消息

- `refreshSessionMessageSnapshots()` 现在会跳过未加载的 session。
- 列表页收到 socket 更新时，如果该 session 没有本地消息快照，就退回到会话摘要刷新，而不是全量消息加载。

### 2. 详情页默认改为“最近消息内存窗口”

- 自动进入会话页、轮询刷新、socket 增量刷新、普通刷新，统一改成只保留最近 `400` 条消息在内存中。
- 仍然保留总消息数和最新 `lastSeq`，因此：
  - 最新消息同步不会丢
  - 预览和统计不会错误回退到窗口大小

### 3. 本地缓存快照只持久化最近消息窗口

- snapshot 不再持久化全部已加载消息，而是只保留最近 `400` 条。
- 启动恢复时也只解析最近 `400` 条，避免大会话整包恢复。

### 4. UI 明示当前是内存窗口模式

- 详情页会展示“当前只加载最近 N / 总数 条消息”的提示。
- 用户如果需要完整历史，可以显式使用右上角的“同步全部消息”。

## 设计原则

- 不再把“列表预览刷新”与“完整消息加载”耦合。
- 不再把“默认详情页浏览”与“完整历史常驻内存”耦合。
- 用总数与窗口分离的方式保留正确业务语义，避免把窗口大小误写成真实消息总数。

## 后续建议

- 如果后端支持 `before_seq` / 倒序分页，应继续升级为“滚动到顶部再按需加载更老消息”的真分页详情页。
- 如果需要长期保存完整本地历史，不应继续把全部消息内嵌进 session metadata snapshot，应单独建立按 session 分片的消息存储结构。
