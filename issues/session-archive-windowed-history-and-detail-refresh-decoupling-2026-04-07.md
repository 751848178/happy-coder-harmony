# 会话历史归档窗口化与详情页刷新解耦复盘（2026-04-07）

## 问题现象

- 大会话进入页即使限制了最近消息窗口，详情页停留期间仍会持续出现后台状态抖动。
- 轮询 / socket 在没有真实新消息时也会反复触发自动滚底，造成滚动动画和布局计算白跑。
- 一旦执行“同步全部消息”，历史会重新整包进入 repository 内存，窗口止血策略会被显式全量同步绕开。

## 已确认根因

### 1. 详情页打开时，列表页和后台刷新还在背后继续工作

- 文件：`lib/features/session/screens/sessions_screen_refresh_controller.dart`
- 文件：`lib/app/widgets/session_background_refresh_gate.dart`
- 之前逻辑：
  - 会话详情页 push 之后，列表页 behind route 仍继续监听 socket、自动同步列表、刷新会话 preview。
  - 后台 refresh gate 也可能在详情页停留期间继续触发 refresh。
- 结果：
  - 详情页前台渲染与列表页后台状态变更叠加，造成无意义 rebuild 和日志风暴。

### 2. 自动滚底只看“应该贴底”，不看“消息是否真的推进”

- 文件：`lib/features/session/screens/session_screen_state_socket.dart`
- 之前逻辑：
  - socket / polling 每次调用 `_scheduleMessageRefresh()` 后，只要当前处于贴底模式，就会触发 `scrollToLatest`。
  - 即使这次刷新没有新增消息，也会反复跑滚动 settle 流程。
- 结果：
  - 真机日志里出现了大量 `scroll-latest`，但对应时段没有新的 `message-sync` 推进。

### 3. “同步全部消息”仍然把完整历史直接驻留在 repository

- 文件：`lib/features/session/domain/session_service_message_coordinator.dart`
- 之前逻辑：
  - 显式全量同步虽然是用户主动操作，但最终仍把完整消息列表交给 repository。
  - 这会让详情页、派生 turn groups、flat items、message bubble 数据一起膨胀。
- 结果：
  - 一旦用户需要完整历史，之前的窗口化止血就被绕过，内存压力重新回到 O(n)。

### 4. 旧消息窗口会误污染列表 preview / 本地 snapshot

- 文件：`lib/features/session/data/session_repository_models.dart`
- 文件：`lib/features/session/domain/session_service_cache_coordinator.dart`
- 之前逻辑：
  - 如果把 repository 当前消息窗口切到较旧历史，preview / lastMessageAt / listStatus 仍可能被当前窗口覆盖。
  - persist cache 时也可能把“旧窗口”当成启动恢复快照写回。
- 结果：
  - 列表 preview 退化、重启恢复错位，造成“正在看旧窗口”状态泄漏到全局会话摘要。

## 本轮修复

### 1. 增加前台会话详情页 gate，暂停 behind-route 刷新

- 新增 provider：`activeSessionDetailIdProvider`
- 详情页进入时注册当前 session id，退出时释放。
- 列表页自动同步、preview refresh、后台 refresh gate 在详情页打开时统一跳过。

### 2. 自动滚底改成“消息推进驱动”

- socket / polling 刷新前后会比较会话消息视图状态。
- 只有消息列表真的发生推进时，且当前处于贴底模式，才执行自动滚底。
- 没有新消息时只刷新必要的视口状态，不再白跑 scroll settle。

### 3. 全量同步改为“本地归档 + 当前窗口驻内存”

- 新增本地 archive 存储：
  - `lib/features/storage/domain/storage_session_message_archive.dart`
  - `lib/features/storage/data/hive_repository_message_archive.dart`
- 新增会话消息归档协调器：
  - `lib/features/session/domain/session_service_message_archive_coordinator.dart`
- 现在“同步全部消息”会：
  - 顺序拉取远端完整历史
  - 全量写入本地 archive
  - repository 只保留当前 resident window
- 结果：
  - 完整历史仍可访问
  - 详情页常驻内存不再随全量同步线性增长

### 4. repository 显式感知“当前窗口位置”

- `SessionMessages` 新增：
  - `windowStartIndex`
  - `hasOlderMessages`
  - `hasNewerMessages`
- repository 新增 `replaceMessageWindow()`，用于显式切换历史窗口，而不是把 older/newer 加载混成普通 append merge。

### 5. 详情页支持“加载更早 / 返回较新”窗口切换

- 顶部提示条现在在 archive 可用时展示窗口位置与切换按钮。
- 用户可在完整历史已归档后，以固定 resident window 在更早 / 较新历史之间切换。
- 当用户停留在较旧窗口时，自动增量刷新不会再偷偷把窗口拉回最新尾部。

### 6. preview 与本地 snapshot 只绑定“最新窗口”

- 当当前窗口不是最新窗口时：
  - repository 不再用旧窗口覆盖 session preview / lastMessageAt / listStatus
  - cache coordinator 不再把旧窗口消息写回 local snapshot
- 这样能保证列表摘要和启动恢复始终代表“最新尾部”，而不是用户临时浏览的旧历史。

## 当前设计结论

- 在没有 `before_seq` 这类后端倒序分页能力时，客户端不能假装做标准双向远端分页。
- 当前最稳妥的方案是：
  - 默认最新尾部窗口
  - 显式全量同步后归档到本地
  - 详情页只加载当前 resident window
  - 通过窗口切换访问完整历史

## 后续建议

- 如果后端补充 `before_seq` / 倒序分页，应把本地 archive window 进一步升级为“远端 + 本地联合分页”。
- 如果需要更平滑的历史切换体验，可以继续把“加载更早 / 返回较新”升级为靠近顶部/底部时的自动窗口平移，并引入 anchor-based offset restore。
- 如果单条 tool result / diff 仍然很重，下一步应继续做消息内容分级水合，把超大文本从默认消息模型中拆出来。
