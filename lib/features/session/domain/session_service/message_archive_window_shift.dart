part of 'session_service.dart';

extension _SessionServiceMessageArchiveWindowShift
    on _SessionServiceMessageArchiveCoordinator {
  Future<bool> shiftSessionMessageArchiveWindowOlder(
    String sessionId, {
    int residentWindowSize =
        SessionServiceNotifier.sessionDetailResidentMessageWindowSize,
    int shiftSize = SessionServiceNotifier.sessionDetailArchiveWindowShiftSize,
  }) async {
    final existing = _notifier._repository.getSessionMessages(sessionId);
    if (existing == null || existing.windowStartIndex <= 0) {
      return false;
    }
    final beforeStartIndex = existing.windowStartIndex;
    final beforeFirstMessageId =
        existing.messages.isEmpty ? null : existing.messages.first.id;
    final beforeLastMessageId =
        existing.messages.isEmpty ? null : existing.messages.last.id;
    final summary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    if (summary.messageCount <= 0 ||
        existing.windowStartIndex > summary.messageCount) {
      return false;
    }
    final pageSize = existing.windowStartIndex > shiftSize
        ? shiftSize
        : existing.windowStartIndex;
    if (pageSize <= 0) {
      return false;
    }
    final pageStartIndex = existing.windowStartIndex - pageSize;
    final olderMessages = await _loadArchiveRange(
      sessionId,
      startIndex: pageStartIndex,
      limit: pageSize,
      expectedTotalCount: summary.messageCount,
    );
    if (olderMessages.isEmpty) {
      return false;
    }
    _notifier._repository.prependMessageWindow(
      sessionId,
      olderMessages,
      totalMessageCount: _resolveWindowTotalMessageCount(
        existing.totalMessageCount,
        summary.messageCount,
        pageStartIndex + olderMessages.length,
      ),
      maxWindowSize: residentWindowSize,
    );
    final updated = _notifier._repository.getSessionMessages(sessionId);
    final effectiveAdvance = updated != null &&
        (updated.windowStartIndex != beforeStartIndex ||
            (updated.messages.isEmpty ? null : updated.messages.first.id) !=
                beforeFirstMessageId ||
            (updated.messages.isEmpty ? null : updated.messages.last.id) !=
                beforeLastMessageId);
    if (!effectiveAdvance) {
      Logger.warning(
        'Prepended archive page did not advance resident window: $sessionId '
        '(requestedStart=$pageStartIndex, loaded=${olderMessages.length}, '
        'resident=$residentWindowSize, start=$beforeStartIndex)',
      );
      return false;
    }
    await _notifier._persistSessionCacheImmediately(sessionId);
    Logger.info(
      'Prepended archived page for session: $sessionId '
      '(start=$pageStartIndex, loaded=${olderMessages.length}, '
      'resident=${residentWindowSize})',
    );
    return true;
  }

  Future<bool> shiftSessionMessageArchiveWindowNewer(
    String sessionId, {
    int residentWindowSize =
        SessionServiceNotifier.sessionDetailResidentMessageWindowSize,
    int shiftSize = SessionServiceNotifier.sessionDetailArchiveWindowShiftSize,
  }) async {
    final existing = _notifier._repository.getSessionMessages(sessionId);
    if (existing == null || existing.hasNewerMessages != true) {
      return false;
    }
    final beforeStartIndex = existing.windowStartIndex;
    final beforeFirstMessageId =
        existing.messages.isEmpty ? null : existing.messages.first.id;
    final beforeLastMessageId =
        existing.messages.isEmpty ? null : existing.messages.last.id;
    final summary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    final currentWindowEnd =
        existing.windowStartIndex + existing.messages.length;
    if (summary.messageCount <= currentWindowEnd) {
      return false;
    }
    final remaining = summary.messageCount - currentWindowEnd;
    final pageSize = remaining > shiftSize ? shiftSize : remaining;
    if (pageSize <= 0) {
      return false;
    }
    final newerMessages = await _loadArchiveRange(
      sessionId,
      startIndex: currentWindowEnd,
      limit: pageSize,
      expectedTotalCount: summary.messageCount,
    );
    if (newerMessages.isEmpty) {
      return false;
    }
    _notifier._repository.appendMessageWindow(
      sessionId,
      newerMessages,
      totalMessageCount: _resolveWindowTotalMessageCount(
        existing.totalMessageCount,
        summary.messageCount,
        currentWindowEnd + newerMessages.length,
      ),
      maxWindowSize: residentWindowSize,
    );
    final updated = _notifier._repository.getSessionMessages(sessionId);
    final effectiveAdvance = updated != null &&
        (updated.windowStartIndex != beforeStartIndex ||
            (updated.messages.isEmpty ? null : updated.messages.first.id) !=
                beforeFirstMessageId ||
            (updated.messages.isEmpty ? null : updated.messages.last.id) !=
                beforeLastMessageId);
    if (!effectiveAdvance) {
      Logger.warning(
        'Appended archive page did not advance resident window: $sessionId '
        '(requestedStart=$currentWindowEnd, loaded=${newerMessages.length}, '
        'resident=$residentWindowSize, start=$beforeStartIndex)',
      );
      return false;
    }
    await _notifier._persistSessionCacheImmediately(sessionId);
    Logger.info(
      'Appended archived page for session: $sessionId '
      '(start=$currentWindowEnd, loaded=${newerMessages.length}, '
      'resident=${residentWindowSize})',
    );
    return true;
  }
}
