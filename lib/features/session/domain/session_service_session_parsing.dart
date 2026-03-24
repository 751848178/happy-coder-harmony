part of 'session_service.dart';

extension SessionServiceSessionParsing on SessionServiceNotifier {
  Future<_ParsedRemoteSessionsResult> _parseRemoteSessions({
    required List<dynamic> sessionItems,
    required Map<String, SessionPreferences> sessionPreferences,
    required String? secretKey,
    required CryptoService? crypto,
  }) async {
    final sessionsMap = <String, Session>{};
    final remoteSessionIds = <String>{};
    final parseFailureSamples = <String>[];
    var parseFailureCount = 0;

    _sessionDataKeys.clear();
    for (final item in sessionItems) {
      final sessionJson = _normalizeSessionPayload(item);
      if (sessionJson == null) {
        final remoteSessionId = _extractSessionId(item);
        if (remoteSessionId != null) {
          remoteSessionIds.add(remoteSessionId);
        }
        parseFailureCount++;
        if (parseFailureSamples.length < 3) {
          parseFailureSamples.add(
            'unrecognized session payload type=${item.runtimeType}',
          );
        }
        continue;
      }

      final remoteSessionId = _extractSessionId(sessionJson);
      if (remoteSessionId != null && remoteSessionId.isNotEmpty) {
        remoteSessionIds.add(remoteSessionId);
      }

      try {
        final session = await _parseRemoteSessionItem(
          sessionJson: sessionJson,
          sessionPreferences: sessionPreferences,
          secretKey: secretKey,
          crypto: crypto,
        );
        sessionsMap[session.id] = session;
      } catch (error) {
        parseFailureCount++;
        if (parseFailureSamples.length < 3) {
          parseFailureSamples.add('${remoteSessionId ?? "unknown"}: $error');
        }
        Logger.warning(
          'Failed to parse session ${remoteSessionId ?? "unknown"}: $error',
        );
      }
    }

    if (sessionsMap.isEmpty && remoteSessionIds.isNotEmpty) {
      for (final remoteSessionId in remoteSessionIds) {
        final cachedSession = _repository.getSession(remoteSessionId);
        if (cachedSession != null) {
          sessionsMap[remoteSessionId] = cachedSession;
        }
      }
    }

    return _ParsedRemoteSessionsResult(
      sessionsMap: sessionsMap,
      remoteSessionIds: remoteSessionIds,
      parseFailureCount: parseFailureCount,
      parseFailureSamples: parseFailureSamples,
    );
  }

  Future<Session> _parseRemoteSessionItem({
    required Map<String, dynamic> sessionJson,
    required Map<String, SessionPreferences> sessionPreferences,
    required String? secretKey,
    required CryptoService? crypto,
  }) async {
    final encryptedDataKey = sessionJson['dataEncryptionKey']?.toString();
    final dataKey = secretKey != null &&
            secretKey.isNotEmpty &&
            crypto != null &&
            encryptedDataKey != null &&
            encryptedDataKey.isNotEmpty
        ? await crypto.decryptHappyCoderDataEncryptionKey(
            encryptedDataKey,
            secretKey,
          )
        : null;

    final metadata = await _decodeEncryptedJsonMap(
      sessionJson['metadata'],
      dataKey: dataKey,
      secretKey: secretKey,
    );
    final agentState = await _decodeEncryptedJsonMap(
      sessionJson['agentState'],
      dataKey: dataKey,
      secretKey: secretKey,
    );
    final parsedSession = Session.fromJson(sessionJson);
    final existingSession = _repository.getSession(parsedSession.id);
    final nextMetadata = metadata ?? parsedSession.metadata;
    final summary = _asStringMap(nextMetadata?['summary']);
    final resolvedPath =
        nextMetadata?['path']?.toString() ?? parsedSession.path;
    final preferences = sessionPreferences[parsedSession.id];
    final session = parsedSession.copyWith(
      title: _resolveSessionTitle(
        path: resolvedPath,
        summary: summary?['text']?.toString(),
        name: preferences?.alias ?? nextMetadata?['name']?.toString(),
        title: nextMetadata?['title']?.toString(),
        fallback: parsedSession.title,
      ),
      path: resolvedPath,
      metadata: nextMetadata,
      agentState: agentState ?? parsedSession.agentState,
      permissionMode: _resolveLocalSessionMode(
        preferred: preferences?.permissionMode,
        explicit: parsedSession.permissionMode,
        metadataValue: nextMetadata?['currentOperatingModeCode']?.toString(),
      ),
      modelMode: _resolveLocalSessionMode(
        preferred: preferences?.modelMode,
        explicit: parsedSession.modelMode,
        metadataValue: nextMetadata?['currentModelCode']?.toString(),
      ),
      draft: _resolveSessionDraft(
        remoteDraft: parsedSession.draft,
        cachedDraft: existingSession?.draft,
      ),
    );
    _sessionDataKeys[session.id] = dataKey;
    return session;
  }

  void _applyLoadedSessions(
    _ParsedRemoteSessionsResult parsed, {
    required bool responseRecognized,
    required int rawCount,
  }) {
    if (responseRecognized) {
      _repository.applySessions(parsed.sessionsMap.values.toList(),
          replace: true);
    } else if (parsed.sessionsMap.isNotEmpty) {
      _repository.applySessions(parsed.sessionsMap.values.toList());
    } else {
      Logger.warning(
        'Sessions response shape was not recognized; keeping cached sessions.',
      );
    }

    _lastRemoteSessionIds
      ..clear()
      ..addAll(parsed.remoteSessionIds);
    _lastSessionsLoadedAt = DateTime.now();
    if (parsed.sessionsMap.isNotEmpty ||
        (responseRecognized && rawCount == 0)) {
      _schedulePersistCachedSessions();
    }
  }

  void _logSessionParseFailures(_ParsedRemoteSessionsResult parsed) {
    if (parsed.parseFailureCount <= 0) {
      return;
    }
    Logger.warning(
      'Sessions load completed with ${parsed.parseFailureCount} parse failures. '
      'samples=${parsed.parseFailureSamples.join(" | ")}',
    );
  }

  Future<void> _handleLoadSessionsError(Object error) async {
    if (_repository.sessionsMap.isEmpty) {
      final restoredSessions = await _restoreCachedSessions();
      if (restoredSessions.isNotEmpty) {
        _repository.applySessions(restoredSessions);
      }
    }

    if (_repository.sessionsMap.isNotEmpty) {
      _emitReadyState();
      Logger.warning('Load sessions failed, using cached sessions: $error');
      return;
    }

    _emitErrorState('加载会话失败: ${error.toString()}');
    Logger.error('Load sessions error: $error');
  }
}
