part of 'session_screen.dart';

extension _SessionScreenMessageBubbleToolHelpers3 on _MessageBubbleState {
  static const _excludedArgumentKeys = <String>{
    'command', 'cmd', 'patch', 'diff',
    'old_string', 'new_string', 'oldText', 'newText', 'edits',
  };

  bool _shouldShowRawArguments(
    Map<String, dynamic> arguments, {
    required String? command,
    required String? diff,
  }) {
    if (arguments.isEmpty) {
      return false;
    }
    if (command == null && diff == null) {
      return true;
    }
    for (final key in arguments.keys) {
      if (!_excludedArgumentKeys.contains(key)) {
        return true;
      }
    }
    return false;
  }

  String? _formatToolResult(String? result) {
    if (result == null || result.trim().isEmpty) {
      return null;
    }
    final trimmed = result.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return trimmed;
      }
    }
    return trimmed;
  }

  String _guessLanguageForResult(
    String? content, {
    required String toolName,
  }) {
    if (content == null || content.isEmpty) {
      return '';
    }
    final lowerTool = toolName.toLowerCase();
    if (content.startsWith('{') || content.startsWith('[')) {
      return 'json';
    }
    if (content.contains('diff --git') || content.contains('@@')) {
      return 'diff';
    }
    final detected = _detectStructuredLanguage(content);
    if (detected.isNotEmpty) {
      return detected;
    }
    if (lowerTool.contains('bash') ||
        lowerTool.contains('shell') ||
        lowerTool.contains('execute')) {
      return 'shell';
    }
    if (lowerTool.contains('read') ||
        lowerTool.contains('write') ||
        lowerTool.contains('edit')) {
      return 'text';
    }
    return '';
  }

  String _resultSectionTitle(String toolName) {
    final lower = toolName.toLowerCase();
    if (lower.contains('bash') ||
        lower.contains('shell') ||
        lower.contains('execute')) {
      return '命令输出';
    }
    if (lower.contains('read')) {
      return '文件内容';
    }
    if (lower.contains('search') ||
        lower.contains('grep') ||
        lower.contains('glob') ||
        lower.contains('ls')) {
      return '搜索结果';
    }
    return '输出结果';
  }

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

  String? _formatToolArguments(Map<String, dynamic> arguments) {
    if (arguments.isEmpty) {
      return null;
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(arguments);
    } catch (_) {
      return arguments.toString();
    }
  }

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
