# 会话详情虚拟列表：窗口切换后缺少边界重算，且顶底按钮未反映历史加载忙碌态

**日期**: 2026-04-25
**严重级别**: P0 Critical
**状态**: 已修复

## 现象

- 进入会话详情后，消息区经常只显示最新一个批次。
- 上翻到边界后不会继续衔接更早历史，看起来像“只能看到最后一页”。
- “到顶 / 到底”按钮在历史加载过程中仍然表现为可点击，但点击后没有稳定反馈。

## 审查范围

- `lib/features/session/screens/session_detail/viewport/state_restore.dart`
- `lib/features/session/screens/session_detail/view/indicators.dart`
- `lib/features/session/screens/session_detail/state/build.dart`
- 关联链路：
  - `state/refresh_anchor.dart`
  - `state/refresh_older.dart`
  - `state/refresh_newer.dart`
  - `viewport/edge_autoload.dart`

## 已确认根因

### 根因 1：拆分文件后，`scheduleViewportStateRefresh()` 丢失了 scroll metrics 重算

历史窗口平移、anchor restore、边界跳转这些流程里，resident window 会变化，但滚动 offset 不一定变化。

这时如果只刷新 sticky prompt，而不主动执行 `handleScrollMetricsChanged()`，就会出现：

- `canScrollToTop / canScrollToBottom` 仍停留在旧状态
- top-edge / bottom-edge autoload 不会基于新窗口重新评估
- 用户停在边界附近时，后续连续续页直接中断

结果上就表现成：

- 列表始终停在最新一批
- 滚动和顶底按钮都不能把窗口继续推进

### 根因 2：顶底按钮只看边界可达标志，没有反映“历史正在加载 / 归档正在 hydration”

按钮 enable 状态此前只依赖：

- `_canScrollToTop`
- `_canScrollToBottom`

但真实动作还会被以下状态短路：

- `_isLoadingOlderMessages`
- `_isLoadingNewerMessages`
- `_isHydratingArchiveHistory`

因此在历史 hydration 或边界加载进行中，按钮仍显示为可点击，用户点击后却只会命中 no-op / await 分支，体感上就是“按钮亮着但没反应”。

## 修复方案

### 修复 1：窗口变化后的延迟刷新必须补做完整 metrics 重算

在 `scheduleViewportStateRefresh()` 的 post-frame 阶段补回：

- `handleScrollMetricsChanged()`

并保持它发生在 `_viewportUpdateScheduled` 仍为 true 的窗口内，避免递归重复调度。

这样可以确保：

- resident window 一旦变化，边界状态立即收敛
- edge autoload 可以继续跨窗口推进
- 顶底按钮状态和真实可达边界重新一致

### 修复 2：顶底按钮加入历史加载忙碌态约束

滚动操作按钮现在除了 `_canScrollToTop / _canScrollToBottom` 外，还会同时检查：

- `_isLoadingOlderMessages`
- `_isLoadingNewerMessages`
- `_isHydratingArchiveHistory`

并在这些状态切换时触发局部重建。

这样按钮只会在“当前真的可操作”时表现为 enabled，避免忙碌中的假可点状态。

## 后续开发约束

1. 任何会替换 resident window 但不一定改变 offset 的流程，都必须主动重算 scroll metrics，不能只依赖 `ScrollController` listener。
2. 边界按钮的 enable 语义必须覆盖真实动作前置条件，不能只看几何滚动范围。
3. 详情页拆分文件后，涉及 viewport 状态机的方法不能只迁移 UI 副作用，必须一起迁移边界/滚动语义更新。
