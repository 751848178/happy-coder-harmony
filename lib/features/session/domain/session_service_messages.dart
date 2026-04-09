part of 'session_service.dart';

extension SessionServiceMessageOperations on SessionServiceNotifier {
  Future<void> loadSessionMessages(
    String sessionId, {
    bool force = false,
    bool throwOnError = false,
    bool preserveOptimisticMessages = true,
    int? maxPages,
    int? messageWindowSize,
  }) =>
      _messageCoordinator.loadSessionMessages(
        sessionId,
        force: force,
        throwOnError: throwOnError,
        preserveOptimisticMessages: preserveOptimisticMessages,
        maxPages: maxPages,
        messageWindowSize: messageWindowSize,
      );

  Future<void> syncFullSessionMessagesFromRemote(
    String sessionId, {
    bool throwOnError = false,
  }) =>
      _messageArchiveCoordinator.syncFullSessionMessagesFromRemote(
        sessionId,
        throwOnError: throwOnError,
      );

  Future<bool> ensureSessionMessageArchiveHydrated(
    String sessionId, {
    bool throwOnError = false,
  }) =>
      _messageArchiveCoordinator.ensureSessionMessageArchiveHydrated(
        sessionId,
        throwOnError: throwOnError,
      );

  Future<int> getSessionMessageArchiveCount(String sessionId) =>
      _messageArchiveCoordinator.getSessionMessageArchiveCount(sessionId);

  Future<storage_models.SessionMessageArchiveSummary>
      getSessionMessageArchiveSummary(
    String sessionId,
  ) =>
          _messageArchiveCoordinator.getSessionMessageArchiveSummary(sessionId);

  Future<List<storage_models.SessionArchivedTurnSummary>>
      loadSessionMessageArchiveTurnSummaries(
    String sessionId,
  ) =>
          _messageArchiveCoordinator.loadSessionMessageArchiveTurnSummaries(
            sessionId,
          );

  Future<bool> shiftSessionMessageArchiveWindowOlder(
    String sessionId, {
    int residentWindowSize =
        SessionServiceNotifier.sessionDetailResidentMessageWindowSize,
    int shiftSize = SessionServiceNotifier.sessionDetailArchiveWindowShiftSize,
  }) =>
      _messageArchiveCoordinator.shiftSessionMessageArchiveWindowOlder(
        sessionId,
        residentWindowSize: residentWindowSize,
        shiftSize: shiftSize,
      );

  Future<bool> shiftSessionMessageArchiveWindowNewer(
    String sessionId, {
    int residentWindowSize =
        SessionServiceNotifier.sessionDetailResidentMessageWindowSize,
    int shiftSize = SessionServiceNotifier.sessionDetailArchiveWindowShiftSize,
  }) =>
      _messageArchiveCoordinator.shiftSessionMessageArchiveWindowNewer(
        sessionId,
        residentWindowSize: residentWindowSize,
        shiftSize: shiftSize,
      );

  Future<bool> loadEarliestSessionMessageArchiveWindow(
    String sessionId, {
    int residentWindowSize =
        SessionServiceNotifier.sessionDetailResidentMessageWindowSize,
  }) =>
      _messageArchiveCoordinator.loadEarliestSessionMessageArchiveWindow(
        sessionId,
        residentWindowSize: residentWindowSize,
      );

  Future<bool> loadLatestSessionMessageArchiveWindow(
    String sessionId, {
    int residentWindowSize =
        SessionServiceNotifier.sessionDetailResidentMessageWindowSize,
  }) =>
      _messageArchiveCoordinator.loadLatestSessionMessageArchiveWindow(
        sessionId,
        residentWindowSize: residentWindowSize,
      );

  Future<bool> loadSessionMessageArchiveWindowAround(
    String sessionId, {
    required int anchorArchiveIndex,
    int residentWindowSize =
        SessionServiceNotifier.sessionDetailResidentMessageWindowSize,
  }) =>
      _messageArchiveCoordinator.loadSessionMessageArchiveWindowAround(
        sessionId,
        anchorArchiveIndex: anchorArchiveIndex,
        residentWindowSize: residentWindowSize,
      );

  Future<void> refreshSessionMessageSnapshots(
    Iterable<String> sessionIds, {
    int batchSize = 4,
    bool force = false,
    int? maxPagesPerSession,
  }) =>
      _messageCoordinator.refreshSessionMessageSnapshots(
        sessionIds,
        batchSize: batchSize,
        force: force,
        maxPagesPerSession: maxPagesPerSession,
      );

  Future<bool> restoreSessionMessagesFromCache(String sessionId) =>
      _cacheCoordinator.restoreSessionMessagesFromCache(sessionId);
}
