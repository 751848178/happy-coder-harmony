import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/server_config_service.dart';
import '../../../../core/config/server_config_models.dart';
import '../../../../core/theme/app_theme.dart';

part 'actions.dart';
part 'content.dart';
part 'widgets.dart';
part 'selection_sheet.dart';
part 'sheet_widgets.dart';

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
