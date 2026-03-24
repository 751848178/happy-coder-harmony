part of 'terminal_connect_screen.dart';

void _handleLinkChangedImpl(_TerminalConnectScreenState state) {
  final current = state._linkController.text.trim();
  if (state._parsedLink != null && current != state._parsedLink) {
    state._updateView(() {
      state._parsedLink = null;
      state._publicKeyPreview = null;
    });
  }
}

Future<void> _connectTerminalImpl(_TerminalConnectScreenState state) async {
  if (state._isConnecting) {
    return;
  }
  final link = state._linkController.text.trim();
  if (link.isEmpty) {
    state._updateView(() {
      state._errorMessage = '请输入电脑端授权链接';
    });
    return;
  }

  final authState = state.ref.read(authStateProvider);
  if (!authState.isAuthenticated) {
    state._updateView(() {
      state._errorMessage = '请先登录或恢复账户';
    });
    return;
  }
  if (!state._previewLink()) {
    return;
  }

  state._updateView(() {
    state._isConnecting = true;
    state._errorMessage = null;
    state._connectFailureMessage = null;
    state._showEntrySheet = false;
  });

  try {
    final notifier = state.ref.read(authStateProvider.notifier);
    await notifier.connectTerminal(link);
    if (!state.mounted) {
      return;
    }
    state._updateView(() {
      state._isConnecting = false;
    });
    await state._showSuccessDialogAndExit();
  } catch (e) {
    if (!state.mounted) {
      return;
    }
    state._updateView(() {
      state._connectFailureMessage = '连接失败: $e';
      state._isConnecting = false;
    });
  }
}

Future<void> _startScanImpl(_TerminalConnectScreenState state) async {
  if (state._isScanning) {
    return;
  }
  state._updateView(() {
    state._isScanning = true;
    state._errorMessage = null;
  });

  final data = await showQrScanner(
    state.context,
    title: '扫描电脑端二维码',
    description: '将摄像头对准电脑上显示的授权二维码，识别后会自动返回。',
  );

  if (!state.mounted) {
    return;
  }
  state._updateView(() {
    state._isScanning = false;
    if (data != null && data.trim().isNotEmpty) {
      state._linkController.text = data.trim();
    }
  });
  if (data == null || data.trim().isEmpty) {
    return;
  }
  state._previewLink(showError: false);
  state._updateView(() {
    state._showEntrySheet = false;
  });
}

Future<void> _showSuccessDialogAndExitImpl(
  _TerminalConnectScreenState state,
) async {
  await state._prepareConnectedState();
  await showDialog<void>(
    context: state.context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('连接成功'),
        content: const Text('电脑连接授权成功'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('确定'),
          ),
        ],
      );
    },
  );

  if (state.mounted) {
    state.context.go('${AppRoutes.home}?tab=sessions');
  }
}

Future<void> _prepareConnectedStateImpl(
  _TerminalConnectScreenState state,
) async {
  final authState = state.ref.read(authStateProvider);
  if (!authState.isAuthenticated) {
    return;
  }

  final credentials = authState.credentials!;
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

  final remoteSessionIds = sessionNotifier.sessions
      .where((session) => sessionNotifier.hasRemoteSession(session.id))
      .map((session) => session.id)
      .toList(growable: false);
  await sessionNotifier.refreshSessionMessageSnapshots(remoteSessionIds);
}
