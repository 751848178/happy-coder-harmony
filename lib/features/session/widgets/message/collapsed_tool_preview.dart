import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'session_message_bubble_presenter.dart';

class CollapsedToolPreview extends StatelessWidget {
  const CollapsedToolPreview({
    this.command,
    this.diffPreview,
    this.resultRaw,
    required this.presenter,
  });
  final String? command;
  final String? diffPreview;
  final String? resultRaw;
  final SessionMessageBubblePresenter presenter;

  @override
  Widget build(BuildContext context) {
    final resultText = resultRaw != null && resultRaw!.isNotEmpty
        ? presenter.plainTextPreview(resultRaw!)
        : null;
    final items = <String>[
      if (command != null && command!.isNotEmpty)
        '命令: ${presenter.plainTextPreview(command!)}',
      if (diffPreview != null && diffPreview!.isNotEmpty)
        '改动: ${diffPreview!.split('\n').length} 行',
      if (resultText != null) '输出: $resultText',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < items.take(3).length; i++) ...[
          Text(items[i],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, height: 1.5, color: AppTheme.neutral700)),
          if (i != items.take(3).length - 1) const SizedBox(height: 6),
        ],
        if (items.isEmpty)
          const Text('展开查看完整调用详情',
              style: TextStyle(fontSize: 12, color: AppTheme.neutral700)),
      ]),
    );
  }
}
