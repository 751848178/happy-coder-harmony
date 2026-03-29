import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../../shared/utils/extensions.dart';

class SessionBackgroundRefreshGate extends ConsumerStatefulWidget {
  const SessionBackgroundRefreshGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<SessionBackgroundRefreshGate> createState() =>
      _SessionBackgroundRefreshGateState();
}

class _SessionBackgroundRefreshGateState
    extends ConsumerState<SessionBackgroundRefreshGate>
    with WidgetsBindingObserver {
  static const Duration _refreshInterval = Duration(seconds: 45);

  Timer? _refreshTimer;
  bool _refreshInFlight = false;
  AppLifecycleState? _lifecycleState;
  bool _lastBackgroundRefreshEnabled = false;

  @override
  void initState() {
    super.initState();
    _lifecycleState = WidgetsBinding.instance.lifecycleState;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncRefreshLoop();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _syncRefreshLoop();
    if (state == AppLifecycleState.resumed) {
      unawaited(
        _refreshAllSessions(
          reason: 'resumed',
          allowForegroundRefresh: true,
        ),
      );
    }
  }

  bool _backgroundRefreshEnabled() {
    final settings = ref.read(settingsStateProvider);
    final credentials = ref.read(authStateProvider).credentials;
    return settings.enableBackgroundSessionRefresh && credentials != null;
  }

  bool _isInBackgroundLifecycle() {
    final lifecycle = _lifecycleState;
    return lifecycle != null &&
        lifecycle != AppLifecycleState.resumed &&
        lifecycle != AppLifecycleState.detached;
  }

  void _syncRefreshLoop() {
    if (!mounted) {
      return;
    }

    final enabled = _backgroundRefreshEnabled();
    if (enabled != _lastBackgroundRefreshEnabled) {
      _lastBackgroundRefreshEnabled = enabled;
      if (enabled) {
        unawaited(
          _refreshAllSessions(
            reason: 'setting-enabled',
            allowForegroundRefresh: true,
          ),
        );
      }
    }

    final shouldPoll = enabled && _isInBackgroundLifecycle();
    if (!shouldPoll) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
      return;
    }
    if (_refreshTimer != null) {
      return;
    }

    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      unawaited(_refreshAllSessions(reason: 'background-timer'));
    });
  }

  Future<void> _refreshAllSessions({
    required String reason,
    bool allowForegroundRefresh = false,
  }) async {
    if (!mounted || _refreshInFlight || !_backgroundRefreshEnabled()) {
      return;
    }
    if (!allowForegroundRefresh && !_isInBackgroundLifecycle()) {
      return;
    }

    _refreshInFlight = true;
    try {
      final credentials = ref.read(authStateProvider).credentials;
      if (credentials == null) {
        return;
      }

      final sessionNotifier = ref.read(sessionStateProvider.notifier);
      await sessionNotifier.loadSessions(force: true);
      final remoteSessionIds = sessionNotifier.sessions
          .where((session) => sessionNotifier.hasRemoteSession(session.id))
          .map((session) => session.id)
          .toList(growable: false);
      if (remoteSessionIds.isNotEmpty) {
        await sessionNotifier.refreshSessionMessageSnapshots(
          remoteSessionIds,
          maxPagesPerSession: 2,
        );
      }

      if (allowForegroundRefresh) {
        final socketState = ref.read(socketStateProvider);
        if (!socketState.isConnected && !socketState.isConnecting) {
          await ref.read(socketStateProvider.notifier).initialize(
                machineId: credentials.machineId,
                token: credentials.token,
              );
        }
      }

      Logger.info(
        'Session background refresh completed '
        '(reason=$reason, sessions=${remoteSessionIds.length})',
      );
    } catch (error) {
      Logger.warning(
        'Session background refresh failed (reason=$reason): $error',
      );
    } finally {
      _refreshInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);
    ref.watch(
      settingsStateProvider.select(
        (settings) => settings.enableBackgroundSessionRefresh,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncRefreshLoop();
    });
    return widget.child;
  }
}
