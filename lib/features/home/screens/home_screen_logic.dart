part of 'home_screen.dart';

void _initializeHomeScreen(
  _HomeScreenState state, {
  required HomeTab initialTab,
}) {
  state._activeTab = initialTab;
  state._clearLegacyPersistedDeviceFilter();
}

void _syncHomeScreenTab(
  _HomeScreenState state, {
  required HomeScreen oldWidget,
  required HomeScreen newWidget,
}) {
  if (oldWidget.initialTab != newWidget.initialTab) {
    state._activeTab = newWidget.initialTab;
  }
}

void _ensureHomeConnectedServices(
  _HomeScreenState state, {
  required String token,
  required String machineId,
}) {
  if (state._initializedToken == token) {
    return;
  }
  state._initializedToken = token;

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!state.mounted) {
      return;
    }

    final socketState = state.ref.read(socketStateProvider);
    final sessionNotifier = state.ref.read(sessionStateProvider.notifier);
    final futures = <Future<void>>[sessionNotifier.loadSessions()];

    if (!socketState.isConnected) {
      futures.add(
        state.ref.read(socketStateProvider.notifier).initialize(
              machineId: machineId,
              token: token,
            ),
      );
    }

    await Future.wait(futures);
    if (state._activeTab == HomeTab.sessions) {
      await state._refreshVisibleSessionSnapshots(sessionNotifier);
    }
    await state._refreshInboxBadge(token);
  });
}

Future<void> _refreshHomeInboxBadge(
    _HomeScreenState state, String token) async {
  final count = await InboxRepository.instance.getUnreadCount(token: token);
  state._updateView(() {
    state._inboxUnreadCount = count;
  });
}

_ConnectionStatus _buildHomeConnectionStatus(SocketState socketState) {
  return socketState.when(
    initial: () => const _ConnectionStatus(
      label: '未连接',
      color: AppTheme.neutral500,
    ),
    connecting: () => const _ConnectionStatus(
      label: '连接中',
      color: AppTheme.warningColor,
    ),
    connected: (_) => const _ConnectionStatus(
      label: '已连接',
      color: AppTheme.successColor,
    ),
    reconnecting: (_) => const _ConnectionStatus(
      label: '重连中',
      color: AppTheme.warningColor,
    ),
    error: (_) => const _ConnectionStatus(
      label: '连接异常',
      color: AppTheme.errorColor,
    ),
  );
}

Future<void> _clearHomeLegacyPersistedDeviceFilter(
    _HomeScreenState state) async {
  final preferences = await state._listPreferencesService.load();
  if (preferences.isDefault) {
    return;
  }

  await state._listPreferencesService.setSelectedMachineId(null);
}

void _setHomeSelectedMachineId(_HomeScreenState state, String? machineId) {
  final trimmedMachineId = machineId?.trim();
  state._updateView(() {
    state._selectedMachineId =
        trimmedMachineId == null || trimmedMachineId.isEmpty
            ? null
            : trimmedMachineId;
  });
}

void _handleHomeTabSelected(_HomeScreenState state, HomeTab tab) {
  state._updateView(() {
    state._activeTab = tab;
  });

  if (tab == HomeTab.inbox) {
    final token = state.ref.read(authStateProvider).credentials?.token;
    if (token != null && token.isNotEmpty) {
      state._refreshInboxBadge(token);
    }
  }
}

void _handleHomeLeadingAction(_HomeScreenState state) {
  if (state._activeTab == HomeTab.sessions) {
    state._scaffoldKey.currentState?.openDrawer();
    return;
  }
  state._openSessionsTab();
}

void _handleHomePrimaryAction(
  _HomeScreenState state, {
  String? selectedMachineId,
}) {
  switch (state._activeTab) {
    case HomeTab.sessions:
      if (selectedMachineId == null ||
          selectedMachineId == SessionsScreen.unknownMachineFilterId) {
        state.context.push(AppRoutes.newFlow);
        return;
      }
      state.context.push(
        Uri(
          path: AppRoutes.newFlow,
          queryParameters: {'machineId': selectedMachineId},
        ).toString(),
      );
      return;
    case HomeTab.inbox:
      state.context.push(AppRoutes.friendsSearch);
      return;
    case HomeTab.settings:
      return;
  }
}
