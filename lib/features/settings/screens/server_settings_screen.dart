import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/server_config_service.dart';
import '../../../core/theme/app_theme.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;
  ServerProbeResult? _probeResult;

  @override
  void initState() {
    super.initState();
    final customServerUrl = ServerConfigService.instance.customServerUrl;
    if (customServerUrl != null) {
      _controller.text = customServerUrl;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final input = _controller.text.trim();
    final formatError = ServerConfigService.validateServerUrl(input);
    if (formatError != null) {
      setState(() {
        _errorMessage = formatError;
        _probeResult = null;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _probeResult = null;
    });

    final probe = await ServerConfigService.instance.probeServer(input);
    if (!mounted) {
      return;
    }

    if (!probe.ok || !probe.supportsTerminalAuth) {
      setState(() {
        _isSaving = false;
        _probeResult = probe;
        _errorMessage = probe.errorMessage;
      });
      return;
    }

    await ServerConfigService.instance.setCustomServerUrl(input);
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _probeResult = probe;
    });

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('服务器已保存'),
        content: const Text('已保存新的 Happy Server。请完全重启 App 后再重新连接电脑。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _reset() async {
    await ServerConfigService.instance.setCustomServerUrl(null);
    if (!mounted) {
      return;
    }

    setState(() {
      _controller.clear();
      _errorMessage = null;
      _probeResult = null;
    });

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('已恢复默认服务器'),
        content: Text('当前默认地址为：${AppConfig.defaultServerUrl}\n\n请完全重启 App 后生效。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customServerUrl = ServerConfigService.instance.customServerUrl;
    final isUsingCustomServer = customServerUrl != null;

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
                _InfoRow(
                  label: '生效地址',
                  value: AppConfig.serverUrl,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: '来源',
                  value: isUsingCustomServer ? '自定义' : '默认',
                ),
                if (!isUsingCustomServer) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: '默认地址',
                    value: AppConfig.defaultServerUrl,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: '自定义 Happy Server',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    hintText: 'https://your-happy-server.example.com',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '这项配置必须和 PC 端 `happy doctor` / `HAPPY_SERVER_URL` 指向同一个后端，否则手机授权成功后 CLI 仍会轮询失败。',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.neutral700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.errorColor,
                        height: 1.5,
                      ),
                    ),
                  ),
                if (_probeResult != null &&
                    _probeResult!.ok &&
                    _probeResult!.supportsTerminalAuth)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '服务器检查通过，已确认支持终端授权接口。',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _reset,
                        child: const Text('恢复默认'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: Text(_isSaving ? '检查中...' : '保存'),
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
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral600,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.neutral900,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
