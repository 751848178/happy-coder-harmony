part of 'new_session_flow_screen.dart';

Widget _buildNewSessionFlowScreen(_NewSessionFlowScreenState state) {
  state.ref.watch(sessionStateProvider.select(
    (s) => s.whenOrNull(
      ready: (sessions, _, machines) => (sessions, machines),
    ),
  ));
  final modelLoadStatus = state.ref.watch(sessionStateProvider.select(
    (s) => s.whenOrNull<int>(
      loading: () => 0,
      initial: () => 0,
      error: (_) => 1,
      ready: (_, __, ___) => 2,
    ) ?? 0,
  ));
  final sessionNotifier = state.ref.read(sessionStateProvider.notifier);
  final settings = state.ref.watch(settingsStateProvider);
  final mediaQuery = MediaQuery.of(state.context);
  final horizontalPadding = mediaQuery.size.width > 700 ? 16.0 : 8.0;

  final machines = _collectSessionFlowMachineOptions(state, sessionNotifier);

  if (!state._seededInitialState) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!state.mounted || state._seededInitialState) {
        return;
      }
      _seedSessionFlowInitialState(
        state,
        settings: settings,
        machines: machines,
        sessions: sessionNotifier.sessions,
      );
    });
  }

  final effectiveMachineId = state._selectedMachineId ??
      (machines.isNotEmpty ? machines.first.id : null);
  final selectedMachine = machines
      .where((item) => item.id == effectiveMachineId)
      .cast<_MachineOption?>()
      .firstWhere((item) => item != null, orElse: () => null);
  final permissionOptions = _sessionFlowPermissionOptions(
    state,
    machineId: effectiveMachineId,
  );
  final resolvedPermissionMode = resolveModeSelection(
    preferred: state._permissionMode,
    options: permissionOptions,
    fallback: _defaultSessionFlowModeKey(
      permissionOptions,
      defaultPermissionModeForAgent(state._selectedAgent),
    ),
  );
  final selectedPermission = resolveCurrentModeOption(
        permissionOptions,
        <String?>[
          resolvedPermissionMode,
          defaultPermissionModeForAgent(state._selectedAgent),
        ],
      ) ??
      permissionOptions.first;
  final modelOptions = _sessionFlowModelOptions(
    state,
    machineId: effectiveMachineId,
  );
  final resolvedModelMode = _resolveSessionFlowModelMode(
    modelOptions,
    preferred: state._modelMode,
    fallback: defaultModelModeForAgent(state._selectedAgent),
  );
  final selectedModel = resolveCurrentModeOption(
    modelOptions,
    <String?>[
      resolvedModelMode,
      defaultModelModeForAgent(state._selectedAgent),
    ],
  );
  if (resolvedPermissionMode != state._permissionMode ||
      resolvedModelMode != state._modelMode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!state.mounted) {
        return;
      }
      state._updateView(() {
        state._permissionMode = resolvedPermissionMode;
        state._modelMode = resolvedModelMode;
      });
    });
  }
  final effectiveDirectory =
      _effectiveSessionFlowDirectory(state, selectedMachine);
  final canCreate = !state._isCreating &&
      selectedMachine != null &&
      effectiveDirectory.trim().isNotEmpty;

  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      title: const Text('新建会话'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: state._closeScreen,
      ),
    ),
    body: SafeArea(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(state.context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        maxWidth: _NewSessionFlowScreenState._maxContentWidth),
                    child: _buildSessionFlowBody(state,
                        selectedMachine: selectedMachine),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 8, horizontalPadding, 12),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxWidth: _NewSessionFlowScreenState._maxContentWidth),
                  child: _buildSessionFlowComposer(
                    state,
                    selectedMachine: selectedMachine,
                    selectedPermission: selectedPermission,
                    selectedModel: selectedModel,
                    modelOptions: modelOptions,
                    modelLoadStatus: modelLoadStatus,
                    canCreate: canCreate,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildSessionFlowBody(
  _NewSessionFlowScreenState state, {
  required _MachineOption? selectedMachine,
}) {
  final notices = <Widget>[];
  if (selectedMachine == null) {
    notices.add(
      const _NoticeCard(
        icon: Icons.desktop_windows_outlined,
        title: '先选择一台电脑',
        message: '电脑、目录、模板和 Agent 都在底部输入面板里切换。',
      ),
    );
  } else if (!selectedMachine.isOnline) {
    notices.add(
      const _NoticeCard(
        icon: Icons.portable_wifi_off_outlined,
        title: '当前电脑离线',
        message: '可以继续配置会话，但服务端恢复在线前不会开始执行。',
        toneColor: AppTheme.warningColor,
      ),
    );
  }

  if (notices.isEmpty) {
    return const SizedBox.expand();
  }
  return ListView.separated(
    padding: const EdgeInsets.only(top: 12, bottom: 16),
    itemBuilder: (context, index) => notices[index],
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemCount: notices.length,
  );
}

Widget _buildSessionFlowComposer(
  _NewSessionFlowScreenState state, {
  required _MachineOption? selectedMachine,
  required SessionModeOption selectedPermission,
  required SessionModeOption? selectedModel,
  required List<SessionModeOption> modelOptions,
  required int modelLoadStatus,
  required bool canCreate,
}) {
  final directory = _effectiveSessionFlowDirectory(state, selectedMachine);
  final connectionColor = selectedMachine == null
      ? AppTheme.neutral500
      : selectedMachine.isOnline
          ? AppTheme.successColor
          : AppTheme.errorColor;
  final connectionText = selectedMachine == null
      ? '未选择电脑'
      : (selectedMachine.isOnline ? '在线' : '离线');

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildSessionFlowComposerHeader(
        state,
        selectedPermission: selectedPermission,
        selectedModel: selectedModel,
        modelOptions: modelOptions,
        modelLoadStatus: modelLoadStatus,
        connectionColor: connectionColor,
        connectionText: connectionText,
      ),
      _buildSessionFlowContextCard(state,
          selectedMachine: selectedMachine, directory: directory),
      _buildSessionFlowPromptCard(
        state,
        canCreate: canCreate,
        selectedMachine: selectedMachine,
      ),
    ],
  );
}
