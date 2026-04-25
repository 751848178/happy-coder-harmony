part of 'session_service.dart';

extension SessionServiceSidechainNesting on SessionServiceNotifier {
  /// Post-processes a flat list of [ReducerMessage]s so that sub-agent
  /// messages are nested as [children] inside their parent Task/Agent
  /// tool-call messages, matching the upstream slopus/happy model.
  List<ReducerMessage> _nestSidechainMessages(List<ReducerMessage> messages) {
    if (messages.isEmpty) return messages;

    // Phase 1: Build subagentId -> parent tool message index.
    // The parent is the last Task/Agent tool-call BEFORE the subagent
    // messages start (or the tool-call whose own subagentId matches).
    final subagentToParent = <String, String>{};
    final messageById = <String, ReducerMessage>{};
    final subagentIds = <String>{};

    for (final msg in messages) {
      messageById[msg.id] = msg;
      final sid = msg.subagentId;
      if (sid != null) {
        subagentIds.add(sid);
      }
    }

    // Identify parent Task/Agent tool calls: they are tool-call messages
    // whose tool.name is 'Task' or 'Agent' and whose metadata carries
    // a subagent registration, OR they precede the first subagent message.
    // For session-protocol messages, the subagent-start event carries
    // the subagentId in its metadata.
    for (final msg in messages) {
      if (msg.isAgentEvent && msg.metadata?['subagentLifecycle'] == 'start') {
        final sid = msg.metadata?['subagentId']?.toString() ?? msg.subagentId;
        if (sid != null) {
          // Find the nearest preceding Task/Agent tool-call message
          final parentId = _findParentToolCall(messages, msg.id);
          if (parentId != null) {
            subagentToParent[sid] = parentId;
          }
        }
      }
    }

    // Also check for Task/Agent tool calls that have subagentId
    // (session protocol: tool-call-start with subagent field)
    for (final msg in messages) {
      if (msg.isToolCall &&
          (msg.tool?.name == 'Task' || msg.tool?.name == 'Agent')) {
        // This Task tool call might be the parent of subsequent subagent messages
        // If we haven't registered a subagent yet, this could be the parent
        final sid = msg.subagentId;
        if (sid != null && !subagentToParent.containsKey(sid)) {
          // The Task tool call itself has a subagentId — it IS the parent
          // But wait — in upstream, the parent is identified by its message ID,
          // not the subagentId. The subagentId comes from envelope.subagent.
          // The Task tool call (tool_use with name 'Agent') is in the main thread,
          // and subsequent session envelope messages with subagent=<cuid2>
          // are children of that tool call.
          // For now, register this tool call's message ID as parent for this subagentId.
          subagentToParent[sid] = msg.id;
        }
      }
    }

    if (subagentToParent.isEmpty) return messages;

    // Phase 2: Collect children for each parent, and build the result list.
    final childrenByParent = <String, List<ReducerMessage>>{};
    final lifecycleEvents = <String>{};

    // Identify lifecycle events (start/stop) — they won't be in children
    for (final msg in messages) {
      if (msg.isAgentEvent && msg.metadata?['subagentLifecycle'] != null) {
        lifecycleEvents.add(msg.id);
      }
    }

    // Assign sub-agent messages to their parent's children list.
    // Normalize role: 'user' → 'agent' for sub-agent text messages, because
    // from the UI perspective these are the main agent's instructions to the
    // sub-agent — not human-authored user messages.
    for (final msg in messages) {
      final sid = msg.subagentId;
      if (sid == null) continue;
      final parentId = subagentToParent[sid];
      if (parentId == null) continue;

      // Skip lifecycle events (start/stop) from children — they're boundary markers
      if (lifecycleEvents.contains(msg.id)) continue;

      final normalizedMsg = msg.isText && msg.metadata?['role'] == 'user'
          ? msg.copyWith(metadata: {
              ...?msg.metadata,
              'role': 'agent',
              'sourceRole': 'agent',
            })
          : msg;
      childrenByParent.putIfAbsent(parentId, () => []).add(normalizedMsg);
    }

    if (childrenByParent.isEmpty) return messages;

    // Phase 3: Build the final list, nesting children into parent tool calls.
    final childIds = <String>{};
    for (final children in childrenByParent.values) {
      for (final child in children) {
        childIds.add(child.id);
      }
    }

    final result = <ReducerMessage>[];
    for (final msg in messages) {
      // Skip children that have been nested
      if (childIds.contains(msg.id)) continue;
      // Skip lifecycle events (start/stop) — they're consumed during nesting
      if (lifecycleEvents.contains(msg.id)) continue;

      // Check if this message is a parent with children
      final children = childrenByParent[msg.id];
      if (children != null && children.isNotEmpty) {
        result.add(msg.copyWith(children: children));
      } else {
        result.add(msg);
      }
    }

    return result;
  }

  /// Upgrades tool call statuses from non-terminal (`pending`/`approved`/`executing`)
  /// to terminal (`completed`/`failed`) for any tool whose enclosing turn has ended.
  ///
  /// When the server returns historical messages, some tool-call-start events may
  /// not have a matching tool-call-end (e.g. session was interrupted).  The visual
  /// state resolver would otherwise show an "auto-processing" spinner for these
  /// stale tool calls.  This method resolves them to a terminal state so the UI
  /// renders them correctly.
  List<ReducerMessage> _resolveHistoricalToolCallStatuses(
    List<ReducerMessage> messages,
  ) {
    if (messages.isEmpty) return messages;

    // Collect tool call indices and turn-close events.
    final toolIndices = <int>[];
    final turnCloseIndices = <(int index, bool abandoned)>[];
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      if (msg.tool != null) {
        toolIndices.add(i);
      }
      if (msg.isTurnClose) {
        turnCloseIndices.add((i, msg.turnClose?.abandoned ?? false));
      }
    }
    if (toolIndices.isEmpty || turnCloseIndices.isEmpty) return messages;

    var modified = false;
    final result = List<ReducerMessage>.of(messages, growable: false);

    for (final toolIndex in toolIndices) {
      final msg = result[toolIndex];
      final status = msg.tool!.status ?? ToolCallStatus.pending;
      if (status == ToolCallStatus.completed ||
          status == ToolCallStatus.failed ||
          status == ToolCallStatus.rejected) {
        continue;
      }

      // Find the nearest turn-close after this tool call.
      for (final (closeIndex, abandoned) in turnCloseIndices) {
        if (closeIndex > toolIndex) {
          final newStatus =
              abandoned ? ToolCallStatus.failed : ToolCallStatus.completed;
          result[toolIndex] = msg.copyWith(
            tool: msg.tool!.copyWith(
              status: newStatus,
              error: abandoned ? (msg.tool!.error ?? 'Turn abandoned') : null,
            ),
          );
          modified = true;
          break;
        }
      }
    }

    return modified ? List<ReducerMessage>.unmodifiable(result) : messages;
  }

  /// Finds the nearest preceding Task/Agent tool-call message before [messageId].
  String? _findParentToolCall(List<ReducerMessage> messages, String messageId) {
    var targetIndex = -1;
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].id == messageId) {
        targetIndex = i;
        break;
      }
    }
    if (targetIndex <= 0) return null;

    // Walk backwards to find the nearest Task/Agent tool call
    for (var i = targetIndex - 1; i >= 0; i--) {
      final msg = messages[i];
      if (msg.isToolCall &&
          (msg.tool?.name == 'Task' || msg.tool?.name == 'Agent')) {
        return msg.id;
      }
    }
    return null;
  }
}
