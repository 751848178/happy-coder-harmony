import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../../harmony/harmony_bridge.dart';

part 'scan_qr_screen_actions.dart';
part 'scan_qr_screen_views.dart';
part 'scan_qr_screen_widgets.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  StreamSubscription<Map<String, dynamic>>? _harmonyScanSubscription;
  bool _handled = false;
  bool _isCheckingScanner = true;
  bool _useHarmonyScanner = false;
  bool _torchEnabled = false;
  String? _scannerMessage;

  @override
  void initState() {
    super.initState();
    _prepareScanner();
  }

  @override
  void dispose() {
    _harmonyScanSubscription?.cancel();
    if (HarmonyBridge.isHarmonyOS) {
      unawaited(HarmonyBridge.stopQRCodeScan());
    }
    _controller.dispose();
    super.dispose();
  }

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  Future<void> _prepareScanner() => _prepareQrScanner(this);

  void _handleHarmonyScanEvent(Map<String, dynamic> event) =>
      _handleHarmonyQrEvent(this, event);

  Future<void> _retryHarmonyScan() => _retryHarmonyQrScan(this);

  void _handleDetection(BarcodeCapture capture) =>
      _handleQrDetection(this, capture);

  Future<void> _toggleTorch() => _toggleQrTorch(this);

  @override
  Widget build(BuildContext context) => _buildScanQrScaffold(this);
}
