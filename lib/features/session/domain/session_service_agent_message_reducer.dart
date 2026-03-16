part of 'session_service.dart';

extension SessionServiceAgentMessageReducer on SessionServiceNotifier {
  List<ReducerMessage> _reduceCodexMessages({
    required Map<String, dynamic>? codexData,
    required String id,
    required DateTime createdAt,
    required String? localId,
    required Map<String, dynamic>? meta,
  }) {
    if (codexData == null) {
      return const <ReducerMessage>[];
    }

    final codexType = codexData['type']?.toString();
    final metadata = {
      ...?meta,
      'role': 'agent',
      'provider': 'codex',
      if (localId != null && localId.isNotEmpty) 'localId': localId,
      if (codexType != null) 'outputType': codexType,
    };

    switch (codexType) {
      case 'message':
      case 'reasoning':
        final text = codexData['message']?.toString();
        if (text == null || text.isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:codex:$codexType',
            createdAt: createdAt,
            text: text,
            metadata: {
              ...metadata,
              if (codexType == 'reasoning') 'outputType': 'thinking',
            },
          ),
        ];
      case 'tool-call':
        final toolId = codexData['callId']?.toString() ??
            codexData['id']?.toString() ??
            id;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: codexData['name']?.toString() ?? 'unknown',
            arguments: _asStringMap(codexData['input']) ?? const {},
            status: ToolCallStatus.pending,
            metadata: metadata,
          ),
        ];
      case 'tool-call-result':
        final toolId = codexData['callId']?.toString() ??
            codexData['id']?.toString() ??
            id;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: codexData['name']?.toString() ?? 'unknown',
            arguments: const <String, dynamic>{},
            status: ToolCallStatus.completed,
            metadata: metadata,
            result: _stringifyStructuredContent(codexData['output']),
          ),
        ];
      default:
        return const <ReducerMessage>[];
    }
  }
}
