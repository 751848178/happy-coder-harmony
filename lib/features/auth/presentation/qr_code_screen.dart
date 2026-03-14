import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/providers/app_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
import '../../encryption/domain/crypto_service.dart';
import '../../../shared/platform/platform_storage.dart';

/// QR 码登录页面
///
/// 显示 QR 码供用户在电脑上扫描登录
/// 支持 Happy Coder 格式的 happy:///account?base64url=<publicKey>
class QRCodeScreen extends ConsumerStatefulWidget {
  const QRCodeScreen({super.key});

  @override
  ConsumerState<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends ConsumerState<QRCodeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _confirmCodeController = TextEditingController();
  bool _isManualConfirm = false;

  // QR 码状态
  String? _qrData;
  String? _qrId;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  // 倒计时
  Timer? _countdownTimer;
  Timer? _statusPollingTimer;
  int _secondsRemaining = 300; // 5分钟 = 300秒
  DateTime? _expiresAt;

  // 轮询状态
  bool _isPolling = false;
  String? _pollingStatus;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _statusPollingTimer?.cancel();
    _confirmCodeController.dispose();
    super.dispose();
  }

  /// 生成 QR 码
  Future<void> _generateQRCode({bool isRefresh = false}) async {
    if (_isRefreshing) return;

    setState(() {
      if (isRefresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
      _errorMessage = null;
      _qrData = null;
      _isPolling = false;
      _pollingStatus = null;
    });

    try {
      // 使用 CryptoService 生成 QR 认证密钥对
      final crypto = await CryptoService.instance;
      final keyPairResult = await crypto.generateQRAuthKeyPair();

      final publicKey = keyPairResult['publicKey'] as String;
      final secretKey = keyPairResult['secretKey'] as String;
      final qrData = keyPairResult['qrData'] as String;

      Logger.info('Generated QR auth key pair, public key: $publicKey');

      // 保存临时密钥用于轮询
      final storage = PlatformStorage.instance;
      await storage.write(key: 'temp_secret_key', value: secretKey);

      setState(() {
        _qrData = qrData;
        _qrId = publicKey.substring(0, 16);
        _expiresAt = DateTime.now().add(const Duration(minutes: 5));
      });

      // 启动倒计时
      _startCountdown(_expiresAt!);

      // 启动状态轮询
      _startStatusPolling();
    } catch (e) {
      setState(() {
        _errorMessage = '生成 QR 码失败: $e';
        _isLoading = false;
        _isRefreshing = false;
      });
      Logger.error('Generate QR code error: $e');
    }
  }

  /// 启动倒计时
  void _startCountdown(DateTime expiresAt) {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final seconds = expiresAt.difference(DateTime.now()).inSeconds;

      if (seconds <= 0) {
        // QR 码过期，重新生成
        timer.cancel();
        _generateQRCode(isRefresh: true);
      } else {
        setState(() {
          _secondsRemaining = seconds;
        });
      }
    });
  }

  /// 启动状态轮询
  void _startStatusPolling() {
    _statusPollingTimer?.cancel();

    _statusPollingTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isPolling || _isManualConfirm) return;

      setState(() {
        _isPolling = true;
      });

      try {
        // 检查认证状态
        final authNotifier = ref.read(authStateProvider.notifier);
        final status = await authNotifier.pollStatusOnce();

        if (status != null) {
          timer.cancel();
          _countdownTimer?.cancel();

          if (status == 'authorized') {
            // 认证成功
            setState(() {
              _pollingStatus = 'authorized';
              _isPolling = false;
            });
          } else if (status == 'rejected') {
            setState(() {
              _pollingStatus = 'rejected';
              _isPolling = false;
            });
          }
        }
      } catch (e) {
        Logger.error('Poll status error: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isPolling = false;
          });
        }
      }
    });

    Logger.info('Status polling started');
  }

  /// 切换到手动输入模式
  void _toggleManualConfirm() {
    setState(() => _isManualConfirm = !_isManualConfirm);
    _confirmCodeController.clear();
  }

  /// 重新生成 QR 码
  Future<void> _refreshQRCode() async {
    await _generateQRCode(isRefresh: true);
  }

  /// 取消并返回
  void _cancel() {
    _countdownTimer?.cancel();
    _statusPollingTimer?.cancel();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    if (authState.isAuthenticated && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(AppRoutes.home);
        }
      });
    }
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _isManualConfirm ? _buildManualConfirmView() : _buildQRCodeView(),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        _isManualConfirm ? '确认登录' : '链接设备',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _cancel,
      ),
      actions: [
        if (_qrData != null && !_isManualConfirm)
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.brandColor,
                    ),
                  )
                : const Icon(Icons.refresh_outlined),
            onPressed: _isRefreshing ? null : _refreshQRCode,
            tooltip: '刷新',
          ),
      ],
    );
  }

  /// 构建 QR 码显示视图
  Widget _buildQRCodeView() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null) ...[
              _buildErrorCard(),
              const SizedBox(height: 24),
            ],

            // 说明文字
            _buildInstructionCard(),

            const SizedBox(height: 32),

            // QR 码显示区域
            if (_isLoading)
              _buildLoadingView()
            else if (_qrData != null)
              _buildQRCodeCard()
            else
              _buildEmptyState(),

            const SizedBox(height: 30),

            // 使用 Secret Key 恢复的按钮
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.restoreManual),
              icon: const Icon(Icons.vpn_key_outlined),
              label: const Text('使用密钥恢复'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.brandColor,
                side: const BorderSide(color: AppTheme.brandColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建说明卡片
  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_scanner,
                    color: AppTheme.brandColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '链接新设备到您的账户',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '在电脑上打开 ${AppConfig.appName}，扫描此二维码即可链接设备',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 说明步骤
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.neutral50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. 在电脑上打开 ${AppConfig.appName}',
                  style: TextStyle(fontSize: 14, color: AppTheme.neutral900),
                ),
                const SizedBox(height: 8),
                const Text(
                  '2. 进入设置 → 账户',
                  style: TextStyle(fontSize: 14, color: AppTheme.neutral900),
                ),
                const SizedBox(height: 8),
                const Text(
                  '3. 点击"链接新设备"',
                  style: TextStyle(fontSize: 14, color: AppTheme.neutral900),
                ),
                const SizedBox(height: 8),
                const Text(
                  '4. 扫描此二维码',
                  style: TextStyle(fontSize: 14, color: AppTheme.neutral900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建 QR 码卡片
  Widget _buildQRCodeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // QR 码
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.neutral200, width: 1),
            ),
            child: QrImageView(
              data: _qrData!,
              version: QrVersions.auto,
              size: 260.0,
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

          const SizedBox(height: 20),

          // 状态标签
          if (_pollingStatus == 'authorized')
            _buildStatusCard(
              icon: Icons.check_circle,
              iconColor: Colors.green,
              message: '设备链接成功！',
              description: '即将跳转...',
              bgColor: Colors.green.withValues(alpha: 0.1),
            )
          else if (_pollingStatus == 'rejected')
            _buildStatusCard(
              icon: Icons.cancel,
              iconColor: Colors.red,
              message: '链接被拒绝',
              description: '请重新生成二维码',
              bgColor: Colors.red.withValues(alpha: 0.1),
            )
          else if (_isPolling)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '等待电脑扫描和批准...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code,
                  size: 16,
                  color: AppTheme.brandColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  '二维码已生成',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.brandColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // 倒计时
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.access_time,
                size: 14,
                color: AppTheme.neutral500,
              ),
              const SizedBox(width: 4),
              Text(
                '剩余时间：${_formatDuration(_secondsRemaining)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutral500,
                ),
              ),
            ],
          ),

          // QR ID
          const SizedBox(height: 8),
          Text(
            'ID: ${_qrId?.substring(0, 8)}...',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建状态卡片
  Widget _buildStatusCard({
    required IconData icon,
    required Color iconColor,
    required String message,
    required String description,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建加载视图
  Widget _buildLoadingView() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: AppTheme.brandColor),
          SizedBox(height: 16),
          Text(
            '正在生成二维码...',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_2, size: 64, color: AppTheme.neutral400),
          const SizedBox(height: 16),
          const Text(
            '二维码生成失败',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshQRCode,
            icon: const Icon(Icons.refresh),
            label: const Text('重新生成'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误卡片
  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => setState(() => _errorMessage = null),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  /// 构建手动确认视图
  Widget _buildManualConfirmView() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // 图标
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.security_outlined,
                  size: 40,
                  color: AppTheme.brandColor,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                '手动输入链接码',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '如果在电脑上看到链接码，可以手动输入',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutral600,
                ),
              ),

              const SizedBox(height: 40),

              // 输入框
              TextField(
                controller: _confirmCodeController,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: '输入链接码',
                  hintStyle: TextStyle(
                    color: AppTheme.neutral400,
                    letterSpacing: 0,
                  ),
                  filled: true,
                  fillColor: AppTheme.neutral50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.neutral300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.neutral300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppTheme.brandColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                maxLength: 50,
              ),

              const SizedBox(height: 24),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 使用手动输入的链接码
                    final linkCode = _confirmCodeController.text.trim();
                    if (linkCode.isNotEmpty) {
                      // TODO: 实现手动链接码处理
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('手动链接功能正在开发中'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    '提交链接码',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _toggleManualConfirm,
                child: Text(
                  '返回二维码',
                  style: TextStyle(
                    color: AppTheme.brandColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 格式化持续时间
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
