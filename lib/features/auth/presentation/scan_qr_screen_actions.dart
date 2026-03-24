part of 'scan_qr_screen.dart';

const String _qrScanFallbackToken = '__fallback__';

bool _isQrScanCanceledMessage(String? message) {
  final normalized = message?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return false;
  }
  return normalized.contains('cancel') ||
      normalized.contains('canceled') ||
      normalized.contains('cancelled') ||
      normalized.contains('user canceled') ||
      normalized.contains('用户取消');
}

void _showQrScanErrorSnackBar(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.errorColor,
    ),
  );
}

Future<String?> _startHarmonySystemQrScan(BuildContext context) async {
  try {
    final available = await HarmonyBridge.isQRCodeAvailable();
    if (!available) {
      return _qrScanFallbackToken;
    }

    final hasPermission = await HarmonyBridge.checkQRCodePermission() ||
        await HarmonyBridge.requestQRCodePermission();
    if (!hasPermission) {
      if (context.mounted) {
        _showQrScanErrorSnackBar(context, '没有获得相机权限，请在系统设置中允许相机后重试。');
      }
      return null;
    }

    final completer = Completer<String?>();
    late final StreamSubscription<Map<String, dynamic>> subscription;
    subscription = HarmonyBridge.qrScanEvents().listen(
      (event) {
        if (completer.isCompleted) {
          return;
        }
        switch (event['type']?.toString()) {
          case 'scan_success':
            final data = event['data'];
            final scanned =
                data is Map ? data['content']?.toString().trim() : null;
            completer.complete(
              scanned == null || scanned.isEmpty ? null : scanned,
            );
            break;
          case 'camera_permission_denied':
            completer.complete(null);
            break;
          case 'scan_error':
            final message = event['error']?.toString();
            if (!_isQrScanCanceledMessage(message) && context.mounted) {
              _showQrScanErrorSnackBar(
                context,
                message ?? '扫码失败，请重试或改用手动输入链接。',
              );
            }
            completer.complete(null);
            break;
          case 'camera_stopped':
            completer.complete(null);
            break;
        }
      },
      onError: (_) {
        if (!completer.isCompleted) {
          if (context.mounted) {
            _showQrScanErrorSnackBar(context, '扫码失败，请重试或改用手动输入链接。');
          }
          completer.complete(null);
        }
      },
    );

    final started = await HarmonyBridge.startQRCodeScan(supportGallery: false);
    if (!started) {
      await subscription.cancel();
      return _qrScanFallbackToken;
    }

    final result = await completer.future;
    await subscription.cancel();
    await HarmonyBridge.stopQRCodeScan();
    return result;
  } on PlatformException {
    return _qrScanFallbackToken;
  }
}

Future<void> _prepareQrScanner(_ScanQrScreenState state) async {
  if (!HarmonyBridge.isHarmonyOS) {
    state._updateView(() => state._isCheckingScanner = false);
    return;
  }
  try {
    final available = await HarmonyBridge.isQRCodeAvailable();
    if (!state.mounted) {
      return;
    }
    if (!available) {
      state._updateView(() {
        state._isCheckingScanner = false;
        state._useHarmonyScanner = false;
        state._scannerMessage = '当前系统没有启用鸿蒙扫码插件，请先返回上一页粘贴链接。';
      });
      return;
    }

    final hasPermission = await HarmonyBridge.checkQRCodePermission() ||
        await HarmonyBridge.requestQRCodePermission();
    if (!state.mounted) {
      return;
    }
    if (!hasPermission) {
      state._updateView(() {
        state._isCheckingScanner = false;
        state._useHarmonyScanner = false;
        state._scannerMessage = '没有获得相机权限，请在系统设置中允许相机后重试。';
      });
      return;
    }

    await state._harmonyScanSubscription?.cancel();
    state._harmonyScanSubscription = HarmonyBridge.qrScanEvents().listen(
      state._handleHarmonyScanEvent,
      onError: (_) {
        state._updateView(() => state._scannerMessage = '扫码失败，请重试或直接粘贴链接。');
      },
    );
    state._updateView(() {
      state._useHarmonyScanner = true;
      state._isCheckingScanner = false;
      state._scannerMessage = '正在唤起鸿蒙原生扫码…';
    });
    final started = await HarmonyBridge.startQRCodeScan(supportGallery: false);
    if (!state.mounted || started) {
      return;
    }
    state._updateView(() {
      state._useHarmonyScanner = false;
      state._scannerMessage = '原生扫码启动失败，请返回上一页粘贴链接。';
    });
  } on PlatformException {
    state._updateView(() {
      state._isCheckingScanner = false;
      state._useHarmonyScanner = false;
      state._scannerMessage = '鸿蒙扫码通道初始化失败，请返回上一页粘贴链接。';
    });
  }
}

void _handleHarmonyQrEvent(
    _ScanQrScreenState state, Map<String, dynamic> event) {
  switch (event['type']?.toString()) {
    case 'camera_started':
      state._updateView(() => state._scannerMessage = '请将摄像头对准电脑端显示的授权二维码。');
      return;
    case 'scan_success':
      final data = event['data'];
      final scanned = data is Map ? data['content']?.toString().trim() : null;
      if (scanned == null || scanned.isEmpty || state._handled) {
        return;
      }
      state._handled = true;
      Navigator.of(state.context).pop(scanned);
      return;
    case 'camera_permission_denied':
      state._updateView(() {
        state._useHarmonyScanner = false;
        state._scannerMessage = '没有获得相机权限，请在系统设置中允许相机后重试。';
      });
      return;
    case 'scan_error':
      final message = event['error']?.toString();
      if (_isQrScanCanceledMessage(message)) {
        if (!state._handled && state.mounted) {
          Navigator.of(state.context).pop();
        }
        return;
      }
      state._updateView(() {
        state._scannerMessage = message ?? '扫码失败，请重试或直接粘贴链接。';
      });
      return;
    case 'camera_stopped':
      if (!state._handled) {
        state._updateView(() {
          state._scannerMessage = state._scannerMessage ?? '扫码已结束，请点击下方按钮重新扫描。';
        });
      }
      return;
  }
}

Future<void> _retryHarmonyQrScan(_ScanQrScreenState state) async {
  if (state._handled) {
    return;
  }
  state._updateView(() => state._scannerMessage = '正在重新唤起扫码…');
  final started = await HarmonyBridge.startQRCodeScan(supportGallery: false);
  if (!state.mounted || started) {
    return;
  }
  state._updateView(() => state._scannerMessage = '重新启动扫码失败，请返回上一页粘贴链接。');
}

void _handleQrDetection(_ScanQrScreenState state, BarcodeCapture capture) {
  if (state._handled) {
    return;
  }
  for (final barcode in capture.barcodes) {
    final value = barcode.rawValue?.trim();
    if (value == null || value.isEmpty) {
      continue;
    }
    state._handled = true;
    Navigator.of(state.context).pop(value);
    return;
  }
}

Future<void> _toggleQrTorch(_ScanQrScreenState state) async {
  await state._controller.toggleTorch();
  state._updateView(() => state._torchEnabled = !state._torchEnabled);
}
