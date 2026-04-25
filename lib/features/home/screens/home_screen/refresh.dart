part of 'home_screen.dart';

Future<void> _refreshHomeSessionsAndConnection(_HomeScreenState state) async {
  if (state._isRefreshingSessionsStatus) {
    return;
  }

  final credentials = state.ref.read(authStateProvider).credentials;
  if (credentials == null) {
    return;
  }

  state._updateView(() {
    state._isRefreshingSessionsStatus = true;
  });

  try {
    final sessionNotifier = state.ref.read(sessionStateProvider.notifier);
    final socketNotifier = state.ref.read(socketStateProvider.notifier);
    await Future.wait([
      sessionNotifier.loadSessions(force: true),
      sessionNotifier.loadMachines(force: true, allowFailure: true),
      socketNotifier.initialize(
        machineId: credentials.machineId,
        token: credentials.token,
      ),
    ]);
    await state._refreshVisibleSessionSnapshots(sessionNotifier);
  } catch (error) {
    if (!state.mounted) {
      return;
    }
    ScaffoldMessenger.of(state.context).showSnackBar(
      SnackBar(
        content: Text('刷新状态失败: $error'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  } finally {
    state._updateView(() {
      state._isRefreshingSessionsStatus = false;
    });
  }
}

Future<void> _refreshHomeVisibleSessionSnapshots(
  _HomeScreenState state,
  SessionServiceNotifier sessionNotifier,
) async {
  final machineOptions = _buildHomeMachineFilterOptions(
    machines: sessionNotifier.machines,
    sessions: sessionNotifier.sessions,
  );
  final selectedMachineId = _effectiveHomeSelectedMachineId(
    state,
    machineOptions,
  );
  final visibleSessionIds = sessionNotifier.sessions
      .where(
        (session) =>
            sessionNotifier.hasRemoteSession(session.id) &&
            _matchesHomeSelectedMachine(session, selectedMachineId),
      )
      .map((session) => session.id)
      .toList(growable: false);

  Logger.info(
    'Home refresh will reload message snapshots for ${visibleSessionIds.length} sessions',
  );
  await sessionNotifier.refreshSessionMessageSnapshots(
    visibleSessionIds,
    maxPagesPerSession: 2,
  );
}
