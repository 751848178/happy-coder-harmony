part of 'session_service.dart';

extension _SessionServiceMessageArchiveRange
    on _SessionServiceMessageArchiveCoordinator {
  Future<List<ReducerMessage>> _loadArchiveRange(
    String sessionId, {
    required int startIndex,
    required int limit,
    required int expectedTotalCount,
    bool allowRepair = true,
  }) async {
    final summary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    var archivedMessages =
        await StorageService.instance.loadSessionMessageArchiveRange(
      sessionId,
      startIndex: startIndex,
      limit: limit,
    );
    if (archivedMessages.isEmpty &&
        summary.messageCount > 0 &&
        await _recoverCorruptedSessionArchive(
          sessionId,
          expectedMessageCount: expectedTotalCount > 0
              ? expectedTotalCount
              : summary.messageCount,
        )) {
      archivedMessages =
          await StorageService.instance.loadSessionMessageArchiveRange(
        sessionId,
        startIndex: startIndex,
        limit: limit,
      );
    }
    if (archivedMessages.isEmpty) {
      return const <ReducerMessage>[];
    }
    final refreshedSummary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    final availableCount = _resolveWindowTotalMessageCount(
      expectedTotalCount,
      refreshedSummary.messageCount,
      startIndex + archivedMessages.length,
    );
    final expectedLoadedCount = availableCount <= startIndex
        ? 0
        : ((startIndex + limit) > availableCount
            ? availableCount - startIndex
            : limit);
    if (allowRepair &&
        refreshedSummary.isComplete &&
        expectedLoadedCount > 0 &&
        archivedMessages.length < expectedLoadedCount) {
      Logger.warning(
        'Archived page was shorter than expected; repairing session archive: '
        '$sessionId (start=$startIndex, expected=$expectedLoadedCount, '
        'actual=${archivedMessages.length}, total=$availableCount)',
      );
      final repaired = await _recoverCorruptedSessionArchive(
        sessionId,
        expectedMessageCount: availableCount,
      );
      if (!repaired) {
        return const <ReducerMessage>[];
      }
      return _loadArchiveRange(
        sessionId,
        startIndex: startIndex,
        limit: limit,
        expectedTotalCount: expectedTotalCount,
        allowRepair: false,
      );
    }
    return archivedMessages;
  }

  Future<bool> _recoverCorruptedSessionArchive(
    String sessionId, {
    required int expectedMessageCount,
  }) async {
    Logger.warning(
      'Session archive window was unavailable despite non-empty summary: '
      '$sessionId (expected=$expectedMessageCount)',
    );
    if (_notifier.getSession(sessionId) == null) {
      await StorageService.instance.saveSessionMessageArchiveSummary(
        sessionId,
        messageCount: expectedMessageCount,
        isComplete: false,
        lastRemoteSeq: 0,
      );
      return false;
    }
    await StorageService.instance.clearSessionMessageArchive(sessionId);
    await syncFullSessionMessagesFromRemote(
      sessionId,
      throwOnError: true,
    );
    return true;
  }
}
