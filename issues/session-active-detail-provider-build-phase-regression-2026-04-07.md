# 会话详情页前台标记在构建期写入 Provider，导致启动渲染失败

## 现象

- 打开应用后进入会话详情页，启动阶段直接出现 `App failed to render`
- Riverpod 报错：
  - `Tried to modify a provider while the widget tree was building`
  - `StateController<String?>`

## 根因

- 为了在详情页打开时暂停列表页和后台的 preview/snapshot 刷新，引入了 `activeSessionDetailIdProvider`
- 该 provider 在 `SessionScreen.initState()` 和 `dispose()` 中被同步写入
- Riverpod 不允许在 widget 生命周期的构建相关阶段直接修改 provider，这会造成状态树不一致风险

## 具体代码

- 问题位置：
  - `lib/features/session/screens/session_screen.dart`
- 出错方式：
  - `initState()` 中同步设置当前详情页 id
  - `dispose()` 中同步清空当前详情页 id

## 修复

- 将“进入详情页”的 provider 写入延后到首帧结束后执行
- 将“离开详情页”的 provider 清理延后到销毁后的下一帧执行
- 保持列表页/后台刷新门控逻辑不变，只修正状态提交时机

## 规避原则

- 不要在以下生命周期中同步修改 Riverpod provider：
  - `build`
  - `initState`
  - `dispose`
  - `didUpdateWidget`
  - `didChangeDependencies`
- 如果必须由 widget 生命周期驱动 provider 变化：
  - 优先把修改移到显式事件回调
  - 如果确实需要绑定页面进入/退出，使用 `addPostFrameCallback` 或等价的帧后调度
  - 异步清理时不要在已销毁的 `State` 上继续使用 `ref`，应先拿到容器或改为外部协调器负责

## 后续建议

- 将“详情页是否在前台”这类页面可见性状态继续从 widget 自己写 provider，逐步收敛到单独的 route/session visibility coordinator
- 为该门控链路补一个 widget 测试，覆盖“进入详情页/退出详情页时 provider 不抛异常”
