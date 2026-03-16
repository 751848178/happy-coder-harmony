import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/scan_qr_screen.dart';

part 'settings_screen_actions.dart';
part 'settings_screen_content.dart';
part 'settings_screen_feature_group.dart';
part 'settings_screen_link_dialog.dart';
part 'settings_screen_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isConnectingTerminal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionStateProvider.notifier).loadSessions();
    });
  }

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  List<_MachineSummary> _collectMachines(
    List<Machine> machines,
    List<Session> sessions,
  ) {
    return _collectSettingsMachines(machines, sessions);
  }

  Future<void> _scanTerminalQrCode() => _scanTerminalQrCodeAction(this);

  Future<void> _showTerminalLinkDialog() => _showTerminalLinkDialogAction(this);

  @override
  Widget build(BuildContext context) {
    return _buildSettingsScaffold(this);
  }
}
