part of 'session_repository.dart';

extension SessionRepositorySessions on SessionRepository {
  List<Session> getAllSessions() {
    return _sessions.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<Session> getActiveSessions() {
    return _sessions.values.where((s) => s.active).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Session? getSession(String sessionId) => _sessions[sessionId];

  void applySessions(List<Session> sessions, {bool replace = false}) {
    var changedCount = 0;
    if (replace) {
      final nextIds = sessions.map((session) => session.id).toSet();
      final staleIds = _sessions.keys
          .where((sessionId) => !nextIds.contains(sessionId))
          .toList();
      for (final staleId in staleIds) {
        _sessions.remove(staleId);
        _sessionMessages.remove(staleId);
        changedCount++;
      }
    }
    for (final session in sessions) {
      final existing = _sessions[session.id];
      if (existing != null &&
          jsonEncode(existing.toJson()) == jsonEncode(session.toJson())) {
        continue;
      }
      _sessions[session.id] = session;
      changedCount++;
    }
    if (changedCount == 0) {
      return;
    }
    _stateController.add(
      SessionStateChange(type: SessionChangeType.sessionsUpdated),
    );
  }

  void updateSessionDraft(String sessionId, String? draft) {
    final existing = _sessions[sessionId];
    if (existing == null) return;

    _sessions[sessionId] = existing.copyWith(draft: draft);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.draftUpdated,
        sessionId: sessionId,
      ),
    );
  }

  void updateSessionPermissionMode(String sessionId, String mode) {
    final existing = _sessions[sessionId];
    if (existing == null) return;

    _sessions[sessionId] = existing.copyWith(permissionMode: mode);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.permissionModeUpdated,
        sessionId: sessionId,
      ),
    );
  }

  void updateSessionModelMode(String sessionId, String mode) {
    final existing = _sessions[sessionId];
    if (existing == null) return;

    _sessions[sessionId] = existing.copyWith(modelMode: mode);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.modelModeUpdated,
        sessionId: sessionId,
      ),
    );
  }

  void deleteSession(String sessionId) {
    _sessions.remove(sessionId);
    _sessionMessages.remove(sessionId);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.sessionDeleted,
        sessionId: sessionId,
      ),
    );
    Logger.info('Deleted session: $sessionId');
  }

  void applyMachines(List<Machine> machines, {bool replace = false}) {
    var changed = false;
    if (replace) {
      final nextIds = machines.map((machine) => machine.id).toSet();
      final staleIds = _machines.keys
          .where((machineId) => !nextIds.contains(machineId))
          .toList();
      for (final staleId in staleIds) {
        _machines.remove(staleId);
        changed = true;
      }
    }

    for (final machine in machines) {
      final existing = _machines[machine.id];
      if (existing != null &&
          jsonEncode(existing.toJson()) == jsonEncode(machine.toJson())) {
        continue;
      }
      _machines[machine.id] = machine;
      changed = true;
    }

    if (!changed) {
      return;
    }

    _stateController.add(
      SessionStateChange(type: SessionChangeType.machinesUpdated),
    );
    Logger.info('Applied ${machines.length} machines');
  }

  Machine? getMachine(String machineId) => _machines[machineId];

  List<Machine> getAllMachines() {
    return _machines.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Map<String, Session> get sessionsMap => Map.from(_sessions);

  Map<String, Machine> get machinesMap => Map.from(_machines);

  void clearAll() {
    _sessions.clear();
    _sessionMessages.clear();
    _machines.clear();
    _stateController.add(
      SessionStateChange(type: SessionChangeType.cleared),
    );
    Logger.info('Cleared all session data');
  }

  void dispose() {
    _stateController.close();
  }
}
