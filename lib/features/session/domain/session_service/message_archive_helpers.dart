part of 'session_service.dart';

extension _SessionServiceMessageArchiveHelpers
    on _SessionServiceMessageArchiveCoordinator {
  int _resolveExpectedArchiveMessageCount(
    String sessionId, {
    SessionMessages? existing,
  }) {
    var expectedMessageCount = existing?.totalMessageCount ?? 0;
    final session = _notifier.getSession(sessionId);
    if (session != null) {
      final persistedMessageCount = resolvePersistedSessionMessageCount(
            session: session,
            loadedMessageCount:
                expectedMessageCount > 0 ? expectedMessageCount : null,
          ) ??
          0;
      if (persistedMessageCount > expectedMessageCount) {
        expectedMessageCount = persistedMessageCount;
      }
    }
    return expectedMessageCount;
  }

  bool _isArchiveSummaryCompleteForExpectedCount(
    storage_models.SessionMessageArchiveSummary summary, {
    required int expectedMessageCount,
  }) {
    if (!summary.isComplete || summary.messageCount <= 0) {
      return false;
    }
    if (expectedMessageCount <= 0) {
      return true;
    }
    return summary.messageCount >= expectedMessageCount;
  }

  int _resolveWindowTotalMessageCount(
    int existingTotalCount,
    int archivedCount,
    int loadedUpperBound,
  ) {
    var totalMessageCount = existingTotalCount;
    if (archivedCount > totalMessageCount) {
      totalMessageCount = archivedCount;
    }
    if (loadedUpperBound > totalMessageCount) {
      totalMessageCount = loadedUpperBound;
    }
    return totalMessageCount;
  }

  ReducerMessage _attachArchiveIndex(
    ReducerMessage message,
    int archiveIndex,
  ) {
    final metadata = message.metadata == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(message.metadata!);
    metadata['archiveIndex'] = archiveIndex;
    return message.copyWith(metadata: metadata);
  }
}
