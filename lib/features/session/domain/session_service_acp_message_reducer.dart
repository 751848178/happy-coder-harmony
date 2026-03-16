part of 'session_service.dart';

extension SessionServiceAcpMessageReducer on SessionServiceNotifier {
  List<ReducerMessage> _reduceAcpMessages({
    required Map<String, dynamic>? acpData,
    required String? provider,
    required String id,
    required DateTime createdAt,
    required String? localId,
    required Map<String, dynamic>? meta,
  }) {
    if (acpData == null) {
      return const <ReducerMessage>[];
    }

    final acpType = acpData['type']?.toString();
    final metadata = {
      ...?meta,
      'role': 'agent',
      if (provider != null && provider.isNotEmpty) 'provider': provider,
      if (localId != null && localId.isNotEmpty) 'localId': localId,
      if (acpType != null) 'outputType': acpType,
    };

    switch (acpType) {
      case 'message':
      case 'reasoning':
        final text = acpData['message']?.toString();
        if (text == null || text.isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:acp:$acpType',
            createdAt: createdAt,
            text: text,
            metadata: {
              ...metadata,
              if (acpType == 'reasoning') 'outputType': 'thinking',
            },
          ),
        ];
      case 'thinking':
        final text = acpData['text']?.toString();
        if (text == null || text.isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:acp:thinking',
            createdAt: createdAt,
            text: text,
            metadata: {...metadata, 'outputType': 'thinking'},
          ),
        ];
      case 'tool-call':
        final toolId =
            acpData['callId']?.toString() ?? acpData['id']?.toString() ?? id;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: acpData['name']?.toString() ?? 'unknown',
            arguments: _asStringMap(acpData['input']) ?? const {},
            status: ToolCallStatus.pending,
            metadata: metadata,
          ),
        ];
      case 'tool-result':
      case 'tool-call-result':
        final toolId =
            acpData['callId']?.toString() ?? acpData['id']?.toString() ?? id;
        final isError =
            acpData['isError'] == true || acpData['is_error'] == true;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: acpData['name']?.toString() ?? 'unknown',
            arguments: const <String, dynamic>{},
            status: isError ? ToolCallStatus.failed : ToolCallStatus.completed,
            metadata: metadata,
            result: _stringifyStructuredContent(acpData['output']),
            error:
                isError ? _stringifyStructuredContent(acpData['output']) : null,
          ),
        ];
      case 'file-edit':
        final toolId = acpData['id']?.toString() ?? id;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: 'Edit',
            arguments: {
              'file_path': acpData['filePath'],
              if (acpData['diff'] != null) 'diff': acpData['diff'],
              if (acpData['oldContent'] != null)
                'old_string': acpData['oldContent'],
              if (acpData['newContent'] != null)
                'new_string': acpData['newContent'],
            },
            status: ToolCallStatus.completed,
            metadata: metadata,
            description: acpData['description']?.toString(),
          ),
        ];
      case 'terminal-output':
      case 'permission-request':
      case 'task_started':
      case 'task_complete':
      case 'turn_aborted':
        return _reduceAcpLifecycleMessages(
          acpData: acpData,
          acpType: acpType,
          id: id,
          createdAt: createdAt,
          metadata: metadata,
        );
      default:
        return const <ReducerMessage>[];
    }
  }

  List<ReducerMessage> _reduceAcpLifecycleMessages({
    required Map<String, dynamic> acpData,
    required String? acpType,
    required String id,
    required DateTime createdAt,
    required Map<String, dynamic> metadata,
  }) {
    switch (acpType) {
      case 'terminal-output':
        final toolId = acpData['callId']?.toString() ?? id;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: 'Bash',
            arguments: const <String, dynamic>{},
            status: ToolCallStatus.completed,
            metadata: metadata,
            result: acpData['data']?.toString(),
          ),
        ];
      case 'permission-request':
        final toolId = acpData['permissionId']?.toString() ?? id;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: acpData['toolName']?.toString() ?? 'unknown',
            arguments: _asStringMap(acpData['options']) ?? const {},
            status: ToolCallStatus.pending,
            metadata: metadata,
            description: acpData['description']?.toString(),
          ),
        ];
      case 'task_started':
        return <ReducerMessage>[
          _buildEventReducerMessage(
            id: '$id:acp:task-started',
            createdAt: createdAt,
            text: '子任务开始',
            metadata: metadata,
          ),
        ];
      case 'task_complete':
        return <ReducerMessage>[
          _buildEventReducerMessage(
            id: '$id:acp:task-complete',
            createdAt: createdAt,
            text: '子任务完成',
            metadata: metadata,
          ),
        ];
      case 'turn_aborted':
        return <ReducerMessage>[
          _buildEventReducerMessage(
            id: '$id:acp:turn-aborted',
            createdAt: createdAt,
            text: '回合已中止',
            metadata: metadata,
          ),
        ];
      default:
        return const <ReducerMessage>[];
    }
  }
}
