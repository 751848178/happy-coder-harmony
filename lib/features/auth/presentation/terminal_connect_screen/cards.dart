part of 'terminal_connect_screen.dart';

Widget _buildTerminalIntroCard() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.neutral200),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.brandColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.computer, color: AppTheme.brandColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '连接电脑终端',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '输入电脑端授权链接或扫描二维码，确认后才会授权当前账户。',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutral600,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildTerminalServerCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.neutral100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '当前 Happy Server：${AppConfig.serverUrl}',
      style: const TextStyle(
        fontSize: 12,
        color: AppTheme.neutral700,
        height: 1.4,
      ),
    ),
  );
}

Widget _buildTerminalWaitingCard(_TerminalConnectScreenState state) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.neutral200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '等待输入终端链接',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '默认会先弹出输入框。你也可以直接扫描二维码。',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.neutral600,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: state._openEntrySheet,
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text('输入链接'),
            ),
            OutlinedButton.icon(
              onPressed: state._isScanning ? null : state._startScan,
              icon: Icon(
                state._isScanning ? Icons.qr_code_2 : Icons.qr_code_scanner,
                size: 18,
              ),
              label: Text(state._isScanning ? '扫码中...' : '扫码连接'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.brandColor,
                side: const BorderSide(color: AppTheme.brandColor),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildTerminalParsedLinkCard(_TerminalConnectScreenState state) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.neutral200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.key_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state._publicKeyPreview ?? state._parsedLink ?? '',
                style: TextStyle(fontSize: 13, color: AppTheme.neutral700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.lock_outline, size: 18),
            const SizedBox(width: 8),
            Text(
              '端到端加密授权',
              style: TextStyle(fontSize: 13, color: AppTheme.neutral700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: state._openEntrySheet,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('重新输入'),
            ),
            TextButton.icon(
              onPressed: state._isScanning ? null : state._startScan,
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text('扫码替换'),
            ),
            if (state._linkController.text.isNotEmpty)
              TextButton(
                onPressed: state._clearInput,
                child: const Text('清空'),
              ),
          ],
        ),
      ],
    ),
  );
}
