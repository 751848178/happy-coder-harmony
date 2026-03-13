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
  String? _initializedToken;
  HomeTab _activeTab = HomeTab.sessions;
  int _inboxUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
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
    Logger.info(
      'HomeScreen.build authenticated=${authState.isAuthenticated} activeTab=$_activeTab',
    );

    if (!authState.isAuthenticated) {
      return const QRLoginScreen();
    }

    final credentials = authState.credentials!;
    _ensureConnectedServices(
      token: credentials.token,
      machineId: credentials.machineId,
    );

    final socketState = ref.watch(socketStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: Column(
        children: [
          _HomeHeader(
            activeTab: _activeTab,
            status: _buildConnectionStatus(socketState),
            onLogoTap: _openSessionsTab,
            onPrimaryAction: _handlePrimaryAction,
          ),
          Expanded(
            child: IndexedStack(
              index: _activeTab.index,
              children: const [
                SessionsScreen(
                  showAppBar: false,
                  showSearchBar: false,
                  showFab: false,
                ),
                InboxScreen(showAppBar: false),
                SettingsScreen(showAppBar: false),
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
      if (!socketState.isConnected) {
        await ref.read(socketStateProvider.notifier).initialize(
              machineId: machineId,
              token: token,
            );
      }

      await ref.read(sessionStateProvider.notifier).loadSessions();
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

  void _handlePrimaryAction() {
    switch (_activeTab) {
      case HomeTab.sessions:
        context.push(AppRoutes.newFlow);
        return;
      case HomeTab.inbox:
        context.push(AppRoutes.friendsSearch);
        return;
      case HomeTab.settings:
        return;
    }
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.activeTab,
    required this.status,
    required this.onLogoTap,
    required this.onPrimaryAction,
  });

  final HomeTab activeTab;
  final _ConnectionStatus status;
  final VoidCallback onLogoTap;
  final VoidCallback onPrimaryAction;

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
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onLogoTap,
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
                    Row(
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
                      ],
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
