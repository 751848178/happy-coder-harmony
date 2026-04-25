part of 'session_service.dart';

class _RemoteSessionLoadResult {
  const _RemoteSessionLoadResult({
    required this.responseRecognized,
    required this.sessionItems,
    required this.sessionPreferences,
    required this.secretKey,
    required this.crypto,
  });

  final bool responseRecognized;
  final List<dynamic> sessionItems;
  final Map<String, SessionPreferences> sessionPreferences;
  final String? secretKey;
  final CryptoService? crypto;
}

class _ParsedRemoteSessionsResult {
  const _ParsedRemoteSessionsResult({
    required this.sessionsMap,
    required this.remoteSessionIds,
    required this.parseFailureCount,
    required this.parseFailureSamples,
  });

  final Map<String, Session> sessionsMap;
  final Set<String> remoteSessionIds;
  final int parseFailureCount;
  final List<String> parseFailureSamples;
}
