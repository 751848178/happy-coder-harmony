# 修正说明：取消 pointer 只能解决长按触发链，不能单独解决页面缩放（2026-03-31）

## 背景

- 这份记录对应的是“长按触发链”这一层。
- 后续复查后确认：页面缩放的最终根因在长按菜单使用的 `showModalBottomSheet(...)`，不是 `cancelPointer(...)` 本身缺失。

## 根因定位

### 1. 消息长按主入口已经在气泡层

- 文件：`lib/features/session/screens/session_screen_message_bubble.dart`
- 当前消息气泡已经使用 `ImmediateLongPressRegion` 作为长按主入口。

### 2. 现有实现只赢了手势竞技场，没有中断当前 pointer 序列

- 文件：`lib/core/widgets/immediate_long_press_region.dart`
- 现状：
  - 组件已经改成 `RawGestureDetector + LongPressGestureRecognizer`
  - 这样确实能更稳定地在 Flutter 手势竞技场中获胜
- 但缺口是：
  - 长按达标后没有调用 `GestureBinding.instance.cancelPointer(...)`

### 3. 这项修改解决的是“触发链稳定性”，不是弹层路由问题

- 结果是：
  - 长按菜单更容易即时弹出
  - 文本选择/系统二次处理更少
  - 但如果弹层仍然是 `ModalBottomSheetRoute`，页面背景仍可能缩放

## 本次修复

- 在 `_ArenaLongPressGestureRecognizer.didExceedDeadline()` 中对当前 pointer 调用 `GestureBinding.instance.cancelPointer(...)`
- 这项改动继续保留，用来保证长按触发时不会再把同一次 pointer 序列继续传给文本选择链路
- 但真正修掉“页面缩放”的，是把长按菜单从 `showModalBottomSheet(...)` 换成自定义底部弹层路由

## 测试补充

- 更新 `test/immediate_long_press_region_test.dart`
- 新增验证：
  - 长按仍会在抬手前触发
  - 子组件长按不会被触发
  - 当前 pointer 会收到 `PointerCancelEvent`

## 涉及文件

- `lib/core/widgets/immediate_long_press_region.dart`
- `test/immediate_long_press_region_test.dart`

## 后续约束

- 对于消息气泡这类交互，要分别验证：
  1. 长按序列有没有被正确终止
  2. 菜单路由会不会让底层页面跟着缩放
- 以后如果页面缩放复现，不要只检查 `cancelPointer(...)`；要先看菜单是不是又改回了 `showModalBottomSheet(...)`。
