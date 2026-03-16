part of 'session_list.dart';

class _SessionsListLoadingView extends StatelessWidget {
  const _SessionsListLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.brandColor),
          const SizedBox(height: 16),
          Text(
            '加载会话中...',
            style: TextStyle(color: AppTheme.neutral600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SessionsListEmptyView extends StatelessWidget {
  const _SessionsListEmptyView({
    required this.showActiveOnly,
    required this.onNewSessionTap,
  });

  final bool showActiveOnly;
  final VoidCallback? onNewSessionTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.neutral400),
          const SizedBox(height: 16),
          Text(
            showActiveOnly ? '暂无活跃会话' : '暂无会话',
            style: TextStyle(color: AppTheme.neutral600, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onNewSessionTap,
            icon: const Icon(Icons.add),
            label: const Text('创建新会话'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionsListErrorView extends StatelessWidget {
  const _SessionsListErrorView({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: AppTheme.neutral600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
