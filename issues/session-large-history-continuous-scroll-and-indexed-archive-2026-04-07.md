# 大会话历史连续滚动访问与归档索引化复盘（2026-04-07）

## 现象

- 用户希望：
  - 会话消息可以完整访问
  - 页面依旧只渲染局部、只保留局部消息在内存
  - 通过正常滚动，以及“到顶 / 到底”，都能连续访问全部消息
- 之前实际行为：
  - 到顶 / 到底会卡住
  - 页面暴露“后台准备完整历史”提示，泄漏了内部实现
  - 历史访问虽然理论上可用，但交互上仍像“切窗口”，不是“连续滚动”

## 根因

### 1. 到顶 / 到底实现成了同步跨窗口循环

- 文件：`lib/features/session/screens/session_screen_viewport_controller.dart`
- 之前逻辑：
  - “到顶 / 到底”会在一次用户动作中反复执行
    - 读 archive
    - 替换 resident window
    - rebuild 列表
    - 再继续下一轮
- 结果：
  - 真实设备上会形成连续多次窗口切换
  - 主线程会长期处于忙状态
  - 用户感知就是按钮按下后卡住不动

### 2. archive 范围读取仍然是 O(total archived messages)

- 文件：`lib/features/storage/data/hive_repository_message_archive.dart`
- 之前逻辑：
  - 每次读 archive range 或 count，都先扫描 `_messagesBox.keys`
  - 再按 prefix 过滤当前 session
  - 再排序
- 结果：
  - 任何一次边界换页都要先扫整盒消息 key
  - 当设备上存在多个大会话时，复杂度会放大为 O(total archived messages)

### 3. 界面把“窗口化实现细节”直接暴露给用户

- 文件：`lib/features/session/screens/session_screen_state_build.dart`
- 文件：`lib/features/session/screens/session_screen_support_widgets.dart`
- 之前逻辑：
  - 页面顶部持续展示“当前窗口 / 后台准备完整历史”提示
- 结果：
  - 用户体验被迫理解内部技术实现
  - 这不是消息页应该暴露的产品语义

### 4. 到顶 / 到底按钮的 enable 状态只看当前窗口滚动位置

- 文件：`lib/features/session/screens/session_screen_viewport_controller.dart`
- 之前逻辑：
  - `canScrollToTop/canScrollToBottom` 只根据当前窗口像素位置判断
- 结果：
  - 即使还有更早 / 较新的历史，只要停在当前窗口边缘，按钮也会被错误禁用

## 本轮修复

### 1. archive 改为“索引直取”，读取复杂度降为 O(limit)

- 文件：`lib/features/storage/data/hive_repository_message_archive.dart`
- 文件：`lib/features/storage/domain/storage_session_message_archive.dart`
- 文件：`lib/features/storage/domain/storage_models_entities.dart`
- 修复内容：
  - archive key 改为 `sessionId + archiveIndex`
  - 不再在 range read 时扫描整盒 key
  - 增加 `SessionMessageArchiveSummary`
  - 归档完成后保存 `messageCount/isComplete`
- 结果：
  - `get count` 变成 O(1)
  - `load range(start, limit)` 变成 O(limit)

### 2. 到顶 / 到底改为“单次边界窗口跳转”，不再循环跨多窗口

- 文件：`lib/features/session/screens/session_screen_state_refresh.dart`
- 文件：`lib/features/session/screens/session_screen_viewport_controller.dart`
- 修复内容：
  - 新增“直接加载最早窗口 / 直接加载最新窗口”
  - 到顶 / 到底只做一次 archive window 读取
  - 不再在一次按钮点击里循环跨多个 resident window

### 3. 普通滚动仍保留边界续历史，但只在靠近边界时单步换窗

- 文件：`lib/features/session/screens/session_screen_viewport_controller.dart`
- 修复内容：
  - 用户手势滚动靠近顶部 / 底部时，只触发一次单步窗口平移
  - 不做同步 while 循环
  - 触发阈值提前，尽量减少“撞到边界再等加载”的顿挫

### 4. 移除顶部“后台准备完整历史”提示

- 文件：`lib/features/session/screens/session_screen_state_build.dart`
- 文件：`lib/features/session/screens/session_screen_support_widgets.dart`
- 修复内容：
  - 删除 `_MessageWindowNotice`
  - 页面只保留消息内容和正常滚动控制

### 5. 到顶 / 到底按钮状态改为感知“是否仍有历史”

- 文件：`lib/features/session/screens/session_screen_viewport_controller.dart`
- 修复内容：
  - `canScrollToTop` 不再只看当前像素位置
  - 还会看是否存在更早历史
  - `canScrollToBottom` 同理

## 当前设计结论

- 现在采用的是更接近社区常见大消息列表的方案：
  - 视口内按需渲染
  - resident window 常驻内存
  - 全量历史落本地 archive
  - 通过边界续窗实现“完整可访问”
- 不是把全量消息同时塞进内存，也不是靠显式切窗口按钮让用户自己理解内部实现

## 规避原则

- “完整历史可访问”不等于“允许用户点击按钮切换窗口”
- 到顶 / 到底这类全局动作，绝不能实现成主线程上的多窗口同步循环
- 本地 archive 只要参与滚动热路径，就必须提供：
  - O(1) 的 count
  - O(limit) 的范围读取

## 后续建议

- 如果后端未来提供 `before_seq` / 双向分页，应继续把 archive 方案升级为真正的远端 + 本地混合分页
- 如果要进一步提高滚动连续性，可以继续做“可见锚点恢复”，让单步换窗时视觉位置更稳定
