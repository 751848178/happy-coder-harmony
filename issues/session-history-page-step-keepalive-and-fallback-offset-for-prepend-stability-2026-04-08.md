# Session History Page Step Keepalive And Fallback Offset For Prepend Stability

## Date
- 2026-04-08

## Symptom
- 向上滚动加载更老历史时，分页会连续闪动。
- prepend 完成后，锚点恢复经常拿不到目标消息行，导致页面停在顶部附近并再次触发下一轮续页。

## Root Cause
- 单次历史步长过大，prepend 后目标锚点消息容易被挤出当前 sliver 的构建范围。
- 消息行没有 keep-alive，前一帧刚可见的消息在 prepend 后可能立刻被回收，锚点恢复拿不到 `BuildContext`。
- 恢复失败后如果仍停在顶部附近，边界自动续页会在冷却结束后马上再次触发。

## Fix
- 将历史窗口平移步长从 `96` 降到 `30`，缩小单次 prepend/append 的突变范围。
- 让消息行 anchor 使用 keep-alive，给锚点恢复提供更稳定的 row 生命周期。
- 当锚点恢复多帧仍失败时，回退到一个安全滚动偏移，而不是继续停在顶部 `0` 附近。

## Guardrail
- 历史分页步长不能只按“减少请求次数”来放大；还要考虑 prepend 后锚点是否还能留在可恢复范围内。
- 对于边界分页，恢复失败时必须有“防重入”的安全偏移或其他兜底策略，不能直接把视口留在触发阈值内。
