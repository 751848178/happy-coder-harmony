import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/widgets/bottom_popup_sheet.dart';
import '../../../../core/widgets/immediate_long_press_region.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/extensions.dart';
import '../../../../shared/widgets/session_history_list.dart';
import '../../data/session_grouping_service.dart';
import '../../domain/session_list_preview.dart';
import '../../domain/session_recency.dart';
import '../../presentation/session_agent_avatar.dart';
import '../../presentation/session_detail_navigation.dart';
import '../../presentation/session_list_status_chip.dart';
import '../../presentation/session_turn_status.dart';
import '../../../socketio/domain/socket_service.dart';

part 'actions.dart';
part 'content.dart';
part 'custom_group_list.dart';
part 'default_group_list.dart';
part 'empty_widgets.dart';
part 'filters.dart';
part 'group_dialogs.dart';
part 'group_widgets.dart';
part 'refresh_controller.dart';
part 'visible_snapshot_refresh.dart';
part 'list_item.dart';
part 'list_item_content.dart';
part 'list_item_helpers.dart';
part 'list_item_support.dart';
part 'session_actions.dart';
part 'session_move_sheet.dart';
part 'section_header.dart';
part 'view_models.dart';

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
  late final _SessionListRefreshController _refreshController =
      _SessionListRefreshController(this);

  // --- Filter / grouping / refresh state backed by ValueNotifiers ---
  // These change independently and each should only rebuild the UI
  // section that depends on it, not the entire screen.
  final ValueNotifier<String> _searchQueryN = ValueNotifier('');
  final ValueNotifier<bool> _showActiveOnlyN = ValueNotifier(false);
  final ValueNotifier<bool> _isRefreshingSessionsN = ValueNotifier(false);
  final ValueNotifier<bool> _groupingLoadedN = ValueNotifier(false);
  final ValueNotifier<SessionGroupingState> _groupingStateN =
      ValueNotifier(const SessionGroupingState());

  String get _searchQuery => _searchQueryN.value;
  bool get _showActiveOnly => _showActiveOnlyN.value;
  bool get _isRefreshingSessions => _isRefreshingSessionsN.value;
  bool get _groupingLoaded => _groupingLoadedN.value;
  SessionGroupingState get _groupingState => _groupingStateN.value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshController.initializeSessionListContext());
    });
    _refreshController.start();
  }

  Future<void> _loadGroupingState() async {
    final state = await _groupingService.load();
    if (!mounted) {
      return;
    }
    _groupingStateN.value = state;
    _groupingLoadedN.value = true;
  }

  Future<void> _updateGroupingState(
    Future<SessionGroupingState> Function() action,
  ) async {
    final nextState = await action();
    if (!mounted) {
      return;
    }
    _groupingStateN.value = nextState;
    _groupingLoadedN.value = true;
  }

  void _updateSearchQuery(String value) {
    _searchQueryN.value = value;
  }

  void _toggleShowActiveOnly() {
    _showActiveOnlyN.value = !_showActiveOnlyN.value;
  }

  void _setRefreshingSessions(bool value) {
    _isRefreshingSessionsN.value = value;
  }

  Future<void> _runSessionListAutoSync({
    bool forceSessions = false,
  }) =>
      _refreshController.runSessionListAutoSync(
        forceSessions: forceSessions,
      );

  @override
  void dispose() {
    _refreshController.dispose();
    _searchQueryN.dispose();
    _showActiveOnlyN.dispose();
    _isRefreshingSessionsN.dispose();
    _groupingLoadedN.dispose();
    _groupingStateN.dispose();
    super.dispose();
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

    // Only the Scaffold (AppBar) rebuilds when refresh/active-only state
    // changes. The body's internal builders are unaffected because their
    // notifiers haven't changed — Flutter reuses their Elements.
    return ListenableBuilder(
      listenable: Listenable.merge([
        _isRefreshingSessionsN,
        _showActiveOnlyN,
      ]),
      builder: (_, __) => Scaffold(
        backgroundColor: AppTheme.neutral50,
        appBar: _buildSessionsAppBar(),
        body: view.body,
        floatingActionButton: widget.showFab ? _buildNewSessionFab() : null,
      ),
    );
  }
}
