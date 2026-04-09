# 会话页默认入口窗口切到 30 条并对齐本地快照窗口

日期：2026-04-08

## 背景

用户要求会话详情页默认只加载更少消息，进入页优先看最新一小段，而不是一次恢复较大的最新窗口。

## 本轮改动

- `SessionServiceNotifier.sessionDetailAutomaticMessageWindowSize`
  - `96 -> 30`
- `localSessionSnapshotMessageWindowSize`
  - `96 -> 30`

## 原因

如果只改远端默认窗口，不改本地 snapshot 窗口，会出现行为不一致：

1. 冷启动从远端加载时只拿 30 条
2. 但从本地缓存恢复时可能仍恢复 96 条

这样会导致：

- 不同进入路径的首屏消息条数不一致
- 首屏滚动锚定和性能表现不稳定

因此本轮把“默认加载窗口”和“本地快照窗口”一起对齐到 30 条。

## 影响

- 会话详情页默认首屏只恢复最新 30 条
- 本地缓存恢复时也只恢复最新 30 条
- resident window / archive window 逻辑不变，仍支持后续边界续历史
