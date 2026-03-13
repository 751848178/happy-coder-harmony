import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/providers/app_providers.dart';
import '../domain/session_stats.dart';

/// 会话详情信息屏幕
///
/// 显示会话的详细信息，包括基本信息、状态、元数据等
class SessionInfoScreen extends ConsumerStatefulWidget {
  const SessionInfoScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<SessionInfoScreen> createState() => _SessionInfoScreenState();
}

class _SessionInfoScreenState extends ConsumerState<SessionInfoScreen> {
  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    await sessionNotifier.loadSessionMessages(widget.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionStateProvider);
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final session = sessionNotifier.getSession(widget.sessionId);
    final stats = session == null
        ? null
        : SessionStatsCalculator.fromSession(
            session: session,
            messages:
                sessionNotifier.getSessionMessages(widget.sessionId)?.messages,
          );

    if (session == null || stats == null) {
      return _buildLoadingView();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _navigateBack();
      },
      child: Scaffold(
        backgroundColor: AppTheme.neutral50,
        appBar: _buildAppBar(context, session),
        body: _SessionInfoBody(
          session: session,
          stats: stats,
        ),
      ),
    );
  }

  void _navigateBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.sessionDetail(widget.sessionId));
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Session session) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _navigateBack,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '会话信息',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            session.title.isNotEmpty ? session.title : '未命名会话',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.neutral600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditSessionDialog(session),
          tooltip: '编辑会话',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'delete') {
              _confirmDeleteSession(session);
            } else if (value == 'clone') {
              _openCloneSession(session);
            } else if (value == 'export') {
              _exportSession(session);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clone',
              child: Row(
                children: [
                  Icon(Icons.control_point_duplicate_outlined, size: 18),
                  SizedBox(width: 12),
                  Text('克隆会话'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: 18),
                  SizedBox(width: 12),
                  Text('导出会话'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18),
                  SizedBox(width: 12),
                  Text('删除会话'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openCloneSession(Session session) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    final uri = AppRoutes.newClonedSession(
      machineId: metadata['machineId']?.toString(),
      path: session.path ?? metadata['path']?.toString(),
      agent: metadata['flavor']?.toString(),
      permissionMode: session.permissionMode ??
          metadata['currentOperatingModeCode']?.toString(),
      modelMode:
          session.modelMode ?? metadata['currentModelCode']?.toString(),
    );
    context.push(uri);
  }

  Widget _buildLoadingView() {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateBack,
        ),
        title: const Text('会话信息'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showEditSessionDialog(Session session) {
    final aliasController = TextEditingController(text: session.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('会话别名'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: aliasController,
              decoration: const InputDecoration(
                labelText: '别名',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _renameSession(session, aliasController.text);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameSession(Session session, String alias) async {
    try {
      await ref.read(sessionStateProvider.notifier).renameSession(
            sessionId: session.id,
            alias: alias,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('会话别名已更新'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新别名失败: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _confirmDeleteSession(Session session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确认要删除会话「${session.title}」吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSession(session);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSession(Session session) async {
    try {
      await ref.read(sessionStateProvider.notifier).deleteSession(session.id);
      if (mounted) {
        context.go('${AppRoutes.home}?tab=sessions');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已删除会话「${session.title}」'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _exportSession(Session session) {
    // TODO: 实现会话导出逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('会话导出功能待实现'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }
}

/// 会话信息主体内容
class _SessionInfoBody extends StatelessWidget {
  const _SessionInfoBody({
    required this.session,
    required this.stats,
  });

  final Session session;
  final SessionStats stats;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 会话状态卡片
          _InfoCard(
            title: '会话状态',
            icon: Icons.info_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow('会话ID', session.id),
                const SizedBox(height: 12),
                _InfoRow(
                    '标题', session.title.isNotEmpty ? session.title : '未命名会话'),
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
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // 时间信息卡片
          _InfoCard(
            title: '时间信息',
            icon: Icons.access_time,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow('创建时间', _formatDateTime(session.createdAt)),
                const SizedBox(height: 12),
                _InfoRow('更新时间', _formatDateTime(session.updatedAt)),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // 权限设置卡片
          _InfoCard(
            title: '权限设置',
            icon: Icons.security,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                    '权限模式', _getPermissionModeText(session.permissionMode)),
                const SizedBox(height: 12),
                _InfoContent(
                  session.permissionMode == 'manual'
                      ? '每次工具调用都需要手动确认'
                      : session.permissionMode == 'auto'
                          ? '自动批准所有工具调用'
                          : '根据工具类型询问是否批准',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // 在线状态卡片
          if (session.presence != null)
            _InfoCard(
              title: '在线状态',
              icon: Icons.people_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    '状态',
                    session.presence!.isOnline ? '在线' : '离线',
                  ),
                  if (session.presence!.lastActiveAt != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      '最后活跃',
                      _formatDateTime(session.presence!.lastActiveAt!),
                    ),
                  ],
                  if (session.presence!.users != null &&
                      session.presence!.users!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoSectionHeader('在线用户'),
                    const SizedBox(height: 8),
                    ...session.presence!.users!.map(
                      (user) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: user.isOnline
                                    ? AppTheme.successColor
                                    : AppTheme.neutral400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(user.userName),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppTheme.spacingMd),

          // 思考状态卡片
          if (session.thinking != null)
            _InfoCard(
              title: 'AI 状态',
              icon: Icons.psychology,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    '思考中',
                    session.thinking! ? '是' : '否',
                  ),
                  if (session.thinkingAt != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      '开始时间',
                      _formatDateTime(session.thinkingAt!),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppTheme.spacingMd),

          // 使用统计卡片
          if (session.latestUsage != null)
            _InfoCard(
              title: '使用统计',
              icon: Icons.bar_chart,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    '消息数',
                    '${session.latestUsage!.messageCount}',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    'Token 数',
                    '${session.latestUsage!.tokenCount}',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    '统计时间',
                    _formatDateTime(session.latestUsage!.timestamp),
                  ),
                  if (session.latestUsage!.filesAccessed != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      '访问文件数',
                      '${session.latestUsage!.filesAccessed}',
                    ),
                  ],
                  if (session.latestUsage!.toolsUsed != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      '使用工具数',
                      '${session.latestUsage!.toolsUsed}',
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppTheme.spacingMd),

          // 路径信息卡片
          if (session.path != null)
            _InfoCard(
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
            ),
          const SizedBox(height: AppTheme.spacingMd),

          // 草稿卡片
          if (session.draft != null && session.draft!.isNotEmpty)
            _InfoCard(
              title: '未发送草稿',
              icon: Icons.edit_note,
              child: _InfoContent(session.draft!),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} 小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else if (diff.inDays < 30) {
      return '${diff.inDays ~/ 7} 周前';
    } else {
      return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getPermissionModeText(String? mode) {
    switch (mode) {
      case 'manual':
        return '手动批准';
      case 'auto':
        return '自动批准';
      case 'ask':
        return '询问模式';
      default:
        return '默认';
    }
  }
}

/// 信息卡片
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppTheme.brandColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          child,
        ],
      ),
    );
  }
}

/// 信息区段标题
class _InfoSectionHeader extends StatelessWidget {
  const _InfoSectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.neutral700,
      ),
    );
  }
}

/// 信息行
class _InfoRow extends StatelessWidget {
  const _InfoRow(
    this.label,
    this.value,
  );

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// 信息内容
class _InfoContent extends StatelessWidget {
  const _InfoContent(this.content);

  final String content;

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 14,
        color: AppTheme.neutral700,
        height: 1.4,
      ),
    );
  }
}
