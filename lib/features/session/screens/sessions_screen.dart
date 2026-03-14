import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
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
    this.selectedMachineId,
    this.selectedMachineName,
  });

  static const String unknownMachineFilterId = '__unknown_machine__';
  static const String unavailableGroupLabel = '过期会话';

  final bool showAppBar;
  final bool showSearchBar;
  final bool showFab;
  final String? selectedMachineId;
  final String? selectedMachineName;

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  final SessionGroupingService _groupingService =
      SessionGroupingService.instance;

  String _searchQuery = '';
  bool _showActiveOnly = false;
  bool _isRefreshingSessions = false;
  bool _groupingLoaded = false;
  SessionGroupingState _groupingState = const SessionGroupingState();

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
    final selectedMachineId = widget.selectedMachineId;
    final hideInactiveByDefault =
        widget.showAppBar && settings.hideInactiveSessions;
    final filteredSessions = sessions.where((session) {
      return _matchesSessionFilters(
        session,
        selectedMachineId: selectedMachineId,
        hideInactiveByDefault: hideInactiveByDefault,
      );
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final statsBySessionId = <String, SessionStats>{
      for (final session in filteredSessions)
        session.id: SessionStatsCalculator.fromSession(
          session: session,
          messages: sessionNotifier.getSessionMessages(session.id)?.messages,
        ),
    };

    final listContent = !_groupingLoaded
        ? const Center(child: CircularProgressIndicator())
        : filteredSessions.isEmpty
            ? _buildRefreshableEmptyState(
                hasSessions: sessions.isNotEmpty,
                selectedMachineName: widget.selectedMachineName,
              )
            : RefreshIndicator(
                onRefresh: _refreshSessionList,
                color: AppTheme.brandColor,
                child: _buildGroupedSessionList(
                  sessions: filteredSessions,
                  statsBySessionId: statsBySessionId,
                ),
              );

    final body = Column(
      children: [
        if (widget.showSearchBar) _buildSearchBar(),
        _buildGroupingToolbar(filteredSessions.isNotEmpty),
        Expanded(
          child: listContent,
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
              if (value == 'refresh') {
                _refreshSessionList();
              } else if (value == 'active') {
                setState(() => _showActiveOnly = !_showActiveOnly);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.brandColor,
                    ),
                    const SizedBox(width: 12),
                    Text(_isRefreshingSessions ? '正在刷新...' : '刷新会话列表'),
                  ],
                ),
              ),
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
              onPressed: _openNewSession,
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

  String? _sessionMachineId(Session session) {
    final machineId = session.metadata?['machineId']?.toString();
    if (machineId == null || machineId.trim().isEmpty) {
      return null;
    }
    return machineId.trim();
  }

  bool _matchesSelectedMachine(Session session, String? selectedMachineId) {
    if (selectedMachineId == null) {
      return true;
    }
    final machineId = _sessionMachineId(session);
    if (selectedMachineId == SessionsScreen.unknownMachineFilterId) {
      return machineId == null;
    }
    return machineId == selectedMachineId;
  }

  bool _matchesSessionFilters(
    Session session, {
    required String? selectedMachineId,
    required bool hideInactiveByDefault,
  }) {
    if (!_matchesSelectedMachine(session, selectedMachineId)) {
      return false;
    }
    if ((_showActiveOnly || hideInactiveByDefault) && !session.active) {
      return false;
    }
    if (_searchQuery.isEmpty) {
      return true;
    }
    final query = _searchQuery.toLowerCase();
    return session.title.toLowerCase().contains(query) ||
        session.tag?.toLowerCase().contains(query) == true ||
        session.path?.toLowerCase().contains(query) == true;
  }

  void _openNewSession() {
    final selectedMachineId = widget.selectedMachineId;
    if (selectedMachineId == null ||
        selectedMachineId == SessionsScreen.unknownMachineFilterId) {
      context.push(AppRoutes.newFlow);
      return;
    }
    context.push(
      Uri(
        path: AppRoutes.newFlow,
        queryParameters: {'machineId': selectedMachineId},
      ).toString(),
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
        8,
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.neutral100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                _GroupingModeButton(
                  label: '默认',
                  selected: !_groupingState.useCustomGroups,
                  onTap: () {
                    _updateGroupingState(
                      () => _groupingService.setUseCustomGroups(false),
                    );
                  },
                ),
                _GroupingModeButton(
                  label: '自定义',
                  selected: _groupingState.useCustomGroups,
                  onTap: () {
                    _updateGroupingState(
                      () => _groupingService.setUseCustomGroups(true),
                    );
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_groupingState.useCustomGroups)
            _GroupingToolbarAction(
              onPressed: () => _showCreateGroupDialog(),
              icon: Icons.create_new_folder_outlined,
              label: '新建',
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

  Widget _buildRefreshableEmptyState({
    required bool hasSessions,
    String? selectedMachineName,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: _refreshSessionList,
        color: AppTheme.brandColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: SizedBox(
            width: double.infinity,
            height: constraints.maxHeight,
            child: _buildEmptyState(
              hasSessions: hasSessions,
              selectedMachineName: selectedMachineName,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultGroupedList({
    required List<Session> sessions,
    required Map<String, SessionStats> statsBySessionId,
  }) {
    final availableSessions = sessions
        .where((session) => !_isSessionUnavailable(session))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final unavailableSessions = sessions.where(_isSessionUnavailable).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final items = availableSessions
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
    final sections = <Widget>[];

    for (final group in groups) {
      final collapsed = _isDefaultGroupCollapsed(group.label);
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SessionSectionHeader(
                title: group.label,
                count: group.items.length,
                collapsed: collapsed,
                onTap: () {
                  _toggleDefaultGroup(group.label);
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
                      onMove: () => _showMoveSessionSheet(sessionMap[item.id]!),
                      onLongPress: () =>
                          _showMoveSessionSheet(sessionMap[item.id]!),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (unavailableSessions.isNotEmpty) {
      final collapsed = _isDefaultGroupCollapsed(
        SessionsScreen.unavailableGroupLabel,
        defaultCollapsed: true,
      );
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SessionSectionHeader(
                title: SessionsScreen.unavailableGroupLabel,
                count: unavailableSessions.length,
                collapsed: collapsed,
                subtle: true,
                onTap: () {
                  _toggleDefaultGroup(
                    SessionsScreen.unavailableGroupLabel,
                    defaultCollapsed: true,
                  );
                },
              ),
              if (!collapsed) ...[
                const SizedBox(height: 8),
                ...unavailableSessions.map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SessionListItem(
                      session: session,
                      stats: statsBySessionId[session.id]!,
                      groupName: _groupNameForSession(session.id),
                      onTap: () => _openSession(session),
                      onDelete: () => _deleteSession(session),
                      onMove: () => _showMoveSessionSheet(session),
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: sections,
    );
  }

  Widget _buildCustomGroupList({
    required List<Session> sessions,
    required Map<String, SessionStats> statsBySessionId,
  }) {
    final availableSessions =
        sessions.where((session) => !_isSessionUnavailable(session)).toList();
    final unavailableSessions = sessions.where(_isSessionUnavailable).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final sessionMap = {
      for (final session in availableSessions) session.id: session,
    };
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
                        onMove: () => _showMoveSessionSheet(session),
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
    final ungroupedSessions = availableSessions
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
                      onMove: () => _showMoveSessionSheet(session),
                      onLongPress: () => _showMoveSessionSheet(session),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );

    if (unavailableSessions.isNotEmpty) {
      final collapsed = _isDefaultGroupCollapsed(
        SessionsScreen.unavailableGroupLabel,
        defaultCollapsed: true,
      );
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SessionSectionHeader(
                title: SessionsScreen.unavailableGroupLabel,
                count: unavailableSessions.length,
                collapsed: collapsed,
                subtle: true,
                onTap: () {
                  _toggleDefaultGroup(
                    SessionsScreen.unavailableGroupLabel,
                    defaultCollapsed: true,
                  );
                },
              ),
              if (!collapsed) ...[
                const SizedBox(height: 8),
                ...unavailableSessions.map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SessionListItem(
                      session: session,
                      stats: statsBySessionId[session.id]!,
                      onTap: () => _openSession(session),
                      onDelete: () => _deleteSession(session),
                      onMove: () => _showMoveSessionSheet(session),
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
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: sections,
    );
  }

  bool _isSessionUnavailable(Session session) {
    return session.thinking != true && !session.active;
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

  Future<void> _refreshSessionList() async {
    if (_isRefreshingSessions) {
      return;
    }

    setState(() {
      _isRefreshingSessions = true;
    });

    try {
      final notifier = ref.read(sessionStateProvider.notifier);
      await Future.wait([
        notifier.loadSessions(force: true),
        notifier.loadMachines(force: true, allowFailure: true),
      ]);
      final settings = ref.read(settingsStateProvider);
      final hideInactiveByDefault =
          widget.showAppBar && settings.hideInactiveSessions;
      final visibleSessionIds = notifier.sessions
          .where(
            (session) => _matchesSessionFilters(
              session,
              selectedMachineId: widget.selectedMachineId,
              hideInactiveByDefault: hideInactiveByDefault,
            ),
          )
          .map((session) => session.id)
          .toList(growable: false);
      Logger.info(
        'Sessions list refresh will reload message snapshots for ${visibleSessionIds.length} sessions',
      );
      await notifier.refreshSessionMessageSnapshots(visibleSessionIds);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新会话列表失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingSessions = false;
        });
      }
    }
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

  Widget _buildEmptyState({
    required bool hasSessions,
    String? selectedMachineName,
  }) {
    if (hasSessions) {
      final hasMachineFilter =
          selectedMachineName != null && selectedMachineName.trim().isNotEmpty;
      final title = hasMachineFilter ? '该设备下没有匹配的会话' : '没有找到匹配的会话';
      final subtitle = hasMachineFilter ? '当前设备：$selectedMachineName' : null;
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
              title,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.neutral700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.neutral600,
                ),
              ),
            ],
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

  bool _isDefaultGroupCollapsed(
    String label, {
    bool defaultCollapsed = false,
  }) {
    if (defaultCollapsed) {
      return !_groupingState.expandedDefaultGroups.contains(label);
    }
    return _groupingState.collapsedDefaultGroups.contains(label);
  }

  Future<void> _toggleDefaultGroup(
    String label, {
    bool defaultCollapsed = false,
  }) {
    return _updateGroupingState(
      () => _groupingService.toggleDefaultGroupCollapsed(
        label,
        defaultCollapsed: defaultCollapsed,
      ),
    );
  }
}

class _SessionSectionHeader extends StatelessWidget {
  const _SessionSectionHeader({
    required this.title,
    required this.collapsed,
    this.count,
    this.subtle = false,
    this.trailingMenu,
    this.onTap,
  });

  final String title;
  final int? count;
  final bool collapsed;
  final bool subtle;
  final Widget? trailingMenu;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = subtle ? AppTheme.neutral500 : AppTheme.neutral700;
    final countColor = subtle ? AppTheme.neutral400 : AppTheme.neutral500;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(subtle ? 8 : 10),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 4,
          vertical: subtle ? 4 : 6,
        ),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: subtle ? 12 : 13,
                    fontWeight: subtle ? FontWeight.w600 : FontWeight.w700,
                    color: titleColor,
                  ),
                  children: [
                    TextSpan(text: title),
                    if (count != null)
                      TextSpan(
                        text: ' · $count',
                        style: TextStyle(
                          fontWeight:
                              subtle ? FontWeight.w500 : FontWeight.w600,
                          color: countColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (trailingMenu != null) trailingMenu!,
            if (onTap != null)
              Icon(
                collapsed
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                color: subtle ? AppTheme.neutral400 : AppTheme.neutral500,
                size: subtle ? 18 : 20,
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

class _GroupingModeButton extends StatelessWidget {
  const _GroupingModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? AppTheme.shadowSm : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppTheme.neutral900 : AppTheme.neutral600,
          ),
        ),
      ),
    );
  }
}

class _GroupingToolbarAction extends StatelessWidget {
  const _GroupingToolbarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.neutral100,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: AppTheme.neutral700,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionListItem extends StatefulWidget {
  const _SessionListItem({
    required this.session,
    required this.stats,
    required this.onTap,
    required this.onDelete,
    this.onMove,
    this.onLongPress,
    this.groupName,
  });

  final Session session;
  final SessionStats stats;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onMove;
  final VoidCallback? onLongPress;
  final String? groupName;

  @override
  State<_SessionListItem> createState() => _SessionListItemState();
}

class _SessionListItemState extends State<_SessionListItem> {
  static const double _actionWidth = 78;

  double _dragExtent = 0;

  double get _maxReveal =>
      widget.onMove == null ? _actionWidth : _actionWidth * 2;

  void _closeActions() {
    if (_dragExtent == 0) {
      return;
    }
    setState(() {
      _dragExtent = 0;
    });
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    setState(() {
      _dragExtent = (_dragExtent + delta).clamp(-_maxReveal, 0.0);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldOpen =
        velocity < -220 || _dragExtent.abs() > (_maxReveal * 0.45);
    setState(() {
      _dragExtent = shouldOpen ? -_maxReveal : 0;
    });
  }

  Future<void> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确认要删除会话「${widget.session.title}」吗？'),
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

    if (result == true) {
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onMove != null)
                  _SwipeActionButton(
                    width: _actionWidth,
                    color: AppTheme.infoColor,
                    icon: Icons.drive_file_move_outline,
                    label: '移动',
                    onTap: () {
                      _closeActions();
                      widget.onMove!.call();
                    },
                  ),
                _SwipeActionButton(
                  width: _actionWidth,
                  color: AppTheme.errorColor,
                  icon: Icons.delete_outline_rounded,
                  label: '删除',
                  onTap: () {
                    _closeActions();
                    _confirmDelete();
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: _handleHorizontalDragUpdate,
            onHorizontalDragEnd: _handleHorizontalDragEnd,
            child: Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: _buildCardContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final session = widget.session;
    final stats = widget.stats;
    final groupName = widget.groupName;
    final directoryLabel = _directoryBadgeLabel(session);
    final statusBadge = session.thinking == true
        ? _SessionThinkingBadge(since: session.thinkingAt)
        : session.active
            ? const _SessionStatusBadge(
                label: '活跃',
                color: AppTheme.successColor,
              )
            : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_dragExtent != 0) {
            _closeActions();
            return;
          }
          widget.onTap();
        },
        onLongPress: _dragExtent == 0 ? widget.onLongPress : _closeActions,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      right: statusBadge == null
                          ? 0
                          : session.thinking == true
                              ? 112
                              : 72,
                    ),
                    child: Row(
                      children: [
                        _SessionLeadingIcon(
                          isActive: session.active,
                          isThinking: session.thinking == true,
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.title.isNotEmpty
                                    ? session.title
                                    : '未命名会话',
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
                              if ((groupName != null && groupName.isNotEmpty) ||
                                  directoryLabel != null) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    if (groupName != null &&
                                        groupName.isNotEmpty)
                                      _SessionBadge(
                                        icon: Icons.folder_open_outlined,
                                        label: groupName,
                                        color: AppTheme.brandColor,
                                      ),
                                    if (directoryLabel != null)
                                      _SessionBadge(
                                        icon: Icons.folder_open_outlined,
                                        label: directoryLabel,
                                        color: AppTheme.brandColor,
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Padding(
                    padding: const EdgeInsets.only(right: 26),
                    child: Row(
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
                          Flexible(
                            child: Text(
                              '${stats.changedLineCount} 行改动',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.neutral600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (statusBadge != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: statusBadge,
                ),
              const Positioned(
                right: 0,
                bottom: 0,
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppTheme.neutral400,
                ),
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

  String? _directoryBadgeLabel(Session session) {
    final path =
        session.path?.trim() ?? session.metadata?['path']?.toString().trim();
    if (path == null || path.isEmpty) {
      final fallbackTag = session.tag?.trim();
      return fallbackTag == null || fallbackTag.isEmpty ? null : fallbackTag;
    }
    final normalized = path.replaceAll('\\', '/');
    final parts =
        normalized.split('/').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return null;
    }
    return parts.last;
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.width,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final double width;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: color,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionLeadingIcon extends StatelessWidget {
  const _SessionLeadingIcon({
    required this.isActive,
    required this.isThinking,
  });

  final bool isActive;
  final bool isThinking;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                AppTheme.brandColor.withValues(alpha: isThinking ? 0.16 : 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            size: 20,
            color: isActive || isThinking
                ? AppTheme.brandColor
                : AppTheme.neutral500,
          ),
        ),
        if (isThinking)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.brandColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SessionStatusBadge extends StatelessWidget {
  const _SessionStatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SessionThinkingBadge extends StatelessWidget {
  const _SessionThinkingBadge({
    this.since,
  });

  final DateTime? since;

  @override
  Widget build(BuildContext context) {
    final duration = since == null ? null : DateTime.now().difference(since!);
    final label = duration == null || duration.inSeconds < 1
        ? 'AI 思考中'
        : duration.inMinutes < 1
            ? 'AI 思考 ${duration.inSeconds}s'
            : 'AI 思考 ${duration.inMinutes}m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.brandColor.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.brandColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandColor,
            ),
          ),
        ],
      ),
    );
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
