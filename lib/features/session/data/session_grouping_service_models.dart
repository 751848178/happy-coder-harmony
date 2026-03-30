part of 'session_grouping_service.dart';

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sessionIds': sessionIds,
        'collapsed': collapsed,
      };

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
    this.collapsedDefaultGroups = const <String>{},
    this.expandedDefaultGroups = const <String>{},
  });

  final bool useCustomGroups;
  final List<SessionGroup> groups;
  final bool ungroupedCollapsed;
  final Set<String> collapsedDefaultGroups;
  final Set<String> expandedDefaultGroups;

  Map<String, dynamic> toJson() => {
        'useCustomGroups': useCustomGroups,
        'groups': groups.map((group) => group.toJson()).toList(),
        'ungroupedCollapsed': ungroupedCollapsed,
        'collapsedDefaultGroups': collapsedDefaultGroups.toList(),
        'expandedDefaultGroups': expandedDefaultGroups.toList(),
      };

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
                  value.map((key, groupValue) =>
                      MapEntry(key.toString(), groupValue)),
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
      collapsedDefaultGroups: _normalizeDefaultGroupLabels(
        (json['collapsedDefaultGroups'] as List?)
                ?.map((value) => value.toString())
                .toSet() ??
            const <String>{},
      ),
      expandedDefaultGroups: _normalizeDefaultGroupLabels(
        (json['expandedDefaultGroups'] as List?)
                ?.map((value) => value.toString())
                .toSet() ??
            const <String>{},
      ),
    );
  }

  SessionGroupingState copyWith({
    bool? useCustomGroups,
    List<SessionGroup>? groups,
    bool? ungroupedCollapsed,
    Set<String>? collapsedDefaultGroups,
    Set<String>? expandedDefaultGroups,
  }) {
    return SessionGroupingState(
      useCustomGroups: useCustomGroups ?? this.useCustomGroups,
      groups: groups ?? this.groups,
      ungroupedCollapsed: ungroupedCollapsed ?? this.ungroupedCollapsed,
      collapsedDefaultGroups:
          collapsedDefaultGroups ?? this.collapsedDefaultGroups,
      expandedDefaultGroups:
          expandedDefaultGroups ?? this.expandedDefaultGroups,
    );
  }
}

Set<String> _normalizeDefaultGroupLabels(Set<String> labels) {
  if (!labels.contains(_legacyUnavailableDefaultGroupLabel)) {
    return labels;
  }
  final normalized = Set<String>.from(labels)
    ..remove(_legacyUnavailableDefaultGroupLabel)
    ..add(_expiredDefaultGroupLabel);
  return normalized;
}

class SessionGroupNameConflictException implements Exception {
  const SessionGroupNameConflictException(this.name);

  final String name;

  @override
  String toString() => '分组名称已存在: $name';
}
