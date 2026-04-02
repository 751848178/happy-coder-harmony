import 'dart:typed_data';

class SessionDataKeyStore {
  SessionDataKeyStore._();

  static final SessionDataKeyStore instance = SessionDataKeyStore._();

  final Map<String, Uint8List> _sessionKeys = <String, Uint8List>{};

  Uint8List? sessionKeyFor(String sessionId) => _sessionKeys[sessionId];

  void replaceAll(Map<String, Uint8List?> nextKeys) {
    _sessionKeys
      ..clear()
      ..addEntries(
        nextKeys.entries.where((entry) => entry.value != null).map(
              (entry) => MapEntry(
                entry.key,
                Uint8List.fromList(entry.value!),
              ),
            ),
      );
  }

  void removeSessionKey(String sessionId) {
    _sessionKeys.remove(sessionId);
  }

  void clear() {
    _sessionKeys.clear();
  }
}
