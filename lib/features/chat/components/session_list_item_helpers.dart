part of 'session_list.dart';

class _SessionListIconSpec {
  const _SessionListIconSpec({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;
}

_SessionListIconSpec sessionListIconSpec(String? tag) {
  switch (tag?.toLowerCase()) {
    case 'work':
    case '工作':
      return const _SessionListIconSpec(
        icon: Icons.work_outline,
        color: AppTheme.brandColor,
      );
    case 'personal':
    case '个人':
      return const _SessionListIconSpec(
        icon: Icons.person_outline,
        color: Colors.purple,
      );
    case 'study':
    case '学习':
      return const _SessionListIconSpec(
        icon: Icons.school_outlined,
        color: Colors.orange,
      );
    case 'code':
    case '代码':
      return const _SessionListIconSpec(
        icon: Icons.code_outlined,
        color: Colors.blue,
      );
    default:
      return const _SessionListIconSpec(
        icon: Icons.chat_bubble_outline,
        color: AppTheme.neutral500,
      );
  }
}

String formatSessionListUpdatedAt(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
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
  return '${dateTime.month}/${dateTime.day}';
}
