part of 'session_models.dart';

/// 会话模型
class Session {
  final String id;
  final int? seq;
  final String title;
  final List<dynamic> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool active;
  final DateTime? activeAt;
  final String? tag;
  final String? path;
  final Map<String, dynamic>? metadata;
  final int? metadataVersion;
  final String? permissionMode;
  final String? modelMode;
  final String? draft;
  final Map<String, dynamic>? agentState;
  final int? agentStateVersion;
  final List<Todo>? todos;
  final PresenceStatus? presence;
  final bool? thinking;
  final DateTime? thinkingAt;
  final LatestUsage? latestUsage;

  /// Pre-computed preview fields for session list — avoids loading all messages.
  /// Computed by repository when messages change, persisted in local snapshot.
  final String? previewText;
  final DateTime? lastMessageAt;
  /// Stored as `SessionListStatusKind.name` string — parsed in UI layer.
  final String? listStatusKind;

  const Session({
    required this.id,
    this.seq,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    required this.active,
    this.activeAt,
    this.tag,
    this.path,
    this.metadata,
    this.metadataVersion,
    this.permissionMode,
    this.modelMode,
    this.draft,
    this.agentState,
    this.agentStateVersion,
    this.todos,
    this.presence,
    this.thinking,
    this.thinkingAt,
    this.latestUsage,
    this.previewText,
    this.lastMessageAt,
    this.listStatusKind,
  });

  Session copyWith({
    String? id,
    int? seq,
    String? title,
    List<dynamic>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? active,
    Object? activeAt = _sessionFieldUnset,
    String? tag,
    String? path,
    Map<String, dynamic>? metadata,
    int? metadataVersion,
    Object? permissionMode = _sessionFieldUnset,
    Object? modelMode = _sessionFieldUnset,
    Object? draft = _sessionFieldUnset,
    Map<String, dynamic>? agentState,
    int? agentStateVersion,
    List<Todo>? todos,
    PresenceStatus? presence,
    bool? thinking,
    Object? thinkingAt = _sessionFieldUnset,
    LatestUsage? latestUsage,
    Object? previewText = _sessionFieldUnset,
    Object? lastMessageAt = _sessionFieldUnset,
    Object? listStatusKind = _sessionFieldUnset,
  }) {
    return Session(
      id: id ?? this.id,
      seq: seq ?? this.seq,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      active: active ?? this.active,
      activeAt: identical(activeAt, _sessionFieldUnset)
          ? this.activeAt
          : activeAt as DateTime?,
      tag: tag ?? this.tag,
      path: path ?? this.path,
      metadata: metadata ?? this.metadata,
      metadataVersion: metadataVersion ?? this.metadataVersion,
      permissionMode: identical(permissionMode, _sessionFieldUnset)
          ? this.permissionMode
          : permissionMode as String?,
      modelMode: identical(modelMode, _sessionFieldUnset)
          ? this.modelMode
          : modelMode as String?,
      draft:
          identical(draft, _sessionFieldUnset) ? this.draft : draft as String?,
      agentState: agentState ?? this.agentState,
      agentStateVersion: agentStateVersion ?? this.agentStateVersion,
      todos: todos ?? this.todos,
      presence: presence ?? this.presence,
      thinking: thinking ?? this.thinking,
      thinkingAt: identical(thinkingAt, _sessionFieldUnset)
          ? this.thinkingAt
          : thinkingAt as DateTime?,
      latestUsage: latestUsage ?? this.latestUsage,
      previewText: identical(previewText, _sessionFieldUnset)
          ? this.previewText
          : previewText as String?,
      lastMessageAt: identical(lastMessageAt, _sessionFieldUnset)
          ? this.lastMessageAt
          : lastMessageAt as DateTime?,
      listStatusKind: identical(listStatusKind, _sessionFieldUnset)
          ? this.listStatusKind
          : listStatusKind as String?,
    );
  }

  Map<String, dynamic> toJson() => _sessionToJson(this);

  factory Session.fromJson(Map<String, dynamic> json) => _sessionFromJson(json);
}
