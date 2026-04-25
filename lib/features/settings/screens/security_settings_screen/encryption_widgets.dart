part of 'security_settings_screen.dart';

class _EncryptionStatusCard extends StatelessWidget {
  const _EncryptionStatusCard({required this.credentials});

  final dynamic credentials;

  @override
  Widget build(BuildContext context) {
    final isEncrypted = credentials != null;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isEncrypted
                      ? AppTheme.successColor.withValues(alpha: 0.1)
                      : AppTheme.neutral200,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  isEncrypted ? Icons.lock : Icons.lock_open,
                  color:
                      isEncrypted ? AppTheme.successColor : AppTheme.neutral500,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEncrypted ? '已启用加密' : '未启用加密',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEncrypted ? '您的数据使用端到端加密保护' : '您的数据未加密，建议启用加密功能',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.neutral600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isEncrypted) ...[
            const SizedBox(height: AppTheme.spacingMd),
            const _EncryptionInfoRow(
              icon: Icons.vpn_key,
              label: '加密类型',
              value: 'Sodium (现代)',
            ),
            const SizedBox(height: AppTheme.spacingSm),
            const _EncryptionInfoRow(
              icon: Icons.key,
              label: '公钥已设置',
              value: '是',
            ),
          ],
        ],
      ),
    );
  }
}

class _EncryptionInfoRow extends StatelessWidget {
  const _EncryptionInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.neutral600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(fontSize: 13, color: AppTheme.neutral600),
          ),
        ),
      ],
    );
  }
}
