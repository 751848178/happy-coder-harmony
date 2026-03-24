part of 'home_screen.dart';

Widget _buildHomeScreen(_HomeScreenState state) {
  final authState = state.ref.watch(authStateProvider);
  state.ref.watch(sessionStateProvider);
  Logger.info(
    'HomeScreen.build authenticated=${authState.isAuthenticated} activeTab=${state._activeTab}',
  );

  if (!authState.isAuthenticated) {
    return const QRLoginScreen();
  }

  final credentials = authState.credentials!;
  final sessionNotifier = state.ref.read(sessionStateProvider.notifier);
  final machineOptions = _buildHomeMachineFilterOptions(
    machines: sessionNotifier.machines,
    sessions: sessionNotifier.sessions,
  );
  final selectedMachineId =
      _effectiveHomeSelectedMachineId(state, machineOptions);
  final selectedMachine =
      machineOptions.cast<_HomeMachineFilterOption?>().firstWhere(
            (option) => option?.id == selectedMachineId,
            orElse: () => null,
          );

  state._ensureConnectedServices(
    token: credentials.token,
    machineId: credentials.machineId,
  );

  return Scaffold(
    key: state._scaffoldKey,
    backgroundColor: AppTheme.neutral50,
    drawer: state._activeTab == HomeTab.sessions
        ? _buildHomeMachineDrawer(
            state,
            options: machineOptions,
            selectedOption: selectedMachine,
            totalSessionCount: sessionNotifier.sessions.length,
          )
        : null,
    body: Column(
      children: [
        _HomeHeader(
          activeTab: state._activeTab,
          status:
              _buildHomeConnectionStatus(state.ref.watch(socketStateProvider)),
          isRefreshingStatus: state._isRefreshingSessionsStatus,
          selectedMachineLabel: state._activeTab == HomeTab.sessions
              ? (selectedMachine?.label ?? '全部设备')
              : null,
          onLeadingAction: state._handleLeadingAction,
          onStatusTap: state._activeTab == HomeTab.sessions
              ? state._refreshSessionsAndConnection
              : null,
          onPrimaryAction: () => state._handlePrimaryAction(
            selectedMachineId: selectedMachineId,
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: state._activeTab.index,
            children: [
              SessionsScreen(
                showAppBar: false,
                showSearchBar: false,
                showFab: false,
                selectedMachineId: selectedMachineId,
                selectedMachineName: selectedMachine?.label,
              ),
              const SettingsScreen(showAppBar: false),
            ],
          ),
        ),
      ],
    ),
    bottomNavigationBar: _HomeTabBar(
      activeTab: state._activeTab,
      onTabSelected: state._handleTabSelected,
    ),
  );
}
