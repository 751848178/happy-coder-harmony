part of 'qr_code_screen.dart';

Widget _buildQRCodeInstructionCard() {
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
              child: const Icon(
                Icons.qr_code_scanner,
                color: AppTheme.brandColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '链接新设备到您的账户',
                    style: TextStyle(
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

Widget _buildQRCodeLoadingView() {
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
          style: TextStyle(fontSize: 16, color: AppTheme.neutral600),
        ),
      ],
    ),
  );
}

Widget _buildQRCodeEmptyState(_QRCodeScreenState state) {
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
          style: TextStyle(fontSize: 16, color: AppTheme.neutral600),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: state._refreshQRCode,
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

Widget _buildQRCodeErrorCard(_QRCodeScreenState state) {
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
            state._errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => state._updateView(() {
            state._errorMessage = null;
          }),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    ),
  );
}
