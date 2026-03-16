part of 'session_service.dart';

extension SessionServiceAgentContentReducer on SessionServiceNotifier {
  List<ReducerMessage> _reduceAgentContentParts(
    List<Map<String, dynamic>> parts, {
    required String baseId,
    required DateTime createdAt,
    required Map<String, dynamic>? meta,
    required String role,
  }) {
    final messages = <ReducerMessage>[];

    for (var index = 0; index < parts.length; index++) {
      final part = parts[index];
      final partType = part['type']?.toString();
      switch (partType) {
        case 'text':
          final text = part['text']?.toString();
          if (text != null && text.isNotEmpty) {
            messages.add(_buildTextReducerMessage(
              id: '$baseId:text:$index',
              createdAt: createdAt,
              text: text,
              metadata: {...?meta, 'role': role},
            ));
          }
          break;
        case 'thinking':
          final thinking = part['thinking']?.toString();
          if (thinking != null && thinking.isNotEmpty) {
            messages.add(_buildTextReducerMessage(
              id: '$baseId:thinking:$index',
              createdAt: createdAt,
              text: thinking,
              metadata: {...?meta, 'role': role, 'outputType': 'thinking'},
            ));
          }
          break;
        case 'tool_use':
        case 'tool-call':
          final toolId = part['id']?.toString() ??
              part['callId']?.toString() ??
              '$baseId:$index';
          messages.add(_buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: part['name']?.toString() ?? 'unknown',
            arguments: _asStringMap(part['input']) ?? const {},
            status: ToolCallStatus.pending,
            metadata: meta,
            description: part['description']?.toString(),
          ));
          break;
        case 'tool_result':
        case 'tool-call-result':
          final toolId = part['tool_use_id']?.toString() ??
              part['callId']?.toString() ??
              '$baseId:$index';
          final isError = part['is_error'] == true || part['isError'] == true;
          final permissions = _asStringMap(part['permissions']);
          messages.add(_buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: part['name']?.toString() ?? 'unknown',
            arguments: const <String, dynamic>{},
            status: isError || permissions?['result']?.toString() == 'denied'
                ? ToolCallStatus.failed
                : ToolCallStatus.completed,
            metadata: {
              ...?meta,
              if (permissions != null) 'permission': permissions,
            },
            result: _stringifyStructuredContent(
              part.containsKey('content') ? part['content'] : part['output'],
            ),
            error: isError
                ? _stringifyStructuredContent(
                    part.containsKey('content')
                        ? part['content']
                        : part['output'],
                  )
                : null,
          ));
          break;
        case 'summary':
          final summary = part['summary']?.toString();
          if (summary != null && summary.isNotEmpty) {
            messages.add(_buildTextReducerMessage(
              id: '$baseId:summary:$index',
              createdAt: createdAt,
              text: summary,
              metadata: {...?meta, 'role': role},
            ));
          }
          break;
        case 'sidechain':
          messages.add(_buildEventReducerMessage(
            id: '$baseId:sidechain:$index',
            createdAt: createdAt,
            text: '子任务分支',
            metadata: meta,
          ));
          break;
      }
    }

    return messages;
  }

  List<Map<String, dynamic>> _normalizeAgentContentParts(dynamic content) {
    if (content is! List) {
      return const <Map<String, dynamic>>[];
    }
    return content.map(_asStringMap).whereType<Map<String, dynamic>>().toList();
  }
}
