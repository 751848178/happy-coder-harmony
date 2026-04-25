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

String permissionModeText(String? mode, {String? flavor}) {
  switch (flavor) {
    case 'codex':
    case 'gemini':
      switch (mode) {
        case 'read-only':
          return '只读';
        case 'safe-yolo':
          return '安全自动';
        case 'yolo':
          return '全自动';
        case 'default':
        case null:
        case '':
          return '默认';
        default:
          return mode;
      }
    case 'claude':
    default:
      switch (mode) {
        case 'acceptEdits':
          return '自动改动';
        case 'plan':
          return '规划';
        case 'bypassPermissions':
          return '跳过权限';
        case 'default':
        case null:
        case '':
          return '默认';
        default:
          return mode;
      }
  }
}

String permissionModeDescription(String? mode, {String? flavor}) {
  switch (flavor) {
    case 'codex':
    case 'gemini':
      switch (mode) {
        case 'read-only':
          return '仅允许读取，不执行写入类操作。';
        case 'safe-yolo':
          return '自动处理低风险操作，保留安全边界。';
        case 'yolo':
          return '尽量不询问，直接执行工具操作。';
        case 'default':
        case null:
        case '':
          return '按工具默认策略请求确认。';
        default:
          return '当前会按 $mode 模式处理工具调用。';
      }
    case 'claude':
    default:
      switch (mode) {
        case 'acceptEdits':
          return '自动批准改动类工具调用。';
        case 'plan':
          return '优先进行规划，不直接执行改动。';
        case 'bypassPermissions':
          return '跳过权限确认，直接执行工具调用。';
        case 'default':
        case null:
        case '':
          return '按工具默认策略请求确认。';
        default:
          return '当前会按 $mode 模式处理工具调用。';
      }
  }
}
