part of 'terminal_connect_screen.dart';

Widget _buildStatusOverlay(_TerminalConnectScreenState state) {
  final isFailure =
      state._connectFailureMessage != null && !state._isConnecting;
  return Positioned.fill(
    child: ColoredBox(
      color: Colors.black.withValues(alpha: 0.32),
      child: Center(
        child: Container(
          width: MediaQuery.of(state.context).size.width - 48,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.shadowLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFailure ? Icons.error_outline : Icons.sync_rounded,
                size: 30,
                color: isFailure ? AppTheme.errorColor : AppTheme.brandColor,
              ),
              const SizedBox(height: 12),
              Text(
                isFailure ? '连接失败' : '正在连接终端',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFailure
                    ? state._connectFailureMessage!
                    : '正在校验授权链接并向电脑端发送批准响应。',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.neutral600,
                  height: 1.45,
                ),
              ),
              if (!isFailure) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(strokeWidth: 2.4),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state._dismissScreen,
                      child: const Text('返回'),
                    ),
                  ),
                  if (isFailure) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          state._updateView(() {
                            state._connectFailureMessage = null;
                          });
                          state._connectTerminal();
                        },
                        child: const Text('重试'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
