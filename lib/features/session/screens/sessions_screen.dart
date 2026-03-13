import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/session_history_list.dart';
import '../data/session_grouping_service.dart';
import '../domain/session_stats.dart';

/// 会话列表屏幕
class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({
    super.key,
    this.showAppBar = true,
    this.showSearchBar = true,
    this.showFab = true,
  });

  final bool showAppBar;
  final bool showSearchBar;
  final bool showFab;

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  final SessionGroupingService _groupingService =
      SessionGroupingService.instance;

  String _searchQuery = '';
  bool _showActiveOnly = false;
  bool _groupingLoaded = false;
  SessionGroupingState _groupingState = const SessionGroupingState();
  final Set<String> _collapsedDefaultGroups = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionStateProvider.notifier).loadSessions();
      _loadGroupingState();
    });
  }

  Future<void> _loadGroupingState() async {
    final state = await _groupingService.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _groupingState = state;
      _groupingLoaded = true;
    });
  }

  Future<void> _updateGroupingState(
    Future<SessionGroupingState> Function() action,
  ) async {
    final nextState = await action();
    if (!mounted) {
      return;
    }
    setState(() {
      _groupingState = nextState;
      _groupingLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionStateProvider);
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final settings = ref.watch(settingsStateProvider);
    final sessions = sessionNotifier.sessions;
    final filteredSessions = sessions.where((session) {
      if ((_showActiveOnly || settings.hideInactiveSessions) &&
          !session.active) {
        return false;
      }
      if (_searchQuery.isEmpty) {
        return true;
      }
      final query = _searchQuery.toLowerCase();
      return session.title.toLowerCase().contains(query) ||
          session.tag?.toLowerCase().contains(query) == true ||
          session.path?.toLowerCase().contains(query) == true;
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final statsBySessionId = <String, SessionStats>{
      for (final session in filteredSessions)
        session.id: SessionStatsCalculator.fromSession(
          session: session,
          messages: sessionNotifier.getSessionMessages(session.id)?.messages,
        ),
    };

    final body = Column(
      children: [
        if (widget.showSearchBar) _buildSearchBar(),
        _buildGroupingToolbar(filteredSessions.isNotEmpty),
        Expanded(
          child: !_groupingLoaded
              ? const Center(child: CircularProgressIndicator())
              : filteredSessions.isEmpty
                  ? _buildEmptyState(sessions.isNotEmpty)
                  : _buildGroupedSessionList(
                      sessions: filteredSessions,
                      statsBySessionId: statsBySessionId,
                    ),
        ),
      ],
    );

    if (!widget.showAppBar) {
      return ColoredBox(
        color: AppTheme.neutral50,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('会话'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'active') {
                setState(() => _showActiveOnly = !_showActiveOnly);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'active',
                child: Row(
                  children: [
                    Icon(
                      _showActiveOnly
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: AppTheme.brandColor,
                    ),
                    const SizedBox(width: 12),
                    const Text('仅显示活跃会话'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: body,
      floatingActionButton: widget.showFab
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.newFlow),
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add),
              label: const Text('新建会话'),
            )
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      color: AppTheme.surface,
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索会话...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          filled: true,
          fillColor: AppTheme.neutral100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildGroupingToolbar(bool hasSessions) {
    if (!hasSessions && !_groupingState.useCustomGroups) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        0,
        AppTheme.spacingMd,
        AppTheme.spacingMd,
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ChoiceChip(
            label: const Text('默认分组'),
            selected: !_groupingState.useCustomGroups,
            onSelected: (_) {
              _updateGroupingState(
                () => _groupingService.setUseCustomGroups(false),
              );
            },
          ),
          ChoiceChip(
            label: const Text('自定义分组'),
            selected: _groupingState.useCustomGroups,
            onSelected: (_) {
              _updateGroupingState(
                () => _groupingService.setUseCustomGroups(true),
              );
            },
          ),
          if (_groupingState.useCustomGroups)
            TextButton.icon(
              onPressed: () => _showCreateGroupDialog(),
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('新建分组'),
            ),
          if (_groupingState.useCustomGroups)
            Text(
              '长按会话可移动到分组',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.neutral600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupedSessionList({
    required List<Session> sessions,
    required Map<String, SessionStats> statsBySessionId,
  }) {
    if (_groupingState.useCustomGroups) {
      return _buildCustomGroupList(
        sessions: sessions,
        statsBySessionId: statsBySessionId,
      );
    }
    return _buildDefaultGroupedList(
      sessions: sessions,
      statsBySessionId: statsBySessionId,
    );
  }

  Widget _buildDefaultGroupedList({
    required List<Session> sessions,
    required Map<String, SessionStats> statsBySessionId,
  }) {
    final items = sessions
        .map(
          (session) => SessionHistoryItem(
            id: session.id,
            title: session.title.isEmpty ? '未命名会话' : session.title,
            subtitle:
                session.path ?? session.metadata?['description']?.toString(),
            createdAt: session.activeAt ?? session.updatedAt,
            lastModified: session.updatedAt,
            type: session.tag,
            messageCount: statsBySessionId[session.id]?.messageCount,
            changedLineCount: statsBySessionId[session.id]?.hasChanges == true
                ? statsBySessionId[session.id]?.changedLineCount
                : null,
          ),
        )
        .toList();
    final groups = DateGrouper.groupByDate(items);
    final sessionMap = {for (final session in sessions) session.id: session};

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final collapsed = _collapsedDefaultGroups.contains(group.label);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SessionSectionHeader(
                title: group.label,
                count: group.items.length,
                collapsed: collapsed,
                onTap: () {
                  setState(() {
                    if (collapsed) {
                      _collapsedDefaultGroups.remove(group.label);
                    } else {
                      _collapsedDefaultGroups.add(group.label);
                    }
                  });
                },
              ),
              if (!collapsed) ...[
                const SizedBox(height: 8),
                ...group.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SessionListItem(
                      session: sessionMap[item.id]!,
                      stats: statsBySessionId[item.id]!,
                      groupName: _groupNameForSession(item.id),
                      onTap: () => _openSession(sessionMap[item.id]!),
                      onDelete: () => _deleteSession(sessionMap[item.id]!),
                      onLongPress: () =>
                          _showMoveSessionSheet(sessionMap[item.id]!),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomGroupList({
    required List<Session> sessions,
    required Map<String, SessionStats> statsBySessionId,
  }) {
    final sessionMap = {for (final session in sessions) session.id: session};
    final sections = <Widget>[];

    for (final group in _groupingState.groups) {
      final groupedSessions = group.sessionIds
          .map((sessionId) => sessionMap[sessionId])
          .whereType<Session>()
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SessionSectionHeader(
                title: group.name,
                count: groupedSessions.length,
                collapsed: group.collapsed,
                trailingMenu: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'rename') {
                      _showRenameGroupDialog(group);
                    } else if (value == 'delete') {
                      _deleteGroup(group);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'rename',
                      child: Text('重命名'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('删除分组'),
                    ),
                  ],
                  child: const Icon(Icons.more_horiz_rounded),
                ),
                onTap: () {
                  _updateGroupingState(
                    () => _groupingService.toggleGroupCollapsed(group.id),
                  );
                },
              ),
              if (!group.collapsed) ...[
                const SizedBox(height: 8),
                if (groupedSessions.isEmpty)
                  _EmptyGroupCard(
                    text: '这个分组还没有会话，长按任意会话后可移动到这里。',
                  )
                else
                  ...groupedSessions.map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SessionListItem(
                        session: session,
                        stats: statsBySessionId[session.id]!,
                        groupName: group.name,
                        onTap: () => _openSession(session),
                        onDelete: () => _deleteSession(session),
                        onLongPress: () => _showMoveSessionSheet(session),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    }

    final groupedIds =
        _groupingState.groups.expand((group) => group.sessionIds).toSet();
    final ungroupedSessions = sessions
        .where((session) => !groupedIds.contains(session.id))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    sections.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SessionSectionHeader(
              title: '未分组',
              count: ungroupedSessions.length,
              collapsed: _groupingState.ungroupedCollapsed,
              onTap: () {
                _updateGroupingState(
                  () => _groupingService.toggleUngroupedCollapsed(),
                );
              },
            ),
            if (!_groupingState.ungroupedCollapsed) ...[
              const SizedBox(height: 8),
              if (ungroupedSessions.isEmpty)
                const _EmptyGroupCard(
                  text: '当前没有未分组会话。',
                )
              else
                ...ungroupedSessions.map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SessionListItem(
                      session: session,
                      stats: statsBySessionId[session.id]!,
                      onTap: () => _openSession(session),
                      onDelete: () => _deleteSession(session),
                      onLongPress: () => _showMoveSessionSheet(session),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );

    if (sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_copy_outlined,
              size: 56,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 12),
            Text(
              '还没有自定义分组',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral800,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _showCreateGroupDialog,
              icon: const Icon(Icons.add),
              label: const Text('创建第一个分组'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: sections,
    );
  }

  Future<void> _showCreateGroupDialog({String? moveSessionId}) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建分组'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '例如：正在处理 / 已归档 / 客户项目',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final name = controller.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入分组名称')),
        );
      }
      return;
    }
    try {
      await _updateGroupingState(
        () => _groupingService.createGroup(name),
      );
      if (moveSessionId != null) {
        final createdGroup = _groupingState.groups.lastWhere(
          (group) => group.name == name,
        );
        await _updateGroupingState(
          () => _groupingService.assignSession(
            sessionId: moveSessionId,
            groupId: createdGroup.id,
          ),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              moveSessionId == null ? '已创建分组「$name」' : '已创建分组「$name」并完成移动',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } on SessionGroupNameConflictException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('分组名称已存在，请换一个名称'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    }
  }

  Future<void> _showRenameGroupDialog(SessionGroup group) async {
    final controller = TextEditingController(text: group.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名分组'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入新的分组名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final name = controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    try {
      await _updateGroupingState(
        () => _groupingService.renameGroup(
          groupId: group.id,
          name: name,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已重命名为「$name」'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } on SessionGroupNameConflictException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('分组名称已存在，请换一个名称'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteGroup(SessionGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分组'),
        content: Text('删除分组「${group.name}」后，其中的会话会回到未分组。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await _updateGroupingState(() => _groupingService.deleteGroup(group.id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除分组「${group.name}」'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _showMoveSessionSheet(Session session) async {
    final currentGroupId = _groupingService.groupIdForSession(
      _groupingState,
      session.id,
    );
    final currentGroupName = currentGroupId == null
        ? '未分组'
        : _groupNameForSession(session.id) ?? '未分组';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '移动到分组',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '当前所在：$currentGroupName',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.neutral600,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              FilledButton.tonalIcon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _showCreateGroupDialog(moveSessionId: session.id);
                },
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('新建分组并移动'),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _SessionGroupOptionTile(
                label: '未分组',
                subtitle: '移出当前分组',
                selected: currentGroupId == null,
                onTap: () async {
                  Navigator.pop(context);
                  await _updateGroupingState(
                    () => _groupingService.assignSession(
                      sessionId: session.id,
                    ),
                  );
                },
              ),
              for (final group in _groupingState.groups)
                _SessionGroupOptionTile(
                  label: group.name,
                  subtitle: group.id == currentGroupId ? '当前分组' : '点击移动到这里',
                  selected: currentGroupId == group.id,
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateGroupingState(
                      () => _groupingService.assignSession(
                        sessionId: session.id,
                        groupId: group.id,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSession(Session session) {
    context.push(AppRoutes.sessionDetail(session.id));
  }

  Future<void> _deleteSession(Session session) async {
    try {
      await ref.read(sessionStateProvider.notifier).deleteSession(session.id);
      await _updateGroupingState(
        () => _groupingService.assignSession(sessionId: session.id),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已删除会话「${session.title}」'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState(bool hasSessions) {
    if (hasSessions) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              '没有找到匹配的会话',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.neutral700,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            '还没有会话',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '点击下方按钮开始新的对话',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  String? _groupNameForSession(String sessionId) {
    final groupId =
        _groupingService.groupIdForSession(_groupingState, sessionId);
    if (groupId == null) {
      return null;
    }
    for (final group in _groupingState.groups) {
      if (group.id == groupId) {
        return group.name;
      }
    }
    return null;
  }
}

class _SessionSectionHeader extends StatelessWidget {
  const _SessionSectionHeader({
    required this.title,
    required this.collapsed,
    this.count,
    this.trailingMenu,
    this.onTap,
  });

  final String title;
  final int? count;
  final bool collapsed;
  final Widget? trailingMenu;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.neutral100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                count == null ? title : '$title · $count',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.neutral700,
                ),
              ),
            ),
            if (trailingMenu != null) trailingMenu!,
            if (onTap != null)
              Icon(
                collapsed
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                color: AppTheme.neutral500,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGroupCard extends StatelessWidget {
  const _EmptyGroupCard({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.neutral600,
          height: 1.5,
        ),
      ),
    );
  }
}

class _SessionGroupOptionTile extends StatelessWidget {
  const _SessionGroupOptionTile({
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.brandColor.withValues(alpha: 0.08)
              : AppTheme.neutral50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.brandColor : AppTheme.neutral200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppTheme.brandColor : AppTheme.neutral500,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionListItem extends StatelessWidget {
  const _SessionListItem({
    required this.session,
    required this.stats,
    required this.onTap,
    required this.onDelete,
    this.onLongPress,
    this.groupName,
  });

  final Session session;
  final SessionStats stats;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;
  final String? groupName;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除会话'),
            content: Text('确认要删除会话「${session.title}」吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        );
        return result ?? false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.brandColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: session.active
                          ? AppTheme.brandColor
                          : AppTheme.neutral500,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title.isNotEmpty ? session.title : '未命名会话',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: session.active
                                ? AppTheme.neutral900
                                : AppTheme.neutral600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((groupName != null && groupName!.isNotEmpty) ||
                            session.tag != null) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (groupName != null && groupName!.isNotEmpty)
                                _SessionBadge(
                                  icon: Icons.folder_open_outlined,
                                  label: groupName!,
                                  color: AppTheme.brandColor,
                                ),
                              if (session.tag != null)
                                _SessionBadge(
                                  icon: Icons.label_outline,
                                  label: session.tag!,
                                  color: AppTheme.infoColor,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (session.active)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '活跃',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 13,
                    color: AppTheme.neutral500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(session.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutral600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Icon(
                    Icons.message_outlined,
                    size: 13,
                    color: AppTheme.neutral500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${stats.messageCount} 条消息',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutral600,
                    ),
                  ),
                  if (stats.hasChanges) ...[
                    const SizedBox(width: AppTheme.spacingMd),
                    Icon(
                      Icons.edit_note_rounded,
                      size: 13,
                      color: AppTheme.neutral500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stats.changedLineCount} 行改动',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppTheme.neutral400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} 小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else if (diff.inDays < 30) {
      return '${diff.inDays ~/ 7} 周前';
    } else {
      return '${dateTime.year}年${dateTime.month}月${dateTime.day}日';
    }
  }
}

class _SessionBadge extends StatelessWidget {
  const _SessionBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
