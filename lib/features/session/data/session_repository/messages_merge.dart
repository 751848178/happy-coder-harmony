part of 'session_repository.dart';

extension SessionRepositoryMessagesMerge on SessionRepository {
  int? _messageArchiveIndex(domain.ReducerMessage message) {
    final rawValue = message.metadata?['archiveIndex'];
    if (rawValue is int) {
      return rawValue;
    }
    if (rawValue is String) {
      return int.tryParse(rawValue);
    }
    if (rawValue is double) {
      return rawValue.toInt();
    }
    return null;
  }

  List<domain.ReducerMessage> _canonicalizeMessageWindow(
    List<domain.ReducerMessage> messages,
  ) {
    if (messages.length < 2) {
      return List<domain.ReducerMessage>.unmodifiable(messages);
    }
    final orderedMessageIds = <String>[];
    final canonicalMessages = <String, domain.ReducerMessage>{};
    for (final incoming in messages) {
      final previous = _findPreviousMessageForIncoming(
        canonicalMessages,
        incoming,
      );
      final previousId = previous?.id;
      final merged = _mergeMessage(previous, incoming);
      if (previousId != null && previousId != incoming.id) {
        canonicalMessages.remove(previousId);
        final previousIndex = orderedMessageIds.indexOf(previousId);
        if (previousIndex >= 0) {
          orderedMessageIds[previousIndex] = incoming.id;
        } else {
          orderedMessageIds.add(incoming.id);
        }
      } else if (!canonicalMessages.containsKey(incoming.id)) {
        orderedMessageIds.add(incoming.id);
      }
      canonicalMessages[incoming.id] = merged;
    }
    final canonicalList = <domain.ReducerMessage>[
      for (final id in orderedMessageIds)
        if (canonicalMessages[id] != null) canonicalMessages[id]!,
    ];
    return List<domain.ReducerMessage>.unmodifiable(canonicalList);
  }

  int _resolveWindowStartIndexFromMessages(
    List<domain.ReducerMessage> messages, {
    required int fallback,
  }) {
    var nextStartIndex = fallback;
    for (final message in messages) {
      final archiveIndex = _messageArchiveIndex(message);
      if (archiveIndex == null) {
        continue;
      }
      if (archiveIndex < nextStartIndex) {
        nextStartIndex = archiveIndex;
      }
    }
    return nextStartIndex < 0 ? 0 : nextStartIndex;
  }

  String? _findMessageIdByLocalId(
    Map<String, domain.ReducerMessage> messagesMap,
    String localId,
  ) {
    if (messagesMap.containsKey(localId)) {
      return localId;
    }
    for (final entry in messagesMap.entries) {
      final candidate = entry.value.metadata?['localId']?.toString();
      if (candidate == localId) {
        return entry.key;
      }
    }
    return null;
  }

  domain.ReducerMessage? _findPreviousMessageForIncoming(
    Map<String, domain.ReducerMessage>? existingMessagesMap,
    domain.ReducerMessage incoming,
  ) {
    if (existingMessagesMap == null) {
      return null;
    }
    final directMatch = existingMessagesMap[incoming.id];
    if (directMatch != null) {
      return directMatch;
    }
    final localId = incoming.metadata?['localId']?.toString();
    if (localId == null || localId.isEmpty) {
      return null;
    }
    final optimisticMessageId = _findMessageIdByLocalId(
      existingMessagesMap,
      localId,
    );
    return optimisticMessageId == null
        ? null
        : existingMessagesMap[optimisticMessageId];
  }

  bool _isOptimisticMessage(domain.ReducerMessage message) {
    return message.metadata?['optimistic'] == true;
  }

  domain.ReducerMessage _mergeMessage(
    domain.ReducerMessage? previous,
    domain.ReducerMessage incoming,
  ) {
    if (previous == null) {
      return incoming;
    }
    if (previous.isToolCall &&
        incoming.isToolCall &&
        previous.tool != null &&
        incoming.tool != null &&
        previous.tool!.id == incoming.tool!.id) {
      final previousStatus =
          previous.tool!.status ?? domain.ToolCallStatus.pending;
      final incomingStatus =
          incoming.tool!.status ?? domain.ToolCallStatus.pending;
      // Preserve children: incoming may have newly nested children from
      // _nestSidechainMessages; prefer incoming when non-empty, else keep
      // previous so we never lose children across incremental merges.
      final mergedChildren =
          incoming.children.isNotEmpty ? incoming.children : previous.children;
      return previous.copyWith(
        createdAt: previous.createdAt,
        metadata: {...?previous.metadata, ...?incoming.metadata},
        tool: previous.tool!.copyWith(
          name: _resolveToolName(previous.tool!.name, incoming.tool!.name),
          arguments: {...previous.tool!.arguments, ...incoming.tool!.arguments},
          status: _resolveMergedToolStatus(previousStatus, incomingStatus),
          result: incoming.tool!.result ?? previous.tool!.result,
          error: incoming.tool!.error ?? previous.tool!.error,
          description: incoming.tool!.description ?? previous.tool!.description,
        ),
        children: mergedChildren,
      );
    }
    return incoming;
  }

  domain.ToolCallStatus _resolveMergedToolStatus(
    domain.ToolCallStatus previous,
    domain.ToolCallStatus incoming,
  ) {
    if (previous != domain.ToolCallStatus.pending &&
        incoming == domain.ToolCallStatus.pending) {
      return previous;
    }
    const terminalStatuses = <domain.ToolCallStatus>{
      domain.ToolCallStatus.completed,
      domain.ToolCallStatus.failed,
      domain.ToolCallStatus.rejected,
    };
    if (terminalStatuses.contains(previous) &&
        !terminalStatuses.contains(incoming)) {
      return previous;
    }
    return incoming;
  }

  String _resolveToolName(String previous, String incoming) {
    return incoming.isEmpty || incoming == 'unknown' ? previous : incoming;
  }
}
