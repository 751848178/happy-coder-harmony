part of 'session_service.dart';

extension _SessionServiceMessageArchiveQueries
    on _SessionServiceMessageArchiveCoordinator {
  Future<int> getSessionMessageArchiveCount(String sessionId) {
    return StorageService.instance.getSessionMessageArchiveCount(sessionId);
  }

  Future<storage_models.SessionMessageArchiveSummary>
      getSessionMessageArchiveSummary(
    String sessionId,
  ) {
    return StorageService.instance.getSessionMessageArchiveSummary(sessionId);
  }

  Future<List<storage_models.SessionArchivedTurnSummary>>
      loadSessionMessageArchiveTurnSummaries(
    String sessionId,
  ) {
    return StorageService.instance.loadSessionArchivedTurnSummaries(sessionId);
  }

  Future<bool> ensureSessionMessageArchiveHydrated(
    String sessionId, {
    bool throwOnError = false,
  }) async {
    final existing = _notifier._repository.getSessionMessages(sessionId);
    if (existing == null ||
        existing.totalMessageCount <= existing.messages.length) {
      return false;
    }
    final summary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    final expectedMessageCount = _resolveExpectedArchiveMessageCount(
      sessionId,
      existing: existing,
    );
    if (_isArchiveSummaryCompleteForExpectedCount(
      summary,
      expectedMessageCount: expectedMessageCount,
    )) {
      return false;
    }
    if (_notifier.getSession(sessionId) == null ||
        !_notifier._sessionDataKeys.containsKey(sessionId)) {
      await _notifier.loadSessions(
        force: _notifier.getSession(sessionId) == null,
      );
      if (_notifier.getSession(sessionId) == null) {
        return false;
      }
    }

    try {
      await _runArchiveHydrationTask(
        sessionId,
        throwOnError: true,
      );
      return true;
    } catch (error) {
      Logger.warning(
        'Failed to hydrate full session archive for $sessionId: $error',
      );
      if (throwOnError) {
        rethrow;
      }
      return false;
    }
  }
}
