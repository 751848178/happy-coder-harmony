part of 'terminal_connect_screen.dart';

Widget _buildEntrySheetOverlay(_TerminalConnectScreenState state) {
  return Positioned.fill(
    child: ColoredBox(
      color: Colors.black.withValues(alpha: 0.38),
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.shadowLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '输入终端链接',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: state._closeEntrySheet,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '粘贴 `happy://terminal?...` 链接，或者直接扫描电脑二维码。',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.neutral600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state._errorMessage != null
                          ? AppTheme.errorColor
                          : AppTheme.neutral300,
                    ),
                  ),
                  child: TextField(
                    controller: state._linkController,
                    autofocus: true,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => state._submitEntrySheet(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'happy://terminal?BASE64URL_PUBLIC_KEY',
                      hintStyle: TextStyle(color: AppTheme.neutral400),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                if (state._errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildTerminalMessage(
                    message: state._errorMessage!,
                    color: AppTheme.errorColor,
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state._isScanning ? null : state._startScan,
                        icon: Icon(
                          state._isScanning
                              ? Icons.qr_code_2
                              : Icons.qr_code_scanner,
                          size: 18,
                        ),
                        label: Text(state._isScanning ? '扫码中...' : '扫码'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: state._submitEntrySheet,
                        child: const Text('继续'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildTerminalMessage({
  required String message,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ),
      ],
    ),
  );
}
