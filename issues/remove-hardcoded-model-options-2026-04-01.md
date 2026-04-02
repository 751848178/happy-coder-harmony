# 移除 APP 内置默认模型选项，对接 PC 端可选项

**日期:** 2026-04-01
**状态:** 进行中
**类型:** 架构重构 / 数据源纠正

## 问题

APP 内置了三组硬编码的模型选项列表：

- `_claudeModelOptions` (default, adaptiveUsage, sonnet, opus)
- `_codexModelOptions` (gpt-5-codex-high/medium/low, gpt-5-minimal/low/medium/high)
- `_geminiModelOptions` (gemini-2.5-pro, gemini-2.5-flash, gemini-2.5-flash-lite)

这些列表在 PC 端未返回模型元数据时作为 fallback 使用，导致：

1. APP 展示的模型选项与 PC 端实际可用的模型不一致
2. PC 端新增或移除模型时，APP 无法同步
3. 用户可能选择到 PC 端不支持的模型，导致会话创建失败

## 根因

`modelOptionsForAgent()` 在 PC metadata 映射为空时，fallback 到硬编码列表：

```dart
List<SessionModeOption> modelOptionsForAgent(String? agent, {dynamic metadataOptions}) {
  final mapped = _mapModeOptions(metadataOptions);
  if (mapped.isNotEmpty) return mapped;
  // fallback to hardcoded lists per agent
  switch (normalizeSessionAgent(agent)) { ... }
}
```

`defaultModelOptionKeyForAgent()` 也依赖硬编码列表返回默认高亮项。

## 解决方案

1. **移除所有硬编码模型列表** — `_claudeModelOptions`, `_codexModelOptions`, `_geminiModelOptions`
2. **`modelOptionsForAgent()` 只返回 PC 端映射结果** — 无 metadata 则返回空列表
3. **移除 `defaultModelOptionKeyForAgent()`** — 所有引用改为使用 `defaultModelModeForAgent()` (返回 `'default'` = "按 PC/CLI 配置" 语义)
4. **UI 增加 loading/error/empty 状态** — 模型选项加载中展示加载态，加载失败展示失败态，无可用选项展示空态

## 涉及文件

| 文件 | 改动 |
|------|------|
| `session_creation_options_modes.dart` | 移除硬编码列表和 fallback，移除 `defaultModelOptionKeyForAgent` |
| `new_session_flow_screen.dart` | 初始 `_modelMode` 改用 `defaultModelModeForAgent` |
| `new_session_flow_screen_content.dart` | fallback 改用 `defaultModelModeForAgent`，增加 loading 状态判断 |
| `new_session_flow_screen_seed.dart` | fallback 改用 `defaultModelModeForAgent` |
| `new_session_flow_screen_pickers.dart` | 设置面板模型区域增加 loading/error/empty 状态 UI |
| `new_session_flow_screen_composer_widgets.dart` | header 模型标签增加 loading/error 状态 |
| `session_screen_view_metadata.dart` | 模型弹窗增加空状态提示 |
| `session_creation_options_test.dart` | 更新测试适配新行为 |

## 经验教训

- APP 不应维护与 PC 端重复的选项列表，所有选项应以 PC 端数据为准
- Fallback 到硬编码数据掩盖了数据源问题，应明确展示 loading/error 状态
- `default` 语义 ("使用 CLI 设置") 和具体模型选项是两个不同概念，不应混淆
