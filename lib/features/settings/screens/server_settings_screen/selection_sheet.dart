part of 'server_settings_screen.dart';

class _ServerSelectionSheet extends StatefulWidget {
  const _ServerSelectionSheet();

  @override
  State<_ServerSelectionSheet> createState() => _ServerSelectionSheetState();
}

class _ServerSelectionSheetState extends State<_ServerSelectionSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _customFocusNode = FocusNode();
  String _selectedServerId = ServerConfigService.defaultServerId;
  bool _isSaving = false;
  String? _errorMessage;
  ServerProbeResult? _probeResult;

  @override
  void initState() {
    super.initState();
    final service = ServerConfigService.instance;
    _selectedServerId = service.selectedServerId;
    final customServerUrl = service.customServerUrl;
    if (customServerUrl != null) {
      _controller.text = customServerUrl;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _customFocusNode.dispose();
    super.dispose();
  }

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  bool get _isCustomSelected =>
      _selectedServerId == ServerConfigService.customServerId;

  Future<void> _selectServerOption(String serverId) =>
      _selectServerOptionInSheet(this, serverId);

  Future<void> _save() => _saveServerSettingsInSheet(this);

  Future<void> _reset() => _resetServerSettingsInSheet(this);

  @override
  Widget build(BuildContext context) {
    final service = ServerConfigService.instance;
    final customServerUrl = service.customServerUrl;
    final isUsingCustomServer = service.isUsingCustomServer;
    final canResetToDefault =
        service.selectedServerId != ServerConfigService.defaultServerId ||
            customServerUrl != null;
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.neutral300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '修改服务器地址',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.neutral900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: '关闭',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '选择默认服务器、开发者提供的国内服务器或自定义 Happy Server 地址。',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.neutral700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                RadioGroup<String>(
                  groupValue: _selectedServerId,
                  onChanged: (value) {
                    if (_isSaving || value == null) {
                      return;
                    }
                    unawaited(_selectServerOption(value));
                  },
                  child: Column(
                    children: [
                      ...ServerConfigService.builtInServerOptions.map(
                        (option) => _ServerOptionTile(
                          value: option.id,
                          title: option.name,
                          subtitle: option.description,
                          url: option.url,
                          isActive: service.selectedServerId == option.id,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ServerOptionTile(
                        value: ServerConfigService.customServerId,
                        title: '自定义服务器',
                        subtitle: '手动输入 Happy Server 地址',
                        url: customServerUrl ?? '未设置',
                        isActive: isUsingCustomServer,
                      ),
                    ],
                  ),
                ),
                if (_isCustomSelected) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    focusNode: _customFocusNode,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enabled: !_isSaving,
                    enableSuggestions: false,
                    onChanged: (_) {
                      if (_errorMessage == null && _probeResult == null) {
                        return;
                      }
                      _updateView(() {
                        _errorMessage = null;
                        _probeResult = null;
                      });
                    },
                    onSubmitted: (_) {
                      if (!_isSaving) {
                        unawaited(_save());
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'https://your-happy-server.example.com',
                      labelText: 'Happy Server 地址',
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
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      '默认服务器和开发者提供的国内服务器点一下就会立即切换。',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutral700,
                        height: 1.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (_errorMessage != null)
                  _buildServerErrorBanner(_errorMessage!),
                if (_probeResult != null &&
                    _probeResult!.ok &&
                    _probeResult!.supportsTerminalAuth)
                  const _ServerProbeSuccessBanner(),
                if (canResetToDefault) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _reset,
                      child: const Text('恢复默认服务器'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (_isCustomSelected)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          child: Text(_isSaving ? '检测中...' : '检测并使用'),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('关闭'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
