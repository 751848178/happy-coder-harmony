import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/server_config_service.dart';
import '../../../core/theme/app_theme.dart';

part 'server_settings_screen_actions.dart';
part 'server_settings_screen_content.dart';
part 'server_settings_screen_widgets.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final TextEditingController _controller = TextEditingController();
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
    super.dispose();
  }

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  Future<void> _save() => _saveServerSettings(this);

  Future<void> _reset() => _resetServerSettings(this);

  bool get _isCustomSelected =>
      _selectedServerId == ServerConfigService.customServerId;

  @override
  Widget build(BuildContext context) {
    return _buildServerSettingsScaffold(this);
  }
}
