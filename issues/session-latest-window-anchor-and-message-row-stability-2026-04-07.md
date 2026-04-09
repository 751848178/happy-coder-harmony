# 会话页最新窗口首屏锚定与消息行稳定性修复

日期：2026-04-07

## 背景

大会话已经切到 resident window + 本地 archive 模式后，页面整体卡顿明显下降，但仍有三个用户可感知的问题：

1. 进入会话页时，列表会先显示当前窗口顶部，再补到底部，视觉上像“从第一条逐步加载到最后几条”。
2. 向上或向下续历史时，详情页使用固定像素偏移恢复位置，导致边缘加载像“逐页跳动”。
3. prepend 历史页后，消息列表没有稳定的顶层 key 和 key->index 回查，Sliver 很容易把整片可视区当成新元素重建。

## 根因

### 1. 首屏最新窗口没有先完成视口锚定

- 详情页默认加载的是“最新 resident window”，但 `ListView` 第一次 layout 仍从 `offset=0` 开始。
- `_scheduleScrollToLatest()` 虽然会在首帧后把列表拉到底部，但首帧已经先把窗口顶部画出来了。
- 因此用户会短暂看到“窗口第一条 -> 最后一条”的视觉过程。

### 2. 边缘续历史使用固定偏移恢复滚动位置

- `_loadOlderArchivedMessages()` 之前在 prepend 完历史页后，统一把滚动位置跳到 `140px`。
- `_loadNewerArchivedMessages()` 之前在 append 新页后，统一跳到 `maxScrollExtent - 140`。
- 这种做法没有保留原来的可见锚点，消息高度一旦不均匀，就会出现明显跳位。

### 3. 顶层消息行缺少稳定 key 和索引回查

- `ListView.builder` 每个顶层 item 之前没有稳定的顶层 key。
- prepend 历史页后，已有消息整体后移，Sliver 无法可靠复用原来的 element。
- 虽然 `_MessageBubble` 自己是 `StatefulWidget`，但如果外层 item 被当成新节点，内部 state 仍会被动跟着重建。

## 本轮修复

### A. 首屏只在“已锚定到最新消息”后再显示

- 新增 `_messageViewportReadyN`。
- 当详情页第一次拿到“最新窗口”且尚未滚到底部时，先让消息列表参与 layout 但不对用户可见。
- `_scrollToLatestUntilSettled()` 完成后才把消息列表切为可见，避免首帧先看到窗口顶部。

### B. 边缘续历史改成“锚点保持”而不是固定偏移

- 续更早历史前，抓取当前第一个可见消息行及其相对视口顶部的距离。
- 续较新历史前，抓取当前最后一个可见消息行及其相对视口底部的距离。
- prepend/append 完成后，通过同一条消息行的真实 render box 反推新 offset，保持用户看到的锚点不跳。

### C. 为消息行补齐稳定 key、索引回查和 widget 复用

- 每条消息的顶层 item 现在都有稳定的 `ValueKey(message.id)`。
- `ListView.builder` 增加 `findChildIndexCallback`，让 Sliver 在 prepend/append 后能正确找到旧 child 的新位置。
- 为每条消息增加顶层 render key，供续历史后的锚点恢复使用。
- 为未变化的 `_MessageBubble` 复用缓存 widget，避免仅因父层 rebuild 就重复进入重消息气泡 build。

## 影响范围

- 仅影响会话详情页消息列表首屏锚定、边缘续历史和消息行复用逻辑。
- 不改变消息业务数据、消息归档格式、socket 协议和会话列表功能。

## 后续建议

1. 如果后续还要继续压缩消息列表 CPU 开销，可以继续给 `_SessionScreenBodyPresenter` 增加 prepend 模式的 turn-group / flat-item 增量构建，而不是 prepend 时回退到整窗重算。
2. 如果后续要进一步做到“未变化消息几乎不重建”，可以把消息气泡中的交互状态再拆成独立 notifier，让授权、展开收起、长按菜单等状态不再依赖父列表 rebuild。
