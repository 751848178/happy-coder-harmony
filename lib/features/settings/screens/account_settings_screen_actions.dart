part of 'account_settings_screen.dart';

extension _AccountSettingsScreenActions on AccountSettingsScreen {
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.neutral600,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.brandColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.brandColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.neutral900,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.neutral600,
              ),
            ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.neutral400),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Future<void> _scanDeviceLink(BuildContext context) async {
    final scannedLink = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScanQrScreen(
          title: '扫描设备二维码',
          description: '将摄像头对准 ${AppConfig.appName} 设备或电脑上的二维码，识别后会自动继续。',
        ),
      ),
    );
    if (!context.mounted || scannedLink == null || scannedLink.trim().isEmpty) {
      return;
    }

    final link = scannedLink.trim();
    final encodedLink = Uri.encodeComponent(link);
    if (link.startsWith('happy://terminal?')) {
      context.push('${AppRoutes.terminalConnect}?url=$encodedLink');
      return;
    }
    if (link.startsWith('happy:///account?')) {
      context.push('${AppRoutes.linkAccount}?url=$encodedLink');
      return;
    }
    if (link.startsWith('happy://') ||
        link.startsWith('handy://') ||
        link.startsWith('https://happy.link/')) {
      context.push('${AppRoutes.restoreManual}?url=$encodedLink');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('无法识别二维码内容，请确认它来自 ${AppConfig.appName}'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除本地数据'),
        content: const Text('确认要清除所有本地数据吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await settings.SettingsService.instance.clearAll();
                await TokenStorageService.instance.clearAll();
                SessionRepository.instance.clearAll();
                await ref
                    .read(settingsStateProvider.notifier)
                    .resetToDefaults();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('本地数据已清除'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('清除数据失败: ${e.toString()}'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确认要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).logout();
              context.push(AppRoutes.auth);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => _QRCodeDialogContent(ref: ref),
    );
  }
}
