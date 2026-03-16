part of 'session_screen.dart';

extension _SessionScreenViewIndicators on _SessionScreenState {
  Widget _buildNewMessageIndicator() {
    return FilledButton.icon(
      onPressed: _scrollToBottom,
      icon: const Icon(Icons.arrow_downward_rounded, size: 16),
      label: const Text('有新消息'),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.brandColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        elevation: 3,
      ),
    );
  }

  Widget _buildFloatingThinkingBadge(Session session) {
    final label = session.thinkingAt == null
        ? 'AI 思考中'
        : _formatThinkingLabel(session.thinkingAt!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.brandColor.withValues(alpha: 0.16)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.brandColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyTurnPrompt() {
    final stickyGroup =
        _visibleTurnGroups.cast<_MessageTurnGroup?>().firstWhere(
              (group) => group?.id == _stickyTurnId,
              orElse: () => null,
            );
    final prompt = stickyGroup?.userPrompt;
    if (stickyGroup == null || prompt == null) {
      return const SizedBox.shrink();
    }

    return Semantics(
      button: true,
      label: '跳转到这条消息的第一条回复',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _scrollToTurnReply(stickyGroup.id),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.neutral200),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 12,
                    color: AppTheme.brandColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prompt.text
                                ?.replaceAll(RegExp(r'\s+'), ' ')
                                .trim()
                                .isNotEmpty ==
                            true
                        ? prompt.text!.replaceAll(RegExp(r'\s+'), ' ').trim()
                        : stickyGroup.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 16,
                  color: AppTheme.neutral500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatThinkingLabel(DateTime since) {
    final duration = DateTime.now().difference(since);
    if (duration.inSeconds < 1) {
      return 'AI 思考中';
    }
    if (duration.inSeconds < 60) {
      return 'AI 思考 ${duration.inSeconds}s';
    }
    if (duration.inMinutes < 60) {
      return 'AI 思考 ${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return 'AI 思考 ${duration.inHours}h ${duration.inMinutes % 60}m';
  }

  Widget _buildScrollActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ScrollActionButton(
          icon: Icons.vertical_align_top_rounded,
          tooltip: '回到顶部',
          enabled: _canScrollToTop,
          onTap: _scrollToTop,
        ),
        const SizedBox(height: 10),
        _ScrollActionButton(
          icon: Icons.vertical_align_bottom_rounded,
          tooltip: '回到最新消息',
          enabled: _canScrollToBottom,
          onTap: _scrollToBottom,
        ),
      ],
    );
  }

  /// 输入区域
}
