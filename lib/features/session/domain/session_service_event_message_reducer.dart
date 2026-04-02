part of 'session_service.dart';

extension SessionServiceEventMessageReducer on SessionServiceNotifier {
  List<ReducerMessage> _reduceAgentEventMessages({
    required Map<String, dynamic>? eventData,
    required String id,
    required DateTime createdAt,
    required String? localId,
    required Map<String, dynamic>? meta,
    String? subagentId,
  }) {
    if (eventData == null) {
      return const <ReducerMessage>[];
    }

    final eventType = eventData['type']?.toString();
    final metadata = {
      ...?meta,
      'role': 'agent',
      if (localId != null && localId.isNotEmpty) 'localId': localId,
      if (eventType != null) 'eventType': eventType,
    };

    switch (eventType) {
      case 'ready':
        return <ReducerMessage>[
          _buildEventReducerMessage(
            id: '$id:event:ready',
            createdAt: createdAt,
            text: '',
            metadata: metadata,
            subagentId: subagentId,
          ),
        ];
      case 'message':
        final message = eventData['message']?.toString();
        if (_isBlankReducerText(message)) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildEventReducerMessage(
            id: '$id:event:message',
            createdAt: createdAt,
            text: message!,
            metadata: metadata,
            subagentId: subagentId,
          ),
        ];
      case 'switch':
        final mode = eventData['mode']?.toString();
        final text = switch (mode) {
          'local' => '已切换为本地处理',
          'remote' => '已切换为远程处理',
          _ => '处理模式已切换',
        };
        return <ReducerMessage>[
          _buildEventReducerMessage(
            id: '$id:event:switch',
            createdAt: createdAt,
            text: text,
            metadata: metadata,
            subagentId: subagentId,
          ),
        ];
      case 'limit-reached':
        return <ReducerMessage>[
          _buildEventReducerMessage(
            id: '$id:event:limit-reached',
            createdAt: createdAt,
            text: 'AI 使用额度已达上限',
            metadata: metadata,
            subagentId: subagentId,
          ),
        ];
      default:
        return const <ReducerMessage>[];
    }
  }
}
