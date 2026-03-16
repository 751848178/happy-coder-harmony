part of 'socket_integration.dart';

extension _SocketIntegrationMessageBuilders on SocketIntegration {
  ReducerMessage _buildAgentStateMessage(
    String id,
    DateTime timestamp,
    Map<String, dynamic>? metadata, {
    required String state,
    required String content,
    Object? result,
  }) {
    return ReducerMessage(
      id: id,
      kind: 'agent-state',
      createdAt: timestamp,
      metadata: {
        'state': state,
        'content': content,
        if (result != null) 'result': result,
        ...?metadata,
      },
    );
  }

  ReducerMessage _buildToolLifecycleMessage(
    String id,
    DateTime timestamp,
    Map<String, dynamic>? metadata, {
    required String kind,
    required String status,
    required Map<String, dynamic> json,
  }) {
    return ReducerMessage(
      id: id,
      kind: kind,
      createdAt: timestamp,
      metadata: {
        'tool': json['tool'],
        'status': status,
        if (json['result'] != null) 'result': json['result'],
        ...?metadata,
      },
    );
  }
}
