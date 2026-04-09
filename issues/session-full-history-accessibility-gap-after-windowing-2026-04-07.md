# 会话窗口化后仍未实现“全量可访问”的回归复盘（2026-04-07）

## 现象

- 进入大会话详情页后，页面只显示当前 resident window，例如 `247 / 5182`
- 顶部仍提示“当前只加载最近消息 / 使用同步全部消息”，没有变成“完整历史可访问”
- 用户无法直接通过窗口切换访问完整历史，必须再手动触发全量同步

## 根因

### 1. 之前只完成了“部分渲染”，没有完成“全量可访问”

- 文件：`lib/features/session/screens/session_screen_load_coordinator.dart`
- 文件：`lib/features/session/domain/session_service_message_archive_coordinator.dart`
- 上一轮改动只把详情页内存驻留限制在 resident window
- 但进入详情页时，并不会自动把剩余历史补齐到本地 archive
- 结果：
  - 页面只会稳定显示当前窗口
  - “完整历史可访问”仍然依赖用户手动点右上角“同步全部消息”

### 2. 错把“archive 里有数据”当成“完整历史已经可访问”

- 文件：`lib/features/session/screens/session_screen.dart`
- 文件：`lib/features/session/screens/session_screen_state_build.dart`
- 文件：`lib/features/session/screens/session_screen_support_widgets.dart`
- 之前逻辑用 `archivedMessageCount > 0` 代表 archive 可用
- 但这只能说明本地 archive 里“存在一些消息”，不能说明完整历史已经补齐
- 结果：
  - UI 状态机不准确
  - 可能在 archive 未完整时错误展示可切换窗口的能力

### 3. archive 回读窗口时，可能把总数错误缩小成“已归档条数”

- 文件：`lib/features/session/domain/session_service_message_archive_coordinator.dart`
- 之前逻辑在读取 archive window 时优先拿 `archiveCount` 作为 `totalMessageCount`
- 如果 archive 只是部分补齐，这会把真实总数缩小成当前已归档条数
- 结果：
  - 顶部窗口范围和“是否还有更早/较新消息”的判断都可能失真

## 本轮修复

### 1. 详情页进入后自动后台补齐完整历史 archive

- 文件：`lib/features/session/screens/session_screen_load_coordinator.dart`
- 文件：`lib/features/session/screens/session_screen_state_refresh.dart`
- 文件：`lib/features/session/domain/session_service_message_archive_coordinator.dart`
- 进入详情页后，如果：
  - 当前 `totalMessageCount > loadedCount`
  - 且本地 archive 仍未覆盖完整历史
- 则自动在后台触发 archive hydration

### 2. 增加 archive hydration 去重，避免重复全量归档

- 文件：`lib/features/session/domain/session_service.dart`
- 文件：`lib/features/session/domain/session_service_message_archive_coordinator.dart`
- `SessionServiceNotifier` 新增每个会话的 archive hydration in-flight 去重表
- 多个入口同时发现 archive 不完整时，只会复用同一次后台归档任务

### 3. UI 只在“完整历史真的可访问”时开放窗口切换

- 文件：`lib/features/session/screens/session_screen.dart`
- 文件：`lib/features/session/screens/session_screen_state_build.dart`
- 文件：`lib/features/session/screens/session_screen_support_widgets.dart`
- 新逻辑不再用 `archiveCount > 0` 判断
- 而是要求：
  - `archivedMessageCount >= totalMessageCount`
- 只有在这个条件满足后，才展示“加载更早消息 / 返回较新消息”

### 4. 顶部提示文案改成真实状态

- 文件：`lib/features/session/screens/session_screen_support_widgets.dart`
- 现在顶部提示分三种状态：
  - 完整历史已可访问
  - 正在后台准备完整历史
  - 当前只渲染窗口，完整历史访问能力尚未准备完成

### 5. archive 回读时不再缩小总消息数

- 文件：`lib/features/session/domain/session_service_message_archive_coordinator.dart`
- archive 回读窗口时，`totalMessageCount` 现在会取：
  - 现有已知总数
  - archive 已归档条数
  - 当前窗口上界
- 三者中的最大值
- 这样即使 archive 只补齐了一部分，也不会把总消息数错误缩小

## 规避原则

- 不要把“存在部分本地数据”和“完整历史可访问”混为一谈
- 做窗口化优化时，必须同时定义：
  - 内存里保留多少
  - 完整历史如何访问
  - 访问能力何时算真正 ready
- 任何依赖 archive 的 UI 按钮，都必须绑定“完整度”而不是“有无数据”

## 后续建议

- 如果后端支持 `before_seq`，应继续把“后台全量归档”升级为真正的远端双向分页
- 如果 archive hydration 的耗时在真机上仍然偏长，应补更细的进度状态，而不是只展示布尔态“准备中”
