import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/providers/app_providers.dart';
import '../../../app/services/settings_service.dart' as settings;

import '../../../shared/models/auth_models.dart';
import '../../../features/auth/data/token_storage_service.dart';
import '../../../features/auth/presentation/scan_qr_screen.dart';
import '../../../features/session/data/session_repository.dart';
import '../../../features/encryption/domain/crypto_service.dart';

/// 账号设置屏幕
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final credentials = authState.credentials;

    if (credentials == null) {
      return _buildNotLoggedInView(context);
    }

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('账号设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 用户信息卡片
          _UserInfoCard(credentials: credentials),
          const SizedBox(height: AppTheme.spacingLg),
          // 账号操作
          _buildSectionHeader(context, '账号操作'),
          _buildSettingItem(
            icon: Icons.qr_code,
            title: '生成连接二维码',
            subtitle: '在另一台设备上扫描此二维码即可完成绑定',
            onTap: () => _showQRCodeDialog(context, ref),
          ),
          _buildSettingItem(
            icon: Icons.qr_code_scanner_outlined,
            title: '扫码连接设备',
            subtitle: '扫描另一台设备上的二维码，继续账户或电脑连接',
            onTap: () => _scanDeviceLink(context),
          ),
          _buildSettingItem(
            icon: Icons.computer,
            title: '连接电脑',
            subtitle: '扫码或粘贴 happy://terminal? 链接进行授权',
            onTap: () => context.push(AppRoutes.terminalConnect),
          ),
          _buildSettingItem(
            icon: Icons.dns_outlined,
            title: '服务器地址',
            subtitle: '确保与电脑端 Happy CLI 使用同一个后端地址',
            onTap: () => context.push(AppRoutes.settingsServer),
          ),
          _buildSettingItem(
            icon: Icons.vpn_key,
            title: '备份恢复密钥',
            subtitle: '保存当前设备的加密密钥，便于后续恢复',
            onTap: () => context.push(AppRoutes.backupKeys),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          // 危险操作
          _buildSectionHeader(context, '危险操作'),
          _buildSettingItem(
            icon: Icons.delete_outline,
            title: '清除本地数据',
            subtitle: '删除所有本地缓存和数据',
            iconColor: AppTheme.errorColor,
            onTap: () => _showClearDataDialog(context, ref),
          ),
          _buildSettingItem(
            icon: Icons.logout,
            title: '退出登录',
            subtitle: '注销当前账号',
            iconColor: AppTheme.errorColor,
            onTap: () => _showLogoutDialog(context, ref),
          ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('账号设置'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              '未登录',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral900,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              '请先登录以访问账号设置',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.auth),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('去登录'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.neutral600,
              ),
            )
          : null,
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
    showDialog(
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
                // 清除设置数据
                await settings.SettingsService.instance.clearAll();

                // 清除认证数据
                await TokenStorageService.instance.clearAll();

                // 清除会话数据
                SessionRepository.instance.clearAll();

                // 重置设置状态
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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('清除数据失败: ${e.toString()}'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
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
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _QRCodeDialogContent(ref: ref),
    );
  }
}

/// QR 码对话框内容
class _QRCodeDialogContent extends ConsumerStatefulWidget {
  const _QRCodeDialogContent({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_QRCodeDialogContent> createState() =>
      _QRCodeDialogContentState();
}

class _QRCodeDialogContentState extends ConsumerState<_QRCodeDialogContent> {
  String? _qrData;
  String? _qrId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  Future<void> _generateQRCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final crypto = await CryptoService.instance;
      final keyPairResult = await crypto.generateQRAuthKeyPair();

      setState(() {
        _qrData = keyPairResult['qrData'] as String;
        _qrId = (keyPairResult['publicKey'] as String).substring(0, 16);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '生成 QR 码失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('链接新设备'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.errorColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: AppTheme.errorColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(32),
                child:
                    const CircularProgressIndicator(color: AppTheme.brandColor),
              )
            else if (_qrData != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.neutral200),
                ),
                child: Column(
                  children: [
                    // QR 码
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: _qrData!,
                        version: QrVersions.auto,
                        size: 200.0,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppTheme.brandColor,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          color: AppTheme.brandColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 说明
                    Text(
                      '在已登录的 ${AppConfig.appName} 设备上扫描此二维码，即可继续连接。',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '连接标识：${_qrId?.substring(0, 8)}...',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.neutral400,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        if (_qrData != null)
          TextButton(
            onPressed: _generateQRCode,
            child: const Text('刷新'),
          ),
      ],
    );
  }
}

/// 用户信息卡片
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
          Row(
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
          ),
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
      if (credentials is Credentials) {
        return credentials.machineId;
      }
      return '未知设备';
    } catch (e) {
      return '未知设备';
    }
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
