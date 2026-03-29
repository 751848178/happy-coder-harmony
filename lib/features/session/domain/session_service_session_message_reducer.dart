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
          ),
        ];
      case 'start':
        final title = event?['title']?.toString();
        return _isBlankReducerText(title)
            ? const <ReducerMessage>[]
            : <ReducerMessage>[
                _buildEventReducerMessage(
                  id: '$id:session:start',
                  createdAt: createdAt,
                  text: title!,
                  metadata: metadata,
                ),
              ];
      case 'stop':
        return <ReducerMessage>[
          _buildEventReducerMessage(
            id: '$id:session:stop',
            createdAt: createdAt,
            text: '任务已结束',
            metadata: metadata,
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
