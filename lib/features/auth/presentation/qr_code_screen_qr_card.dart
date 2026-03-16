part of 'qr_code_screen.dart';

Widget _buildQRCodeCard(_QRCodeScreenState state) {
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.neutral200, width: 1),
          ),
          child: QrImageView(
            data: state._qrData!,
            version: QrVersions.auto,
            size: 260,
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
        _buildQRCodeStatusSection(state),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, size: 14, color: AppTheme.neutral500),
            const SizedBox(width: 4),
            Text(
              '剩余时间：${state._formatDuration(state._secondsRemaining)}',
              style: const TextStyle(fontSize: 12, color: AppTheme.neutral500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'ID: ${state._qrId?.substring(0, 8)}...',
          style: const TextStyle(fontSize: 12, color: AppTheme.neutral500),
        ),
      ],
    ),
  );
}

Widget _buildQRCodeStatusSection(_QRCodeScreenState state) {
  if (state._pollingStatus == 'authorized') {
    return _buildQRCodeStatusCard(
      icon: Icons.check_circle,
      iconColor: Colors.green,
      message: '设备链接成功！',
      description: '即将跳转...',
      bgColor: Colors.green.withValues(alpha: 0.1),
    );
  }
  if (state._pollingStatus == 'rejected') {
    return _buildQRCodeStatusCard(
      icon: Icons.cancel,
      iconColor: Colors.red,
      message: '链接被拒绝',
      description: '请重新生成二维码',
      bgColor: Colors.red.withValues(alpha: 0.1),
    );
  }
  if (state._isPolling) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.green,
          ),
        ),
        SizedBox(width: 8),
        Text(
          '等待电脑扫描和批准...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.green,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: const [
      Icon(Icons.qr_code, size: 16, color: AppTheme.brandColor),
      SizedBox(width: 8),
      Text(
        '二维码已生成',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.brandColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

Widget _buildQRCodeStatusCard({
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
                style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
