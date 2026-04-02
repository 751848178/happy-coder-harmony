# 消息合并丢失子代理 children 数据

> 创建日期: 2026-03-31

## 问题概述

增量消息合并时，`_mergeMessage()` 在合并 tool-call 类型消息时丢失 `children` 字段，导致嵌套后的 sub-agent 子消息被清除。

## 根因

- 文件：`lib/features/session/data/session_repository_messages_merge.dart`
- `_mergeMessage()` 对 tool-call 合并路径调用 `previous.copyWith(tool: ...)` 但未传递 `children`
- `copyWith` 的 `children` 参数默认为 `const []`，导致每次合并都把 children 清空

## 修复

在合并 tool-call 消息时：
1. 优先使用 `incoming.children`（来自 `_nestSidechainMessages` 的新数据）
2. 如果 incoming children 为空，保留 `previous.children`
3. 通过 `copyWith(children: mergedChildren)` 显式传递

```dart
final mergedChildren = incoming.children.isNotEmpty
    ? incoming.children
    : previous.children;
return previous.copyWith(
  // ...
  children: mergedChildren,
);
```
