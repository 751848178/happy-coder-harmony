part of 'session_service.dart';

class _SessionServiceCatalogCoordinator {
  static const Duration sessionListAutoSyncMinAge = Duration(seconds: 12);

  const _SessionServiceCatalogCoordinator(this._notifier);

  final SessionServiceNotifier _notifier;

  Future<void> loadSessions({bool force = false}) async {
    if (_notifier._loadSessionsInFlight != null) {
      Logger.info('Sessions load already in flight, joining existing request');
      return _notifier._loadSessionsInFlight!;
    }

    final completer = Completer<void>();
    _notifier._loadSessionsInFlight = completer.future;

    try {
      final hasCachedSessions = await _restoreCachedSessionsIfNeeded();
      if (_shouldSkipSessionReload(
        force: force,
        hasCachedSessions: hasCachedSessions,
      )) {
        return;
      }

      if (!hasCachedSessions) {
        _notifier._emitLoadingState();
      }

      final remoteLoad = await fetchRemoteSessionLoad();
      _notifier._accountSecret = remoteLoad.secretKey;

      final machinesFuture = loadMachines(
        force: force || _notifier._repository.machinesMap.isEmpty,
        allowFailure: true,
      );
      final parsed = await _notifier._parseRemoteSessions(
        sessionItems: remoteLoad.sessionItems,
        sessionPreferences: remoteLoad.sessionPreferences,
        secretKey: remoteLoad.secretKey,
        crypto: remoteLoad.crypto,
      );

      _notifier._applyLoadedSessions(
        parsed,
        responseRecognized: remoteLoad.responseRecognized,
        rawCount: remoteLoad.sessionItems.length,
      );
      await machinesFuture;
      _notifier._logSessionParseFailures(parsed);
      Logger.info(
        'Sessions loaded: ${parsed.sessionsMap.length} '
        '(raw=${remoteLoad.sessionItems.length}, '
        'confirmed=${parsed.remoteSessionIds.length})',
      );
      await _reactivateInactiveSessions(parsed.sessionsMap.values);
    } catch (error) {
      await _notifier._handleLoadSessionsError(error);
    } finally {
      _notifier._loadSessionsInFlight = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<void> loadMachines({
    bool force = false,
    bool allowFailure = false,
  }) async {
    if (_notifier._loadMachinesInFlight != null) {
      return _notifier._loadMachinesInFlight!;
    }

    final hasCachedMachines = _notifier._repository.machinesMap.isNotEmpty;
    if (!force &&
        hasCachedMachines &&
        _notifier._lastMachinesLoadedAt != null &&
        DateTime.now().difference(_notifier._lastMachinesLoadedAt!) <
            const Duration(seconds: 2)) {
      return;
    }

    final completer = Completer<void>();
    _notifier._loadMachinesInFlight = completer.future;

    try {
      final response = await ApiService.instance.get<dynamic>('/v1/machines');
      final machineItems = response is List
          ? response
          : _notifier._extractListPayload(
              _notifier._asStringMap(response),
              'machines',
            );
      final secretKey = _notifier._accountSecret ??
          await _notifier._tokenStorage.getSecretKey();
      final crypto = secretKey != null && secretKey.isNotEmpty
          ? await CryptoService.instance
          : null;
      final nextKeys = <String, Uint8List?>{};
      final machines = <Machine>[];

      for (final item in machineItems) {
        final machineJson = _notifier._asStringMap(item);
        if (machineJson == null) {
          continue;
        }

        try {
          final encryptedDataKey = machineJson['dataEncryptionKey']?.toString();
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
          final metadata = await _notifier._decodeEncryptedJsonMap(
            machineJson['metadata'],
            dataKey: dataKey,
            secretKey: secretKey,
          );
          final parsedMachine = Machine.fromJson({
            ...machineJson,
            if (metadata != null) 'metadata': metadata,
          });
          machines.add(parsedMachine.copyWith(
            metadata: metadata ?? parsedMachine.metadata,
          ));
          nextKeys[parsedMachine.id] = dataKey;
        } catch (error) {
          Logger.warning('Failed to parse machine: $error');
        }
      }

      _notifier._machineDataKeys
        ..clear()
        ..addAll(nextKeys);
      _notifier._repository.applyMachines(machines, replace: true);
      _notifier._lastMachinesLoadedAt = DateTime.now();
      await _reactivateInactiveMachines(machines);
    } catch (error) {
      Logger.error('Load machines error: $error');
      if (!allowFailure) {
        rethrow;
      }
    } finally {
      _notifier._loadMachinesInFlight = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<bool> _restoreCachedSessionsIfNeeded() async {
    if (_notifier._repository.sessionsMap.isNotEmpty) {
      return true;
    }
    final restored = await _notifier._restoreCachedSessions();
    if (restored.isEmpty) {
      return false;
    }
    _notifier._repository.applySessions(restored.sessions);
    for (final entry in restored.sessionMessagesById.entries) {
      _notifier._repository.replaceMessages(
        entry.key,
        entry.value.messages,
        preserveOptimisticMessages: false,
      );
    }
    _notifier._sessionLastSeq.addAll(restored.lastSeqBySessionId);
    _notifier._scheduleEmitReadyState();
    return true;
  }

  bool _shouldSkipSessionReload({
    required bool force,
    required bool hasCachedSessions,
  }) {
    return !force &&
        hasCachedSessions &&
        _notifier._lastSessionsLoadedAt != null &&
        DateTime.now().difference(_notifier._lastSessionsLoadedAt!) <
            const Duration(seconds: 2);
  }

  Future<void> syncSessionsIfStale({
    Duration minAge = sessionListAutoSyncMinAge,
  }) async {
    if (_notifier._loadSessionsInFlight != null) {
      return _notifier._loadSessionsInFlight!;
    }
    if (_notifier._repository.sessionsMap.isEmpty ||
        _notifier._lastRemoteSessionIds.isEmpty) {
      return loadSessions(force: true);
    }

    final lastLoadedAt = _notifier._lastSessionsLoadedAt;
    if (lastLoadedAt == null ||
        DateTime.now().difference(lastLoadedAt) >= minAge) {
      return loadSessions(force: true);
    }
  }

  Future<_RemoteSessionLoadResult> fetchRemoteSessionLoad() async {
    final response = await ApiService.instance.get<dynamic>(
      '/v1/sessions',
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    final responseRecognized = _notifier._containsListPayloadKey(
      response,
      'sessions',
      fallbackKeys: const ['items', 'data', 'results'],
    );
    final sessionItems = _notifier._extractListPayload(
      response,
      'sessions',
      fallbackKeys: const ['items', 'data', 'results'],
    );
    final responseMap = _notifier._asStringMap(response);
    Logger.info(
      'Sessions response extracted ${sessionItems.length} items '
      '(recognized=$responseRecognized, '
      'keys=${responseMap?.keys.take(6).join(",") ?? "none"})',
    );

    final sessionPreferences = await _notifier._preferencesService.loadAll();
    final secretKey = await _notifier._tokenStorage.getSecretKey();
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

  Future<void> _reactivateInactiveMachines(List<Machine> machines) async {
    final inactive = machines.where((m) => !m.active).toList();
    if (inactive.isEmpty) return;

    Logger.info('Reactivating ${inactive.length} inactive machines...');
    final reactivated = <Machine>[];
    await Future.wait(inactive.map((machine) async {
      try {
        await ApiService.instance.post<dynamic>(
          '/v1/machines/${machine.id}/activate',
        );
        reactivated.add(machine.copyWith(active: true));
        Logger.info('Reactivated machine: ${machine.name}');
      } catch (e) {
        Logger.warning('Failed to reactivate machine ${machine.name}: $e');
      }
    }));
    if (reactivated.isNotEmpty) {
      _notifier._repository.applyMachines(reactivated);
    }
  }

  Future<void> _reactivateInactiveSessions(
    Iterable<Session> sessions,
  ) async {
    final inactive = sessions.where((s) => !s.active).toList();
    if (inactive.isEmpty) return;

    Logger.info('Reactivating ${inactive.length} inactive sessions...');
    final reactivated = <Session>[];
    await Future.wait(inactive.map((session) async {
      try {
        await ApiService.instance.post<dynamic>(
          '/v1/sessions/${session.id}/unarchive',
        );
        reactivated.add(session.copyWith(active: true));
        Logger.info('Reactivated session: ${session.id}');
      } catch (e) {
        Logger.warning('Failed to reactivate session ${session.id}: $e');
      }
    }));
    if (reactivated.isNotEmpty) {
      _notifier._repository.applySessions(reactivated);
    }
  }
}
