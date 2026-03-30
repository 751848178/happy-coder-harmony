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
              if (isUsingCustomServer && customServerUrl != null) ...[
                const SizedBox(height: 8),
                _InfoRow(label: '已保存自定义地址', value: customServerUrl),
              ],
              const SizedBox(height: 16),
              _ServerSettingsActionTile(
                title: '修改服务器地址',
                subtitle: '切换默认服务器、开发者提供的国内服务器或自定义 Happy Server 地址',
                onTap: state._openServerEditorSheet,
              ),
              const SizedBox(height: 12),
              const Text(
                '修改后如果当前已经连接电脑，请重新连接一次，确保手机与 PC CLI 指向同一个 Happy Server。',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.neutral700,
                  height: 1.5,
                ),
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
