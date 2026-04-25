# 会话页面审查：消息动作缓存失效与对话框控制器生命周期问题

**日期**: 2026-04-25
**严重级别**: P1
**状态**: 已修复

## 审查范围

- `lib/features/session/screens/session_detail/message/bubble.dart`
- `lib/features/session/screens/session_detail/state/actions.dart`
- `lib/features/session/screens/session_detail/command/template_editor.dart`

## 问题 1：消息气泡缓存了过期的动作回调

### 定位

- `_MessageBubbleState.didUpdateWidget(...)`
- `_MessageBubbleState._ensureActionState()`

### 根因

`_MessageBubble` 会把：

- `_actionText`
- `_onMessageAction`
- `_onLongPressMessage`

延迟缓存起来，减少高频重建时的重复计算。这个方向本身没问题，但原实现只有在
`message` 引用变化时才把这组缓存标记为失效。

这会带来两个真实风险：

1. 如果消息对象没变，但父层传入的 `onMessageActionChoice` /
   `onShowMessageActionSheet` 发生变化，长按消息后仍会执行旧回调。
2. 如果消息内容变化但 `shouldResetCollapsedState(...) == false`，
   `_canCollapse` 不会更新，文本/工具消息的“展开/收起”能力会和真实内容脱节。

### 修复

- 增加 `_resetActionState()`，统一失效动作缓存。
- `didUpdateWidget(...)` 中对动作回调变化单独做失效处理。
- 只要消息发生变化，就重新计算 `_canCollapse`。
- 是否重置 `_collapsed` 仍继续交给 `shouldResetCollapsedState(...)` 判断，
  保持原有交互语义不变。

## 问题 2：会话页对话框里的 TextEditingController 生命周期不完整

### 定位

- `_showRenameDialog(...)`
- `_showInputTemplateEditor(...)`

### 根因

原实现把 `TextEditingController` 创建在方法里，但只在部分按钮点击路径上手动
`dispose()`，没有覆盖这些关闭方式：

- 点击遮罩关闭对话框
- 系统返回关闭对话框
- 其它异常提前返回路径

这会让 controller 生命周期依赖 UI 分支，而不是函数作用域本身，不符合原子化和
解耦原则。

### 修复

- 改成 `await showDialog(...)` + `try/finally` 模式。
- 对话框结束后统一 `dispose()` controller。
- `rename` 和 `input template editor` 两条路径都收敛到同一生命周期模型。

## 修改文件

- `lib/features/session/screens/session_detail/message/bubble.dart`
- `lib/features/session/screens/session_detail/state/actions.dart`
- `lib/features/session/screens/session_detail/command/template_editor.dart`

## 后续开发约束

1. 只要 widget 内缓存了 callback 衍生状态，就必须在 `didUpdateWidget(...)`
   中显式覆盖“输入未变但回调变了”的场景。
2. “是否重置交互状态” 与 “是否重算展示能力” 要分开处理，不能把两者混在一个条件里。
3. 页面方法里临时创建的 controller / focus node / animation 等对象，必须由该方法自身
   以 `try/finally` 或等价结构收口生命周期，不能依赖按钮分支手动释放。
