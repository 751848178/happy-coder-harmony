import 'reducer.dart';
import 'session_models.dart';

class SessionStats {
  const SessionStats({
    required this.messageCount,
    required this.changedLineCount,
    required this.addedLineCount,
    required this.removedLineCount,
  });

  final int messageCount;
  final int changedLineCount;
  final int addedLineCount;
  final int removedLineCount;

  bool get hasChanges => changedLineCount > 0;
}

class SessionStatsCalculator {
  static SessionStats fromSession({
    required Session session,
    List<ReducerMessage>? messages,
  }) {
    final messageCount = _resolveMessageCount(session, messages);
    final metadataSummary = _extractStructuredChangeSummary(session);
    final messageSummary = messages == null || messages.isEmpty
        ? const _ChangeSummary()
        : _extractMessageChangeSummary(messages);

    final added = _firstPositive([
          metadataSummary.addedLines,
          messageSummary.addedLines,
        ]) ??
        0;
    final removed = _firstPositive([
          metadataSummary.removedLines,
          messageSummary.removedLines,
        ]) ??
        0;
    final changed = _firstPositive([
          metadataSummary.changedLines,
          added + removed,
          messageSummary.changedLines,
        ]) ??
        0;

    return SessionStats(
      messageCount: messageCount,
      changedLineCount: changed,
      addedLineCount: added,
      removedLineCount: removed,
    );
  }

  static int _resolveMessageCount(Session session, List<ReducerMessage>? messages) {
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

  static _ChangeSummary _extractStructuredChangeSummary(Session session) {
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

  static _ChangeSummary _extractMessageChangeSummary(List<ReducerMessage> messages) {
    var addedLines = 0;
    var removedLines = 0;

    for (final message in messages) {
      final textSummary = _extractPatchSummary(message.text);
      addedLines += textSummary.addedLines ?? 0;
      removedLines += textSummary.removedLines ?? 0;

      final tool = message.tool;
      if (tool != null) {
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
    }

    return _ChangeSummary(
      changedLines: addedLines + removedLines,
      addedLines: addedLines,
      removedLines: removedLines,
    );
  }

  static _ChangeSummary _extractPatchSummary(String? text) {
    if (text == null || text.trim().isEmpty) {
      return const _ChangeSummary();
    }

    final lines = text.split('\n');
    final looksLikePatch = text.contains('@@') ||
        text.contains('*** Begin Patch') ||
        text.contains('diff --git') ||
        text.contains('+++ ') ||
        text.contains('--- ');
    if (!looksLikePatch) {
      return const _ChangeSummary();
    }

    var added = 0;
    var removed = 0;

    for (final line in lines) {
      if (line.startsWith('+++') || line.startsWith('---')) {
        continue;
      }
      if (line.startsWith('+')) {
        added += 1;
      } else if (line.startsWith('-')) {
        removed += 1;
      }
    }

    if (added == 0 && removed == 0) {
      return const _ChangeSummary();
    }

    return _ChangeSummary(
      changedLines: added + removed,
      addedLines: added,
      removedLines: removed,
    );
  }

  static _ChangeSummary _extractReplacementSummary(
    String original,
    String modified,
  ) {
    final originalLines = original.split('\n');
    final modifiedLines = modified.split('\n');
    final maxLength = originalLines.length > modifiedLines.length
        ? originalLines.length
        : modifiedLines.length;

    var added = 0;
    var removed = 0;
    for (var index = 0; index < maxLength; index += 1) {
      final oldLine = index < originalLines.length ? originalLines[index] : null;
      final newLine = index < modifiedLines.length ? modifiedLines[index] : null;

      if (oldLine == newLine) {
        continue;
      }
      if (oldLine != null) {
        removed += 1;
      }
      if (newLine != null) {
        added += 1;
      }
    }

    return _ChangeSummary(
      changedLines: added + removed,
      addedLines: added,
      removedLines: removed,
    );
  }

  static Map<String, dynamic>? _deepMap(
    Map<String, dynamic>? source,
    List<String> path,
  ) {
    dynamic current = source;
    for (final key in path) {
      if (current is! Map) {
        return null;
      }
      current = current[key];
    }
    if (current is Map<String, dynamic>) {
      return current;
    }
    if (current is Map) {
      return current.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return null;
  }

  static int? _deepInt(Map<String, dynamic>? source, List<String> path) {
    dynamic current = source;
    for (final key in path) {
      if (current is! Map) {
        return null;
      }
      current = current[key];
    }
    return _asInt(current);
  }

  static int? _asInt(dynamic value) {
    if (value is int && value > 0) {
      return value;
    }
    if (value is double && value > 0) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static int? _firstPositive(List<int?> values) {
    for (final value in values) {
      if (value != null && value > 0) {
        return value;
      }
    }
    return null;
  }

  static String? _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}

class _ChangeSummary {
  const _ChangeSummary({
    this.changedLines,
    this.addedLines,
    this.removedLines,
  });

  final int? changedLines;
  final int? addedLines;
  final int? removedLines;
}
