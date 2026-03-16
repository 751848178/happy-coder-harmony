part of 'sessions_screen.dart';

String _formatSessionUpdatedAt(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inMinutes < 1) {
    return '刚刚';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} 分钟前';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} 小时前';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} 天前';
  }
  if (diff.inDays < 30) {
    return '${diff.inDays ~/ 7} 周前';
  }
  return '${dateTime.year}年${dateTime.month}月${dateTime.day}日';
}

String? _directoryBadgeLabel(Session session) {
  final path =
      session.path?.trim() ?? session.metadata?['path']?.toString().trim();
  if (path == null || path.isEmpty) {
    final fallbackTag = session.tag?.trim();
    return fallbackTag == null || fallbackTag.isEmpty ? null : fallbackTag;
  }
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return null;
  }
  return parts.last;
}
