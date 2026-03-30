import 'dart:async';

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
  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  Future<void> _openServerEditorSheet() => _openServerEditorSheetInternal(this);

  @override
  Widget build(BuildContext context) {
    return _buildServerSettingsScaffold(this);
  }
}
