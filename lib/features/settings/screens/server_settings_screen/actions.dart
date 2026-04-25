part of 'server_settings_screen.dart';

Future<void> _openServerEditorSheetInternal(
  _ServerSettingsScreenState state,
) async {
  final changed = await showModalBottomSheet<bool>(
    context: state.context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ServerSelectionSheet(),
  );
  if (changed != true) {
    return;
  }
  state._updateView(() {});
}

Future<void> _selectServerOptionInSheet(
  _ServerSelectionSheetState state,
  String serverId,
) async {
  if (state._isSaving) {
    return;
  }

  if (serverId == ServerConfigService.customServerId) {
    state._updateView(() {
      state
        .._selectedServerId = ServerConfigService.customServerId
        .._errorMessage = null
        .._probeResult = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!state.mounted) {
        return;
      }
      FocusScope.of(state.context).requestFocus(state._customFocusNode);
    });
    return;
  }

  final service = ServerConfigService.instance;
  if (service.selectedServerId == serverId) {
    state._updateView(() {
      state
        .._selectedServerId = serverId
        .._errorMessage = null
        .._probeResult = null;
    });
    return;
  }

  state._updateView(() {
    state
      .._isSaving = true
      .._selectedServerId = serverId
      .._errorMessage = null
      .._probeResult = null;
  });

  try {
    await service.setBuiltInServer(serverId);
    if (!state.mounted) {
      return;
    }
    _showServerSettingsMessage(
      state.context,
      content: '已切换到 ${service.selectedServerName}：${service.serverUrl}',
    );
    Navigator.of(state.context).pop(true);
  } catch (_) {
    if (!state.mounted) {
      return;
    }
    state._updateView(() {
      state
        .._isSaving = false
        .._errorMessage = '切换服务器失败，请重试'
        .._probeResult = null;
    });
  }
}

Future<void> _saveServerSettingsInSheet(
    _ServerSelectionSheetState state) async {
  final service = ServerConfigService.instance;
  FocusScope.of(state.context).unfocus();
  state._updateView(() {
    state
      .._isSaving = true
      .._errorMessage = null
      .._probeResult = null;
  });

  final input = state._controller.text.trim();
  final formatError = ServerConfigService.validateServerUrl(input);
  if (formatError != null) {
    state._updateView(() {
      state
        .._isSaving = false
        .._errorMessage = formatError
        .._probeResult = null;
    });
    return;
  }

  final probe = await service.probeServer(input);
  if (!state.mounted) {
    return;
  }
  if (!probe.ok || !probe.supportsTerminalAuth) {
    state._updateView(() {
      state
        .._isSaving = false
        .._probeResult = probe
        .._errorMessage = probe.errorMessage;
    });
    return;
  }

  await service.setCustomServerUrl(input);
  if (!state.mounted) {
    return;
  }
  _showServerSettingsMessage(
    state.context,
    content: '已启用自定义 Happy Server：${service.serverUrl}\n如果当前已经连接电脑，请重新连接一次。',
  );
  Navigator.of(state.context).pop(true);
}

Future<void> _resetServerSettingsInSheet(
  _ServerSelectionSheetState state,
) async {
  FocusScope.of(state.context).unfocus();
  await ServerConfigService.instance.setCustomServerUrl(null);
  if (!state.mounted) {
    return;
  }
  _showServerSettingsMessage(
    state.context,
    content: '已恢复默认服务器：${AppConfig.defaultServerUrl}\n如果当前已经连接电脑，请重新连接一次。',
  );
  Navigator.of(state.context).pop(true);
}

void _showServerSettingsMessage(
  BuildContext context, {
  required String content,
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(content),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? AppTheme.errorColor : AppTheme.textPrimary,
    ),
  );
}
