import 'dart:convert';

import '../../../shared/platform/platform_storage.dart';

part 'session_grouping_service_models.dart';
part 'session_grouping_service_storage.dart';

const _legacyUnavailableDefaultGroupLabel = '暂不可对话';
const _expiredDefaultGroupLabel = '过期会话';

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
    final next = (await load()).copyWith(useCustomGroups: value);
    await _persist(next);
    return next;
  }

  Future<SessionGroupingState> createGroup(String name) async {
    final state = await load();
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return state;
    }
    _ensureUniqueName(state.groups, candidate: trimmed);
    final next = state.copyWith(
      groups: <SessionGroup>[
        ...state.groups,
        SessionGroup(
          id: 'group_${DateTime.now().microsecondsSinceEpoch}',
          name: trimmed,
          sessionIds: const <String>[],
        ),
      ],
      useCustomGroups: true,
    );
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
    _ensureUniqueName(state.groups, candidate: trimmed, excludingGroupId: groupId);
    final next = state.copyWith(
      groups: state.groups
          .map((group) => group.id == groupId ? group.copyWith(name: trimmed) : group)
          .toList(),
    );
    await _persist(next);
    return next;
  }

  Future<SessionGroupingState> deleteGroup(String groupId) async {
    final next = (await load()).copyWith(
      groups: (await load()).groups.where((group) => group.id != groupId).toList(),
    );
    await _persist(next);
    return next;
  }

  Future<SessionGroupingState> toggleGroupCollapsed(String groupId) async {
    final state = await load();
    final next = state.copyWith(
      groups: state.groups
          .map((group) => group.id == groupId
              ? group.copyWith(collapsed: !group.collapsed)
              : group)
          .toList(),
    );
    await _persist(next);
    return next;
  }

  Future<SessionGroupingState> toggleUngroupedCollapsed() async {
    final state = await load();
    final next = state.copyWith(ungroupedCollapsed: !state.ungroupedCollapsed);
    await _persist(next);
    return next;
  }

  Future<SessionGroupingState> toggleDefaultGroupCollapsed(
    String label, {
    bool defaultCollapsed = false,
  }) async {
    final state = await load();
    final nextCollapsed = Set<String>.from(state.collapsedDefaultGroups);
    final nextExpanded = Set<String>.from(state.expandedDefaultGroups);
    if (defaultCollapsed) {
      nextExpanded.contains(label) ? nextExpanded.remove(label) : nextExpanded.add(label);
    } else {
      nextCollapsed.contains(label) ? nextCollapsed.remove(label) : nextCollapsed.add(label);
    }
    final next = state.copyWith(
      collapsedDefaultGroups: nextCollapsed,
      expandedDefaultGroups: nextExpanded,
    );
    await _persist(next);
    return next;
  }

  Future<SessionGroupingState> assignSession({
    required String sessionId,
    String? groupId,
  }) async {
    final state = await load();
    final next = state.copyWith(
      groups: state.groups.map((group) {
        final nextSessionIds =
            group.sessionIds.where((existingId) => existingId != sessionId).toList();
        if (group.id == groupId && !nextSessionIds.contains(sessionId)) {
          nextSessionIds.add(sessionId);
        }
        return group.copyWith(sessionIds: nextSessionIds);
      }).toList(),
    );
    await _persist(next);
    return next;
  }

  String? groupIdForSession(SessionGroupingState state, String sessionId) {
    for (final group in state.groups) {
      if (group.sessionIds.contains(sessionId)) {
        return group.id;
      }
    }
    return null;
  }
}
