import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../encryption/domain/crypto_service.dart';
import '../../../shared/utils/extensions.dart';

/// 链接账户批准页面
///
/// 当用户点击 happy:///account? 链接时显示
/// 用于批准新设备的登录请求
class LinkAccountScreen extends ConsumerStatefulWidget {
  const LinkAccountScreen({super.key, required this.authUrl});

  final String? authUrl;

  @override
  ConsumerState<LinkAccountScreen> createState() => _LinkAccountScreenState();
}

class _LinkAccountScreenState extends ConsumerState<LinkAccountScreen> {
  String? _publicKey;
  String? _publicKeyShort;
  bool _isProcessing = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processAuthUrl();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 处理认证 URL
  Future<void> _processAuthUrl() async {
    try {
      final authState = ref.read(authStateProvider);
      final credentials = authState.credentials;

      if (credentials == null || credentials.secret == null || credentials.secret!.isEmpty) {
        setState(() {
          _errorMessage = '未找到凭证，请先登录';
          _isLoading = false;
        });
        return;
      }

      // 从 URL 参数中获取公钥
      // 格式: happy:///account?base64url=<publicKey>
      final authUrl = widget.authUrl ?? '';
      Logger.info('Processing auth URL: $authUrl');

      String publicKeyBase64Url;

      if (authUrl.startsWith('happy:///account?')) {
        final uri = Uri.tryParse(authUrl);
        if (uri != null && uri.queryParameters.containsKey('base64url')) {
          publicKeyBase64Url = uri.queryParameters['base64url']!;
        } else {
          // 尝试从字符串中提取参数
          final paramStart = authUrl.indexOf('base64url=');
          if (paramStart > 0) {
            publicKeyBase64Url = authUrl.substring(paramStart + 10);
          } else {
            throw Exception('无法解析 base64url 参数');
          }
        }
      } else {
        // 直接使用传入的值作为公钥
        publicKeyBase64Url = authUrl;
      }

      // 使用 CryptoService 解码公钥
      final crypto = await CryptoService.instance;
      final publicKeyBase64 = CryptoService.base64UrlDecode(publicKeyBase64Url);

      setState(() {
        _publicKey = publicKeyBase64;
        _publicKeyShort = publicKeyBase64Url.length > 40
            ? '${publicKeyBase64Url.substring(0, 20)}...${publicKeyBase64Url.substring(publicKeyBase64Url.length - 20)}'
            : publicKeyBase64Url;
        _isLoading = false;
      });

      Logger.info('Public key extracted: ${_publicKeyShort}');
    } catch (e) {
      setState(() {
        _errorMessage = '处理认证链接失败: $e';
        _isLoading = false;
      });
      Logger.error('Process auth URL error: $e');
    }
  }

  /// 批准链接
  Future<void> _approveLink() async {
    if (_publicKey == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);

      // 直接传递公钥（已经从 URL 中解码）
      final success = await authNotifier.linkAccount(_publicKey!);

      if (success && mounted) {
        // 链接成功，返回之前的页面
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('设备链接成功'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = '链接失败，请重试';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '链接失败: $e';
        _isProcessing = false;
      });
      Logger.error('Approve link error: $e');
    }
  }

  /// 取消链接
  void _cancelLink() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingView(context);
    }

    if (_errorMessage != null) {
      return _buildErrorView(context);
    }

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('链接新设备'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 图标
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.brandColor,
                      AppTheme.brandDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.devices,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // 标题
              const Text(
                '设备链接请求',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutral900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // 说明
              const Text(
                '有一台设备请求链接到您的账户。是否批准此请求？',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 公钥信息
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.vpn_key,
                          size: 20,
                          color: AppTheme.brandColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '设备公钥',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.neutral900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.neutral100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _publicKeyShort ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: AppTheme.neutral800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 安全提示
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.security,
                      size: 20,
                      color: AppTheme.infoColor,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '此连接使用端到端加密保护。仅批准您信任的设备。',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.neutral700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 按钮
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _approveLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '批准链接',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : _cancelLink,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.neutral600,
                        side: const BorderSide(color: AppTheme.neutral300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '拒绝',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建加载视图
  Widget _buildLoadingView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('链接新设备'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.brandColor),
            SizedBox(height: 16),
            Text(
              '正在处理链接请求...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('链接失败'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 24),
              const Text(
                '处理链接请求时发生错误',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? '未知错误',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
