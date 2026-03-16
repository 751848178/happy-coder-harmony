part of 'qr_code_screen.dart';

Widget _buildManualConfirmView(_QRCodeScreenState state) {
  return SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
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
              style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: state._confirmCodeController,
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
                  borderSide: BorderSide(color: AppTheme.brandColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final linkCode = state._confirmCodeController.text.trim();
                  if (linkCode.isEmpty) {
                    return;
                  }
                  ScaffoldMessenger.of(state.context).showSnackBar(
                    const SnackBar(content: Text('手动链接功能正在开发中')),
                  );
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: state._toggleManualConfirm,
              child: Text(
                '返回二维码',
                style: TextStyle(color: AppTheme.brandColor, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
