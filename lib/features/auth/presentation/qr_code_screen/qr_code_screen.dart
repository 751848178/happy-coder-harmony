import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/platform/platform_storage.dart';
import '../../../../shared/utils/extensions.dart';
import '../../../encryption/domain/crypto_service.dart';

part 'logic.dart';
part 'root_view.dart';
part 'cards.dart';
part 'qr_card.dart';
part 'manual_view.dart';

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
  String? _qrData;
  String? _qrId;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  Timer? _countdownTimer;
  Timer? _statusPollingTimer;
  int _secondsRemaining = 300;
  DateTime? _expiresAt;
  bool _isPolling = false;
  String? _pollingStatus;

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

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

  Future<void> _generateQRCode({bool isRefresh = false}) =>
      _generateQRCodeImpl(this, isRefresh: isRefresh);

  void _startCountdown(DateTime expiresAt) =>
      _startCountdownImpl(this, expiresAt);

  void _startStatusPolling() => _startStatusPollingImpl(this);

  void _toggleManualConfirm() => _toggleManualConfirmImpl(this);

  Future<void> _refreshQRCode() => _refreshQRCodeImpl(this);

  void _cancel() => _cancelQRCodeScreen(this);

  String _formatDuration(int seconds) => _formatDurationValue(seconds);

  @override
  Widget build(BuildContext context) => _buildQRCodeScaffold(this, context);
}
