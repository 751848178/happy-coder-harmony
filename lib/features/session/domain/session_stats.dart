import 'reducer.dart';
import 'session_models.dart';

part 'session_stats_helpers.dart';
part 'session_stats_summary.dart';

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
    final messageCount = _resolveSessionMessageCount(session, messages);
    final metadataSummary = _extractStructuredChangeSummary(session);
    final messageSummary = messages == null || messages.isEmpty
        ? const _ChangeSummary()
        : _extractMessageChangeSummary(messages);
    final added = _firstPositive(
            [metadataSummary.addedLines, messageSummary.addedLines]) ??
        0;
    final removed = _firstPositive(
            [metadataSummary.removedLines, messageSummary.removedLines]) ??
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
}
