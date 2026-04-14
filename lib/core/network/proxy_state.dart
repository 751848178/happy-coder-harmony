import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_proxy_server.dart';

/// Immutable state for the local HTTP proxy.
class ProxyState {
  final bool isRunning;
  final String proxyUrl;
  final int? localPort;
  final int targetPort;
  final String? activeSessionId;

  const ProxyState({
    this.isRunning = false,
    this.proxyUrl = '',
    this.localPort,
    this.targetPort = 8080,
    this.activeSessionId,
  });

  ProxyState copyWith({
    bool? isRunning,
    String? proxyUrl,
    int? localPort,
    int? targetPort,
    String? activeSessionId,
  }) =>
      ProxyState(
        isRunning: isRunning ?? this.isRunning,
        proxyUrl: proxyUrl ?? this.proxyUrl,
        localPort: localPort ?? this.localPort,
        targetPort: targetPort ?? this.targetPort,
        activeSessionId: activeSessionId ?? this.activeSessionId,
      );
}

/// StateNotifier that bridges LocalProxyServer into Riverpod.
class ProxyNotifier extends StateNotifier<ProxyState> {
  final LocalProxyServer _server;

  ProxyNotifier(this._server) : super(const ProxyState());

  /// Start the proxy server and update state.
  Future<void> start({
    required String sessionId,
    int targetPort = 8080,
  }) async {
    await _server.start(sessionId: sessionId, targetPort: targetPort);
    state = ProxyState(
      isRunning: _server.isRunning,
      proxyUrl: _server.proxyUrl,
      localPort: _server.localPort,
      targetPort: _server.targetPort,
      activeSessionId: _server.activeSessionId,
    );
  }

  /// Stop the proxy server and update state.
  Future<void> stop() async {
    await _server.stop();
    state = const ProxyState();
  }

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }
}

/// Provider for the proxy state.
final proxyStateProvider =
    StateNotifierProvider<ProxyNotifier, ProxyState>((ref) {
  return ProxyNotifier(LocalProxyServer.instance);
});
