part of 'session_service.dart';

extension SessionServiceOutputMessageReducer on SessionServiceNotifier {
  List<ReducerMessage> _reduceOutputMessages({
    required Map<String, dynamic>? outputData,
    required String id,
    required DateTime createdAt,
    required String? localId,
    required Map<String, dynamic>? meta,
  }) {
    if (outputData == null) {
      return const <ReducerMessage>[];
    }

    final outputType = outputData['type']?.toString();
    final baseMetadata = {
      ...?meta,
      'role': 'agent',
      if (localId != null && localId.isNotEmpty) 'localId': localId,
      if (outputType != null) 'outputType': outputType,
    };

    switch (outputType) {
      case 'message':
      case 'reasoning':
        final text = outputData['message']?.toString();
        if (text == null || text.isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:output:$outputType',
            createdAt: createdAt,
            text: text,
            metadata: {
              ...baseMetadata,
              if (outputType == 'reasoning') 'outputType': 'thinking',
            },
          ),
        ];
      case 'summary':
        final summary = outputData['summary']?.toString();
        if (summary == null || summary.isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:output:summary',
            createdAt: createdAt,
            text: summary,
            metadata: baseMetadata,
          ),
        ];
      case 'assistant':
      case 'user':
        final message = _asStringMap(outputData['message']);
        final content = message?['content'];
        final parts = _normalizeAgentContentParts(content);
        if (parts.isNotEmpty) {
          return _reduceAgentContentParts(
            parts,
            baseId: id,
            createdAt: createdAt,
            meta: {
              ...baseMetadata,
              if (outputType == 'user') 'sourceRole': 'user',
            },
            role: 'agent',
          );
        }
        final directText =
            content is String ? content : message?['content']?.toString();
        if (directText == null || directText.trim().isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:output:$outputType',
            createdAt: createdAt,
            text: directText,
            metadata: {
              ...baseMetadata,
              if (outputType == 'user') 'sourceRole': 'user',
            },
          ),
        ];
      default:
        final message = _asStringMap(outputData['message']);
        final content = message?['content'];
        final parts = _normalizeAgentContentParts(content);
        if (parts.isNotEmpty) {
          return _reduceAgentContentParts(
            parts,
            baseId: id,
            createdAt: createdAt,
            meta: baseMetadata,
            role: 'agent',
          );
        }
        return const <ReducerMessage>[];
    }
  }
}
