part of 'session_service.dart';

extension SessionServiceSessionLoaders on SessionServiceNotifier {
  static const Duration _sessionListAutoSyncMinAge = Duration(seconds: 12);

  Future<void> loadSessions({bool force = false}) async {
    if (_loadSessionsInFlight != null) {
      Logger.info('Sessions load already in flight, joining existing request');
      return _loadSessionsInFlight!;
    }

    final completer = Completer<void>();
    _loadSessionsInFlight = completer.future;

    try {
      final hasCachedSessions = await _restoreCachedSessionsIfNeeded();
      if (_shouldSkipSessionReload(
        force: force,
        hasCachedSessions: hasCachedSessions,
      )) {
        return;
      }

      if (!hasCachedSessions) {
        _emitLoadingState();
      }

      final remoteLoad = await _fetchRemoteSessionLoad();
      _accountSecret = remoteLoad.secretKey;

      final machinesFuture = loadMachines(
        force: force || _repository.machinesMap.isEmpty,
        allowFailure: true,
      );
      final parsed = await _parseRemoteSessions(
        sessionItems: remoteLoad.sessionItems,
        sessionPreferences: remoteLoad.sessionPreferences,
        secretKey: remoteLoad.secretKey,
        crypto: remoteLoad.crypto,
      );

      _applyLoadedSessions(
        parsed,
        responseRecognized: remoteLoad.responseRecognized,
        rawCount: remoteLoad.sessionItems.length,
      );
      _emitReadyState();
      await machinesFuture;
      unawaited(_warmSessionPreviewData(parsed.sessionsMap.values.toList()));
      _logSessionParseFailures(parsed);
      Logger.info(
        'Sessions loaded: ${parsed.sessionsMap.length} '
        '(raw=${remoteLoad.sessionItems.length}, '
        'confirmed=${parsed.remoteSessionIds.length})',
      );
    } catch (error) {
      await _handleLoadSessionsError(error);
    } finally {
      _loadSessionsInFlight = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<bool> _restoreCachedSessionsIfNeeded() async {
    if (_repository.sessionsMap.isNotEmpty) {
      return true;
    }
    final restored = await _restoreCachedSessions();
    if (restored.isEmpty) {
      return false;
    }
    _repository.applySessions(restored.sessions);
    for (final entry in restored.sessionMessagesById.entries) {
      _repository.replaceMessages(
        entry.key,
        entry.value.messages,
        preserveOptimisticMessages: false,
      );
    }
    _sessionLastSeq.addAll(restored.lastSeqBySessionId);
    _emitReadyState();
    return true;
  }

  bool _shouldSkipSessionReload({
    required bool force,
    required bool hasCachedSessions,
  }) {
    return !force &&
        hasCachedSessions &&
        _lastSessionsLoadedAt != null &&
        DateTime.now().difference(_lastSessionsLoadedAt!) <
            const Duration(seconds: 2);
  }

  Future<void> syncSessionsIfStale({
    Duration minAge = _sessionListAutoSyncMinAge,
  }) async {
    if (_loadSessionsInFlight != null) {
      return _loadSessionsInFlight!;
    }
    if (_repository.sessionsMap.isEmpty || _lastRemoteSessionIds.isEmpty) {
      return loadSessions(force: true);
    }

    final lastLoadedAt = _lastSessionsLoadedAt;
    if (lastLoadedAt == null ||
        DateTime.now().difference(lastLoadedAt) >= minAge) {
      return loadSessions(force: true);
    }
  }

  Future<_RemoteSessionLoadResult> _fetchRemoteSessionLoad() async {
    final response = await ApiService.instance.get<dynamic>(
      '/v1/sessions',
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    final responseRecognized = _containsListPayloadKey(
      response,
      'sessions',
      fallbackKeys: const ['items', 'data', 'results'],
    );
    final sessionItems = _extractListPayload(
      response,
      'sessions',
      fallbackKeys: const ['items', 'data', 'results'],
    );
    final responseMap = _asStringMap(response);
    Logger.info(
      'Sessions response extracted ${sessionItems.length} items '
      '(recognized=$responseRecognized, '
      'keys=${responseMap?.keys.take(6).join(",") ?? "none"})',
    );

    final sessionPreferences = await _preferencesService.loadAll();
    final secretKey = await _tokenStorage.getSecretKey();
    final crypto = secretKey != null && secretKey.isNotEmpty
        ? await CryptoService.instance
        : null;
    return _RemoteSessionLoadResult(
      responseRecognized: responseRecognized,
      sessionItems: sessionItems,
      sessionPreferences: sessionPreferences,
      secretKey: secretKey,
      crypto: crypto,
    );
  }
}
