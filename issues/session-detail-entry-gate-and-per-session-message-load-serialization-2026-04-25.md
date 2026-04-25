# 会话页状态冲突审查：详情页门闩残留入口 + 同会话消息加载并发覆盖

**日期**: 2026-04-25
**严重级别**: P0 Critical
**状态**: 已修复

## 现象

- 会话详情页偶发出现历史窗口被重置、到顶到底失效、翻历史过程中被打断。
- 同一会话可能同时受到多个刷新源影响：
  - 列表页预览刷新
  - 后台会话快照刷新
  - 详情页 warm refresh
  - 详情页 socket / polling / 手动 refresh

## 这次确认的两个具体问题

### 根因 1：仍有部分进入详情页的导航入口绕过了活跃详情门闩

虽然已经引入了 `activeSessionDetailIdProvider` 和详情页导航助手，
但代码中仍残留多处直接：

- `context.push(AppRoutes.sessionDetail(...))`
- `context.pushReplacement(AppRoutes.sessionDetail(...))`
- `context.go(AppRoutes.sessionDetail(...))`

这些入口会让来源页的列表预览刷新或后台刷新在导航瞬间抢先运行，
继续对目标会话执行预览消息加载，覆盖详情页 resident window。

### 根因 2：同一会话的 `loadSessionMessages` 允许 force 刷新并发执行

`message_coordinator.dart` 里原本只对非 `force` 请求做 in-flight 去重，
`force=true` 会无条件继续执行。

这意味着同一会话上可能出现：

- 详情页 warm refresh `force=true`
- 手动 refresh
- 其它增量/预览消息加载

并发请求同时落库，谁最后完成谁就覆盖当前消息窗口，
形成典型的状态竞争和资源抢占。

## 修复方案

- 把所有已确认的会话详情入口统一收口到导航助手：
  - 导航前先同步设置 `activeSessionDetailIdProvider`
  - 再执行 push / pushReplacement / go
- 将 `loadSessionMessages(sessionId)` 改为按会话串行：
  - 非 force 请求继续复用 in-flight
  - force 请求若发现已有 in-flight，则等待当前请求完成后再运行
- 详情页 warm refresh 与手动 refresh 额外增加互斥保护：
  - 正在加载 older/newer 历史窗口时不替换消息窗口
  - 程序化滚动进行中时不替换消息窗口

## 修改文件

- `lib/features/session/presentation/session_detail_navigation.dart`
- `lib/features/session/domain/session_service/message_coordinator.dart`
- `lib/features/session/screens/session_detail/controllers/load_coordinator.dart`
- `lib/features/session/screens/session_detail/state/refresh_session_sync.dart`
- `lib/features/session/screens/new_session_flow_screen/create.dart`
- `lib/features/session/screens/new_session_screen/content.dart`
- `lib/features/session/screens/session_info_screen/actions.dart`
- `lib/features/session/screens/session_detail/message/forward.dart`

## 后续开发约束

1. 任何会打开会话详情页的入口，都必须在导航动作发起前先设置活跃详情门闩。
2. 同一会话的消息窗口加载必须串行，不能允许多个刷新源并发覆盖同一 resident window。
3. 详情页只要处于历史浏览、边界加载或程序化滚动阶段，就不能再触发会替换消息窗口的 refresh。
