part of 'session_stats.dart';

int _resolveSessionMessageCount(
    Session session, List<ReducerMessage>? messages) {
  if (messages != null && messages.isNotEmpty) {
    return messages.length;
  }
  return _firstPositive([
        session.latestUsage?.messageCount,
        _deepInt(session.metadata, const ['summary', 'messageCount']),
        _deepInt(session.metadata, const ['stats', 'messageCount']),
        _deepInt(session.metadata, const ['messageCount']),
        _deepInt(session.agentState, const ['messageCount']),
        _deepInt(session.agentState, const ['summary', 'messageCount']),
        _deepInt(session.agentState, const ['stats', 'messageCount']),
        session.messages.length,
      ]) ??
      0;
}

_ChangeSummary _extractStructuredChangeSummary(Session session) {
  final candidates = <Map<String, dynamic>?>[
    session.metadata,
    _deepMap(session.metadata, const ['summary']),
    _deepMap(session.metadata, const ['stats']),
    session.agentState,
    _deepMap(session.agentState, const ['summary']),
    _deepMap(session.agentState, const ['stats']),
  ];
  for (final candidate in candidates) {
    if (candidate == null) {
      continue;
    }
    final added = _firstPositive([
      _deepInt(candidate, const ['linesAdded']),
      _deepInt(candidate, const ['addedLines']),
      _deepInt(candidate, const ['insertions']),
    ]);
    final removed = _firstPositive([
      _deepInt(candidate, const ['linesRemoved']),
      _deepInt(candidate, const ['removedLines']),
      _deepInt(candidate, const ['deletions']),
    ]);
    final changed = _firstPositive([
      _deepInt(candidate, const ['linesChanged']),
      _deepInt(candidate, const ['changedLines']),
      _deepInt(candidate, const ['modifiedLines']),
      _deepInt(candidate, const ['lineCount']),
      _deepInt(candidate, const ['modifiedCount']),
      if (added != null || removed != null) (added ?? 0) + (removed ?? 0),
    ]);
    if (changed != null || added != null || removed != null) {
      return _ChangeSummary(
        changedLines: changed,
        addedLines: added,
        removedLines: removed,
      );
    }
  }
  return const _ChangeSummary();
}

_ChangeSummary _extractMessageChangeSummary(List<ReducerMessage> messages) {
  var addedLines = 0;
  var removedLines = 0;
  for (final message in messages) {
    final textSummary = _extractPatchSummary(message.text);
    addedLines += textSummary.addedLines ?? 0;
    removedLines += textSummary.removedLines ?? 0;
    final tool = message.tool;
    if (tool == null) {
      continue;
    }
    final arguments = tool.arguments;
    final patchSummary = _extractPatchSummary(
      _firstString([
        arguments['patch'],
        arguments['diff'],
        arguments['content'],
        tool.result,
      ]),
    );
    addedLines += patchSummary.addedLines ?? 0;
    removedLines += patchSummary.removedLines ?? 0;
    final oldText = arguments['oldText'];
    final newText = arguments['newText'];
    if (oldText is String && newText is String) {
      final editSummary = _extractReplacementSummary(oldText, newText);
      addedLines += editSummary.addedLines ?? 0;
      removedLines += editSummary.removedLines ?? 0;
    }
  }
  return _ChangeSummary(
    changedLines: addedLines + removedLines,
    addedLines: addedLines,
    removedLines: removedLines,
  );
}
