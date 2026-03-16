part of 'qr_login_screen.dart';

Future<void> _showQrLoginDialog(
    _QRLoginScreenState state, String qrData) async {
  if (!state.mounted) {
    return;
  }
  final trimmed = qrData.trim();
  final hasQrData = trimmed.isNotEmpty;
  await showDialog<void>(
    context: state.context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('创建账户',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const Text('请用另一个设备扫描此二维码以批准账户'),
                const SizedBox(height: 16),
                Center(child: _buildQrLoginDialogCode(trimmed, hasQrData)),
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

Widget _buildQrLoginDialogCode(String qrData, bool hasQrData) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: hasQrData
        ? QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 220,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppTheme.brandColor,
            ),
            dataModuleStyle:
                const QrDataModuleStyle(color: AppTheme.brandColor),
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
                        fontSize: 12, color: AppTheme.errorColor),
                  ),
                ),
              );
            },
          )
        : const SizedBox(
            width: 220,
            height: 220,
            child: Center(
              child: Text('二维码数据为空',
                  style: TextStyle(fontSize: 12, color: AppTheme.errorColor)),
            ),
          ),
  );
}
