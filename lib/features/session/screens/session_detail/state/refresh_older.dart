part of '../session_detail.dart';

extension _SessionScreenRefreshOlderHistory on _SessionScreenState {
  Future<void> _loadOlderArchivedMessages({
    bool adjustScrollAfterLoad = true,
  }) async {
    if (_isLoadingOlderMessages ||
        !_hasOlderMessages ||
        (!_hasLocallyAccessibleOlderArchivedMessages &&
            !_hasCompleteArchivedMessageHistory)) {
      return;
    }
    _isLoadingOlderMessagesN.value = true;
    final beforeWindowStart = _messageWindowStartIndex;
    final beforeLoadedCount = _messages.length;
    final beforeOffset = _scrollController.hasClients
        ? _scrollController.effectivePosition.pixels
        : null;
    final beforeMaxScroll = _scrollController.hasClients
        ? _scrollController.effectivePosition.maxScrollExtent
        : null;
    // Capture from TOP of viewport: prependMessageWindow trims from the
    // tail when the window exceeds 288 messages.  The top-most visible
    // message survives tail trimming, while the bottom-most one does not.
    final anchor = adjustScrollAfterLoad
        ? _captureMessageViewportAnchor(alignToBottom: false)
        : null;
    Logger.info(
      '[SessionWindowDiag] load-older start session=${widget.sessionId} '
      'adjust=$adjustScrollAfterLoad anchor=${anchor?.messageId ?? "none"} '
      'before(start=$beforeWindowStart loaded=$beforeLoadedCount '
      'offset=${beforeOffset?.toStringAsFixed(1) ?? "na"} '
      'max=${beforeMaxScroll?.toStringAsFixed(1) ?? "na"}) '
      '${_debugMessageWindowSummary()} ${_debugScrollSummary()} '
      '${_debugArchiveAccessSummary()} '
      '${anchor == null ? "" : _debugAnchorStateSummary(anchor.messageId, rowId: anchor.rowId)}',
    );
    try {
      final loaded = await ref
          .read(sessionStateProvider.notifier)
          .shiftSessionMessageArchiveWindowOlder(widget.sessionId);
      Logger.info(
        '[SessionArchive] load-older result session=${widget.sessionId} '
        'loaded=$loaded ${_debugMessageWindowSummary()} ${_debugScrollSummary()}',
      );
      if (!loaded) {
        return;
      }
      // Sliding archive windows prepend at the head and trim from the tail.
      // In that case maxScrollExtent delta is only a net height change, not
      // the actual height inserted above the viewport, so standby-based
      // synchronous correction will overshoot and then anchor restore jumps
      // back again. Rely on anchor restoration only.
      _suppressContentFlickerN.value = adjustScrollAfterLoad;
      _syncMessagesFromRepository();
      final afterOffset = _scrollController.hasClients
          ? _scrollController.effectivePosition.pixels
          : null;
      final afterMaxScroll = _scrollController.hasClients
          ? _scrollController.effectivePosition.maxScrollExtent
          : null;
      Logger.info(
        '[SessionWindowDiag] load-older synced session=${widget.sessionId} '
        'delta(start=${_messageWindowStartIndex - beforeWindowStart} '
        'loaded=${_messages.length - beforeLoadedCount} '
        'offset=${beforeOffset == null || afterOffset == null ? "na" : (afterOffset - beforeOffset).toStringAsFixed(1)} '
        'max=${beforeMaxScroll == null || afterMaxScroll == null ? "na" : (afterMaxScroll - beforeMaxScroll).toStringAsFixed(1)}) '
        '${_debugMessageWindowSummary()} ${_debugScrollSummary()} '
        '${_debugVisibleMessageSummary()} ${_debugArchiveAccessSummary()} '
        '${_viewportController.debugEdgeLoadStateSummary()} '
        '${anchor == null ? "" : _debugAnchorStateSummary(anchor.messageId, rowId: anchor.rowId)}',
      );
      _viewportController.recordEdgeLoadCompleted('older');
      // Don't clear _hasScrolledToLatest here — this is an incremental
      // edge load during user scrolling, not a boundary jump.  Clearing
      // it allows _SessionScreenBodyEffects to fire scroll-to-latest
      // when the user explicitly scrolled up.
      _shouldStickToLatestN.value = false;
      if (adjustScrollAfterLoad) {
        await _restoreMessageViewportAnchorAfterFrame(
          anchor,
          fallbackOffset: beforeOffset,
          fallbackMaxScrollExtent: beforeMaxScroll,
        );
      } else {
        _scheduleViewportStateRefresh();
      }
      Logger.info(
        '[SessionWindowDiag] load-older end session=${widget.sessionId} '
        '${_debugMessageWindowSummary()} ${_debugScrollSummary()} '
        '${_debugVisibleMessageSummary()} ${_debugArchiveAccessSummary()}',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载更早消息失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (adjustScrollAfterLoad) {
        _suppressContentFlickerN.value = false;
      }
      _isLoadingOlderMessagesN.value = false;
    }
  }

  Future<bool> _loadEarliestArchivedMessages({
    bool adjustScrollAfterLoad = true,
  }) async {
    if (_isLoadingOlderMessages) {
      return false;
    }
    if (!_hasCompleteArchivedMessageHistory &&
        !_canJumpToEarliestArchivedBoundary) {
      final ready = await _awaitArchivedMessageHistoryAccessible();
      if (!ready) {
        return false;
      }
    }
    if (_messageWindowStartIndex <= 0) {
      return true;
    }
    _isLoadingOlderMessagesN.value = true;
    Logger.info(
      '[SessionArchive] load-earliest start session=${widget.sessionId} '
      'adjust=$adjustScrollAfterLoad ${_debugMessageWindowSummary()} '
      '${_debugScrollSummary()}',
    );
    try {
      final loaded = await ref
          .read(sessionStateProvider.notifier)
          .loadEarliestSessionMessageArchiveWindow(
            widget.sessionId,
            residentWindowSize:
                SessionServiceNotifier.sessionDetailAutomaticMessageWindowSize,
          );
      Logger.info(
        '[SessionArchive] load-earliest result session=${widget.sessionId} '
        'loaded=$loaded ${_debugMessageWindowSummary()} ${_debugScrollSummary()}',
      );
      if (!loaded) {
        return false;
      }
      _syncMessagesFromRepository();
      Logger.info(
        '[SessionJumpDiag] load-earliest synced session=${widget.sessionId} '
        '${_debugMessageWindowSummary()} ${_debugScrollSummary()} '
        '${_debugVisibleMessageSummary()} '
        '${_viewportController.debugEdgeLoadStateSummary()}',
      );
      _viewportController.recordEdgeLoadCompleted('older-boundary');
      _hasScrolledToLatest = false;
      _shouldStickToLatestN.value = false;
      if (adjustScrollAfterLoad) {
        await _jumpToHistoryWindowOffsetAfterFrame(
          (position) => position.minScrollExtent,
        );
      } else {
        _scheduleViewportStateRefresh();
      }
      Logger.info(
        '[SessionArchive] load-earliest end session=${widget.sessionId} '
        '${_debugMessageWindowSummary()} ${_debugScrollSummary()}',
      );
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载最早消息失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return false;
    } finally {
      _isLoadingOlderMessagesN.value = false;
    }
  }
}
