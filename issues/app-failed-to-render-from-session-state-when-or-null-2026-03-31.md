# App failed to render：`whenOrNull` 非空强转导致首页首帧崩溃

> 创建日期: 2026-03-31

## 问题概述

最新代码在真机调试态启动时，首页首帧直接进入全局 `ErrorWidget`，界面显示 `App failed to render`。

## 真正根因

根因不在弹层，也不在 HarmonyOS 构建流程，而在会话状态工具方法本身：

- 文件：`lib/features/session/domain/session_service_state.dart`
- 方法：`SessionServiceState.whenOrNull<T>(...)`

该方法名字是 “`whenOrNull`”，但返回类型却写成了非空 `T`，并在没有命中分支时执行了 `return null as T;`。

这会让调用方只要被 Dart/riverpod 推断成非空类型，就会在 `initial/loading/error` 状态下直接抛运行时类型错误。

本次真机实际报错就是：

`type 'Null' is not a subtype of type '(int, int, Iterable<String>)' in type cast`

触发位置：

- `lib/features/home/screens/home_screen_content.dart`
- 首页为了监听 session/machine 指纹，使用了 `sessionStateProvider.select((s) => s.whenOrNull(...))`
- 应用首帧时 `sessionStateProvider` 仍处于 `initial/loading`
- `whenOrNull` 返回 `null as T`
- Riverpod 在 selector 里拿到这个非法非空结果，直接导致 `HomeScreen` build 抛异常

## 修复方案

### Fix 1：修正 `whenOrNull` 的语义

- 将 `SessionServiceState.whenOrNull<T>` 改为返回 `T?`
- 未命中分支时直接返回 `null`
- 不再做 `null as T` 这种运行时强转

### Fix 2：首页 selector 不再依赖空分支推断

- `home_screen_content.dart` 中的首页 watch 改成显式 `when(...)`
- 为 `initial/loading/error` 提供稳定 fallback 指纹
- `ready` 分支只返回值语义的 fingerprint：`(session 数量, machine 数量, machine key hash)`

## 经验总结

1. 任何叫 `whenOrNull` / `mapOrNull` 的 API，都必须返回可空类型，不能靠强转伪装成非空。
2. `ref.watch(provider.select(...))` 里如果只是做“刷新指纹”，应该提供显式 fallback，避免把 `null` 留给类型推断。
3. 首页、设置页、新建会话页这类启动期页面最容易先看到 `initial/loading` 状态，selector 代码必须先对这两个状态安全。

## 本次关联修复

- `lib/features/session/domain/session_service_state.dart`
- `lib/features/home/screens/home_screen_content.dart`
- `lib/features/chat/screens/chat_screen_messages.dart`
- `test/session_service_state_test.dart`
