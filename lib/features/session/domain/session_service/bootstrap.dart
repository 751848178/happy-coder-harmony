part of 'session_service.dart';

extension SessionServiceSessionBootstrap on SessionServiceNotifier {
  Future<void> _persistSessionCreationModes({
    required String sessionId,
    String? permissionMode,
    String? modelMode,
  }) async {
    final normalizedPermissionMode = _normalizeOptionalValue(permissionMode);
    final normalizedModelMode = _normalizeOptionalValue(modelMode);

    await _preferencesService.update(
      sessionId: sessionId,
      permissionMode: normalizedPermissionMode == 'default'
          ? null
          : normalizedPermissionMode,
      modelMode: normalizedModelMode == 'default' ? null : normalizedModelMode,
    );

    if (normalizedPermissionMode != null) {
      _repository.updateSessionPermissionMode(
          sessionId, normalizedPermissionMode);
      unawaited(_syncSessionMetadata(
        sessionId: sessionId,
        permissionMode: normalizedPermissionMode,
      ).catchError((Object error) {
        Logger.warning(
            'Failed to sync created session permission mode: $error');
      }));
    }

    if (normalizedModelMode != null) {
      _repository.updateSessionModelMode(sessionId, normalizedModelMode);
      unawaited(_syncSessionMetadata(
        sessionId: sessionId,
        modelMode: normalizedModelMode,
      ).catchError((Object error) {
        Logger.warning('Failed to sync created session model mode: $error');
      }));
    }
  }

  void _seedLocalSpawnedSession({
    required String sessionId,
    required String machineId,
    required String directory,
    required String agent,
    String? permissionMode,
    String? modelMode,
  }) {
    if (_repository.getSession(sessionId) != null) {
      return;
    }

    final machine = _repository.getMachine(machineId);
    final machineMetadata = machine?.metadata ?? const <String, dynamic>{};
    final resolvedPermissionMode = _resolveLocalSessionMode(
      preferred: permissionMode,
      explicit: null,
      metadataValue: null,
    );
    final resolvedModelMode = _resolveLocalSessionMode(
      preferred: modelMode,
      explicit: null,
      metadataValue: null,
    );
    final metadata = <String, dynamic>{
      'machineId': machineId,
      'path': directory,
      'flavor': agent,
      if ((machineMetadata['host']?.toString() ?? '').isNotEmpty)
        'host': machineMetadata['host'].toString()
      else if (machine != null)
        'host': machine.name,
      if ((machineMetadata['homeDir']?.toString() ?? '').isNotEmpty)
        'homeDir': machineMetadata['homeDir'].toString(),
      if ((machineMetadata['platform']?.toString() ?? '').isNotEmpty)
        'platform': machineMetadata['platform'].toString(),
      if ((machineMetadata['version']?.toString() ?? '').isNotEmpty)
        'version': machineMetadata['version'].toString(),
      if (resolvedPermissionMode != null)
        'currentOperatingModeCode': resolvedPermissionMode,
      if (resolvedModelMode != null) 'currentModelCode': resolvedModelMode,
    };
    final now = DateTime.now();
    final fallbackId =
        sessionId.length > 8 ? sessionId.substring(0, 8) : sessionId;

    _repository.applySessions([
      Session(
        id: sessionId,
        title: _resolveSessionTitle(
          path: directory,
          summary: null,
          name: null,
          title: null,
          fallback: '会话 $fallbackId',
        ),
        messages: const [],
        createdAt: now,
        updatedAt: now,
        active: true,
        tag: 'session',
        path: directory,
        metadata: metadata,
        permissionMode: resolvedPermissionMode,
        modelMode: resolvedModelMode,
      ),
    ]);
  }
}
