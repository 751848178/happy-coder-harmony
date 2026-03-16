part of 'socket_connection_screen.dart';

extension _SocketConnectionScreenStatus on _SocketConnectionScreenState {
  Widget _buildConnectionStatusCard(SocketState state) {
    final viewModel = _SocketStatusViewModel.fromState(state);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.neutral300)),
      ),
      child: Row(
        children: [
          Icon(viewModel.icon, color: viewModel.color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '连接状态',
                  style: TextStyle(fontSize: 12, color: AppTheme.neutral600),
                ),
                Text(
                  viewModel.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: viewModel.color,
                  ),
                ),
              ],
            ),
          ),
          if (!viewModel.isConnected)
            ElevatedButton.icon(
              onPressed: _connect,
              icon: const Icon(Icons.link, size: 18),
              label: const Text('连接'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.link_off, size: 18),
              label: const Text('断开'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}

class _SocketStatusViewModel {
  const _SocketStatusViewModel({
    required this.color,
    required this.text,
    required this.icon,
    required this.isConnected,
  });

  final Color color;
  final String text;
  final IconData icon;
  final bool isConnected;

  factory _SocketStatusViewModel.fromState(SocketState state) {
    return state.when(
      initial: () => const _SocketStatusViewModel(
        color: Colors.grey,
        text: '未连接',
        icon: Icons.wifi_off,
        isConnected: false,
      ),
      connecting: () => const _SocketStatusViewModel(
        color: Colors.orange,
        text: '连接中...',
        icon: Icons.sync,
        isConnected: false,
      ),
      connected: (socketId) => _SocketStatusViewModel(
        color: Colors.green,
        text: '已连接: $socketId',
        icon: Icons.wifi,
        isConnected: true,
      ),
      reconnecting: (attempt) => _SocketStatusViewModel(
        color: Colors.orange,
        text: '重连中... (第 $attempt 次)',
        icon: Icons.sync_problem,
        isConnected: false,
      ),
      error: (message) => _SocketStatusViewModel(
        color: Colors.red,
        text: '错误: $message',
        icon: Icons.error,
        isConnected: false,
      ),
    );
  }
}
