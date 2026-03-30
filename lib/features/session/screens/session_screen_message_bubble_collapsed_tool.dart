part of 'session_screen.dart';

extension _SessionScreenMessageBubbleCollapsedTool on _MessageBubbleState {
  Widget _buildCollapsedToolPreview({
    required String? command,
    required String? diffPreview,
    required String? resultPreview,
  }) {
    final summaryItems = <String>[
      if (command != null && command.isNotEmpty)
        '命令: ${_plainTextPreview(command)}',
      if (diffPreview != null && diffPreview.isNotEmpty)
        '改动: ${diffPreview.split('\n').length} 行',
      if (resultPreview != null && resultPreview.isNotEmpty)
        '输出: ${_plainTextPreview(resultPreview)}',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < summaryItems.take(3).length; index++) ...[
            Text(
              summaryItems[index],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppTheme.neutral700,
              ),
            ),
            if (index != summaryItems.take(3).length - 1)
              const SizedBox(height: 6),
          ],
          if (summaryItems.isEmpty)
            const Text(
              '展开查看完整调用详情',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.neutral700,
              ),
            ),
        ],
      ),
    );
  }
}
