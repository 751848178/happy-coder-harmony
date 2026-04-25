import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

part 'card.dart';
part 'content.dart';
part 'grouping.dart';
part 'support.dart';

/// Session item model for history
class SessionHistoryItem {
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

  Duration get age => DateTime.now().difference(createdAt);
}

class DateGroup {
  const DateGroup({
    required this.label,
    required this.items,
    required this.date,
  });

  final String label;
  final List<SessionHistoryItem> items;
  final DateTime date;
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
  final ValueChanged<SessionHistoryItem> onItemTap;
  final ValueChanged<SessionHistoryItem>? onItemLongPress;
  final bool showDateHeaders;
  final bool compact;
  final bool showThumbnails;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _buildEmptyState();
    final groupedItems = DateGrouper.groupByDate(items);
    return ListView.separated(
      itemCount: groupedItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildDateGroup(groupedItems[index]),
    );
  }
}
