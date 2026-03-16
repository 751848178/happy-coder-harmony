part of 'socket_integration.dart';

extension _SocketIntegrationMessageParsing on SocketIntegration {
  ReducerMessage? _convertToReducerMessage(SocketMessage socketMessage) {
    final timestamp = socketMessage.timestamp ?? DateTime.now();

    switch (socketMessage.type) {
      case SocketMessageType.user:
      case SocketMessageType.system:
        return ReducerMessage(
          id: socketMessage.id,
          kind: 'text',
          createdAt: timestamp,
          text: socketMessage.type == SocketMessageType.error
              ? 'Error: ${socketMessage.content}'
              : socketMessage.content,
          metadata: socketMessage.metadata,
        );
      case SocketMessageType.server:
        return _parseServerMessage(
          socketMessage.id,
          socketMessage.content,
          timestamp,
          socketMessage.metadata,
        );
      case SocketMessageType.tool:
        return _parseToolMessage(
          socketMessage.id,
          socketMessage.content,
          timestamp,
          socketMessage.metadata,
        );
      case SocketMessageType.error:
        return ReducerMessage(
          id: socketMessage.id,
          kind: 'text',
          createdAt: timestamp,
          text: 'Error: ${socketMessage.content}',
          metadata: socketMessage.metadata,
        );
    }
  }

  ReducerMessage? _parseServerMessage(
    String id,
    String content,
    DateTime timestamp,
    Map<String, dynamic>? metadata,
  ) {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>?;
      if (json == null) {
        return ReducerMessage(
          id: id,
          kind: 'text',
          createdAt: timestamp,
          text: content,
          metadata: metadata,
        );
      }

      switch (json['type'] as String?) {
        case 'agent_thinking':
          return _buildAgentStateMessage(
            id,
            timestamp,
            metadata,
            state: 'thinking',
            content: json['content'] as String? ?? '',
          );
        case 'agent_processing':
          return _buildAgentStateMessage(
            id,
            timestamp,
            metadata,
            state: 'processing',
            content: json['content'] as String? ?? '',
          );
        case 'agent_complete':
          return _buildAgentStateMessage(
            id,
            timestamp,
            metadata,
            state: 'complete',
            content: json['content'] as String? ?? '',
            result: json['result'],
          );
        case 'agent_error':
          return ReducerMessage(
            id: id,
            kind: 'agent-state',
            createdAt: timestamp,
            text: json['error'] as String? ?? 'An error occurred',
            metadata: {'state': 'error', 'error': json['error'], ...?metadata},
          );
        case 'tool_start':
          return _buildToolLifecycleMessage(
            id,
            timestamp,
            metadata,
            kind: 'tool-start',
            status: 'running',
            json: json,
          );
        case 'tool_complete':
          return _buildToolLifecycleMessage(
            id,
            timestamp,
            metadata,
            kind: 'tool-complete',
            status: 'complete',
            json: json,
          );
        case 'tool_error':
          return ReducerMessage(
            id: id,
            kind: 'tool-error',
            createdAt: timestamp,
            text: json['error'] as String? ?? 'Tool error',
            metadata: {'tool': json['tool'], 'error': json['error'], ...?metadata},
          );
        default:
          return ReducerMessage(
            id: id,
            kind: 'text',
            createdAt: timestamp,
            text: content,
            metadata: metadata,
          );
      }
    } catch (e) {
      Logger.error('Failed to parse server message: $e');
      return ReducerMessage(
        id: id,
        kind: 'text',
        createdAt: timestamp,
        text: content,
        metadata: metadata,
      );
    }
  }

  ReducerMessage? _parseToolMessage(
    String id,
    String content,
    DateTime timestamp,
    Map<String, dynamic>? metadata,
  ) {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>?;
      if (json == null || json['id'] == null) {
        return null;
      }
      return ReducerMessage(
        id: id,
        kind: 'tool-call',
        createdAt: timestamp,
        tool: ToolInfo(
          id: json['id'] as String,
          name: json['name'] as String? ?? 'unknown',
          arguments: json['arguments'] as Map<String, dynamic>? ?? {},
        ),
        metadata: metadata,
      );
    } catch (e) {
      Logger.error('Failed to parse tool message: $e');
      return null;
    }
  }
}
