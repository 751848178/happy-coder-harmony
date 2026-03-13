import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
import '../../session/domain/reducer.dart';

/// 消息气泡组件
///
/// 显示用户和 AI 的消息
class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.isOwnMessage = false,
    this.onTap,
    this.onLongPress,
  });

  final ReducerMessage message;
  final bool isOwnMessage;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alignment =
        isOwnMessage ? Alignment.centerRight : Alignment.centerLeft;

    final bubbleColor = isOwnMessage
        ? AppTheme.brandColor
        : AppTheme.surface;

    final textColor = isOwnMessage ? Colors.white : AppTheme.textPrimary;

    final borderRadius = BorderRadius.only(
      topLeft: isOwnMessage
          ? const Radius.circular(16)
          : const Radius.circular(4),
      topRight: isOwnMessage
          ? const Radius.circular(4)
          : const Radius.circular(16),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
    );

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.only(
            left: isOwnMessage ? 48 : 0,
            right: isOwnMessage ? 0 : 48,
            bottom: 8,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 消息气泡
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildMessageContent(context, textColor),
              ),
              // 时间戳
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatTimestamp(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.neutral500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建消息内容
  Widget _buildMessageContent(BuildContext context, Color textColor) {
    if (message.isText && message.text != null) {
      return _buildMarkdownContent(context, message.text!, textColor);
    }

    if (message.isToolCall && message.tool != null) {
      return _buildToolCallContent(context, textColor);
    }

    if (message.isPermissionRequest && message.permission != null) {
      return _buildPermissionRequestContent(context, textColor);
    }

    if (message.isTurnClose) {
      return _buildTurnCloseContent(context, textColor);
    }

    return Text(
      'Unknown message type',
      style: TextStyle(color: textColor),
    );
  }

  /// 构建 Markdown 内容
  Widget _buildMarkdownContent(BuildContext context, String content, Color textColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: textColor,
          fontSize: 15,
          height: 1.4,
        ),
        h1: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        h2: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        h3: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        listBullet: TextStyle(
          color: textColor,
          fontSize: 15,
          height: 1.4,
        ),
        blockquote: TextStyle(
          color: textColor.withValues(alpha: 0.8),
          fontSize: 14,
          fontStyle: FontStyle.italic,
          decoration: TextDecoration.none,
        ),
        codeblockDecoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        code: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 13,
          height: 1.4,
        ),
        codeblockPadding: const EdgeInsets.all(12),
        a: TextStyle(
          color: AppTheme.brandColor,
          decoration: TextDecoration.underline,
        ),
        strong: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        em: TextStyle(
          color: textColor,
          fontStyle: FontStyle.italic,
        ),
      ),
      onTapLink: (text, href, title) {
        Logger.info('Link tapped: $href');
      },
    );
  }

  /// 构建工具调用内容
  Widget _buildToolCallContent(BuildContext context, Color textColor) {
    final tool = message.tool!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOwnMessage
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.build,
            size: 20,
            color: textColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (tool.status != null) ...[
                  const SizedBox(height: 4),
                  _buildStatusBadge(tool.status!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建状态徽章
  Widget _buildStatusBadge(dynamic status) {
    Color badgeColor = Colors.grey;
    String statusText = '未知';

    final statusStr = status is ToolCallStatus
        ? status.toString().split('.').last
        : 'pending';

    switch (statusStr) {
      case 'pending':
        badgeColor = Colors.orange;
        statusText = '待批准';
        break;
      case 'approved':
        badgeColor = Colors.green;
        statusText = '已批准';
        break;
      case 'rejected':
        badgeColor = Colors.red;
        statusText = '已拒绝';
        break;
      case 'executing':
        badgeColor = Colors.blue;
        statusText = '执行中';
        break;
      case 'completed':
        badgeColor = Colors.green;
        statusText = '已完成';
        break;
      case 'failed':
        badgeColor = Colors.red;
        statusText = '失败';
        break;
      default:
        badgeColor = Colors.grey;
        statusText = statusText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建权限请求内容
  Widget _buildPermissionRequestContent(
    BuildContext context,
    Color textColor,
  ) {
    final permission = message.permission!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 18,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                '权限请求',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            permission.tool,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建回合关闭内容
  Widget _buildTurnCloseContent(BuildContext context, Color textColor) {
    final turnClose = message.turnClose;

    if (turnClose == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.close,
            size: 14,
            color: AppTheme.neutral500,
          ),
          const SizedBox(width: 6),
          Text(
            turnClose.abandoned ? '对话已放弃' : '回合已结束',
            style: TextStyle(
              color: AppTheme.neutral500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化时间戳
  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小时前';
    } else {
      return '${difference.inDays} 天前';
    }
  }
}
