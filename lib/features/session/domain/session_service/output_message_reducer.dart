part of 'session_service.dart';

extension SessionServiceOutputMessageReducer on SessionServiceNotifier {
  List<ReducerMessage> _reduceOutputMessages({
    required Map<String, dynamic>? outputData,
    required String id,
    required DateTime createdAt,
    required String? localId,
    required Map<String, dynamic>? meta,
    String? subagentId,
  }) {
    if (outputData == null) {
      return const <ReducerMessage>[];
    }

    final outputType = outputData['type']?.toString();
    final role = outputType == 'user' ? 'user' : 'agent';
    final baseMetadata = {
      ...?meta,
      'role': role,
      if (localId != null && localId.isNotEmpty) 'localId': localId,
      if (outputType != null) 'outputType': outputType,
    };

    switch (outputType) {
      case 'message':
      case 'reasoning':
        final text = outputData['message']?.toString();
        if (_isBlankReducerText(text)) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:output:$outputType',
            createdAt: createdAt,
            text: text!,
            metadata: {
              ...baseMetadata,
              if (outputType == 'reasoning') 'outputType': 'thinking',
            },
            subagentId: subagentId,
          ),
        ];
      case 'summary':
        final summary = outputData['summary']?.toString();
        if (_isBlankReducerText(summary)) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:output:summary',
            createdAt: createdAt,
            text: summary!,
            metadata: baseMetadata,
            subagentId: subagentId,
          ),
        ];
      case 'assistant':
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
            role: role,
            subagentId: subagentId,
          );
        }
        final directText =
            content is String ? content : message?['content']?.toString();
        if (_isBlankReducerText(directText)) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:output:$outputType',
            createdAt: createdAt,
            text: directText!,
            metadata: {
              ...baseMetadata,
              if (outputType == 'user') 'sourceRole': 'user',
            },
            subagentId: subagentId,
          ),
        ];
      case 'user':
        final message = _asStringMap(outputData['message']);
        final content = message?['content'];
        if (content is String) {
          if (_isBlankReducerText(content)) {
            return const <ReducerMessage>[];
          }
          return <ReducerMessage>[
            _buildTextReducerMessage(
              id: '$id:output:user',
              createdAt: createdAt,
              text: content,
              metadata: {
                ...baseMetadata,
                'role': 'user',
                'sourceRole': 'user',
              },
              subagentId: subagentId,
            ),
          ];
        }
        final parts = _normalizeAgentContentParts(content);
        if (parts.isNotEmpty) {
          return _reduceAgentContentParts(
            parts,
            baseId: id,
            createdAt: createdAt,
            meta: {
              ...baseMetadata,
              'role': 'agent',
              'sourceRole': 'user',
            },
            role: 'agent',
            subagentId: subagentId,
          );
        }
        return const <ReducerMessage>[];
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
            subagentId: subagentId,
          );
        }
        return const <ReducerMessage>[];
    }
  }
}
