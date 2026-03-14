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
    return SocketMessage(
      id: json['id'] as String? ?? '',
      type: json['type'] != null
          ? SocketMessageType.values.firstWhere(
              (value) => value.name == json['type'],
              orElse: () => SocketMessageType.user,
            )
          : SocketMessageType.user,
      content: json['content'] as String? ?? '',
      sessionId: json['sessionId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
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
