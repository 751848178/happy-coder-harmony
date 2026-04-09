# Session Anchor Restore Needs Multi-Frame Retry And Programmatic Guard

## Date
- 2026-04-08

## Symptom
- 手动向上滚动加载更老历史时，消息列表会连续闪动、像分页一样快速切页。
- 点“到顶”或手动贴近顶部后，历史窗口 prepend 完成，但列表又马上触发下一轮顶部续页。

## Root Cause
- 历史 prepend 后，消息行的 `_BuildContextAnchor` 会在后续 frame 才把新的 row `BuildContext` 注册回 `_messageRowContexts`。
- 旧逻辑在 prepend 后只尝试一次 post-frame 锚点恢复，第一拍拿不到 `rowContext` 就直接放弃。
- 锚点恢复放弃后，滚动位置仍停在顶部附近；而这段恢复期又没有持续处于程序化滚动保护中，导致顶部自动续页立即再次判定为 `eligible` 并重入。

## Fix
- 锚点恢复改成跨多帧重试，而不是第一次 `restore-miss` 就结束。
- 历史窗口 `jumpTo` 和锚点恢复整个过程都纳入程序化滚动保护，恢复期间不允许顶部/底部自动续页再次触发。
- 如果多帧后仍无法恢复锚点，则短暂挂起边界自动加载，避免页面持续闪动。

## Guardrail
- 任何依赖 row `BuildContext` 的视口恢复逻辑，都不能假设“下一帧一定已经重新注册完成”。
- 任何会改变历史窗口并随后执行 `jumpTo` 的逻辑，都必须持有完整的程序化滚动保护生命周期，而不是只包裹最终那一次 `jumpTo`。
