part of 'sessions_screen.dart';

class _SessionListRefreshController {
  _SessionListRefreshController(this._state);

  static const Duration _sessionListAutoSyncDebounce =
      Duration(milliseconds: 320);
  static const Duration _sessionListAutoSyncInterval = Duration(seconds: 10);
  static const int _sessionListPriorityPreviewCount = 10;
  static const int _sessionListTailPreviewCount = 12;
  static const int _sessionListPreviewMaxPages = 2;
  static const Duration _sessionPreviewRefreshThrottle =
      Duration(milliseconds: 220);

  final _SessionsScreenState _state;
  final Map<String, Timer> _sessionPreviewRefreshDebounce = <String, Timer>{};
  final Map<String, DateTime> _sessionPreviewLastRefreshAt =
      <String, DateTime>{};
  final Set<String> _sessionPreviewRefreshInFlight = <String>{};

  StreamSubscription<SocketEvent>? _socketEventSubscription;
  Timer? _visibleSnapshotRefreshDebounce;
  Timer? _sessionListAutoSyncTimer;
  Future<void>? _sessionListSyncInFlight;
  int _sessionListTailRefreshCursor = 0;

  bool get _isSessionDetailActive =>
      _state.ref.read(activeSessionDetailIdProvider) != null;
  String? get _activeSessionDetailId =>
      _state.ref.read(activeSessionDetailIdProvider);

  void start() {
    _subscribeToSocketEvents();
    _startSessionListAutoSyncTimer();
  }

  Future<void> initializeSessionListContext() async {
    final notifier = _state.ref.read(sessionStateProvider.notifier);
    await Future.wait([
      notifier.loadSessions(),
      _state._loadGroupingState(),
    ]);
    if (!_state.mounted) {
      return;
    }
    unawaited(notifier.loadMachines(force: true, allowFailure: true));
    unawaited(runSessionListAutoSync());
  }

  void _subscribeToSocketEvents() {
    _socketEventSubscription?.cancel();
    final socketNotifier = _state.ref.read(socketStateProvider.notifier);
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
    if (_isSessionDetailActive) {
      return;
    }
    _visibleSnapshotRefreshDebounce?.cancel();
    _visibleSnapshotRefreshDebounce = Timer(
      _sessionListAutoSyncDebounce,
      () => unawaited(runSessionListAutoSync()),
    );
  }

  void _scheduleSessionPreviewRefresh(String sessionId) {
    if (_isSessionDetailActive) {
      return;
    }
    if (!_state.mounted) {
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
    if (_isSessionDetailActive) {
      return;
    }
    if (!_state.mounted) {
      return;
    }
    if (_sessionPreviewRefreshInFlight.contains(sessionId)) {
      return;
    }
    final notifier = _state.ref.read(sessionStateProvider.notifier);
    if (notifier.getSession(sessionId) == null) {
      return;
    }
    final existing = notifier.getSessionMessages(sessionId);
    if (existing?.isLoaded != true) {
      _scheduleVisibleSessionSnapshotRefresh();
      return;
    }
    _sessionPreviewRefreshInFlight.add(sessionId);
    _sessionPreviewLastRefreshAt[sessionId] = DateTime.now();
    try {
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

  void _startSessionListAutoSyncTimer() {
    _sessionListAutoSyncTimer?.cancel();
    _sessionListAutoSyncTimer = Timer.periodic(
      _sessionListAutoSyncInterval,
      (_) {
        if (_isSessionDetailActive) {
          return;
        }
        unawaited(runSessionListAutoSync());
      },
    );
  }

  Future<void> runSessionListAutoSync({
    bool forceSessions = false,
  }) async {
    if (_isSessionDetailActive) {
      return;
    }
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
    if (_isSessionDetailActive) {
      return;
    }
    final notifier = _state.ref.read(sessionStateProvider.notifier);
    if (forceSessions) {
      await notifier.loadSessions(force: true);
    } else {
      await notifier.syncSessionsIfStale();
    }
    if (!_state.mounted) {
      return;
    }
    await _refreshVisibleSessionSnapshotsInBackground(force: false);
  }

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
  }
}
