part of 'session_repository.dart';

extension SessionRepositorySessions on SessionRepository {
  List<Session> getAllSessions() {
    return _sessions.values.toList()..sort(compareSessionsByRecency);
  }

  List<Session> getActiveSessions() {
    return _sessions.values.where((s) => s.active).toList()
      ..sort(compareSessionsByRecency);
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
      if (existing != null && _sessionsEqual(existing, session)) {
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
      if (existing != null && _machinesEqual(existing, machine)) {
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

  Map<String, Session> get sessionsMap =>
      UnmodifiableMapView(_sessions);

  Map<String, Machine> get machinesMap =>
      UnmodifiableMapView(_machines);

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

bool _sessionsEqual(Session current, Session next) {
  return current.id == next.id &&
      current.seq == next.seq &&
      current.title == next.title &&
      _sessionRepositoryDeepEquality.equals(current.messages, next.messages) &&
      current.createdAt == next.createdAt &&
      current.updatedAt == next.updatedAt &&
      current.active == next.active &&
      current.activeAt == next.activeAt &&
      current.tag == next.tag &&
      current.path == next.path &&
      _sessionRepositoryDeepEquality.equals(current.metadata, next.metadata) &&
      current.metadataVersion == next.metadataVersion &&
      current.permissionMode == next.permissionMode &&
      current.modelMode == next.modelMode &&
      current.draft == next.draft &&
      _sessionRepositoryDeepEquality.equals(
        current.agentState,
        next.agentState,
      ) &&
      current.agentStateVersion == next.agentStateVersion &&
      _sessionRepositoryDeepEquality.equals(
        _todosToComparable(current.todos),
        _todosToComparable(next.todos),
      ) &&
      _sessionRepositoryDeepEquality.equals(
        current.presence?.toJson(),
        next.presence?.toJson(),
      ) &&
      current.thinking == next.thinking &&
      current.thinkingAt == next.thinkingAt &&
      _sessionRepositoryDeepEquality.equals(
        current.latestUsage?.toJson(),
        next.latestUsage?.toJson(),
      ) &&
      current.previewText == next.previewText &&
      current.lastMessageAt == next.lastMessageAt &&
      current.listStatusKind == next.listStatusKind;
}

bool _machinesEqual(Machine current, Machine next) {
  return current.id == next.id &&
      current.seq == next.seq &&
      current.name == next.name &&
      current.platform == next.platform &&
      current.createdAt == next.createdAt &&
      current.updatedAt == next.updatedAt &&
      current.active == next.active &&
      current.activeAt == next.activeAt &&
      _sessionRepositoryDeepEquality.equals(current.metadata, next.metadata) &&
      current.metadataVersion == next.metadataVersion;
}

List<Map<String, dynamic>>? _todosToComparable(List<domain.Todo>? todos) {
  if (todos == null) {
    return null;
  }
  return todos.map((todo) => todo.toJson()).toList(growable: false);
}
