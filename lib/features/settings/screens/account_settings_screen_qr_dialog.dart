part of 'account_settings_screen.dart';

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
            if (_errorMessage != null) _buildErrorBanner(),
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(32),
                child:
                    const CircularProgressIndicator(color: AppTheme.brandColor),
              )
            else if (_qrData != null)
              _buildQrCard(),
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

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: QrImageView(
              data: _qrData!,
              version: QrVersions.auto,
              size: 200,
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
          Text(
            '在已登录的 ${AppConfig.appName} 设备上扫描此二维码，即可继续连接。',
            style: const TextStyle(fontSize: 12, color: AppTheme.neutral600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '连接标识：${_qrId?.substring(0, 8)}...',
            style: const TextStyle(fontSize: 11, color: AppTheme.neutral400),
          ),
        ],
      ),
    );
  }
}
