part of 'session_history_list.dart';

class DateGrouper {
  static List<DateGroup> groupByDate(List<SessionHistoryItem> items) {
    final groups = <String, List<SessionHistoryItem>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final item in items) {
      final itemDate = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      final groupKey = _groupKeyForDate(itemDate, today, yesterday);
      groups.putIfAbsent(groupKey, () => []).add(item);
    }

    final orderedKeys = <String>[
      if (groups.containsKey('today')) 'today',
      if (groups.containsKey('yesterday')) 'yesterday',
      if (groups.containsKey('week')) 'week',
      if (groups.containsKey('month')) 'month',
      ...groups.keys.where((k) => k.contains('-')).toList()
        ..sort((a, b) => b.compareTo(a)),
    ];

    return orderedKeys.map((key) {
      final groupItems = groups[key]!;
      final firstItem = groupItems.first;
      return DateGroup(
        label: _groupLabelForKey(key),
        items: groupItems,
        date: DateTime(
          firstItem.createdAt.year,
          firstItem.createdAt.month,
          firstItem.createdAt.day,
        ),
      );
    }).toList();
  }

  static String getRelativeTime(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return '刚刚';
    if (difference.inMinutes < 60) return '${difference.inMinutes}分钟前';
    if (difference.inHours < 24) return '${difference.inHours}小时前';
    if (difference.inDays < 7) return '${difference.inDays}天前';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}周前';
    if (difference.inDays < 365)
      return '${(difference.inDays / 30).floor()}个月前';
    return '${(difference.inDays / 365).floor()}年前';
  }
}

class SessionHistorySearch {
  static List<SessionHistoryItem> search(
    List<SessionHistoryItem> items,
    String query,
  ) {
    if (query.isEmpty) return items;
    final lowerQuery = query.toLowerCase();
    return items.where((item) {
      return item.title.toLowerCase().contains(lowerQuery) ||
          (item.subtitle?.toLowerCase().contains(lowerQuery) ?? false) ||
          (item.type?.toLowerCase().contains(lowerQuery) ?? false) ||
          (item.machine?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}

String _groupKeyForDate(DateTime itemDate, DateTime today, DateTime yesterday) {
  if (itemDate == today) return 'today';
  if (itemDate == yesterday) return 'yesterday';
  final daysDiff = today.difference(itemDate).inDays;
  if (daysDiff < 7) return 'week';
  if (daysDiff < 30) return 'month';
  return '${itemDate.year}-${itemDate.month}';
}

String _groupLabelForKey(String key) {
  if (key == 'today') return '今天';
  if (key == 'yesterday') return '昨天';
  if (key == 'week') return '本周';
  if (key == 'month') return '本月';
  final parts = key.split('-');
  return '${parts[0]}年${parts[1]}月';
}
