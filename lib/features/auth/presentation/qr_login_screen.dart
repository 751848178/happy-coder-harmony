import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/providers/app_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
import '../data/auth_repository.dart';
import '../../encryption/domain/crypto_service.dart';
import 'scan_qr_screen.dart';

/// 欢迎页面
///
/// 支持两种方式：
/// 1. 创建新账户
/// 2. 链接或恢复现有账户（QR 扫描或 Secret Key 输入）
class QRLoginScreen extends ConsumerStatefulWidget {
  const QRLoginScreen({super.key});

  @override
  ConsumerState<QRLoginScreen> createState() => _QRLoginScreenState();
}

class _QRLoginScreenState extends ConsumerState<QRLoginScreen>
    with TickerProviderStateMixin {
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _isLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height;
  }

  Future<void> _startScanLogin() async {
    if (_isScanning) {
      return;
    }
    setState(() {
      _isScanning = true;
    });

    final link = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScanQrScreen(
          title: '扫描登录二维码',
          description: '将摄像头对准 ${AppConfig.appName} 生成的二维码，识别后会自动继续。',
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isScanning = false;
    });
    if (link == null || link.trim().isEmpty) {
      return;
    }
    await _handleScannedLink(link);
  }

  Future<void> _handleScannedLink(String link) async {
    final trimmed = link.trim();
    final authState = ref.read(authStateProvider);

    if (trimmed.startsWith('happy://terminal?')) {
      if (!authState.isAuthenticated) {
        _showSnackBar('这是电脑连接二维码，请先恢复账户后再扫描');
        return;
      }
      if (!mounted) {
        return;
      }
      context.push(
        '${AppRoutes.terminalConnect}?url=${Uri.encodeComponent(trimmed)}',
      );
      return;
    }

    if (trimmed.startsWith('happy:///account?')) {
      if (!authState.isAuthenticated) {
        _showSnackBar('这是设备授权二维码，请先恢复账户后再扫描');
        return;
      }
      if (!mounted) {
        return;
      }
      context.push(
        '${AppRoutes.linkAccount}?url=${Uri.encodeComponent(trimmed)}',
      );
      return;
    }

    final authNotifier = ref.read(authStateProvider.notifier);
    await authNotifier.loginWithLink(trimmed);
    final nextState = ref.read(authStateProvider);
    if (!mounted) {
      return;
    }
    if (nextState.isAuthenticated) {
      context.go(AppRoutes.home);
      _showSnackBar('扫码登录成功');
      return;
    }
    _showSnackBar(nextState.errorMessage ?? '扫码内容无法用于登录');
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // If already authenticated, redirect to home
    if (authState.isAuthenticated && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(AppRoutes.home);
        }
      });
      return const SizedBox.shrink();
    }

    // Portrait layout with create/restore options
    if (!_isLandscape(context)) {
      return _buildPortraitView(context);
    }

    // Landscape layout
    return _buildLandscapeView(context);
  }

  Widget _buildPortraitView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Icon(
                  Icons.code,
                  size: 80,
                  color: AppTheme.brandColor,
                ),

                const SizedBox(height: 24),

                // App Name
                const Text(
                  AppConfig.appName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutral900,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  AppConfig.appTagline,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.neutral600,
                  ),
                ),

                const SizedBox(height: 48),

                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('创建账户'),
                    onPressed: _createAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(
                      _isScanning
                          ? Icons.qr_code_2_rounded
                          : Icons.center_focus_strong_rounded,
                    ),
                    label: Text(_isScanning ? '扫码中...' : '扫码登录'),
                    onPressed: _isScanning ? null : _startScanLogin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: BorderSide(color: AppTheme.neutral300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Link/Restore Account Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner_outlined),
                    label: const Text('链接或恢复账户'),
                    onPressed: () => context.push(AppRoutes.restore),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.brandColor,
                      side: const BorderSide(color: AppTheme.brandColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Icon(
                      Icons.code,
                      size: 80,
                      color: AppTheme.brandColor,
                    ),

                    const SizedBox(height: 24),

                    // App Name
                    const Text(
                      AppConfig.appName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutral900,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      AppConfig.appTagline,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Create Account Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('创建账户'),
                        onPressed: _createAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(
                          _isScanning
                              ? Icons.qr_code_2_rounded
                              : Icons.center_focus_strong_rounded,
                        ),
                        label: Text(_isScanning ? '扫码中...' : '扫码登录'),
                        onPressed: _isScanning ? null : _startScanLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: BorderSide(color: AppTheme.neutral300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Link/Restore Account Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner_outlined),
                        label: const Text('链接或恢复账户'),
                        onPressed: () => context.push(AppRoutes.restore),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.brandColor,
                          side: const BorderSide(color: AppTheme.brandColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createAccount() async {
    try {
      final authRepository = AuthRepository.instance;

      // Try to create & login locally first (no other device required)
      final crypto = await CryptoService.instance;
      final keyPair = await crypto.generateKeyPair();
      final secretKey = keyPair['secretKey'];
      if (secretKey == null || secretKey.isEmpty) {
        throw Exception('生成密钥失败');
      }

      final authNotifier = ref.read(authStateProvider.notifier);
      await authNotifier.loginWithSecretKey(secretKey);
      final authState = ref.read(authStateProvider);
      if (authState.isAuthenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('创建账户成功'),
              backgroundColor: AppTheme.successColor,
              duration: Duration(seconds: 3),
            ),
          );
          context.go(AppRoutes.home);
        }
        return;
      }

      // Fallback: request approval via QR from another device
      final qrResponse = await authRepository.generateQRCodeForTerminal();
      final fallbackSecret = qrResponse.secretKey;
      if (fallbackSecret == null || fallbackSecret.isEmpty) {
        throw Exception('生成密钥失败');
      }

      await authRepository.saveSecretKey(fallbackSecret);
      Logger.info('Secret key saved locally');

      await authNotifier.startAccountAuthPolling(
        secretKey: fallbackSecret,
        expiresAt: qrResponse.expiresAt,
      );

      if (mounted) {
        await _showQRCodeDialog(qrResponse.qrData);
      }
    } catch (e) {
      Logger.error('Create account error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建账户失败: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _showQRCodeDialog(String qrData) async {
    if (!mounted) return;
    final trimmed = qrData.trim();
    final hasQrData = trimmed.isNotEmpty;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '创建账户',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text('请用另一个设备扫描此二维码以批准账户'),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: hasQrData
                          ? QrImageView(
                              data: trimmed,
                              version: QrVersions.auto,
                              size: 220.0,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppTheme.brandColor,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                color: AppTheme.brandColor,
                              ),
                              gapless: false,
                              errorStateBuilder: (context, error) {
                                return SizedBox(
                                  width: 220,
                                  height: 220,
                                  child: Center(
                                    child: Text(
                                      '二维码生成失败\n$error',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.errorColor,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : const SizedBox(
                              width: 220,
                              height: 220,
                              child: Center(
                                child: Text(
                                  '二维码数据为空',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '链接: ${trimmed.length > 32 ? trimmed.substring(0, 32) : trimmed}...',
                    style: TextStyle(fontSize: 12, color: AppTheme.neutral600),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('关闭'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
