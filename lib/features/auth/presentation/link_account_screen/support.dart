part of 'link_account_screen.dart';

Widget _buildLinkAccountHero() {
  return Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      gradient:
          LinearGradient(colors: [AppTheme.brandColor, AppTheme.brandDark]),
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Icon(Icons.devices, size: 48, color: Colors.white),
  );
}

Widget _buildLinkAccountKeyCard(String publicKeyShort) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.neutral200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.vpn_key, size: 20, color: AppTheme.brandColor),
            SizedBox(width: 8),
            Text(
              '设备公钥',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.neutral100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            publicKeyShort,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: AppTheme.neutral800,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}

Widget _buildLinkAccountSecurityTip() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.infoColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.3)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.security, size: 20, color: AppTheme.infoColor),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            '此连接使用端到端加密保护。仅批准您信任的设备。',
            style: TextStyle(fontSize: 14, color: AppTheme.neutral700),
          ),
        ),
      ],
    ),
  );
}

Widget _buildLinkAccountActions(_LinkAccountScreenState state) {
  return Column(
    children: [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: state._isProcessing ? null : state._approveLink,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: state._isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('批准链接',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: state._isProcessing ? null : state._cancelLink,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.neutral600,
            side: const BorderSide(color: AppTheme.neutral300),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('拒绝',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      ),
    ],
  );
}
