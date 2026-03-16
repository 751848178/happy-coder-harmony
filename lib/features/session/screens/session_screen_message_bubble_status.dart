part of 'session_screen.dart';

extension _SessionScreenMessageBubbleStatus on _MessageBubbleState {
  Widget _buildPermissionRequestMessage() {
    final permission = message.permission;
    if (permission == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.warningColor, size: 20),
              const SizedBox(width: AppTheme.spacingSm),
              const Text(
                '权限请求',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text('工具: ${permission.tool}'),
          if (permission.reason != null) ...[
            const SizedBox(height: 4),
            Text(
              permission.reason!,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutral700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAgentEventMessage() {
    final text = message.text?.trim();
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.neutral100,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral700,
          ),
        ),
      ),
    );
  }

  Widget _buildTurnCloseMessage() {
    final turnClose = message.turnClose;
    if (turnClose == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            turnClose.abandoned ? Icons.cancel : Icons.check_circle_outline,
            size: 16,
            color:
                turnClose.abandoned ? AppTheme.errorColor : AppTheme.neutral600,
          ),
          const SizedBox(width: 8),
          Text(
            turnClose.abandoned ? '回合已终止' : '回合已结束',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              message.text ?? '发生错误',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }


}
