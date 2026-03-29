part of 'socket_service.dart';

enum SocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

enum SocketMessageType {
  server,
  user,
  system,
  tool,
  error,
}

class SocketMessage {
  const SocketMessage({
    required this.id,
    required this.type,
    required this.content,
    this.sessionId,
    this.metadata,
    this.timestamp,
  });

  final String id;
  final SocketMessageType type;
  final String content;
  final String? sessionId;
  final Map<String, dynamic>? metadata;
  final DateTime? timestamp;

  factory SocketMessage.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString();
    final type = rawType == null
        ? SocketMessageType.user
        : SocketMessageType.values.firstWhere(
            (value) => value.name == rawType,
            orElse: () => SocketMessageType.user,
          );
    return SocketMessage(
      id: json['id'] as String? ?? '',
      type: type,
      content: json['content'] as String? ?? '',
      sessionId: _resolveSocketMessageSessionId(json),
      metadata: _asSocketMessageMetadata(json['metadata']),
      timestamp: _parseSocketMessageTimestamp(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      if (sessionId != null) 'sessionId': sessionId,
      if (metadata != null) 'metadata': metadata,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }
}

String? _resolveSocketMessageSessionId(Map<String, dynamic> json) {
  for (final key in const ['sessionId', 'sid', 'session_id', 'session']) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value != 'null') {
      return value;
    }
  }
  return null;
}

Map<String, dynamic>? _asSocketMessageMetadata(dynamic value) {
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

DateTime? _parseSocketMessageTimestamp(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String && value.isNotEmpty) {
    final asInt = int.tryParse(value);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    return DateTime.tryParse(value);
  }
  return null;
}
