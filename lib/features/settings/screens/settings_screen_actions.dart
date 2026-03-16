part of 'settings_screen.dart';

Future<void> _scanTerminalQrCodeAction(_SettingsScreenState state) async {
  if (state._isConnectingTerminal) {
    return;
  }
  final scannedLink = await Navigator.of(state.context).push<String>(
    MaterialPageRoute(
      builder: (_) => const ScanQrScreen(
        title: '扫描电脑端二维码',
        description: '将摄像头对准电脑上显示的授权二维码，识别后会自动连接。',
      ),
    ),
  );
  if (!state.mounted || scannedLink == null || scannedLink.trim().isEmpty) {
    return;
  }
  await _connectTerminalAction(state, scannedLink.trim());
}

Future<void> _showTerminalLinkDialogAction(_SettingsScreenState state) async {
  if (state._isConnectingTerminal) {
    return;
  }
  final submittedLink = await showDialog<String>(
    context: state.context,
    builder: (_) => const _TerminalLinkInputDialog(),
  );
  if (!state.mounted || submittedLink == null || submittedLink.trim().isEmpty) {
    return;
  }
  await _connectTerminalAction(state, submittedLink.trim());
}

Future<void> _connectTerminalAction(
  _SettingsScreenState state,
  String link,
) async {
  if (state._isConnectingTerminal) {
    return;
  }
  FocusManager.instance.primaryFocus?.unfocus();
  state._updateView(() {
    state._isConnectingTerminal = true;
  });
  try {
    await state.ref.read(authStateProvider.notifier).connectTerminal(link);
    await _prepareConnectedSettingsState(state);
    if (!state.mounted) {
      return;
    }
    ScaffoldMessenger.of(state.context).showSnackBar(
      const SnackBar(
        content: Text('终端连接成功'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  } catch (error) {
    if (!state.mounted) {
      return;
    }
    ScaffoldMessenger.of(state.context).showSnackBar(
      SnackBar(
        content: Text('终端连接失败: $error'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  } finally {
    state._updateView(() {
      state._isConnectingTerminal = false;
    });
  }
}

Future<void> _prepareConnectedSettingsState(_SettingsScreenState state) async {
  final credentials = state.ref.read(authStateProvider).credentials;
  if (credentials == null) {
    return;
  }
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
}
