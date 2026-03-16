part of 'session_service.dart';

extension SessionServiceMachineLoaders on SessionServiceNotifier {
  Future<void> loadMachines({
    bool force = false,
    bool allowFailure = false,
  }) async {
    if (_loadMachinesInFlight != null) {
      return _loadMachinesInFlight!;
    }

    final hasCachedMachines = _repository.machinesMap.isNotEmpty;
    if (!force &&
        hasCachedMachines &&
        _lastMachinesLoadedAt != null &&
        DateTime.now().difference(_lastMachinesLoadedAt!) <
            const Duration(seconds: 2)) {
      return;
    }

    final completer = Completer<void>();
    _loadMachinesInFlight = completer.future;

    try {
      final response = await ApiService.instance.get<dynamic>('/v1/machines');
      final machineItems = response is List
          ? response
          : _extractListPayload(_asStringMap(response), 'machines');
      final secretKey = _accountSecret ?? await _tokenStorage.getSecretKey();
      final crypto = secretKey != null && secretKey.isNotEmpty
          ? await CryptoService.instance
          : null;
      final nextKeys = <String, Uint8List?>{};
      final machines = <Machine>[];

      for (final item in machineItems) {
        final machineJson = _asStringMap(item);
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
          final metadata = await _decodeEncryptedJsonMap(
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

      _machineDataKeys
        ..clear()
        ..addAll(nextKeys);
      _repository.applyMachines(machines, replace: true);
      _lastMachinesLoadedAt = DateTime.now();
    } catch (error) {
      Logger.error('Load machines error: $error');
      if (!allowFailure) {
        rethrow;
      }
    } finally {
      _loadMachinesInFlight = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }
}
