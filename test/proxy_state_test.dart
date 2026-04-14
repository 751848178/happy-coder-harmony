import 'package:flutter_test/flutter_test.dart';
import 'package:happy_coder_flutter/core/network/proxy_state.dart';

void main() {
  group('ProxyState', () {
    test('default state has correct values', () {
      const state = ProxyState();

      expect(state.isRunning, isFalse);
      expect(state.proxyUrl, '');
      expect(state.localPort, isNull);
      expect(state.targetPort, 8080);
      expect(state.activeSessionId, isNull);
    });

    test('copyWith updates specified fields only', () {
      const state = ProxyState(
        isRunning: true,
        proxyUrl: 'http://127.0.0.1:12345',
        localPort: 12345,
        targetPort: 3000,
        activeSessionId: 'session-abc',
      );

      final updated = state.copyWith(targetPort: 8080);

      expect(updated.isRunning, isTrue);
      expect(updated.proxyUrl, 'http://127.0.0.1:12345');
      expect(updated.localPort, 12345);
      expect(updated.targetPort, 8080);
      expect(updated.activeSessionId, 'session-abc');
    });

    test('copyWith can clear fields', () {
      const state = ProxyState(
        isRunning: true,
        proxyUrl: 'http://127.0.0.1:12345',
        localPort: 12345,
      );

      final cleared = state.copyWith(
        isRunning: false,
        proxyUrl: '',
      );

      expect(cleared.isRunning, isFalse);
      expect(cleared.proxyUrl, '');
    });
  });
}
