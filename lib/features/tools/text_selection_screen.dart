import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 文本选择测试页
class TextSelectionScreen extends StatelessWidget {
  const TextSelectionScreen({
    super.key,
    this.text,
  });

  final String? text;

  @override
  Widget build(BuildContext context) {
    final content = text ??
        'Happy Coder 文本选择页。\n\n这个页面用于对齐原项目中的 `/text-selection`，'
            '便于在移动端验证长文本、代码片段和可复制内容的选择行为。';

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('文本选择'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              side: BorderSide(color: AppTheme.neutral200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SelectableText(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
