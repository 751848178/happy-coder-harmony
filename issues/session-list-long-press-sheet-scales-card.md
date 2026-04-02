# 会话列表长按弹出菜单时卡片缩放问题记录

## 背景

用户在会话列表长按条目弹出“移动到分组”菜单时，整个页面背景会跟着出现明显缩放，体感像“会话页被整体压小了一层”。

## 根因定位

- 文件：
  - `lib/features/session/screens/sessions_screen_session_move_sheet.dart`
  - `lib/features/session/screens/session_screen_message_actions.dart`
- 根因：真正导致背景缩放的不是长按识别器，而是长按菜单最终走了 `showModalBottomSheet(...)`。
- 说明：
  - `ImmediateLongPressRegion` 负责解决“长按能不能及时触发、会不会被文本选择抢走”的问题。
  - 但只要最终还是 `ModalBottomSheetRoute`，HarmonyOS 真机上页面背景仍会在菜单出现时跟着缩。
- 结果：即使长按入口已经换成更稳定的手势组件，长按菜单一旦用底部 sheet 弹出，页面缩放问题仍然存在。

## 本次修复

- 长按菜单不再走 `showModalBottomSheet(...)`
- 改成自定义 `RawDialogRoute` 底部弹层，只动画弹层面板本身，不再让底层页面参与缩放
- 会话列表的“移动到分组”和消息长按菜单统一复用这套弹层路由，避免两边再次分叉

## 后续约束

1. 长按交互要分两层排查：
   手势有没有正确触发，以及菜单最终用的是什么路由。
2. 如果问题表现为“菜单出来后背景页跟着缩”，先检查是不是 `showModalBottomSheet(...)`，不要再只盯着 `onLongPress`。
3. `ImmediateLongPressRegion` 仍然保留，用于稳定长按识别；但它不是“背景缩放”问题的最终根因。
