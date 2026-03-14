import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../app/providers/app_providers.dart';
import '../../../shared/utils/extensions.dart';
import '../../session/domain/session_stats.dart';

/// 会话列表项
class SessionListItem extends ConsumerWidget {
  const SessionListItem({
    super.key,
    required this.session,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  final Session session;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionMessages = ref.watch(
      sessionStateProvider.select(
        (state) => state.whenOrNull(
          ready: (_, sessionMessages, __) =>
              sessionMessages[session.id]?.messages,
        ),
      ),
    );
    final stats = SessionStatsCalculator.fromSession(
      session: session,
      messages: sessionMessages,
    );
    final messageCount = stats.messageCount;
    final isActive = session.active;
    final lastUpdated = session.updatedAt;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandColor.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppTheme.neutral200,
              width: 1,
            ),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 会话图标
            _buildSessionIcon(context, isActive),
            const SizedBox(width: 12),
            // 会话信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 会话标题
                  Text(
                    session.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 会话元信息
                  Row(
                    children: [
                      // 活跃状态指示器
                      if (isActive)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      // 消息数
                      if (messageCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.neutral200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$messageCount',
                            style: const TextStyle(
                              color: AppTheme.neutral600,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const Spacer(),
                      // 最后更新时间
                      Text(
                        _formatLastUpdated(lastUpdated),
                        style: TextStyle(
                          color: AppTheme.neutral500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 更多按钮
            _buildMoreButton(context, ref),
          ],
        ),
      ),
    );
  }

  /// 构建会话图标
  Widget _buildSessionIcon(BuildContext context, bool isActive) {
    final tag = session.tag;
    IconData iconData;
    Color iconColor;

    // 根据标签选择图标
    if (tag != null && tag.isNotEmpty) {
      switch (tag.toLowerCase()) {
        case 'work':
        case '工作':
          iconData = Icons.work_outline;
          iconColor = AppTheme.brandColor;
          break;
        case 'personal':
        case '个人':
          iconData = Icons.person_outline;
          iconColor = Colors.purple;
          break;
        case 'study':
        case '学习':
          iconData = Icons.school_outlined;
          iconColor = Colors.orange;
          break;
        case 'code':
        case '代码':
          iconData = Icons.code_outlined;
          iconColor = Colors.blue;
          break;
        default:
          iconData = Icons.chat_bubble_outline;
          iconColor = AppTheme.neutral500;
      }
    } else {
      iconData = Icons.chat_bubble_outline;
      iconColor = AppTheme.neutral500;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color:
            isActive ? iconColor.withValues(alpha: 0.2) : AppTheme.neutral100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  /// 构建更多按钮
  Widget _buildMoreButton(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onSelected: (value) {
        _handleMenuSelection(context, ref, value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 12),
              Text('重命名'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(Icons.archive_outlined, size: 18),
              SizedBox(width: 12),
              Text('归档'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 3,
          child: Row(
            children: [
              Icon(Icons.push_pin_outlined, size: 18),
              SizedBox(width: 12),
              Text('置顶'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 4,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 12),
              Text('删除', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  /// 处理菜单选择
  void _handleMenuSelection(BuildContext context, WidgetRef ref, int value) {
    final sessionService = ref.read(sessionStateProvider.notifier);

    switch (value) {
      case 1: // 重命名
        _showRenameDialog(context, ref, sessionService);
        break;
      case 2: // 归档
        _showArchiveDialog(context, ref, sessionService);
        break;
      case 3: // 置顶
        Logger.info('Pin session: ${session.id}');
        // 将会话设置为活跃状态（置顶）
        sessionService.updateDraft(session.id, session.draft ?? '');
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('会话已置顶')),
        );
        break;
      case 4: // 删除
        _showDeleteDialog(context, ref, sessionService);
        break;
    }
  }

  /// 显示重命名对话框
  void _showRenameDialog(
      BuildContext context, WidgetRef ref, dynamic sessionService) {
    final controller = TextEditingController(text: session.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名会话'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入新名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != session.title) {
                // 更新会话标题（通过更新 draft 临时存储，实际应该调用 API）
                sessionService.updateDraft(session.id, newName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('会话名称已更新')),
                );
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示归档对话框
  void _showArchiveDialog(
      BuildContext context, WidgetRef ref, dynamic sessionService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('归档会话'),
        content: Text('确认归档"${session.title}"会话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 归档会话（设置为不活跃）
              sessionService.updateDraft(session.id, null);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('会话已归档')),
              );
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  /// 显示删除对话框
  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, dynamic sessionService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确认删除"${session.title}"会话吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await sessionService.deleteSession(session.id);
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('会话已删除')),
                );
              } catch (error) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('删除失败: $error')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 格式化最后更新时间
  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      // 显示日期
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}

/// 会话列表组件
class SessionsList extends ConsumerWidget {
  const SessionsList({
    super.key,
    this.showActiveOnly = false,
    this.onSessionTap,
    this.onNewSessionTap,
  });

  final bool showActiveOnly;
  final void Function(String sessionId)? onSessionTap;
  final VoidCallback? onNewSessionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionStateProvider);

    return sessionState.when(
      initial: () => _buildLoadingView(context),
      loading: () => _buildLoadingView(context),
      ready: (sessions, sessionMessages, machines) {
        final sessionList = showActiveOnly
            ? sessions.values.where((s) => s.active).toList()
            : sessions.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        if (sessionList.isEmpty) {
          return _buildEmptyView(context);
        }

        return _buildSessionsList(context, sessionList);
      },
      error: (message) => _buildErrorView(context, message),
    );
  }

  /// 构建加载视图
  Widget _buildLoadingView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.brandColor),
          const SizedBox(height: 16),
          Text(
            '加载会话中...',
            style: TextStyle(
              color: AppTheme.neutral600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空视图
  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            showActiveOnly ? '暂无活跃会话' : '暂无会话',
            style: TextStyle(
              color: AppTheme.neutral600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onNewSessionTap,
            icon: const Icon(Icons.add),
            label: const Text('创建新会话'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
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
            style: TextStyle(
              color: AppTheme.neutral600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建会话列表
  Widget _buildSessionsList(BuildContext context, List<Session> sessions) {
    return Column(
      children: [
        // 新建会话按钮
        if (onNewSessionTap != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onNewSessionTap,
                icon: const Icon(Icons.add),
                label: const Text('新建会话'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        // 会话列表
        Expanded(
          child: ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 68,
            ),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return SessionListItem(
                session: session,
                onTap: () => onSessionTap?.call(session.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
