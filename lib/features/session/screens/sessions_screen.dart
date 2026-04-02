import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/bottom_popup_sheet.dart';
import '../../../core/widgets/immediate_long_press_region.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/session_history_list.dart';
import '../data/session_grouping_service.dart';
import '../domain/session_list_preview.dart';
import '../domain/session_recency.dart';
import '../domain/session_stats.dart';
import '../presentation/session_turn_status.dart';
import '../presentation/session_agent_avatar.dart';
import '../presentation/session_list_status_chip.dart';
import '../../socketio/domain/socket_service.dart';

part 'sessions_screen_actions.dart';
part 'sessions_screen_content.dart';
part 'sessions_screen_custom_group_list.dart';
part 'sessions_screen_default_group_list.dart';
part 'sessions_screen_empty_widgets.dart';
part 'sessions_screen_filters.dart';
part 'sessions_screen_group_dialogs.dart';
part 'sessions_screen_group_widgets.dart';
part 'sessions_screen_list_item.dart';
part 'sessions_screen_list_item_content.dart';
part 'sessions_screen_list_item_helpers.dart';
part 'sessions_screen_list_item_support.dart';
part 'sessions_screen_session_actions.dart';
part 'sessions_screen_session_move_sheet.dart';
part 'sessions_screen_section_header.dart';
part 'sessions_screen_stats.dart';

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
  static const Duration _sessionListAutoSyncDebounce =
      Duration(milliseconds: 320);
  static const Duration _sessionListAutoSyncInterval = Duration(seconds: 10);
  static const int _sessionListPriorityPreviewCount = 10;
  static const int _sessionListTailPreviewCount = 12;
  static const int _sessionListPreviewMaxPages = 2;
  static const Duration _sessionPreviewRefreshThrottle =
      Duration(milliseconds: 220);

  final SessionGroupingService _groupingService =
      SessionGroupingService.instance;
  final Map<String, _SessionStatsCacheEntry> _sessionStatsCache =
      <String, _SessionStatsCacheEntry>{};
  final Set<String> _sessionStatsInFlight = <String>{};
  final Map<String, Timer> _sessionPreviewRefreshDebounce = <String, Timer>{};
  final Map<String, DateTime> _sessionPreviewLastRefreshAt =
      <String, DateTime>{};
  final Set<String> _sessionPreviewRefreshInFlight = <String>{};

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
  StreamSubscription<SocketEvent>? _socketEventSubscription;
  Timer? _visibleSnapshotRefreshDebounce;
  Timer? _sessionListAutoSyncTimer;
  Future<void>? _sessionListSyncInFlight;
  int _sessionListTailRefreshCursor = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeSessionListContext());
    });
    _subscribeToSocketEvents();
    _startSessionListAutoSyncTimer();
  }

  Future<void> _initializeSessionListContext() async {
    final notifier = ref.read(sessionStateProvider.notifier);
    await Future.wait([
      notifier.loadSessions(),
      _loadGroupingState(),
    ]);
    if (!mounted) {
      return;
    }
    unawaited(notifier.loadMachines(force: true, allowFailure: true));
    unawaited(_runSessionListAutoSync());
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

  void _rebuildView() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _subscribeToSocketEvents() {
    _socketEventSubscription?.cancel();
    final socketNotifier = ref.read(socketStateProvider.notifier);
    _socketEventSubscription = socketNotifier.eventStream.listen((event) {
      event.when(
        connecting: () {},
        connected: (_) => _scheduleVisibleSessionSnapshotRefresh(),
        disconnected: (_) {},
        error: (_) {},
        messageReceived: (message) {
          final sessionId = message.sessionId?.trim();
          if (sessionId == null || sessionId.isEmpty) {
            _scheduleVisibleSessionSnapshotRefresh();
            return;
          }
          _scheduleSessionPreviewRefresh(sessionId);
        },
        reconnecting: (_) => _scheduleVisibleSessionSnapshotRefresh(),
      );
    });
  }

  void _scheduleVisibleSessionSnapshotRefresh() {
    _visibleSnapshotRefreshDebounce?.cancel();
    _visibleSnapshotRefreshDebounce = Timer(
      _sessionListAutoSyncDebounce,
      () => unawaited(_runSessionListAutoSync()),
    );
  }

  void _scheduleSessionPreviewRefresh(String sessionId) {
    if (!mounted) {
      return;
    }
    final now = DateTime.now();
    final lastRefreshedAt = _sessionPreviewLastRefreshAt[sessionId];
    final elapsed = lastRefreshedAt == null
        ? _sessionPreviewRefreshThrottle
        : now.difference(lastRefreshedAt);

    if (elapsed >= _sessionPreviewRefreshThrottle &&
        !_sessionPreviewRefreshInFlight.contains(sessionId)) {
      _sessionPreviewRefreshDebounce.remove(sessionId)?.cancel();
      unawaited(_refreshSessionPreviewNow(sessionId));
      return;
    }
    if (_sessionPreviewRefreshDebounce.containsKey(sessionId)) {
      return;
    }
    final remaining = elapsed >= _sessionPreviewRefreshThrottle
        ? _sessionPreviewRefreshThrottle
        : _sessionPreviewRefreshThrottle - elapsed;
    _sessionPreviewRefreshDebounce[sessionId] = Timer(remaining, () {
      _sessionPreviewRefreshDebounce.remove(sessionId);
      unawaited(_refreshSessionPreviewNow(sessionId));
    });
  }

  Future<void> _refreshSessionPreviewNow(String sessionId) async {
    if (!mounted) {
      return;
    }
    if (_sessionPreviewRefreshInFlight.contains(sessionId)) {
      return;
    }
    final notifier = ref.read(sessionStateProvider.notifier);
    if (!_shouldRefreshSessionPreview(sessionId, notifier)) {
      return;
    }
    _sessionPreviewRefreshInFlight.add(sessionId);
    _sessionPreviewLastRefreshAt[sessionId] = DateTime.now();
    try {
      final existing = notifier.getSessionMessages(sessionId);
      await notifier.loadSessionMessages(
        sessionId,
        maxPages:
            existing?.isLoaded == true ? _sessionListPreviewMaxPages : null,
      );
    } catch (error) {
      Logger.warning(
        'Failed to refresh session preview for $sessionId: $error',
      );
    } finally {
      _sessionPreviewRefreshInFlight.remove(sessionId);
    }
  }

  bool _shouldRefreshSessionPreview(
    String sessionId,
    SessionServiceNotifier notifier,
  ) {
    return notifier.getSession(sessionId) != null;
  }

  void _startSessionListAutoSyncTimer() {
    _sessionListAutoSyncTimer?.cancel();
    _sessionListAutoSyncTimer = Timer.periodic(
      _sessionListAutoSyncInterval,
      (_) => unawaited(_runSessionListAutoSync()),
    );
  }

  List<String> _sessionIdsForBackgroundRefresh(
    SessionServiceNotifier notifier,
  ) {
    final remoteSessions = notifier.sessions
        .where((session) => notifier.hasRemoteSession(session.id))
        .toList(growable: false)
      ..sort(compareSessionsByRecency);
    if (remoteSessions.isEmpty) {
      return const <String>[];
    }

    final settings = ref.read(settingsStateProvider);
    final hideInactiveByDefault =
        widget.showAppBar && settings.hideInactiveSessions;
    final visibleIds = remoteSessions
        .where(
          (session) => _matchesSessionFilters(
            session,
            selectedMachineId: widget.selectedMachineId,
            hideInactiveByDefault: hideInactiveByDefault,
          ),
        )
        .map((session) => session.id)
        .toList(growable: false);
    final visibleSet = visibleIds.toSet();
    final remainingIds = remoteSessions
        .map((session) => session.id)
        .where((sessionId) => !visibleSet.contains(sessionId))
        .toList(growable: false);
    return <String>[
      ...visibleIds,
      ...remainingIds,
    ];
  }

  Future<void> _runSessionListAutoSync({
    bool forceSessions = false,
  }) async {
    final inFlight = _sessionListSyncInFlight;
    if (inFlight != null) {
      await inFlight;
      if (!forceSessions) {
        return;
      }
    }

    final future = _performSessionListAutoSync(forceSessions: forceSessions);
    _sessionListSyncInFlight = future;
    try {
      await future;
    } finally {
      if (identical(_sessionListSyncInFlight, future)) {
        _sessionListSyncInFlight = null;
      }
    }
  }

  Future<void> _performSessionListAutoSync({
    required bool forceSessions,
  }) async {
    final notifier = ref.read(sessionStateProvider.notifier);
    if (forceSessions) {
      await notifier.loadSessions(force: true);
    } else {
      await notifier.syncSessionsIfStale();
    }
    if (!mounted) {
      return;
    }
    await _refreshVisibleSessionSnapshotsInBackground(force: false);
  }

  Future<void> _refreshVisibleSessionSnapshotsInBackground({
    required bool force,
  }) async {
    final notifier = ref.read(sessionStateProvider.notifier);
    final sessionIds = _sessionIdsForBackgroundRefresh(notifier);
    if (sessionIds.isEmpty) {
      return;
    }
    try {
      final priorityIds = sessionIds
          .take(_sessionListPriorityPreviewCount)
          .toList(growable: false);
      await notifier.refreshSessionMessageSnapshots(
        priorityIds,
        batchSize: force ? 4 : 6,
        force: force,
        maxPagesPerSession: _sessionListPreviewMaxPages,
      );

      final remainingIds = sessionIds
          .skip(_sessionListPriorityPreviewCount)
          .toList(growable: false);
      final tailIds = _nextTailSessionPreviewIds(remainingIds);
      if (tailIds.isNotEmpty) {
        await notifier.refreshSessionMessageSnapshots(
          tailIds,
          batchSize: force ? 3 : 2,
          force: force,
          maxPagesPerSession: _sessionListPreviewMaxPages,
        );
      }
    } catch (error) {
      Logger.warning('Failed to refresh visible session previews: $error');
    }
  }

  List<String> _nextTailSessionPreviewIds(List<String> remainingIds) {
    if (remainingIds.isEmpty) {
      _sessionListTailRefreshCursor = 0;
      return const <String>[];
    }
    if (remainingIds.length <= _sessionListTailPreviewCount) {
      _sessionListTailRefreshCursor = 0;
      return remainingIds;
    }

    final normalizedCursor =
        _sessionListTailRefreshCursor % remainingIds.length;
    final selected = <String>[];
    for (var index = 0; index < _sessionListTailPreviewCount; index++) {
      final nextIndex = (normalizedCursor + index) % remainingIds.length;
      selected.add(remainingIds[nextIndex]);
    }
    _sessionListTailRefreshCursor =
        (normalizedCursor + selected.length) % remainingIds.length;
    return selected;
  }

  @override
  void dispose() {
    _socketEventSubscription?.cancel();
    _visibleSnapshotRefreshDebounce?.cancel();
    _sessionListAutoSyncTimer?.cancel();
    for (final timer in _sessionPreviewRefreshDebounce.values) {
      timer.cancel();
    }
    _sessionPreviewRefreshDebounce.clear();
    _sessionPreviewLastRefreshAt.clear();
    _sessionPreviewRefreshInFlight.clear();
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

class _SessionStatsCacheEntry {
  const _SessionStatsCacheEntry({
    required this.stats,
    required this.metadata,
    required this.metadataVersion,
    required this.agentState,
    required this.agentStateVersion,
    required this.latestUsage,
    required this.rawMessageCount,
    required this.messages,
  });

  final SessionStats stats;
  final Map<String, dynamic>? metadata;
  final int? metadataVersion;
  final Map<String, dynamic>? agentState;
  final int? agentStateVersion;
  final Object? latestUsage;
  final int rawMessageCount;
  final List<ReducerMessage>? messages;

  bool matches(Session session, List<ReducerMessage>? nextMessages) {
    return identical(metadata, session.metadata) &&
        metadataVersion == session.metadataVersion &&
        identical(agentState, session.agentState) &&
        agentStateVersion == session.agentStateVersion &&
        identical(latestUsage, session.latestUsage) &&
        rawMessageCount == session.messages.length &&
        identical(messages, nextMessages);
  }
}
