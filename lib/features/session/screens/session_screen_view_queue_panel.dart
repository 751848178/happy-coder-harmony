part of 'session_screen.dart';

extension _SessionScreenViewQueuePanel on _SessionScreenState {
  Widget _buildQueuedComposerPanel({required bool busy}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: SizedBox(
        key: ValueKey<String>('queued-panel-${_queuedMessages.length}-$busy'),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.playlist_add_check_rounded,
                    size: 14,
                    color: AppTheme.brandColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '待发送消息 ${_queuedMessages.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (busy)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.brandColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'AI 回复中',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.brandColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 112),
              child: ListView.separated(
                shrinkWrap: true,
                physics: _queuedMessages.length > 2
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: _queuedMessages.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppTheme.neutral200,
                ),
                itemBuilder: (context, index) {
                  final item = _queuedMessages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text(
                            '${index + 1}.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.neutral700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _editQueuedComposerMessage(item),
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              item.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _editQueuedComposerMessage(item),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            '修改',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _removeQueuedComposerMessage(item.id),
                          tooltip: '删除待发送消息',
                          visualDensity: VisualDensity.compact,
                          splashRadius: 18,
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldAutoApprove(Session session) {
    final normalized =
        (session.metadata?['currentOperatingModeCode']?.toString() ??
                session.permissionMode ??
                '')
            .replaceAll(RegExp(r'[\s_\-]'), '')
            .toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    return normalized.contains('bypass') ||
        normalized.contains('skip') ||
        normalized.contains('yolo') ||
        normalized.contains('acceptedit') ||
        normalized.contains('auto');
  }
}
