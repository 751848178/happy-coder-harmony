part of 'chat_screen.dart';

extension _ChatScreenLayout on _ChatScreenState {
  Widget _buildSessionListOverlay() {
    return Container(
      width: 320,
      color: AppTheme.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.neutral300)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _toggleSessionList,
                ),
                const SizedBox(width: 8),
                const Text(
                  '会话列表',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('新建'),
                ),
              ],
            ),
          ),
          Expanded(child: SessionsList(onSessionTap: _handleSessionTap)),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    if (widget.sessionId == null) {
      return _buildWelcomeView();
    }

    return Column(
      children: [
        _buildAppBar(),
        Expanded(child: _buildMessageList()),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildWelcomeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: AppTheme.neutral300),
          const SizedBox(height: 24),
          Text(
            'Welcome to ${AppConfig.appName}',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '选择一个会话开始对话',
            style: TextStyle(color: AppTheme.neutral600, fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _toggleSessionList,
            icon: const Icon(Icons.list),
            label: const Text('查看会话列表'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final session = ref.watch(sessionStateProvider).whenOrNull(
          ready: (sessions, _, __) => sessions[widget.sessionId],
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.neutral300)),
      ),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.list), onPressed: _toggleSessionList),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              session?.title ?? 'New Chat',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onSelected: (value) => _handleMenuSelection(context, value),
            itemBuilder: (context) => _buildMenuItems(),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<int>> _buildMenuItems() {
    return const [
      PopupMenuItem(
        value: 1,
        child: _ChatMenuItem(icon: Icons.edit_outlined, label: '重命名'),
      ),
      PopupMenuItem(
        value: 2,
        child: _ChatMenuItem(icon: Icons.push_pin_outlined, label: '置顶'),
      ),
      PopupMenuItem(
        value: 3,
        child: _ChatMenuItem(icon: Icons.archive_outlined, label: '归档'),
      ),
      PopupMenuDivider(),
      PopupMenuItem(
        value: 4,
        child: _ChatMenuItem(
          icon: Icons.delete_outline,
          label: '删除',
          color: Colors.red,
        ),
      ),
    ];
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _toggleSessionList,
      backgroundColor: AppTheme.brandColor,
      child: const Icon(Icons.list),
    );
  }
}

class _ChatMenuItem extends StatelessWidget {
  const _ChatMenuItem({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(label, style: color == null ? null : TextStyle(color: color)),
      ],
    );
  }
}
