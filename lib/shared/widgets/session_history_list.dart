import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Session item model for history
class SessionHistoryItem {
  final String id;
  final String title;
  final String? subtitle;
  final DateTime createdAt;
  final DateTime? lastModified;
  final String? type;
  final String? machine;
  final int? messageCount;
  final int? changedLineCount;
  final String? thumbnail;

  const SessionHistoryItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.createdAt,
    this.lastModified,
    this.type,
    this.machine,
    this.messageCount,
    this.changedLineCount,
    this.thumbnail,
  });

  Duration get age => DateTime.now().difference(createdAt);
}

/// Date group model
class DateGroup {
  final String label;
  final List<SessionHistoryItem> items;
  final DateTime date;

  const DateGroup({
    required this.label,
    required this.items,
    required this.date,
  });
}

/// Date grouping helper
class DateGrouper {
  /// Group items by date category
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

      String groupKey;

      if (itemDate == today) {
        groupKey = 'today';
      } else if (itemDate == yesterday) {
        groupKey = 'yesterday';
      } else {
        final daysDiff = today.difference(itemDate).inDays;
        if (daysDiff < 7) {
          groupKey = 'week';
        } else if (daysDiff < 30) {
          groupKey = 'month';
        } else {
          groupKey = '${itemDate.year}-${itemDate.month}';
        }
      }

      groups.putIfAbsent(groupKey, () => []);
      groups[groupKey]!.add(item);
    }

    // Build ordered group list
    final orderedKeys = <String>[];
    if (groups.containsKey('today')) orderedKeys.add('today');
    if (groups.containsKey('yesterday')) orderedKeys.add('yesterday');
    if (groups.containsKey('week')) orderedKeys.add('week');
    if (groups.containsKey('month')) orderedKeys.add('month');

    // Add month keys sorted
    final monthKeys = groups.keys
        .where((k) => k.contains('-'))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    orderedKeys.addAll(monthKeys);

    // Build result
    return orderedKeys.map((key) {
      final groupItems = groups[key]!;
      final firstItem = groupItems.first;

      String label;
      if (key == 'today') {
        label = '今天';
      } else if (key == 'yesterday') {
        label = '昨天';
      } else if (key == 'week') {
        label = '本周';
      } else if (key == 'month') {
        label = '本月';
      } else {
        final parts = key.split('-');
        label = '${parts[0]}年${parts[1]}月';
      }

      return DateGroup(
        label: label,
        items: groupItems,
        date: DateTime(
          firstItem.createdAt.year,
          firstItem.createdAt.month,
          firstItem.createdAt.day,
        ),
      );
    }).toList();
  }

  /// Get date category label
  static String getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return '今天';
    } else if (itemDate == yesterday) {
      return '昨天';
    }

    final daysDiff = today.difference(itemDate).inDays;

    if (daysDiff == 1) return '1天前';
    if (daysDiff < 7) return '${daysDiff}天前';
    if (daysDiff < 30) return '本周';
    if (daysDiff < 60) return '本月';
    if (daysDiff < 365) return '${date.month}月${date.day}日';

    return '${date.year}年${date.month}月${date.day}日';
  }

  /// Get relative time string
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return mins == 1 ? '1分钟前' : '$mins分钟前';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? '1小时前' : '$hours小时前';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1 ? '1天前' : '$days天前';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1周前' : '$weeks周前';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1个月前' : '$months个月前';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1年前' : '$years年前';
    }
  }
}

/// Session History List Widget
///
/// Displays session history grouped by date
class SessionHistoryList extends StatelessWidget {
  const SessionHistoryList({
    super.key,
    required this.items,
    required this.onItemTap,
    this.onItemLongPress,
    this.showDateHeaders = true,
    this.compact = false,
    this.showThumbnails = false,
  });

  final List<SessionHistoryItem> items;
  final Function(SessionHistoryItem) onItemTap;
  final Function(SessionHistoryItem)? onItemLongPress;
  final bool showDateHeaders;
  final bool compact;
  final bool showThumbnails;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    final groupedItems = DateGrouper.groupByDate(items);

    return ListView.separated(
      itemCount: groupedItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final group = groupedItems[index];
        return _buildDateGroup(group);
      },
    );
  }

  Widget _buildDateGroup(DateGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDateHeaders) _buildDateHeader(group),
        const SizedBox(height: 8),
        ...group.items.map((item) => _buildSessionItem(item)).toList(),
      ],
    );
  }

  Widget _buildDateHeader(DateGroup group) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        group.label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutral600,
        ),
      ),
    );
  }

  Widget _buildSessionItem(SessionHistoryItem item) {
    return InkWell(
      onTap: () => onItemTap(item),
      onLongPress: onItemLongPress != null ? () => onItemLongPress!(item) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: Row(
          children: [
            if (showThumbnails && item.thumbnail != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.thumbnail!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (!showThumbnails)
              Container(
                width: compact ? 40 : 48,
                height: compact ? 40 : 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(item.type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(item.type),
                  color: _getTypeColor(item.type),
                  size: compact ? 20 : 24,
                ),
              ),
            if (!showThumbnails) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (!compact) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.machine != null) ...[
                          Icon(
                            Icons.computer,
                            size: 12,
                            color: AppTheme.neutral500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.machine!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.neutral500,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppTheme.neutral500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateGrouper.getRelativeTime(item.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.neutral500,
                          ),
                        ),
                        if (item.messageCount != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.brandColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.messageCount}条消息',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.brandColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (item.changedLineCount != null &&
                            item.changedLineCount! > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.changedLineCount}行改动',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.warningColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (compact && item.messageCount != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.messageCount}条',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.brandColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (compact &&
                item.changedLineCount != null &&
                item.changedLineCount! > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.changedLineCount}行',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 16),
            const Text(
              '暂无历史记录',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'code':
        return Icons.code;
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'writing':
        return Icons.edit_note_outlined;
      case 'debug':
        return Icons.bug_report_outlined;
      case 'review':
        return Icons.rate_review_outlined;
      case 'translate':
        return Icons.translate;
      default:
        return Icons.chat;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'code':
        return const Color(0xFF6366F1);
      case 'chat':
        return const Color(0xFF10B981);
      case 'writing':
        return const Color(0xFFF59E0B);
      case 'debug':
        return const Color(0xFFEF4444);
      case 'review':
        return const Color(0xFF8B5CF6);
      case 'translate':
        return const Color(0xFFEC4899);
      default:
        return AppTheme.brandColor;
    }
  }
}

/// Session history card (for grid view)
class SessionHistoryCard extends StatelessWidget {
  const SessionHistoryCard({
    super.key,
    required this.item,
    required this.onTap,
    this.compact = false,
  });

  final SessionHistoryItem item;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: compact
              ? const EdgeInsets.all(12)
              : const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (item.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  item.subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutral600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: AppTheme.neutral500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateGrouper.getRelativeTime(item.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.neutral500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Session history search helper
class SessionHistorySearch {
  static List<SessionHistoryItem> search(
    List<SessionHistoryItem> items,
    String query,
  ) {
    if (query.isEmpty) return items;

    final lowerQuery = query.toLowerCase();

    return items.where((item) {
      final titleMatch = item.title.toLowerCase().contains(lowerQuery);
      final subtitleMatch = item.subtitle?.toLowerCase().contains(lowerQuery) ?? false;
      final typeMatch = item.type?.toLowerCase().contains(lowerQuery) ?? false;
      final machineMatch = item.machine?.toLowerCase().contains(lowerQuery) ?? false;

      return titleMatch || subtitleMatch || typeMatch || machineMatch;
    }).toList();
  }
}
