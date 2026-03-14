import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
import '../../auth/presentation/qr_login_screen.dart';
import '../../friends/data/inbox_repository.dart';
import '../../friends/screens/inbox_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../session/data/session_list_preferences_service.dart';
import '../../session/screens/sessions_screen.dart';
import '../../socketio/domain/socket_service.dart';

enum HomeTab {
  sessions,
  inbox,
  settings;

  static HomeTab fromRouteValue(String? value) {
    switch (value) {
      case 'inbox':
        return HomeTab.inbox;
      case 'settings':
        return HomeTab.settings;
      case 'sessions':
      default:
        return HomeTab.sessions;
    }
  }
}

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
  int _inboxUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _clearLegacyPersistedDeviceFilter();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _activeTab = widget.initialTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    ref.watch(sessionStateProvider);
    Logger.info(
      'HomeScreen.build authenticated=${authState.isAuthenticated} activeTab=$_activeTab',
    );

    if (!authState.isAuthenticated) {
      return const QRLoginScreen();
    }

    final credentials = authState.credentials!;
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final machineOptions = _buildMachineFilterOptions(
      machines: sessionNotifier.machines,
      sessions: sessionNotifier.sessions,
    );
    final effectiveSelectedMachineId =
        _effectiveSelectedMachineId(machineOptions);
    final selectedMachineOption =
        machineOptions.cast<_HomeMachineFilterOption?>().firstWhere(
              (option) => option?.id == effectiveSelectedMachineId,
              orElse: () => null,
            );
    _ensureConnectedServices(
      token: credentials.token,
      machineId: credentials.machineId,
    );

    final socketState = ref.watch(socketStateProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.neutral50,
      drawer: _activeTab == HomeTab.sessions
          ? _buildMachineDrawer(
              options: machineOptions,
              selectedOption: selectedMachineOption,
              totalSessionCount: sessionNotifier.sessions.length,
            )
          : null,
      body: Column(
        children: [
          _HomeHeader(
            activeTab: _activeTab,
            status: _buildConnectionStatus(socketState),
            isRefreshingStatus: _isRefreshingSessionsStatus,
            selectedMachineLabel: _activeTab == HomeTab.sessions
                ? (selectedMachineOption?.label ?? '全部设备')
                : null,
            onLeadingAction: _handleLeadingAction,
            onStatusTap: _activeTab == HomeTab.sessions
                ? _refreshSessionsAndConnection
                : null,
            onPrimaryAction: () => _handlePrimaryAction(
              selectedMachineId: effectiveSelectedMachineId,
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _activeTab.index,
              children: [
                SessionsScreen(
                  showAppBar: false,
                  showSearchBar: false,
                  showFab: false,
                  selectedMachineId: effectiveSelectedMachineId,
                  selectedMachineName: selectedMachineOption?.label,
                ),
                const InboxScreen(showAppBar: false),
                const SettingsScreen(showAppBar: false),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _HomeTabBar(
        activeTab: _activeTab,
        inboxBadgeCount: _inboxUnreadCount,
        onTabSelected: _handleTabSelected,
      ),
    );
  }

  void _ensureConnectedServices({
    required String token,
    required String machineId,
  }) {
    if (_initializedToken == token) {
      return;
    }
    _initializedToken = token;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final socketState = ref.read(socketStateProvider);
      final futures = <Future<void>>[
        ref.read(sessionStateProvider.notifier).loadSessions(),
      ];

      if (!socketState.isConnected) {
        futures.add(
          ref.read(socketStateProvider.notifier).initialize(
                machineId: machineId,
                token: token,
              ),
        );
      }

      await Future.wait(futures);
      await _refreshInboxBadge(token);
    });
  }

  Future<void> _refreshInboxBadge(String token) async {
    final count = await InboxRepository.instance.getUnreadCount(token: token);
    if (!mounted) {
      return;
    }
    setState(() {
      _inboxUnreadCount = count;
    });
  }

  _ConnectionStatus _buildConnectionStatus(SocketState socketState) {
    return socketState.when(
      initial: () => const _ConnectionStatus(
        label: '未连接',
        color: AppTheme.neutral500,
      ),
      connecting: () => const _ConnectionStatus(
        label: '连接中',
        color: AppTheme.warningColor,
      ),
      connected: (_) => const _ConnectionStatus(
        label: '已连接',
        color: AppTheme.successColor,
      ),
      reconnecting: (_) => const _ConnectionStatus(
        label: '重连中',
        color: AppTheme.warningColor,
      ),
      error: (_) => const _ConnectionStatus(
        label: '连接异常',
        color: AppTheme.errorColor,
      ),
    );
  }

  void _openSessionsTab() {
    _handleTabSelected(HomeTab.sessions);
  }

  Future<void> _clearLegacyPersistedDeviceFilter() async {
    final preferences = await _listPreferencesService.load();
    if (preferences.isDefault) {
      return;
    }

    // Device selection moved into a hidden drawer entry. Keep the default view
    // on "all devices" so a stale persisted filter doesn't silently narrow the
    // list to a single machine after relaunch.
    await _listPreferencesService.setSelectedMachineId(null);
  }

  void _setSelectedMachineId(String? machineId) {
    final trimmedMachineId = machineId?.trim();
    setState(() {
      _selectedMachineId = trimmedMachineId == null || trimmedMachineId.isEmpty
          ? null
          : trimmedMachineId;
    });
  }

  void _handleTabSelected(HomeTab tab) {
    setState(() {
      _activeTab = tab;
    });

    if (tab == HomeTab.inbox) {
      final token = ref.read(authStateProvider).credentials?.token;
      if (token != null && token.isNotEmpty) {
        _refreshInboxBadge(token);
      }
    }
  }

  void _handleLeadingAction() {
    if (_activeTab == HomeTab.sessions) {
      _scaffoldKey.currentState?.openDrawer();
      return;
    }
    _openSessionsTab();
  }

  void _handlePrimaryAction({String? selectedMachineId}) {
    switch (_activeTab) {
      case HomeTab.sessions:
        if (selectedMachineId == null ||
            selectedMachineId == SessionsScreen.unknownMachineFilterId) {
          context.push(AppRoutes.newFlow);
          return;
        }
        context.push(
          Uri(
            path: AppRoutes.newFlow,
            queryParameters: {'machineId': selectedMachineId},
          ).toString(),
        );
        return;
      case HomeTab.inbox:
        context.push(AppRoutes.friendsSearch);
        return;
      case HomeTab.settings:
        return;
    }
  }

  Future<void> _refreshSessionsAndConnection() async {
    if (_isRefreshingSessionsStatus) {
      return;
    }

    final authState = ref.read(authStateProvider);
    final credentials = authState.credentials;
    if (credentials == null) {
      return;
    }

    setState(() {
      _isRefreshingSessionsStatus = true;
    });

    try {
      final sessionNotifier = ref.read(sessionStateProvider.notifier);
      final socketNotifier = ref.read(socketStateProvider.notifier);
      await Future.wait([
        sessionNotifier.loadSessions(force: true),
        sessionNotifier.loadMachines(force: true, allowFailure: true),
        socketNotifier.initialize(
          machineId: credentials.machineId,
          token: credentials.token,
        ),
      ]);
      await _refreshInboxBadge(credentials.token);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新状态失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingSessionsStatus = false;
        });
      }
    }
  }

  List<_HomeMachineFilterOption> _buildMachineFilterOptions({
    required List<Machine> machines,
    required List<Session> sessions,
  }) {
    final countsByMachineId = <String, int>{};
    final recentSessionByMachineId = <String, Session>{};
    var unknownCount = 0;

    for (final session in sessions) {
      final machineId = _sessionMachineId(session);
      if (machineId == null) {
        unknownCount++;
        continue;
      }
      countsByMachineId[machineId] = (countsByMachineId[machineId] ?? 0) + 1;
      final previous = recentSessionByMachineId[machineId];
      if (previous == null || session.updatedAt.isAfter(previous.updatedAt)) {
        recentSessionByMachineId[machineId] = session;
      }
    }

    final options = <_HomeMachineFilterOption>[];
    final seenIds = <String>{};
    final sortedMachines = List<Machine>.from(machines)
      ..sort((a, b) {
        final activeCompare = (b.active ? 1 : 0).compareTo(a.active ? 1 : 0);
        if (activeCompare != 0) {
          return activeCompare;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    for (final machine in sortedMachines) {
      if (!seenIds.add(machine.id)) {
        continue;
      }
      options.add(
        _HomeMachineFilterOption(
          id: machine.id,
          label: machine.name,
          subtitle: machine.platform ?? '设备',
          sessionCount: countsByMachineId[machine.id] ?? 0,
          isOnline: machine.active,
        ),
      );
    }

    for (final entry in recentSessionByMachineId.entries) {
      if (!seenIds.add(entry.key)) {
        continue;
      }
      final session = entry.value;
      options.add(
        _HomeMachineFilterOption(
          id: entry.key,
          label: session.metadata?['host']?.toString() ?? entry.key,
          subtitle: session.path ?? '来自最近会话',
          sessionCount: countsByMachineId[entry.key] ?? 0,
        ),
      );
    }

    if (unknownCount > 0) {
      options.add(
        _HomeMachineFilterOption(
          id: SessionsScreen.unknownMachineFilterId,
          label: '未知设备',
          subtitle: '没有 machineId 的历史会话',
          sessionCount: unknownCount,
          isUnknown: true,
        ),
      );
    }

    return options;
  }

  String? _effectiveSelectedMachineId(List<_HomeMachineFilterOption> options) {
    final selectedMachineId = _selectedMachineId;
    if (selectedMachineId == null) {
      return null;
    }
    final exists = options.any((option) => option.id == selectedMachineId);
    if (exists) {
      return selectedMachineId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedMachineId != selectedMachineId) {
        return;
      }
      _setSelectedMachineId(null);
    });
    return null;
  }

  String? _sessionMachineId(Session session) {
    final machineId = session.metadata?['machineId']?.toString();
    if (machineId == null || machineId.trim().isEmpty) {
      return null;
    }
    return machineId.trim();
  }

  Widget _buildMachineDrawer({
    required List<_HomeMachineFilterOption> options,
    required _HomeMachineFilterOption? selectedOption,
    required int totalSessionCount,
  }) {
    return Drawer(
      width: 324,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '设备会话',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedOption == null
                        ? '当前显示全部设备的会话'
                        : '当前设备：${selectedOption.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.neutral200),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                children: [
                  _HomeMachineDrawerTile(
                    icon: Icons.apps_rounded,
                    label: '全部设备',
                    subtitle: '显示全部设备的会话',
                    count: totalSessionCount,
                    selected: selectedOption == null,
                    onTap: () {
                      Navigator.of(context).pop();
                      _setSelectedMachineId(null);
                    },
                  ),
                  if (options.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      child: Text(
                        '设备列表',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.neutral500,
                        ),
                      ),
                    ),
                    for (final option in options)
                      _HomeMachineDrawerTile(
                        icon: option.isUnknown
                            ? Icons.device_unknown_rounded
                            : Icons.desktop_windows_outlined,
                        label: option.label,
                        subtitle: option.subtitle,
                        count: option.sessionCount,
                        selected: selectedOption?.id == option.id,
                        isOnline: option.isOnline,
                        onTap: () {
                          Navigator.of(context).pop();
                          _setSelectedMachineId(option.id);
                        },
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.activeTab,
    required this.status,
    required this.isRefreshingStatus,
    required this.onLeadingAction,
    required this.onPrimaryAction,
    this.onStatusTap,
    this.selectedMachineLabel,
  });

  final HomeTab activeTab;
  final _ConnectionStatus status;
  final bool isRefreshingStatus;
  final VoidCallback onLeadingAction;
  final VoidCallback onPrimaryAction;
  final Future<void> Function()? onStatusTap;
  final String? selectedMachineLabel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _HeaderLeadingButton(
                    activeTab: activeTab,
                    onTap: onLeadingAction,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _titleForTab(activeTab),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            onStatusTap == null ? null : () => onStatusTap!(),
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: status.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                status.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: status.color,
                                ),
                              ),
                              if (activeTab == HomeTab.sessions &&
                                  selectedMachineLabel != null &&
                                  selectedMachineLabel!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                const Text(
                                  '·',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.neutral400,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    selectedMachineLabel!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.neutral600,
                                    ),
                                  ),
                                ),
                              ],
                              if (onStatusTap != null) ...[
                                const SizedBox(width: 6),
                                isRefreshingStatus
                                    ? SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.7,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            status.color,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.refresh_rounded,
                                        size: 14,
                                        color: AppTheme.neutral500,
                                      ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 44,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _HeaderActionButton(
                    activeTab: activeTab,
                    onPressed: onPrimaryAction,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleForTab(HomeTab tab) {
    switch (tab) {
      case HomeTab.sessions:
        return '会话';
      case HomeTab.inbox:
        return '收件箱';
      case HomeTab.settings:
        return '设置';
    }
  }
}

class _HeaderLeadingButton extends StatelessWidget {
  const _HeaderLeadingButton({
    required this.activeTab,
    required this.onTap,
  });

  final HomeTab activeTab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (activeTab == HomeTab.sessions) {
      return IconButton(
        icon: const Icon(Icons.menu_rounded),
        color: AppTheme.textPrimary,
        onPressed: onTap,
        tooltip: '选择设备',
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.neutral900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.code_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.activeTab,
    required this.onPressed,
  });

  final HomeTab activeTab;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    switch (activeTab) {
      case HomeTab.sessions:
        return IconButton(
          icon: const Icon(Icons.add_rounded),
          color: AppTheme.textPrimary,
          onPressed: onPressed,
          tooltip: '新建会话',
        );
      case HomeTab.inbox:
        return IconButton(
          icon: const Icon(Icons.person_add_alt_1_rounded),
          color: AppTheme.textPrimary,
          onPressed: onPressed,
          tooltip: '添加好友',
        );
      case HomeTab.settings:
        return const SizedBox(width: 40, height: 40);
    }
  }
}

class _HomeTabBar extends StatelessWidget {
  const _HomeTabBar({
    required this.activeTab,
    required this.inboxBadgeCount,
    required this.onTabSelected,
  });

  final HomeTab activeTab;
  final int inboxBadgeCount;
  final ValueChanged<HomeTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.surface,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.neutral200),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TabBarItem(
                  label: '收件箱',
                  icon: Icons.inbox_outlined,
                  activeIcon: Icons.inbox_rounded,
                  selected: activeTab == HomeTab.inbox,
                  badgeCount: inboxBadgeCount,
                  onTap: () => onTabSelected(HomeTab.inbox),
                ),
              ),
              Expanded(
                child: _TabBarItem(
                  label: '会话',
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  selected: activeTab == HomeTab.sessions,
                  onTap: () => onTabSelected(HomeTab.sessions),
                ),
              ),
              Expanded(
                child: _TabBarItem(
                  label: '设置',
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  selected: activeTab == HomeTab.settings,
                  onTap: () => onTabSelected(HomeTab.settings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarItem extends StatelessWidget {
  const _TabBarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.textPrimary : AppTheme.neutral500;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      selected ? activeIcon : icon,
                      size: 24,
                      color: color,
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(minWidth: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionStatus {
  const _ConnectionStatus({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;
}

class _HomeMachineFilterOption {
  const _HomeMachineFilterOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.sessionCount,
    this.isOnline = false,
    this.isUnknown = false,
  });

  final String id;
  final String label;
  final String subtitle;
  final int sessionCount;
  final bool isOnline;
  final bool isUnknown;
}

class _HomeMachineDrawerTile extends StatelessWidget {
  const _HomeMachineDrawerTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.count,
    required this.selected,
    required this.onTap,
    this.isOnline = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final int count;
  final bool selected;
  final bool isOnline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? AppTheme.brandColor.withValues(alpha: 0.08)
        : Colors.transparent;
    final borderColor = selected
        ? AppTheme.brandColor.withValues(alpha: 0.18)
        : AppTheme.neutral200;
    final iconBackground = selected
        ? AppTheme.brandColor.withValues(alpha: 0.14)
        : AppTheme.neutral100;
    final iconColor = selected ? AppTheme.brandColor : AppTheme.neutral500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Icon(
                          icon,
                          size: 22,
                          color: iconColor,
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppTheme.successColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? AppTheme.brandColor.withValues(
                                        alpha: 0.14,
                                      )
                                    : iconBackground,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.brandColor.withValues(alpha: 0.14)
                        : AppTheme.neutral100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color:
                          selected ? AppTheme.brandColor : AppTheme.neutral700,
                    ),
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
