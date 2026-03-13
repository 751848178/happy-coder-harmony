import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../../harmony/harmony_bridge.dart';

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

  Future<void> _prepareScanner() async {
    if (!HarmonyBridge.isHarmonyOS) {
      if (mounted) {
        setState(() => _isCheckingScanner = false);
      }
      return;
    }

    try {
      final available = await HarmonyBridge.isQRCodeAvailable();
      if (!mounted) {
        return;
      }
      if (!available) {
        setState(() {
          _isCheckingScanner = false;
          _useHarmonyScanner = false;
          _scannerMessage = '当前系统没有启用鸿蒙扫码插件，请先返回上一页粘贴链接。';
        });
        return;
      }

      final hasPermission = await HarmonyBridge.checkQRCodePermission() ||
          await HarmonyBridge.requestQRCodePermission();
      if (!mounted) {
        return;
      }
      if (!hasPermission) {
        setState(() {
          _isCheckingScanner = false;
          _useHarmonyScanner = false;
          _scannerMessage = '没有获得相机权限，请在系统设置中允许相机后重试。';
        });
        return;
      }

      _harmonyScanSubscription?.cancel();
      _harmonyScanSubscription = HarmonyBridge.qrScanEvents().listen(
        _handleHarmonyScanEvent,
        onError: (Object error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _scannerMessage = '扫码失败，请重试或直接粘贴链接。';
          });
        },
      );

      setState(() {
        _useHarmonyScanner = true;
        _isCheckingScanner = false;
        _scannerMessage = '正在唤起鸿蒙原生扫码…';
      });

      final started = await HarmonyBridge.startQRCodeScan(
        supportGallery: false,
      );
      if (!mounted) {
        return;
      }
      if (!started) {
        setState(() {
          _useHarmonyScanner = false;
          _scannerMessage = '原生扫码启动失败，请返回上一页粘贴链接。';
        });
      }
    } on PlatformException {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCheckingScanner = false;
        _useHarmonyScanner = false;
        _scannerMessage = '鸿蒙扫码通道初始化失败，请返回上一页粘贴链接。';
      });
    }
  }

  void _handleHarmonyScanEvent(Map<String, dynamic> event) {
    final type = event['type']?.toString();
    switch (type) {
      case 'camera_started':
        if (mounted) {
          setState(() {
            _scannerMessage = '请将摄像头对准电脑端显示的授权二维码。';
          });
        }
        return;
      case 'scan_success':
        final data = event['data'];
        String? scanned;
        if (data is Map) {
          final content = data['content'];
          if (content is String) {
            scanned = content.trim();
          }
        }
        if (scanned == null || scanned.isEmpty || _handled) {
          return;
        }
        _handled = true;
        Navigator.of(context).pop(scanned);
        return;
      case 'camera_permission_denied':
        if (mounted) {
          setState(() {
            _useHarmonyScanner = false;
            _scannerMessage = '没有获得相机权限，请在系统设置中允许相机后重试。';
          });
        }
        return;
      case 'scan_error':
        if (mounted) {
          setState(() {
            _scannerMessage = event['error']?.toString() ?? '扫码失败，请重试或直接粘贴链接。';
          });
        }
        return;
      case 'camera_stopped':
        if (mounted && !_handled) {
          setState(() {
            _scannerMessage = _scannerMessage ?? '扫码已结束，请点击下方按钮重新扫描。';
          });
        }
        return;
    }
  }

  Future<void> _retryHarmonyScan() async {
    if (_handled) {
      return;
    }
    setState(() {
      _scannerMessage = '正在重新唤起扫码…';
    });
    final started = await HarmonyBridge.startQRCodeScan(
      supportGallery: false,
    );
    if (!mounted) {
      return;
    }
    if (!started) {
      setState(() {
        _scannerMessage = '重新启动扫码失败，请返回上一页粘贴链接。';
      });
    }
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_handled) {
      return;
    }
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) {
        continue;
      }
      _handled = true;
      Navigator.of(context).pop(value);
      return;
    }
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (!mounted) {
      return;
    }
    setState(() => _torchEnabled = !_torchEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final scannerBody = _isCheckingScanner
        ? const Center(
            child: CircularProgressIndicator(color: Colors.white),
          )
        : HarmonyBridge.isHarmonyOS
            ? (_useHarmonyScanner
                ? _buildHarmonyScannerState()
                : _buildHarmonyUnavailableState())
            : MobileScanner(
                controller: _controller,
                onDetect: _handleDetection,
              );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: scannerBody,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.35),
                    width: 52,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!HarmonyBridge.isHarmonyOS)
                      FilledButton.icon(
                        onPressed: _toggleTorch,
                        icon: Icon(
                          _torchEnabled
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                        ),
                        label: Text(_torchEnabled ? '关闭补光' : '打开补光'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.brandColor,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else if (_useHarmonyScanner)
                      Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _scannerMessage ?? '正在等待扫码结果…',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _retryHarmonyScan,
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            label: const Text('重新扫码'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarmonyScannerState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 72,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _scannerMessage ?? '请使用鸿蒙原生扫码能力扫描二维码',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHarmonyUnavailableState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.link_rounded,
                  color: Colors.white,
                  size: 72,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _scannerMessage ?? '当前设备还没有接通鸿蒙原生扫码能力，请先返回上一页粘贴链接。',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
