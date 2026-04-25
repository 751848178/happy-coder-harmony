part of '../session_detail.dart';

extension _SessionScreenRefreshNewerHistory on _SessionScreenState {
  Future<void> _loadNewerArchivedMessages({
    bool adjustScrollAfterLoad = true,
  }) async {
    if (_isLoadingNewerMessages ||
        !_hasNewerMessages ||
        (!_hasLocallyAccessibleNewerArchivedMessages &&
            !_hasCompleteArchivedMessageHistory)) {
      return;
    }
    _isLoadingNewerMessagesN.value = true;
    final beforeWindowStart = _messageWindowStartIndex;
    final beforeLoadedCount = _messages.length;
    final beforeOffset = _scrollController.hasClients
        ? _scrollController.effectivePosition.pixels
        : null;
    final beforeMaxScroll = _scrollController.hasClients
        ? _scrollController.effectivePosition.maxScrollExtent
        : null;
    // Capture from BOTTOM of viewport: appendMessageWindow trims from
    // the head when the window exceeds 288 messages.  The bottom-most
    // visible message survives head trimming, while the top-most one does not.
    final anchor = adjustScrollAfterLoad
        ? _captureMessageViewportAnchor(alignToBottom: true)
        : null;
    Logger.info(
      '[SessionWindowDiag] load-newer start session=${widget.sessionId} '
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
          .shiftSessionMessageArchiveWindowNewer(widget.sessionId);
      Logger.info(
        '[SessionArchive] load-newer result session=${widget.sessionId} '
        'loaded=$loaded ${_debugMessageWindowSummary()} ${_debugScrollSummary()}',
      );
      if (!loaded) {
        return;
      }
      // Sliding archive windows append at the tail and trim from the head.
      // Here too, maxScrollExtent delta is only a net height change and
      // cannot preserve the visible anchor accurately. Let anchor restore
      // perform the only correction to avoid visible double-jumps.
      _suppressContentFlickerN.value = adjustScrollAfterLoad;
      _syncMessagesFromRepository();
      final afterOffset = _scrollController.hasClients
          ? _scrollController.effectivePosition.pixels
          : null;
      final afterMaxScroll = _scrollController.hasClients
          ? _scrollController.effectivePosition.maxScrollExtent
          : null;
      Logger.info(
        '[SessionWindowDiag] load-newer synced session=${widget.sessionId} '
        'delta(start=${_messageWindowStartIndex - beforeWindowStart} '
        'loaded=${_messages.length - beforeLoadedCount} '
        'offset=${beforeOffset == null || afterOffset == null ? "na" : (afterOffset - beforeOffset).toStringAsFixed(1)} '
        'max=${beforeMaxScroll == null || afterMaxScroll == null ? "na" : (afterMaxScroll - beforeMaxScroll).toStringAsFixed(1)}) '
        '${_debugMessageWindowSummary()} ${_debugScrollSummary()} '
        '${_debugVisibleMessageSummary()} ${_debugArchiveAccessSummary()} '
        '${_viewportController.debugEdgeLoadStateSummary()} '
        '${anchor == null ? "" : _debugAnchorStateSummary(anchor.messageId, rowId: anchor.rowId)}',
      );
      _viewportController.recordEdgeLoadCompleted('newer');
      _hasScrolledToLatest = !_hasNewerMessages;
      _shouldStickToLatestN.value = !_hasNewerMessages;
      _hasUnreadMessagesN.value = false;
      if (adjustScrollAfterLoad) {
        await _restoreMessageViewportAnchorAfterFrame(anchor);
      } else {
        _scheduleViewportStateRefresh();
      }
      Logger.info(
        '[SessionWindowDiag] load-newer end session=${widget.sessionId} '
        '${_debugMessageWindowSummary()} ${_debugScrollSummary()} '
        '${_debugVisibleMessageSummary()} ${_debugArchiveAccessSummary()}',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('返回较新消息失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (adjustScrollAfterLoad) {
        _suppressContentFlickerN.value = false;
      }
      _isLoadingNewerMessagesN.value = false;
    }
  }

  Future<bool> _loadLatestArchivedMessages({
    bool adjustScrollAfterLoad = true,
  }) async {
    if (_isLoadingNewerMessages) {
      return false;
    }
    if (!_hasCompleteArchivedMessageHistory) {
      final ready = await _awaitArchivedMessageHistoryAccessible();
      if (!ready) {
        return false;
      }
    }
    if (!_hasNewerMessages && !_hasOlderMessages) {
      return true;
    }
    _isLoadingNewerMessagesN.value = true;
    Logger.info(
      '[SessionArchive] load-latest start session=${widget.sessionId} '
      'adjust=$adjustScrollAfterLoad ${_debugMessageWindowSummary()} '
      '${_debugScrollSummary()}',
    );
    try {
      final loaded = await ref
          .read(sessionStateProvider.notifier)
          .loadLatestSessionMessageArchiveWindow(
            widget.sessionId,
            residentWindowSize:
                SessionServiceNotifier.sessionDetailAutomaticMessageWindowSize,
          );
      Logger.info(
        '[SessionArchive] load-latest result session=${widget.sessionId} '
        'loaded=$loaded ${_debugMessageWindowSummary()} ${_debugScrollSummary()}',
      );
      if (!loaded) {
        return false;
      }
      // Prepare synchronous bottom-alignment so the viewport jumps to the
      // bottom of the new content during layout — prevents the one-frame
      // white flash when replacing the entire message window.
      if (adjustScrollAfterLoad) {
        _scrollController.standbyForBottomJump();
      }
      _syncMessagesFromRepository();
      Logger.info(
        '[SessionJumpDiag] load-latest synced session=${widget.sessionId} '
        '${_debugMessageWindowSummary()} ${_debugScrollSummary()} '
        '${_debugVisibleMessageSummary()} '
        '${_viewportController.debugEdgeLoadStateSummary()}',
      );
      _viewportController.recordEdgeLoadCompleted('newer-boundary');
      _hasScrolledToLatest = true;
      _shouldStickToLatestN.value = true;
      _hasUnreadMessagesN.value = false;
      if (adjustScrollAfterLoad) {
        _scheduleScrollToLatest(force: true);
      } else {
        _scheduleViewportStateRefresh();
      }
      Logger.info(
        '[SessionArchive] load-latest end session=${widget.sessionId} '
        '${_debugMessageWindowSummary()} ${_debugScrollSummary()}',
      );
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载最新消息失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return false;
    } finally {
      _isLoadingNewerMessagesN.value = false;
    }
  }
}
