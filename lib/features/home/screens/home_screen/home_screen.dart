import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/extensions.dart';
import '../../../auth/presentation/qr_login_screen.dart';
import '../../../session/data/session_list_preferences_service.dart';
import '../../../session/screens/sessions_screen.dart';
import '../../../settings/screens/settings_screen.dart';
import '../../../socketio/domain/socket_service.dart';

part 'models.dart';
part 'logic.dart';
part 'refresh.dart';
part 'machine_filters.dart';
part 'content.dart';
part 'header.dart';
part 'header_actions.dart';
part 'tab_bar.dart';
part 'drawer.dart';
part 'drawer_tile.dart';

/// Root entry aligned with upstream:
/// unauthenticated users land on auth entry,
/// authenticated users land on the main tab container.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    this.initialTab = HomeTab.sessions,
  });

  final HomeTab initialTab;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SessionListPreferencesService _listPreferencesService =
      SessionListPreferencesService.instance;
  String? _initializedToken;
  String? _selectedMachineId;
  bool _isRefreshingSessionsStatus = false;
  HomeTab _activeTab = HomeTab.sessions;

  @override
  void initState() {
    super.initState();
    _initializeHomeScreen(this, initialTab: widget.initialTab);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncHomeScreenTab(this, oldWidget: oldWidget, newWidget: widget);
  }

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  void _ensureConnectedServices({
    required String token,
    required String machineId,
  }) {
    _ensureHomeConnectedServices(this, token: token, machineId: machineId);
  }

  void _openSessionsTab() => _handleTabSelected(HomeTab.sessions);

  Future<void> _clearLegacyPersistedDeviceFilter() =>
      _clearHomeLegacyPersistedDeviceFilter(this);

  void _setSelectedMachineId(String? machineId) =>
      _setHomeSelectedMachineId(this, machineId);

  void _handleTabSelected(HomeTab tab) => _handleHomeTabSelected(this, tab);

  void _handleLeadingAction() => _handleHomeLeadingAction(this);

  void _handlePrimaryAction({String? selectedMachineId}) =>
      _handleHomePrimaryAction(this, selectedMachineId: selectedMachineId);

  Future<void> _refreshSessionsAndConnection() =>
      _refreshHomeSessionsAndConnection(this);

  Future<void> _refreshVisibleSessionSnapshots(
    SessionServiceNotifier sessionNotifier,
  ) =>
      _refreshHomeVisibleSessionSnapshots(this, sessionNotifier);

  @override
  Widget build(BuildContext context) => _buildHomeScreen(this);
}
