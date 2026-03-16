import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
import '../../encryption/domain/crypto_service.dart';
import '../data/auth_repository.dart';
import 'scan_qr_screen.dart';

part 'qr_login_screen_actions.dart';
part 'qr_login_screen_dialog.dart';
part 'qr_login_screen_views.dart';

class QRLoginScreen extends ConsumerStatefulWidget {
  const QRLoginScreen({super.key});

  @override
  ConsumerState<QRLoginScreen> createState() => _QRLoginScreenState();
}

class _QRLoginScreenState extends ConsumerState<QRLoginScreen> {
  bool _isScanning = false;

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  bool _isLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height;
  }

  Future<void> _startScanLogin() => _startQrScanLogin(this);

  Future<void> _handleScannedLink(String link) =>
      _handleQrScannedLink(this, link);

  Future<void> _createAccount() => _createQrLoginAccount(this);

  void _showSnackBar(String message) => _showQrLoginSnackBar(this, message);

  Future<void> _showQRCodeDialog(String qrData) =>
      _showQrLoginDialog(this, qrData);

  @override
  Widget build(BuildContext context) => _buildQrLoginScreen(this);
}
