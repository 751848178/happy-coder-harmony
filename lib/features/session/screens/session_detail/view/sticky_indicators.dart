part of '../session_detail.dart';

extension _SessionScreenStickyIndicators on _SessionScreenState {
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
}
