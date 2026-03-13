import 'dart:convert';

import '../../../shared/platform/platform_storage.dart';

class SessionGroup {
  const SessionGroup({
    required this.id,
    required this.name,
    required this.sessionIds,
    this.collapsed = false,
  });

  final String id;
  final String name;
  final List<String> sessionIds;
  final bool collapsed;

  SessionGroup copyWith({
    String? id,
    String? name,
    List<String>? sessionIds,
    bool? collapsed,
  }) {
    return SessionGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      sessionIds: sessionIds ?? this.sessionIds,
      collapsed: collapsed ?? this.collapsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sessionIds': sessionIds,
      'collapsed': collapsed,
    };
  }

  factory SessionGroup.fromJson(Map<String, dynamic> json) {
    final sessionIds = json['sessionIds'] is List
        ? (json['sessionIds'] as List<dynamic>)
            .map((value) => value.toString())
            .toList()
        : const <String>[];
    return SessionGroup(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '未命名分组',
      sessionIds: sessionIds,
      collapsed: json['collapsed'] == true,
    );
  }
}

class SessionGroupingState {
  const SessionGroupingState({
    this.useCustomGroups = false,
    this.groups = const <SessionGroup>[],
    this.ungroupedCollapsed = false,
  });

  final bool useCustomGroups;
  final List<SessionGroup> groups;
  final bool ungroupedCollapsed;

  Map<String, dynamic> toJson() {
    return {
      'useCustomGroups': useCustomGroups,
      'groups': groups.map((group) => group.toJson()).toList(),
      'ungroupedCollapsed': ungroupedCollapsed,
    };
  }

  factory SessionGroupingState.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'];
    final groups = rawGroups is List
        ? rawGroups
            .map((value) {
              if (value is Map<String, dynamic>) {
                return SessionGroup.fromJson(value);
              }
              if (value is Map) {
                return SessionGroup.fromJson(
                  value.map(
                    (key, groupValue) => MapEntry(key.toString(), groupValue),
                  ),
                );
              }
              return null;
            })
            .whereType<SessionGroup>()
            .toList()
        : const <SessionGroup>[];
    return SessionGroupingState(
      useCustomGroups: json['useCustomGroups'] == true,
      groups: groups,
      ungroupedCollapsed: json['ungroupedCollapsed'] == true,
    );
  }

  SessionGroupingState copyWith({
    bool? useCustomGroups,
    List<SessionGroup>? groups,
    bool? ungroupedCollapsed,
  }) {
    return SessionGroupingState(
      useCustomGroups: useCustomGroups ?? this.useCustomGroups,
      groups: groups ?? this.groups,
      ungroupedCollapsed: ungroupedCollapsed ?? this.ungroupedCollapsed,
    );
  }
}

class SessionGroupNameConflictException implements Exception {
  const SessionGroupNameConflictException(this.name);

  final String name;

  @override
  String toString() => '分组名称已存在: $name';
}

class SessionGroupingService {
  SessionGroupingService._();

  static final SessionGroupingService instance = SessionGroupingService._();

  static const String _storageKey = 'session_grouping_v1';

  final PlatformStorage _storage = PlatformStorage.instance;
  SessionGroupingState? _cache;

  Future<SessionGroupingState> load() async {
    if (_cache != null) {
      return _cache!;
    }

    final raw = await _storage.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _cache = const SessionGroupingState();
      return _cache!;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _cache = SessionGroupingState.fromJson(decoded);
      } else if (decoded is Map) {
        _cache = SessionGroupingState.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      } else {
        _cache = const SessionGroupingState();
      }
    } catch (_) {
      _cache = const SessionGroupingState();
    }
    return _cache!;
  }

  Future<SessionGroupingState> setUseCustomGroups(bool value) async {
    final state = await load();
    final next = state.copyWith(useCustomGroups: value);
    await _persist(next);
    return next;
  }

  Future<SessionGroupingState> createGroup(String name) async {
    final state = await load();
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return state;
    }
    _ensureUniqueName(
      state.groups,
      candidate: trimmed,
    );

    final nextGroups = <SessionGroup>[
      ...state.groups,
      SessionGroup(
        id: 'group_${DateTime.now().microsecondsSinceEpoch}',
        name: trimmed,
        sessionIds: const <String>[],
      ),
    ];
    final next = state.copyWith(groups: nextGroups, useCustomGroups: true);
    await _persist(next);
    return next;
  }

  Future<SessionGroupingState> renameGroup({
    required String groupId,
    required String name,
  }) async {
    final state = await load();
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return state;
    }
    _ensureUniqueName(
      state.groups,
      candidate: trimmed,
      excludingGroupId: groupId,
    );
    final next = state.copyWith(
      groups: state.groups
          .map(
            (group) =>
                group.id == groupId ? group.copyWith(name: trimmed) : group,
          )
          .toList(),
    );
    await _persist(next);
    return next;
  }

  Future<SessionGroupingState> deleteGroup(String groupId) async {
    final state = await load();
    final next = state.copyWith(
      groups: state.groups.where((group) => group.id != groupId).toList(),
    );
    await _persist(next);
    return next;
  }

  Future<SessionGroupingState> toggleGroupCollapsed(String groupId) async {
    final state = await load();
    final next = state.copyWith(
      groups: state.groups
          .map(
            (group) => group.id == groupId
                ? group.copyWith(collapsed: !group.collapsed)
                : group,
          )
          .toList(),
    );
    await _persist(next);
    return next;
  }

  Future<SessionGroupingState> toggleUngroupedCollapsed() async {
    final state = await load();
    final next = state.copyWith(
      ungroupedCollapsed: !state.ungroupedCollapsed,
    );
    await _persist(next);
    return next;
  }

  Future<SessionGroupingState> assignSession({
    required String sessionId,
    String? groupId,
  }) async {
    final state = await load();
    final nextGroups = state.groups.map((group) {
      final nextSessionIds = group.sessionIds
          .where((existingId) => existingId != sessionId)
          .toList();
      if (group.id == groupId && !nextSessionIds.contains(sessionId)) {
        nextSessionIds.add(sessionId);
      }
      return group.copyWith(sessionIds: nextSessionIds);
    }).toList();
    final next = state.copyWith(groups: nextGroups);
    await _persist(next);
    return next;
  }

  String? groupIdForSession(
    SessionGroupingState state,
    String sessionId,
  ) {
    for (final group in state.groups) {
      if (group.sessionIds.contains(sessionId)) {
        return group.id;
      }
    }
    return null;
  }

  Future<void> _persist(SessionGroupingState state) async {
    _cache = state;
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(state.toJson()),
    );
  }

  void _ensureUniqueName(
    List<SessionGroup> groups, {
    required String candidate,
    String? excludingGroupId,
  }) {
    final normalized = candidate.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }
    final exists = groups.any(
      (group) =>
          group.id != excludingGroupId &&
          group.name.trim().toLowerCase() == normalized,
    );
    if (exists) {
      throw SessionGroupNameConflictException(candidate);
    }
  }
}
