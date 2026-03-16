part of 'session_info_screen.dart';

String formatSessionInfoDateTime(DateTime dateTime) {
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
  return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 '
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}';
}

String permissionModeText(String? mode) {
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
