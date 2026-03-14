import 'dart:convert';

import '../../../shared/platform/platform_storage.dart';

class SessionUiState {
  const SessionUiState({
    this.overviewCollapsed = true,
    this.collapseAllTurns = false,
    this.expandedTurnIds = const <String>{},
  });

  final bool overviewCollapsed;
  final bool collapseAllTurns;
  final Set<String> expandedTurnIds;

  bool get isDefault =>
      overviewCollapsed == true &&
      collapseAllTurns == false &&
      expandedTurnIds.isEmpty;

  SessionUiState copyWith({
    bool? overviewCollapsed,
    bool? collapseAllTurns,
    Set<String>? expandedTurnIds,
  }) {
    return SessionUiState(
      overviewCollapsed: overviewCollapsed ?? this.overviewCollapsed,
      collapseAllTurns: collapseAllTurns ?? this.collapseAllTurns,
      expandedTurnIds: expandedTurnIds ?? this.expandedTurnIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overviewCollapsed': overviewCollapsed,
      'collapseAllTurns': collapseAllTurns,
      'expandedTurnIds': expandedTurnIds.toList(),
    };
  }

  factory SessionUiState.fromJson(Map<String, dynamic> json) {
    return SessionUiState(
      overviewCollapsed: json['overviewCollapsed'] != false,
      collapseAllTurns: json['collapseAllTurns'] == true,
      expandedTurnIds: (json['expandedTurnIds'] as List?)
              ?.map((value) => value.toString())
              .toSet() ??
          const <String>{},
    );
  }
}

class SessionUiStateService {
  SessionUiStateService._();

  static final SessionUiStateService instance = SessionUiStateService._();

  static const String _storageKey = 'session_ui_state_v1';

  final PlatformStorage _storage = PlatformStorage.instance;
  Map<String, SessionUiState>? _cache;

  Future<Map<String, SessionUiState>> loadAll() async {
    if (_cache != null) {
      return Map<String, SessionUiState>.from(_cache!);
    }

    final rawValue = await _storage.read(_storageKey);
    if (rawValue == null || rawValue.trim().isEmpty) {
      _cache = <String, SessionUiState>{};
      return <String, SessionUiState>{};
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map) {
        _cache = <String, SessionUiState>{};
        return <String, SessionUiState>{};
      }

      final next = <String, SessionUiState>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          next[entry.key.toString()] = SessionUiState.fromJson(value);
        } else if (value is Map) {
          next[entry.key.toString()] = SessionUiState.fromJson(
            value.map((key, mapValue) => MapEntry(key.toString(), mapValue)),
          );
        }
      }

      _cache = next;
      return Map<String, SessionUiState>.from(next);
    } catch (_) {
      _cache = <String, SessionUiState>{};
      return <String, SessionUiState>{};
    }
  }

  Future<SessionUiState> get(String sessionId) async {
    final all = await loadAll();
    return all[sessionId] ?? const SessionUiState();
  }

  Future<void> update(
    String sessionId, {
    bool? overviewCollapsed,
    bool? collapseAllTurns,
    Set<String>? expandedTurnIds,
  }) async {
    final all = await loadAll();
    final current = all[sessionId] ?? const SessionUiState();
    final next = current.copyWith(
      overviewCollapsed: overviewCollapsed,
      collapseAllTurns: collapseAllTurns,
      expandedTurnIds: expandedTurnIds,
    );

    if (next.isDefault) {
      all.remove(sessionId);
    } else {
      all[sessionId] = next;
    }

    _cache = all;
    await _persist(all);
  }

  Future<void> clearSession(String sessionId) async {
    final all = await loadAll();
    if (!all.containsKey(sessionId)) {
      return;
    }
    all.remove(sessionId);
    _cache = all;
    await _persist(all);
  }

  Future<void> _persist(Map<String, SessionUiState> values) async {
    final serializable = values.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(serializable),
    );
  }
}
