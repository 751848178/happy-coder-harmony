part of 'session_info_screen.dart';

class _SessionStatusCard extends StatelessWidget {
  const _SessionStatusCard({
    required this.session,
    required this.stats,
  });

  final Session session;
  final SessionStats stats;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: '会话状态',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow('会话ID', session.id),
          const SizedBox(height: 12),
          _InfoRow('标题', session.title.isNotEmpty ? session.title : '未命名会话'),
          const SizedBox(height: 12),
          _InfoRow('状态', session.active ? '活跃' : '已关闭'),
          const SizedBox(height: 12),
          if (session.tag != null) ...[
            _InfoRow('标签', session.tag!),
            const SizedBox(height: 12),
          ],
          _InfoRow('消息数', '${stats.messageCount}'),
          const SizedBox(height: 12),
          _InfoRow('改动行数', '${stats.changedLineCount}'),
        ],
      ),
    );
  }
}

class _SessionTimeCard extends StatelessWidget {
  const _SessionTimeCard({
    required this.session,
  });

  final Session session;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: '时间信息',
      icon: Icons.access_time,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow('创建时间', formatSessionInfoDateTime(session.createdAt)),
          const SizedBox(height: 12),
          _InfoRow('更新时间', formatSessionInfoDateTime(session.updatedAt)),
        ],
      ),
    );
  }
}

class _SessionPermissionCard extends StatelessWidget {
  const _SessionPermissionCard({
    required this.session,
  });

  final Session session;

  @override
  Widget build(BuildContext context) {
    final flavor = session.metadata?['flavor']?.toString();
    return _InfoCard(
      title: '权限设置',
      icon: Icons.security,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            '权限模式',
            permissionModeText(session.permissionMode, flavor: flavor),
          ),
          const SizedBox(height: 12),
          _InfoContent(
            permissionModeDescription(
              session.permissionMode,
              flavor: flavor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionPathCard extends StatelessWidget {
  const _SessionPathCard({
    required this.session,
  });

  final Session session;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: '路径信息',
      icon: Icons.folder_open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow('工作路径', session.path!),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                AppRoutes.sessionGitDetail(session.id),
              ),
              icon: const Icon(Icons.account_tree_outlined, size: 18),
              label: const Text('查看 Git 仓库'),
            ),
          ),
        ],
      ),
    );
  }
}
