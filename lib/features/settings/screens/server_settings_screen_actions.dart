part of 'server_settings_screen.dart';

Future<void> _saveServerSettings(_ServerSettingsScreenState state) async {
  final service = ServerConfigService.instance;
  state._updateView(() {
    state
      .._isSaving = true
      .._errorMessage = null
      .._probeResult = null;
  });
  if (state._isCustomSelected) {
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
    state._updateView(() {
      state
        .._isSaving = false
        .._probeResult = probe;
    });
    await _showServerSettingsDialog(
      state.context,
      title: '服务器已保存',
      content:
          '已保存自定义 Happy Server：${service.serverUrl}\n\n后续新的请求会使用该地址；如果当前已经连接电脑，请重新连接一次。',
    );
    return;
  }

  await service.setBuiltInServer(state._selectedServerId);
  if (!state.mounted) {
    return;
  }
  state._updateView(() {
    state
      .._isSaving = false
      .._probeResult = null;
  });
  await _showServerSettingsDialog(
    state.context,
    title: '服务器已保存',
    content:
        '当前已切换到 ${service.selectedServerName}：${service.serverUrl}\n\n后续新的请求会使用该地址；如果当前已经连接电脑，请重新连接一次。',
  );
}

Future<void> _resetServerSettings(_ServerSettingsScreenState state) async {
  await ServerConfigService.instance.setCustomServerUrl(null);
  if (!state.mounted) {
    return;
  }
  state._updateView(() {
    state
      .._selectedServerId = ServerConfigService.defaultServerId
      .._errorMessage = null
      .._probeResult = null;
    state._controller.clear();
  });
  await _showServerSettingsDialog(
    state.context,
    title: '已恢复默认服务器',
    content:
        '当前默认地址为：${AppConfig.defaultServerUrl}\n\n后续新的请求会使用该地址；如果当前已经连接电脑，请重新连接一次。',
  );
}

Future<void> _showServerSettingsDialog(
  BuildContext context, {
  required String title,
  required String content,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}
