# 会话消息气泡实例缓存触发 Flutter child ownership 断言

日期：2026-04-08

## 现象

会话详情页启动时报错：

- `package:flutter/src/widgets/framework.dart': Failed assertion: line 7010 pos 12: 'child == _child': is not true`

页面直接进入 `App failed to render`。

## 根因

上一轮为了减少消息列表重复 build，在详情页里新增了 `_messageBubbleWidgetCache`，按消息 `id` 缓存 `_MessageBubble` 对应的 `Widget` 实例，然后在后续 build 中直接复用同一个 widget 对象。

这在 Flutter 里是不安全的：

- widget 是配置描述，不应该被当成“可跨父节点复用的实例对象”缓存。
- 当列表结构变化时，比如：
  - 首屏隐藏列表后再切为可见
  - prepend / append 历史页
  - 顶层 wrapper 发生位置变化
- 同一个 `_MessageBubble` widget 实例会被不同父节点生命周期交替持有。

最终触发 `SingleChildRenderObjectElement.forgetChild()` 的 ownership 断言，也就是：

- 旧父节点在 forget child 时，发现这个 child 已经不是自己当前记录的 `_child`

## 修复

- 移除了 `_messageBubbleWidgetCache`
- 保留安全的性能优化：
  - 顶层消息 item 的稳定 `ValueKey(message.id)`
  - `ListView.builder.findChildIndexCallback`
  - `_MessageBubble` 自身的 state/presenter/cache
  - `RepaintBoundary`

## 结论

要缓存的是：

- 解析结果
- presenter 结果
- 索引映射
- 行定位 key

不要缓存的是：

- 可被 Flutter element tree 挂载的 widget 实例本身

## 后续约束

后续如果要继续优化“消息进入可视区后尽量只渲染一次”，只能走这些安全方向：

1. 保持稳定 key，让 element/state 能被复用
2. 缓存 message presenter / markdown parse / tool preview
3. 把会变的交互状态局部化，避免父列表 rebuild 传导
4. 不在业务层缓存可直接挂载到 widget tree 的 widget 实例
