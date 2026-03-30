# 会话消息长按菜单被 SelectableText 吃掉问题记录

## 背景

本次问题的表象是：

- 会话消息已经接入了“转发到其他会话 / 保存到模板 / 插入到输入框”能力。
- 但真机上长按用户消息气泡时，看不到这些菜单项，尤其是用户文本消息最明显。

这会直接让用户误以为“长按功能没有实现”或“安装的还是旧代码”。

## 根因定位

### 1. 长按菜单逻辑并没有缺失，真正断在了手势层

- `session_screen_view_messages.dart` 已经给 `_MessageBubble` 传入了 `onLongPressMessage`。
- `session_screen_message_bubble.dart` 也确实在外层包了一层 `GestureDetector(onLongPress: ...)`。

也就是说，消息级长按菜单链路本身是存在的。

### 2. 用户消息文本实际渲染使用了多处 `SelectableText`

以下组件都会把消息内容渲染成可选中文本：

- `session_screen_markdown_text.dart`
- `session_screen_markdown_table.dart`
- `session_screen_inline_code_panel_render.dart`
- `session_screen_tool_support.dart`

这些 `SelectableText` 在移动端会自己处理长按手势并触发文本选择上下文菜单，导致外层 `_MessageBubble` 的 `onLongPress` 无法拿到事件。

### 3. 之前的实现只给“外层气泡”加了菜单，没有给“可选中文本”补对应菜单

- 结果就是：
  - 长按气泡空白区时，理论上可能触发外层菜单。
  - 长按真正的文本内容时，事件会被 `SelectableText` 抢走。
- 用户最常操作的是文本区域，所以最终体验就是“没有长按菜单”。

## 本次修复

### A. 统一消息动作执行入口

- 将“转发 / 保存模板 / 插入输入框”收敛到统一动作处理入口。
- 底部 action sheet 和文本选择 context menu 共用同一套动作执行逻辑，避免两边能力不一致。

### B. 给所有会吞长按的消息文本组件补自定义 context menu

- 基于 `SelectableText.contextMenuBuilder` 扩展文本选择菜单。
- 在保留原有复制/全选等能力的同时，追加：
  - `转发`
  - `存模板`
  - `插入`

### C. 覆盖消息气泡内所有相关可选文本渲染点

- 普通 markdown 文本
- markdown 表格单元格
- 纯文本代码块 / diff 行
- 工具摘要与工具结果文本

这样长按真正的文本区域时，也能稳定进入消息操作能力，而不再只依赖外层气泡手势。

## 二次问题补充

第一次修复虽然补齐了 `SelectableText.contextMenuBuilder`，但它解决的是“能不能看到动作”，没有解决“什么时候弹出来”。

- `SelectableText` 的文本选择菜单会跟随自身的选择时机。
- 在真机上，用户感受到的是要等手指抬起后，工具栏才出现。
- 这和会话消息的“长按即弹消息操作”预期不一致。

根因不是业务逻辑缺失，而是把消息动作入口挂在了 `SelectableText` 的选择菜单生命周期上。

## 最终方案

- 消息动作的主入口重新收敛到消息气泡层。
- 通过独立的原始指针长按计时器，在长按达标时立刻触发消息操作菜单。
- 触发后立即对当前 pointer 调用 `GestureBinding.instance.cancelPointer(...)`，中断底层 `SelectableText` 的同一次长按序列，避免再等到抬手后弹出文本选择菜单。
- `SelectableText.contextMenuBuilder` 继续保留为辅助能力，但不再承担长按主入口。

## 测试与验证

- 新增 `session_message_actions_test.dart` 用例，覆盖：
  - 文本消息 actionText 解析
  - context menu 自定义按钮插入顺序
  - `转发 / 存模板 / 插入` 回调可触发
- 新增即时长按区域测试，覆盖：
  - 手指未抬起前即可触发长按回调
  - 触发后会取消当前 pointer 序列
  - 手指移动超出阈值时不会误触发

## 后续开发约束

- 任何“气泡级长按能力”只要消息内容里用了 `SelectableText` 或其他自带长按处理的组件，都必须同步检查手势竞争问题。
- 不允许只给外层容器挂 `onLongPress` 或只扩展 `contextMenuBuilder` 就认为“长按功能完成”，必须验证用户真正触达的文本区域，以及菜单是否在长按达标时即时出现。
- 以后新增消息内容组件时，要优先复用统一的消息 context menu 扩展能力，避免再次出现“外层有菜单、文本区域没有菜单”的问题。
