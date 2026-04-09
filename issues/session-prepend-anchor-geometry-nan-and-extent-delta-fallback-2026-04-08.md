# Session Prepend Anchor Geometry NaN And Extent-Delta Fallback

## Date
- 2026-04-08

## Symptom
- 快速向上翻历史时，会卡在某一页。
- 反复上下翻后，消息开始来回闪动，最后才跳到更老甚至最早历史。

## Root Cause
- 历史 prepend 后，锚点消息虽然仍在窗口里，也还能拿到 row context，但它的全局几何在某些 frame 会变成 `NaN/Infinity`。
- 旧逻辑只要拿到了 row context 就会继续走几何恢复，导致 `delta=NaN` 被当成正常恢复路径的一部分。
- 结果视口没有真正恢复到 prepend 前的位置，仍然停留在顶部触发区附近，后续顶部自动续页继续重入，引发闪动。

## Fix
- 对 anchor 恢复使用的 row/global geometry 加入有限值校验，`NaN/Infinity` 直接视为无效恢复。
- 当 prepend 后的 anchor 几何不可用时，改用 `scroll extent delta` 作为兜底恢复策略，尽量保持 prepend 前的可视内容位置。
- sticky prompt 的 viewport 查询也改成安全分支，避免在不稳定 frame 中因为 render tree 暂态再触发额外异常。

## Guardrail
- 历史 prepend 的视口恢复不能只依赖“锚点行仍然存在”；还必须校验该行几何是稳定且有限的。
- 对长列表历史分页，`scroll extent delta` 应作为 anchor 恢复失败时的标准兜底路径，而不是固定偏移量回退。
