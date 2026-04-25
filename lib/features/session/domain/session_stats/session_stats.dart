import 'package:flutter/foundation.dart';

import '../reducer.dart';
import '../session_local_snapshot.dart';
import '../session_models.dart';

part 'helpers.dart';
part 'summary.dart';

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
    final metadataSummary = _extractStructuredChangeSummary(session);
    final messageSummary = messages == null || messages.isEmpty
        ? const _ChangeSummary()
        : _extractMessageChangeSummary(messages);
    return _buildSessionStats(
      messageCount: _resolveSessionMessageCount(session, messages),
      metadataSummary: metadataSummary,
      messageSummary: messageSummary,
    );
  }

  static SessionStats fromSessionPreview({
    required Session session,
    List<ReducerMessage>? messages,
  }) {
    return _buildSessionStats(
      messageCount: _resolveSessionMessageCount(session, messages),
      metadataSummary: _extractStructuredChangeSummary(session),
      messageSummary: const _ChangeSummary(),
    );
  }

  static SessionStats _buildSessionStats({
    required int messageCount,
    required _ChangeSummary metadataSummary,
    required _ChangeSummary messageSummary,
  }) {
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

class SessionStatsSnapshotRequest {
  const SessionStatsSnapshotRequest({
    required this.sessionId,
    required this.session,
    required this.messages,
  });

  final String sessionId;
  final Session session;
  final List<ReducerMessage>? messages;

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'session': session.toJson(),
      'messages': messages?.map((message) => message.toJson()).toList(),
    };
  }
}

Future<Map<String, SessionStats>> computeSessionStatsBatch(
  Iterable<SessionStatsSnapshotRequest> requests,
) async {
  final payloads =
      requests.map((request) => request.toJson()).toList(growable: false);
  if (payloads.isEmpty) {
    return const <String, SessionStats>{};
  }

  final results = await compute(_computeSessionStatsBatch, payloads);
  return {
    for (final result in results)
      result['sessionId']?.toString() ?? '': SessionStats(
        messageCount: result['messageCount'] as int? ?? 0,
        changedLineCount: result['changedLineCount'] as int? ?? 0,
        addedLineCount: result['addedLineCount'] as int? ?? 0,
        removedLineCount: result['removedLineCount'] as int? ?? 0,
      ),
  };
}

List<Map<String, dynamic>> _computeSessionStatsBatch(
  List<Map<String, dynamic>> payloads,
) {
  return payloads.map((payload) {
    final session = Session.fromJson(
        payload['session'] as Map<String, dynamic>? ?? const {});
    final messages = (payload['messages'] as List<dynamic>? ?? const [])
        .map((item) => ReducerMessage.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    final stats = SessionStatsCalculator.fromSession(
      session: session,
      messages: messages,
    );
    return {
      'sessionId': payload['sessionId']?.toString() ?? session.id,
      'messageCount': stats.messageCount,
      'changedLineCount': stats.changedLineCount,
      'addedLineCount': stats.addedLineCount,
      'removedLineCount': stats.removedLineCount,
    };
  }).toList(growable: false);
}
