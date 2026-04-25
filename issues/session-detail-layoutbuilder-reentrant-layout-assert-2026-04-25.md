# 会话详情页真机崩溃：消息区 `LayoutBuilder` 在重入布局链路下触发断言

**日期**: 2026-04-25
**严重级别**: P0 Critical
**状态**: 已修复

## 现象

- 真机上发送消息后，消息区再次出现“两个消息列表上下平分屏幕”的异常。
- 紧接着页面进入全局错误页，首个断言为：
  - `package:flutter/src/rendering/object.dart: Failed assertion: line 4166 pos 14: 'debugNeedsLayout': is not true.`
- 用户返回上一页后，又继续出现二次断言：
  - `package:flutter/src/widgets/framework.dart: Failed assertion: line 6171 pos 14: '_dependents.isEmpty': is not true.`

## 这次确认的具体问题

### 根因 1：会话消息区仍然依赖 `LayoutBuilder` 提供悬浮按钮高度

会话详情页消息区主体在 `Expanded` 内包了一层 `LayoutBuilder`，它唯一用途只是把
`constraints.maxHeight` 传给滚动操作按钮。

但同一块区域里同时存在：

- 消息窗口切换后的同步滚动校正
- 行锚点 attach/detach
- 多个 `ValueListenableBuilder` 的高频更新
- 历史窗口 prepend/append 后的 post-frame 恢复

真机上这几条链路叠在一起时，`LayoutBuilder` 对应的
`RenderConstrainedLayoutBuilder` 会进入重复 `scheduleLayoutCallback()` 的非法状态，
最终命中 `rendering/object.dart` 4166 行断言。

### 根因 2：`_dependents.isEmpty` 是首个布局断言后的连锁损坏

第二个 `framework.dart` 6171 行断言发生在页面已经因为首个布局断言进入损坏状态后。
此时返回上一页，框架在清理 inherited 依赖链时发现元素树不一致，于是再次报错。

因此这次真正需要修的是首个布局期断言，而不是单独去处理第二个销毁阶段异常。

## 修复方案

- 移除会话消息区 `Expanded` 内的 `LayoutBuilder`。
- 滚动操作按钮的 `viewportHeight` 改为直接读取：
  - 当前消息列表 `RenderBox` 的实际高度
  - 或滚动位置的 `viewportDimension`
  - 最后再降级到 `MediaQuery`

这样消息区不再依赖布局回调型组件，也就切断了真机上“发送消息/滚动修正/历史窗口切换”
时触发重入布局断言的入口。

## 修改文件

- `lib/features/session/screens/session_detail/state/build.dart`
- `lib/features/session/screens/session_detail/view/indicators.dart`

## 后续开发约束

1. 会话页主消息区不要再为获取尺寸引入 `LayoutBuilder` 这类布局回调型组件，优先读取现成视口尺寸。
2. 涉及滚动校正、历史窗口切换、锚点恢复的区域，避免把“布局回调”和“状态回写”放在同一热路径上。
3. 出现 `_dependents.isEmpty` 时，先排查前序断言，不要把后续清理异常当成第一根因。
