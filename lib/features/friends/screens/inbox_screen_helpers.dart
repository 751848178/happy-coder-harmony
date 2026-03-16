part of 'inbox_screen.dart';

String? mergeInboxLoadErrors(Object? feedError, Object? relationshipError) {
  if (feedError == null && relationshipError == null) {
    return null;
  }
  if (feedError == null && relationshipError != null) {
    return friendlyInboxErrorMessage(relationshipError);
  }
  if (feedError != null && relationshipError == null) {
    return null;
  }
  return friendlyInboxErrorMessage(feedError!);
}

String friendlyInboxErrorMessage(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 400 || statusCode == 404) {
      return '当前账号的收件箱数据尚未准备好，请稍后下拉重试。';
    }
    if (statusCode == 401 || statusCode == 403) {
      return '登录状态已失效，请重新登录后再查看收件箱。';
    }
    if (statusCode != null && statusCode >= 500) {
      return '服务端暂时不可用，请稍后重试。';
    }
    return '网络请求失败，请检查网络或服务器地址。';
  }
  return '收件箱加载失败，请稍后重试。';
}

IconData inboxFeedIcon(InboxItem item) {
  switch (item.type) {
    case InboxItemType.friendRequest:
      return Icons.person_add_alt_1_rounded;
    case InboxItemType.message:
      return Icons.mail_outline_rounded;
    case InboxItemType.notification:
      return Icons.notifications_none_rounded;
  }
}

Color inboxFeedIconColor(InboxItem item) {
  switch (item.type) {
    case InboxItemType.friendRequest:
      return AppTheme.brandColor;
    case InboxItemType.message:
      return AppTheme.infoColor;
    case InboxItemType.notification:
      return AppTheme.warningColor;
  }
}

String formatInboxRelativeTime(DateTime time) {
  final difference = DateTime.now().difference(time);
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
  return '${time.month}/${time.day}';
}
