# 会话消息行 GlobalKey 导致列表重排断言

日期：2026-04-08

## 现象

会话详情页启动或切换消息窗口时，Flutter 抛出：

- `framework.dart: Failed assertion: line 7010 pos 12: 'child == _child'`

## 根因

为了做“续历史后的锚点恢复”，之前给每条消息行都分配了一个 `GlobalKey`，再通过 `currentContext` 读取 render box。

这在长列表里风险很高：

1. 列表 child 会因为 prepend / append / 初始隐藏后显示而频繁换 slot
2. `GlobalKey` 会触发跨父节点 reparent 语义
3. 一旦 child 在更新过程中被框架判定为从旧父节点迁移到新父节点，就可能命中 `SingleChildRenderObjectElement.forgetChild()` 的 ownership 断言

## 修复

- 去掉每条消息行上的 `GlobalKey`
- 改成轻量的“行上下文注册”方案：
  - 行 widget mount 后，把自己的 `BuildContext` 注册到详情页 state
  - 行 widget deactive 时，从注册表移除
  - 续历史前后仍然可以通过 `BuildContext.findRenderObject()` 做锚点恢复

## 结论

在滚动大列表里：

- 可以用稳定 `ValueKey`
- 可以用 `findChildIndexCallback`
- 可以缓存索引和解析结果
- 但不要给每一行上 `GlobalKey`，除非确实需要跨树搬移语义
