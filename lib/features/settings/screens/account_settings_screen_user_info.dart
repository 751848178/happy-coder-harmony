part of 'account_settings_screen.dart';

class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({required this.credentials});

  final dynamic credentials;

  @override
  Widget build(BuildContext context) {
    final machineId = _getMachineId();
    final machineKeyReady = credentials is Credentials &&
        (credentials.publicKey?.isNotEmpty ?? false);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingMd,
        AppTheme.spacingMd,
        AppTheme.spacingSm,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.neutral200),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _UserInfoHeader(),
          const SizedBox(height: AppTheme.spacingLg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: AppTheme.neutral100,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '机器标识',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutral600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  machineId,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppTheme.textPrimary,
                    fontFamily: AppTheme.fontFamilyMono,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.security_outlined,
                      label: machineKeyReady ? '公钥已就绪' : '公钥未就绪',
                    ),
                    _InfoPill(
                      icon: Icons.lock_outline,
                      label: credentials is Credentials
                          ? '加密：${(credentials as Credentials).encryptionType.toValue()}'
                          : '加密已启用',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMachineId() {
    try {
      if (credentials is Credentials) return credentials.machineId;
      return '未知设备';
    } catch (_) {
      return '未知设备';
    }
  }
}

class _UserInfoHeader extends StatelessWidget {
  const _UserInfoHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.brandColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.devices_outlined,
            size: 26,
            color: AppTheme.brandColor,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '当前设备',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.neutral900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '用于接收会话列表、扫码绑定和电脑授权',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.neutral600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.brandColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
