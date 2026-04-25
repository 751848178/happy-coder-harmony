part of 'session_service.dart';

extension _SessionServiceMessageArchiveWindowLoad
    on _SessionServiceMessageArchiveCoordinator {
  Future<bool> loadEarliestSessionMessageArchiveWindow(
    String sessionId, {
    int residentWindowSize =
        SessionServiceNotifier.sessionDetailResidentMessageWindowSize,
  }) async {
    final existing = _notifier._repository.getSessionMessages(sessionId);
    return _loadSessionMessageArchiveWindow(
      sessionId,
      startIndex: 0,
      limit: residentWindowSize,
      fallbackTotalCount: existing?.totalMessageCount,
    );
  }

  Future<bool> loadLatestSessionMessageArchiveWindow(
    String sessionId, {
    int residentWindowSize =
        SessionServiceNotifier.sessionDetailResidentMessageWindowSize,
  }) async {
    final existing = _notifier._repository.getSessionMessages(sessionId);
    final summary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    final totalMessageCount = summary.messageCount > 0
        ? summary.messageCount
        : (existing?.totalMessageCount ?? 0);
    if (totalMessageCount <= 0) {
      return false;
    }
    final startIndex = totalMessageCount > residentWindowSize
        ? totalMessageCount - residentWindowSize
        : 0;
    return _loadSessionMessageArchiveWindow(
      sessionId,
      startIndex: startIndex,
      limit: residentWindowSize,
      fallbackTotalCount: totalMessageCount,
    );
  }

  Future<bool> loadSessionMessageArchiveWindowAround(
    String sessionId, {
    required int anchorArchiveIndex,
    int residentWindowSize =
        SessionServiceNotifier.sessionDetailResidentMessageWindowSize,
  }) async {
    final summary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    final totalMessageCount = summary.messageCount;
    if (totalMessageCount <= 0) {
      return false;
    }
    final clampedAnchor = anchorArchiveIndex.clamp(0, totalMessageCount - 1);
    final halfWindow = residentWindowSize ~/ 2;
    var startIndex = clampedAnchor - halfWindow;
    if (startIndex < 0) {
      startIndex = 0;
    }
    final maxStartIndex = totalMessageCount > residentWindowSize
        ? totalMessageCount - residentWindowSize
        : 0;
    if (startIndex > maxStartIndex) {
      startIndex = maxStartIndex;
    }
    return _loadSessionMessageArchiveWindow(
      sessionId,
      startIndex: startIndex,
      limit: residentWindowSize,
      fallbackTotalCount: totalMessageCount,
    );
  }

  Future<bool> _loadSessionMessageArchiveWindow(
    String sessionId, {
    required int startIndex,
    required int limit,
    int? fallbackTotalCount,
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
          expectedMessageCount: summary.messageCount,
        )) {
      archivedMessages =
          await StorageService.instance.loadSessionMessageArchiveRange(
        sessionId,
        startIndex: startIndex,
        limit: limit,
      );
    }
    if (archivedMessages.isEmpty) {
      return false;
    }
    final refreshedSummary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    var totalMessageCount = fallbackTotalCount ?? archivedMessages.length;
    if (refreshedSummary.messageCount > totalMessageCount) {
      totalMessageCount = refreshedSummary.messageCount;
    }
    final availableCount = totalMessageCount > 0
        ? totalMessageCount
        : refreshedSummary.messageCount;
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
        'Archived window was shorter than expected; repairing session archive: '
        '$sessionId (start=$startIndex, expected=$expectedLoadedCount, '
        'actual=${archivedMessages.length}, total=$availableCount)',
      );
      final repaired = await _recoverCorruptedSessionArchive(
        sessionId,
        expectedMessageCount: availableCount,
      );
      if (!repaired) {
        return false;
      }
      return _loadSessionMessageArchiveWindow(
        sessionId,
        startIndex: startIndex,
        limit: limit,
        fallbackTotalCount: fallbackTotalCount,
        allowRepair: false,
      );
    }
    final loadedUpperBound = startIndex + archivedMessages.length;
    if (loadedUpperBound > totalMessageCount) {
      totalMessageCount = loadedUpperBound;
    }
    _notifier._repository.replaceMessageWindow(
      sessionId,
      archivedMessages,
      totalMessageCount: totalMessageCount,
      windowStartIndex: startIndex,
    );
    await _notifier._persistSessionCacheImmediately(sessionId);
    Logger.info(
      'Loaded archived session message window: $sessionId '
      '(start=$startIndex, loaded=${archivedMessages.length}, total=$totalMessageCount)',
    );
    return true;
  }
}
