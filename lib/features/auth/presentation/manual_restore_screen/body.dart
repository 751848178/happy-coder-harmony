part of 'manual_restore_screen.dart';

Widget _buildManualRestoreScaffold(_ManualRestoreScreenState state) {
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => state.context.pop(),
      ),
      title: const Text('恢复账户'),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildManualRestoreInfoCard(),
            const SizedBox(height: 32),
            _buildManualRestoreField(state),
            if (state._errorMessage != null) ...[
              const SizedBox(height: 12),
              _buildManualRestoreError(state._errorMessage!),
            ],
            const SizedBox(height: 24),
            _buildManualRestoreButton(state),
          ],
        ),
      ),
    ),
  );
}

Widget _buildManualRestoreInfoCard() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.neutral200),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.brandColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              const Icon(Icons.vpn_key, color: AppTheme.brandColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '输入您的 Secret Key',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Secret Key 用于恢复您对账户的访问权限。请确保从可信来源获取。',
                style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildManualRestoreField(_ManualRestoreScreenState state) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Secret Key',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutral700,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: state._errorMessage != null
                ? AppTheme.errorColor
                : AppTheme.neutral300,
          ),
        ),
        child: TextField(
          controller: state._secretKeyController,
          obscureText: !state._showSecret,
          maxLines: state._showSecret ? 4 : 1,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'XXXXX-XXXXX-XXXXX...',
            hintStyle: TextStyle(color: AppTheme.neutral400),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          TextButton(
            onPressed: state._toggleSecretVisibility,
            child: Text(
              state._showSecret ? '隐藏' : '显示',
              style: const TextStyle(
                color: AppTheme.brandColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          if (state._secretKeyController.text.isNotEmpty)
            TextButton(onPressed: state._clearSecret, child: const Text('清空')),
        ],
      ),
    ],
  );
}

Widget _buildManualRestoreError(String message) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.errorColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, size: 16, color: AppTheme.errorColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 13, color: AppTheme.errorColor),
          ),
        ),
      ],
    ),
  );
}

Widget _buildManualRestoreButton(_ManualRestoreScreenState state) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: state._isRestoring ? null : state._restoreAccount,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.brandColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: state._isRestoring
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Text(
              '恢复账户',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    ),
  );
}
