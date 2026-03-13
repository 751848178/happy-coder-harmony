import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../routes/app_routes.dart';
import '../services/happy_link_service.dart';
import '../../shared/utils/extensions.dart';

class HappyLinkGate extends ConsumerStatefulWidget {
  const HappyLinkGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HappyLinkGate> createState() => _HappyLinkGateState();
}

class _HappyLinkGateState extends ConsumerState<HappyLinkGate>
    with WidgetsBindingObserver {
  final HappyLinkService _linkService = HappyLinkService.instance;

  String? _pendingLink;
  bool _isHandlingLink = false;
  bool _awaitingAuthentication = false;
  bool _isBootstrappingAuth = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapAuth();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPendingLink();
    }
  }

  Future<void> _loadPendingLink() async {
    final link = await _linkService.takePendingLink();
    if (!mounted || link == null || link.isEmpty) {
      return;
    }

    setState(() {
      _pendingLink = link;
    });
    _scheduleHandlePendingLink();
  }

  Future<void> _bootstrapAuth() async {
    Logger.info('HappyLinkGate bootstrap auth start');
    try {
      await ref.read(authStateProvider.notifier).checkAuthStatus();
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBootstrappingAuth = false;
      });
      Logger.info('HappyLinkGate bootstrap auth done');
      _loadPendingLink();
    }
  }

  void _scheduleHandlePendingLink() {
    if (_isBootstrappingAuth ||
        _pendingLink == null ||
        _pendingLink!.isEmpty ||
        _isHandlingLink) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePendingLink();
    });
  }

  Future<void> _handlePendingLink() async {
    if (!mounted || _isHandlingLink || _pendingLink == null) {
      return;
    }

    final link = _pendingLink!.trim();
    final targetRoute = _resolveRoute(link);
    if (targetRoute == null) {
      setState(() {
        _pendingLink = null;
      });
      return;
    }

    final authState = ref.read(authStateProvider);
    final requiresAuthenticatedSession = targetRoute == AppRoutes.terminalConnect ||
        targetRoute == AppRoutes.linkAccount;
    if (requiresAuthenticatedSession && !authState.isAuthenticated) {
      if (_awaitingAuthentication) {
        return;
      }
      _awaitingAuthentication = true;
      context.go(AppRoutes.auth);
      return;
    }

    _awaitingAuthentication = false;
    _isHandlingLink = true;

    try {
      final encodedLink = Uri.encodeComponent(link);
      context.push('$targetRoute?url=$encodedLink');
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingLink = null;
      });
    } finally {
      _isHandlingLink = false;
    }
  }

  String? _resolveRoute(String link) {
    if (_linkService.isTerminalLink(link)) {
      return AppRoutes.terminalConnect;
    }
    if (_linkService.isAccountLink(link)) {
      return AppRoutes.linkAccount;
    }
    if (_linkService.isRestoreLink(link)) {
      return AppRoutes.restoreManual;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);
    Logger.info(
      'HappyLinkGate.build bootstrapping=$_isBootstrappingAuth pendingLink=${_pendingLink != null}',
    );
    if (_isBootstrappingAuth) {
      return const Material(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    _scheduleHandlePendingLink();
    return widget.child;
  }
}
