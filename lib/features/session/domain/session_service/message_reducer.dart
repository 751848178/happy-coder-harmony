part of 'session_service.dart';

extension SessionServiceSessionMessageReducer on SessionServiceNotifier {
  List<ReducerMessage> _reduceSessionEnvelopeMessages({
    required Map<String, dynamic>? envelope,
    required String id,
    required DateTime createdAt,
    required String? localId,
    required Map<String, dynamic>? meta,
  }) {
    if (envelope == null) {
      return const <ReducerMessage>[];
    }

    final event = _asStringMap(envelope['ev']);
    final eventType = event?['t']?.toString();
    final envelopeRole = envelope['role']?.toString() ?? 'agent';
    final subagentId = envelope['subagent']?.toString();
    final metadata = {
      ...?meta,
      'role': envelopeRole,
      'sourceRole': envelopeRole,
      if (localId != null && localId.isNotEmpty) 'localId': localId,
      if (eventType != null) 'eventType': eventType,
    };

    switch (eventType) {
      case 'text':
        final text = event?['text']?.toString();
        if (_isBlankReducerText(text)) {
          return const <ReducerMessage>[];
        }
        if (envelopeRole == 'user') {
          return <ReducerMessage>[
            _buildTextReducerMessage(
              id: '$id:session:text',
              createdAt: createdAt,
              text: text!,
              metadata: metadata,
              subagentId: subagentId,
            ),
          ];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:session:text',
            createdAt: createdAt,
            text: text!,
            metadata: {
              ...metadata,
              if (event?['thinking'] == true) 'outputType': 'thinking',
            },
            subagentId: subagentId,
          ),
        ];
      case 'service':
        final text = event?['text']?.toString();
        if (_isBlankReducerText(text)) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:session:service',
            createdAt: createdAt,
            text: text!,
            metadata: metadata,
            subagentId: subagentId,
          ),
        ];
      case 'start':
      case 'subagent-start':
        final title = event?['title']?.toString();
        final agentId = event?['agentId']?.toString() ?? subagentId;
        final agentType = event?['agentType']?.toString();
        return _isBlankReducerText(title)
            ? const <ReducerMessage>[]
            : <ReducerMessage>[
                _buildEventReducerMessage(
                  id: '$id:session:start',
                  createdAt: createdAt,
                  text: title!,
                  metadata: {
                    ...metadata,
                    'subagentLifecycle': 'start',
                    if (agentId != null) 'subagentId': agentId,
                    if (agentType != null) 'subagentType': agentType,
                  },
                  subagentId: agentId,
                ),
              ];
      case 'stop':
      case 'subagent-stop':
        final agentId = event?['agentId']?.toString() ?? subagentId;
        final status = event?['status']?.toString();
        final isFailed = status == 'failed' || status == 'cancelled';
        return <ReducerMessage>[
          _buildEventReducerMessage(
            id: '$id:session:stop',
            createdAt: createdAt,
            text: isFailed ? '子任务已中止' : '子任务已完成',
            metadata: {
              ...metadata,
              'subagentLifecycle': 'stop',
              if (agentId != null) 'subagentId': agentId,
              if (isFailed) 'subagentStatus': 'failed',
            },
            subagentId: agentId,
          ),
        ];
      case 'turn-start':
        return const <ReducerMessage>[];
      case 'tool-call-start':
        final toolId = event?['call']?.toString() ?? id;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: event?['name']?.toString() ?? 'unknown',
            arguments:
                _asStringMap(event?['args']) ?? const <String, dynamic>{},
            status: ToolCallStatus.pending,
            metadata: metadata,
            description: _firstNonEmptyString([
              event?['description']?.toString(),
              event?['title']?.toString(),
            ]),
            subagentId: subagentId,
          ),
        ];
      case 'tool-call-end':
        final toolId = event?['call']?.toString() ?? id;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: event?['name']?.toString() ?? 'unknown',
            arguments: const <String, dynamic>{},
            status: ToolCallStatus.completed,
            metadata: metadata,
            result: _stringifyStructuredContent(event?['result']),
            error: event?['error']?.toString(),
            subagentId: subagentId,
          ),
        ];
      case 'file':
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: '$id:file',
            createdAt: createdAt,
            toolId: id,
            name: 'file',
            arguments: {
              'ref': event?['ref'],
              'name': event?['name'],
              'size': event?['size'],
              if (event?['image'] != null) 'image': event?['image'],
            },
            status: ToolCallStatus.completed,
            metadata: metadata,
            subagentId: subagentId,
          ),
        ];
      case 'turn-end':
        final status = event?['status']?.toString();
        return <ReducerMessage>[
          ReducerMessage(
            id: '$id:turn-end',
            kind: 'turn-close',
            createdAt: createdAt,
            metadata: metadata,
            turnClose: TurnClose(
              abandoned: status == 'failed' || status == 'cancelled',
              reason: status,
            ),
          ),
        ];
      default:
        return const <ReducerMessage>[];
    }
  }
}
