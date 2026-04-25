part of 'security_settings_screen.dart';

void _showPermissionModeDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('默认权限模式'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PermissionModeOption(
            icon: Icons.block,
            title: '手动批准',
            description: '每次工具调用都需要手动确认',
            onTap: () => _applyPermissionMode(
                dialogContext, ref, 'manual', '已设置为手动批准模式'),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _PermissionModeOption(
            icon: Icons.check_circle,
            title: '自动批准',
            description: '自动批准所有工具调用',
            onTap: () =>
                _applyPermissionMode(dialogContext, ref, 'auto', '已设置为自动批准模式'),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _PermissionModeOption(
            icon: Icons.help_outline,
            title: '询问模式',
            description: '根据工具类型询问是否批准',
            onTap: () =>
                _applyPermissionMode(dialogContext, ref, 'ask', '已设置为询问模式'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('取消'),
        ),
      ],
    ),
  );
}

void _applyPermissionMode(
  BuildContext context,
  WidgetRef ref,
  String mode,
  String message,
) {
  Navigator.pop(context);
  ref.read(settingsStateProvider.notifier).setPermissionMode(mode);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _showRestoreDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('恢复密钥'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: '备份ID',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: AppTheme.spacingMd),
          TextField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: '密码',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('密钥恢复功能需要后端 API 支持')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('恢复'),
        ),
      ],
    ),
  );
}

void _showComingSoonDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('即将推出'),
      content: const Text('此功能正在开发中，敬请期待！'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}
