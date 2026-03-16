part of 'server_settings_screen.dart';

Widget _buildServerSettingsScaffold(_ServerSettingsScreenState state) {
  final service = ServerConfigService.instance;
  final customServerUrl = service.customServerUrl;
  final isUsingCustomServer = service.isUsingCustomServer;
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: AppBar(
      title: const Text('服务器配置'),
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          title: '当前服务器',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: '生效地址', value: AppConfig.serverUrl),
              const SizedBox(height: 8),
              _InfoRow(label: '来源', value: service.selectedServerName),
              if (service.isUsingBuiltInServer) ...[
                const SizedBox(height: 8),
                _InfoRow(
                  label: '内置地址',
                  value: service.selectedBuiltInServerOption.url,
                ),
              ],
              if (isUsingCustomServer && customServerUrl != null) ...[
                const SizedBox(height: 8),
                _InfoRow(label: '已保存自定义地址', value: customServerUrl),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: '选择 Happy Server',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '默认继续使用原来的服务器。你也可以切换到内置服务器，或者手动填写自定义地址。',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.neutral700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: state._selectedServerId,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  state._updateView(() {
                    state
                      .._selectedServerId = value
                      .._errorMessage = null
                      .._probeResult = null;
                  });
                },
                child: Column(
                  children: [
                    ...ServerConfigService.builtInServerOptions.map(
                      (option) => _ServerOptionTile(
                        value: option.id,
                        title: option.name,
                        subtitle: option.description,
                        url: option.url,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ServerOptionTile(
                      value: ServerConfigService.customServerId,
                      title: '自定义服务器',
                      subtitle: '手动输入 Happy Server 地址',
                      url: customServerUrl ?? '未设置',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (state._isCustomSelected) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: state._controller,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    hintText: 'https://your-happy-server.example.com',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '这项配置必须和 PC 端 `happy doctor` / `HAPPY_SERVER_URL` 指向同一个后端，否则手机授权成功后 CLI 仍会轮询失败。',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.neutral700,
                    height: 1.5,
                  ),
                ),
              ],
              if (!state._isCustomSelected)
                const Text(
                  '选择内置服务器后会直接保存，下次启动仍然优先使用你的选择。',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.neutral700,
                    height: 1.5,
                  ),
                ),
              const SizedBox(height: 12),
              if (state._errorMessage != null)
                _buildServerErrorBanner(state._errorMessage!),
              if (state._probeResult != null &&
                  state._probeResult!.ok &&
                  state._probeResult!.supportsTerminalAuth)
                const _ServerProbeSuccessBanner(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state._isSaving ? null : state._reset,
                      child: const Text('恢复默认'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: state._isSaving ? null : state._save,
                      child: Text(state._isSaving ? '保存中...' : '保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildServerErrorBanner(String message) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.errorColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: const TextStyle(
        fontSize: 13,
        color: AppTheme.errorColor,
        height: 1.5,
      ),
    ),
  );
}
