part of 'todo_tool_screen.dart';

extension _TodoTaskItemHelpers on _TaskItem {
  Color get _priorityColor {
    return switch (task.priority) {
      TaskPriority.low => AppTheme.successColor,
      TaskPriority.medium => AppTheme.infoColor,
      TaskPriority.high => Colors.orange,
      TaskPriority.urgent => Colors.red,
    };
  }

  String get _priorityLabel {
    return switch (task.priority) {
      TaskPriority.low => '低',
      TaskPriority.medium => '中',
      TaskPriority.high => '高',
      TaskPriority.urgent => '紧急',
    };
  }

  String get _timeAgo {
    final difference = DateTime.now().difference(task.createdAt);
    if (difference.inMinutes < 1) {
      return '刚刚';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟前';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} 小时前';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    }
    return '${task.createdAt.month}/${task.createdAt.day}';
  }

  IconData _getPriorityIcon() {
    return switch (task.priority) {
      TaskPriority.low => Icons.looks_one,
      TaskPriority.medium => Icons.looks_two,
      TaskPriority.high => Icons.looks_3,
      TaskPriority.urgent => Icons.priority_high,
    };
  }
}
