part of 'session_screen.dart';

extension _SessionScreenMessageBubbleToolHelpers3 on _MessageBubbleState {
  bool _shouldShowRawArguments(
    Map<String, dynamic> arguments, {
    required String? command,
    required String? diff,
  }) => _MessageBubbleState._bubblePresenter.shouldShowRawArguments(
        arguments,
        command: command,
        diff: diff,
      );

  String? _formatToolResult(String? result) =>
      _MessageBubbleState._bubblePresenter.formatToolResult(result);

  String _guessLanguageForResult(
    String? content, {
    required String toolName,
  }) => _MessageBubbleState._bubblePresenter.guessLanguageForResult(
        content,
        toolName: toolName,
      );

  String _resultSectionTitle(String toolName) =>
      _MessageBubbleState._bubblePresenter.resultSectionTitle(toolName);

  Widget _buildToolStatusBadge(ToolCallStatus status) {
    Color color;
    String text;

    switch (status) {
      case ToolCallStatus.pending:
        color = AppTheme.warningColor;
        text = '待确认';
        break;
      case ToolCallStatus.approved:
        color = AppTheme.infoColor;
        text = '已处理';
        break;
      case ToolCallStatus.rejected:
        color = AppTheme.errorColor;
        text = '已拒绝';
        break;
      case ToolCallStatus.executing:
        color = AppTheme.infoColor;
        text = '执行中';
        break;
      case ToolCallStatus.completed:
        color = AppTheme.infoColor;
        text = '已完成';
        break;
      case ToolCallStatus.failed:
        color = AppTheme.errorColor;
        text = '失败';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String? _formatToolArguments(Map<String, dynamic> arguments) =>
      _MessageBubbleState._bubblePresenter.formatToolArguments(arguments);

  String _messageKindLabel(String kind) {
    switch (kind) {
      case 'text':
        return '文本消息';
      case 'tool-call':
        return '工具调用';
      case 'permission-request':
        return '权限请求';
      case 'turn-close':
        return '回合结束';
      case 'agent-event':
        return '状态事件';
      case 'error':
        return '错误消息';
      default:
        return kind;
    }
  }

  Widget _buildDefaultMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Text(
        _messageKindLabel(message.kind),
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.neutral600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
