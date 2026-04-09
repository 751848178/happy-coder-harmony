# 会话入口转场与到顶/到底按钮卡顿复盘

日期: 2026-04-06
状态: 已修复

## 现象

1. 从会话列表点击进入详情时，页面滑入阶段掉帧。
2. 进入会话页后点击到顶/到底，按钮反馈不顺滑，消息列表滚动明显发卡。

## 本次确认的具体根因

### 1. 详情页在转场动画期间启动了不必要的重工作

文件:
- `lib/features/session/screens/session_screen_state_load.dart`
- `lib/features/session/domain/session_service_messages.dart`
- `lib/features/session/domain/session_local_snapshot.dart`

问题链路:
- 会话已有缓存消息时，详情页首屏其实已经有足够数据可以先展示。
- 但旧逻辑仍会在转场尚未结束时立刻继续执行:
  - 本地缓存消息反序列化
  - `loadSessionMessages()`
  - `loadSessions()` / `loadMachines()`
- 其中缓存消息恢复里的 `ReducerMessage.fromJson` + 排序原本跑在主 isolate，会直接占用动画帧预算。

修复:
- 为缓存消息恢复增加 `restoreMessagesFromSnapshotPayload()`，并在大快照场景下通过 `compute()` 放到后台 isolate 解析。
- 会话已有内存/缓存快照时，详情页先展示现有消息，再等路由入场动画完成后执行远端增量刷新和上下文补齐。

### 2. 列表页在详情页加载期间被全页牵连重建

文件:
- `lib/features/session/screens/sessions_screen_content.dart`
- `lib/features/session/screens/sessions_screen.dart`

问题链路:
- 会话列表外层过去直接监听整份 `sessions` 状态，并且 provider 每次发射都会让外层重新走一遍筛选/分组构建。
- 同时列表页还会额外计算一轮 `stats/thinking` 映射，但这些结果实际上没有被列表项消费。
- 结果是详情页打开时产生的全局会话状态更新，会把背后的列表页也拖进重建，放大转场卡顿。

修复:
- 外层监听改成 `_SessionsScreenLayoutSelection`，只跟踪真正会影响列表布局的字段:
  - `id`
  - `seq`
  - `title`
  - `createdAt`
  - `updatedAt`
  - `active`
  - `thinking`
  - `tag`
  - `path`
  - `machineId`
- 删除列表页未使用的 `stats/thinking` 计算链路，避免每次 provider 发射都做无效工作。
- 保留每个列表项自己的细粒度监听，避免列表外层不动时丢失单项更新能力。

## 3. 到顶/到底按钮对长列表使用固定时长整段动画

文件:
- `lib/features/session/screens/session_screen_state_scroll.dart`
- `lib/features/session/screens/session_screen_state_socket.dart`

问题链路:
- 旧逻辑无论列表多长，都对整段距离直接执行 `260ms animateTo()`。
- 长消息列表下，这会迫使 `ListView` 在极短时间内构建大量中间项。
- 同一时间滚动监听还会驱动 sticky prompt 的视口刷新，进一步挤占主线程。

修复:
- 长距离滚动改为“两段式”:
  - 先 `jumpTo()` 到目标附近
  - 再只对最后一个屏幕附近距离做短动画
- 程序化滚动期间暂停 sticky prompt 刷新，滚动结束后再统一补一次视口状态更新。

## 结果

本次修改后，链路被拆成了三层原子职责:

1. 会话入口:
   - 先显示已有快照
   - 非关键刷新延后到转场完成
2. 会话列表:
   - 只在布局相关字段变化时重建外层
   - 单项内容更新交给列表项自身
3. 会话页滚动:
   - 长距离跳转不再强行逐帧穿过整个列表
   - 程序化滚动期间不再触发无意义的 sticky 计算

## 约束与教训

1. 路由入场动画期间只能做首屏必需工作，缓存命中的远端刷新必须后置。
2. 列表页外层 selector 不能监听比“布局所需字段”更大的状态面。
3. 不要保留未消费的衍生计算链路，尤其是列表页的批量统计。
4. 长列表的“到顶/到底”不能用固定时长整段 `animateTo()`，必须做距离分段。
5. 程序化滚动期间要避免运行依赖 render tree 遍历的附加逻辑。

## 验证

- `flutter analyze lib/features/session/screens/sessions_screen.dart lib/features/session/screens/sessions_screen_content.dart lib/features/session/screens/sessions_screen_default_group_list.dart lib/features/session/screens/sessions_screen_custom_group_list.dart lib/features/session/screens/sessions_screen_list_item.dart lib/features/session/screens/session_screen.dart lib/features/session/screens/session_screen_state_load.dart lib/features/session/screens/session_screen_state_scroll.dart lib/features/session/screens/session_screen_state_socket.dart lib/features/session/domain/session_service_messages.dart lib/features/session/domain/session_local_snapshot.dart`
- `flutter test test/session_local_snapshot_test.dart test/session_list_preview_test.dart`
