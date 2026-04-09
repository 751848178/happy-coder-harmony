# 会话窗口化后，完整历史仍必须可通过滚动连续访问（2026-04-07）

## 现象

- 详情页虽然只在内存里保留一个 resident window
- 但用户滚动到顶部或底部时，历史不会自动续上
- “到顶 / 到底”按钮也只会滚动当前窗口，而不会跨窗口跳到真正的最早 / 最新消息
- 结果上，完整历史变成了“理论上可切换窗口访问”，而不是“实际可通过滚动访问”

## 根因

### 1. 之前实现的是“窗口切换”，不是“连续滚动访问”

- 文件：`lib/features/session/screens/session_screen_state_refresh.dart`
- 文件：`lib/features/session/screens/session_screen_viewport_controller.dart`
- 原有 `loadOlderArchivedMessages / loadNewerArchivedMessages` 只挂在提示条按钮上
- 用户正常滚动到边界时，不会自动触发窗口平移

### 2. 到顶 / 到底按钮只操作当前窗口

- 文件：`lib/features/session/screens/session_screen_viewport_controller.dart`
- 原有 `scrollToTop()` 只滚到当前窗口的 `minScrollExtent`
- 原有 `scrollToBottom()` 只滚到当前窗口的 `maxScrollExtent`
- 当会话处于较旧窗口时，这两个动作都不能带用户到真正的历史边界

### 3. 交互语义和性能语义被混淆

- “内存里只保留窗口”是性能策略
- “用户能否连续访问全部历史”是交互能力
- 两者不能互相替代

## 本轮修复

### 1. 滚动到顶部 / 底部时自动续上历史窗口

- 文件：`lib/features/session/screens/session_screen_viewport_controller.dart`
- 当用户真实滚动到顶部边界时：
  - 若存在更早消息，则自动加载更早窗口
- 当用户真实滚动到底部边界时：
  - 若存在较新消息，则自动加载较新窗口

### 2. 到顶 / 到底按钮升级为“跨窗口到边界”

- 文件：`lib/features/session/screens/session_screen_viewport_controller.dart`
- “到顶”现在会：
  - 必要时先等待完整历史可访问
  - 再持续向更早窗口平移，直到真正最早消息
- “到底”现在会：
  - 必要时先等待完整历史可访问
  - 再持续向较新窗口平移，直到真正最新消息

### 3. 历史窗口平移支持两种模式

- 文件：`lib/features/session/screens/session_screen_state_refresh.dart`
- 普通边界续历史：
  - 加载后保持用户还在边界附近，方便继续滚动
- 显式到顶 / 到底：
  - 加载窗口时不插入中间停顿，最终直接收敛到真实边界

## 规避原则

- 验收“完整历史可访问”时，必须检查：
  - 普通滚动是否能连续穿过窗口边界
  - 到顶 / 到底是否能跨窗口工作
- 不要把“有按钮能切窗口”当成“滚动访问语义已经成立”
- 窗口化优化必须保证：
  - 渲染是局部的
  - 访问语义仍然是完整的

## 后续建议

- 如果后续引入更稳定的消息高度缓存，可以把边界平移做得更丝滑，进一步减少窗口切换瞬间的视觉跳动
- 如果服务端提供真正的双向分页能力，应把当前“本地 archive + 窗口平移”继续升级为远端驱动的连续分页
