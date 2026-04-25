part of 'reducer.dart';

enum MessageType {
  text,
  toolCall,
  permissionRequest,
  turnClose,
  agentEvent,
  error,
}

class ReducerMessage {
  ReducerMessage({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.text,
    this.metadata,
    this.tool,
    this.permission,
    this.turnClose,
    this.subagentId,
    this.children = const [],
  });

  final String id;
  final String kind;
  final DateTime createdAt;
  final String? text;
  final Map<String, dynamic>? metadata;
  final ToolInfo? tool;
  final PermissionRequest? permission;
  final TurnClose? turnClose;

  /// CUID2 identifier for sub-agent messages.  Non-null when this message
  /// was produced by a sub-agent (e.g. a Claude Task tool invocation).
  final String? subagentId;

  /// Child messages from a sub-agent.  Non-empty when this is a Task/Agent
  /// tool call that spawned a sub-agent whose messages are nested here.
  final List<ReducerMessage> children;

  bool get isSubagentMessage => subagentId != null;

  bool get hasChildren => children.isNotEmpty;

  bool get isText => kind == 'text';
  bool get isToolCall => kind == 'tool-call';
  bool get isPermissionRequest => kind == 'permission-request';
  bool get isTurnClose => kind == 'turn-close';
  bool get isAgentEvent => kind == 'agent-event';
  bool get isError => kind == 'error';

  ReducerMessage copyWith({
    String? id,
    String? kind,
    DateTime? createdAt,
    String? text,
    Map<String, dynamic>? metadata,
    ToolInfo? tool,
    PermissionRequest? permission,
    TurnClose? turnClose,
    String? subagentId,
    List<ReducerMessage>? children,
  }) {
    return ReducerMessage(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      text: text ?? this.text,
      metadata: metadata ?? this.metadata,
      tool: tool ?? this.tool,
      permission: permission ?? this.permission,
      turnClose: turnClose ?? this.turnClose,
      subagentId: subagentId ?? this.subagentId,
      children: children ?? this.children,
    );
  }

  factory ReducerMessage.fromJson(Map<String, dynamic> json) {
    final content = json['content'];
    return ReducerMessage(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? 'text',
      createdAt: json['createdAt'] != null
          ? _parseMessageDateTime(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      text: json['text'] as String? ?? _extractMessageText(content),
      metadata: _asStringMap(json['metadata']),
      tool: json['tool'] != null
          ? ToolInfo.fromJson(json['tool'] as Map<String, dynamic>)
          : null,
      permission: json['permission'] != null
          ? PermissionRequest.fromJson(
              json['permission'] as Map<String, dynamic>,
            )
          : null,
      turnClose: json['turnClose'] != null
          ? TurnClose.fromJson(json['turnClose'] as Map<String, dynamic>)
          : null,
      subagentId: json['subagentId'] as String?,
      children: json['children'] is List
          ? (json['children'] as List)
              .map((c) => ReducerMessage.fromJson(c as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind,
      'createdAt': createdAt.toIso8601String(),
      if (text != null) 'text': text,
      if (metadata != null) 'metadata': metadata,
      if (tool != null) 'tool': tool!.toJson(),
      if (permission != null) 'permission': permission!.toJson(),
      if (turnClose != null) 'turnClose': turnClose!.toJson(),
      if (subagentId != null) 'subagentId': subagentId,
      if (children.isNotEmpty)
        'children': children.map((c) => c.toJson()).toList(),
    };
  }
}

DateTime? _parseMessageDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    if (value.isEmpty) {
      return null;
    }
    final asInt = int.tryParse(value);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    return DateTime.tryParse(value);
  }
  return null;
}

String? _extractMessageText(dynamic content) {
  if (content == null) {
    return null;
  }
  if (content is String) {
    return content;
  }
  if (content is Map) {
    final encryptedContent = content['c'];
    if (encryptedContent is String && encryptedContent.isNotEmpty) {
      return encryptedContent;
    }
    final text = content['text'];
    if (text is String && text.isNotEmpty) {
      return text;
    }
  }
  return null;
}

Map<String, dynamic>? _asStringMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
  }
  return null;
}
