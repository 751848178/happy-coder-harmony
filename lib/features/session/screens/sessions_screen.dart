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

part 'sessions_screen_actions.dart';
part 'sessions_screen_content.dart';
part 'sessions_screen_custom_group_list.dart';
part 'sessions_screen_default_group_list.dart';
part 'sessions_screen_empty_widgets.dart';
part 'sessions_screen_filters.dart';
part 'sessions_screen_group_dialogs.dart';
part 'sessions_screen_group_widgets.dart';
part 'sessions_screen_list_item.dart';
part 'sessions_screen_list_item_badges.dart';
part 'sessions_screen_list_item_content.dart';
part 'sessions_screen_list_item_helpers.dart';
part 'sessions_screen_list_item_support.dart';
part 'sessions_screen_session_actions.dart';
part 'sessions_screen_session_move_sheet.dart';
part 'sessions_screen_section_header.dart';

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

  void _updateSearchQuery(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _toggleShowActiveOnly() {
    setState(() {
      _showActiveOnly = !_showActiveOnly;
    });
  }

  void _setRefreshingSessions(bool value) {
    setState(() {
      _isRefreshingSessions = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final view = _buildSessionsScreenView();
    if (!widget.showAppBar) {
      return ColoredBox(
        color: AppTheme.neutral50,
        child: view.body,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: _buildSessionsAppBar(),
      body: view.body,
      floatingActionButton: widget.showFab ? _buildNewSessionFab() : null,
    );
  }
}
