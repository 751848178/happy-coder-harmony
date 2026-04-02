# 会话消息长按缩放整个页面 & 误触率高

## 问题现象

### 问题 1：长按消息导致整个会话页面缩放（放大）

在纯血鸿蒙（HarmonyOS NEXT）设备上，长按会话消息气泡时，整个页面发生放大（zoom in）效果，而不是触发长按菜单。

### 问题 2：长按菜单误触率高

正常滚动浏览消息时，手指停留稍久就会误触长按菜单，用户体验差。

## 根因分析

### 问题 1 根因：`Listener` 不参与手势竞技场（Gesture Arena）

原始实现（`immediate_long_press_region.dart`）使用 `Listener` + `HitTestBehavior.translucent` + `GestureBinding.cancelPointer` 来检测长按：

```dart
// 旧实现（有问题）
Listener(
  behavior: HitTestBehavior.translucent,
  onPointerDown: (event) { /* 启动 Timer */ },
  onPointerUp: (event) { /* 取消 Timer */ },
  child: child,
)
```

**问题**：`Listener` 只监听原始指针事件，不参与 Flutter 手势竞技场。在长按等待的 420ms 窗口期内，`SelectableText` 的内部手势识别器也在等待长按。由于 `Listener` 不会 "赢" 得竞技场，`SelectableText` 的长按识别器最终获胜，触发文本选择行为。

在鸿蒙系统上，文本选择行为会进一步触发系统级的缩放（magnifier / zoom）效果。

### 问题 2 根因：移动容差（move slop）太小

- 原始 `moveSlop` 为 `kTouchSlop`（18px），在可滚动列表中太灵敏
- 原始长按延迟为 420ms，稍慢的滚动手指停留即触发

## 修复方案

### 1. 使用 `RawGestureDetector` + 自定义 `LongPressGestureRecognizer`

新实现使用 `RawGestureDetector` 配合 `LongPressGestureRecognizer` 子类，直接参与手势竞技场：

```dart
// 新实现
RawGestureDetector(
  behavior: HitTestBehavior.opaque,
  gestures: {
    _ArenaLongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<...>(
      () => _ArenaLongPressGestureRecognizer(
        duration: longPressDelay,
        movementThreshold: moveSlop,
      ),
      (recognizer) {
        recognizer.onLongPress = () { onLongPress(); };
      },
    ),
  },
  child: child,
)
```

关键设计点：

- **继承 `LongPressGestureRecognizer`**：复用 Flutter 内置的竞技场生命周期管理（accept/reject、timer、velocity tracking），而不是直接继承 `PrimaryPointerGestureRecognizer`
- **覆盖 `preAcceptSlopTolerance` getter**：自定义移动容差，替代默认的 18px
- **`HitTestBehavior.opaque`**：确保 `RawGestureDetector` 在所有区域都能接收触摸事件，即使子组件（如 `SizedBox`）不绘制任何内容

### 2. 调整长按参数

```dart
// session_screen.dart
const Duration _sessionMessageImmediateLongPressDelay = Duration(milliseconds: 480);
const double _sessionMessageLongPressMoveSlop = 36.0;
```

- 延迟从 420ms → 480ms：减少快速滚动时的误触
- 移动容差从 18px → 36px：允许更大的手指漂移而不触发长按

## 涉及文件

| 文件 | 变更 |
|------|------|
| `lib/core/widgets/immediate_long_press_region.dart` | 完全重写，使用 `RawGestureDetector` + `LongPressGestureRecognizer` 子类 |
| `lib/features/session/screens/session_screen.dart` | 延迟 420→480ms，新增 36px 移动容差常量 |
| `lib/features/session/screens/session_screen_message_bubble.dart` | 传入 `moveSlop` 参数 |
| `test/immediate_long_press_region_test.dart` | 更新测试适配新实现 |

## 测试注意事项

在测试中使用 `ImmediateLongPressRegion` 时，确保内部子组件使用 `HitTestBehavior.opaque` 或能通过 hit test 的组件（如带颜色的 `Container`）。`SizedBox` 不绘制任何内容，配合 `deferToChild` 行为会导致 hit test 失败，手势识别器不会注册。

## 后续修复：滚动时仍触发长按菜单（2026-03-30）

### 问题

即使 `moveSlop` 已设为 36px，用户慢速滚动时手指可能在 480ms 内漂移不超过 36px（Euclidean 距离），导致长按定时器触发并弹出菜单。

### 根因

`_ArenaLongPressGestureRecognizer` 仅通过 `preAcceptSlopTolerance`（Euclidean 距离）判断是否取消长按，不检查指针移动速度。慢速滚动时：
- 手指速度 ≈ 60-120 px/s
- 480ms 内漂移 ≈ 29-58px，部分场景落在 36px 容差内
- 长按定时器先于滚动识别器赢得竞技场

### 修复：基于速度的拒绝

在 `_ArenaLongPressGestureRecognizer.handleEvent` 中追踪连续 `PointerMoveEvent` 的瞬时速度：

- 若连续 2 帧速度超过 120 px/s，立即 `resolve(rejected)`
- 速度低于阈值时重置计数器
- 在 `acceptGesture` / `rejectGesture` 中清理追踪状态

这使得手指在移动（滚动）时，即使 Euclidean 距离未超限，也能因速度信号被正确拒绝。

## 相关历史

- `issues/session-message-long-press-actions-blocked-by-selectable-text.md`：前次修复尝试（使用 `Listener` + `cancelPointer`），解决了菜单被吃掉的问题，但引入了本 issue 的缩放和误触问题

## 2026-03-31 补充

后续再次排查发现，仅仅“参与手势竞技场并获胜”还不够。

- 文件：`lib/core/widgets/immediate_long_press_region.dart`
- 现象：菜单已经能弹出，但同一次长按序列没有被 `cancelPointer(...)` 中断时，HarmonyOS 真机上仍可能继续出现页面缩放效果。
- 最新约束：
  1. `ImmediateLongPressRegion` 既要赢得竞技场
  2. 也要在长按达标后取消当前 pointer

否则问题会从“菜单弹不出来”变成“菜单弹出来了，但页面还是缩放”。详见 `issues/session-message-long-press-must-cancel-pointer-2026-03-31.md`。
