part of '../session_detail.dart';

extension _SessionScreenRefreshAnchor on _SessionScreenState {
  Future<void> _awaitPostFrame() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    return completer.future;
  }

  int _resolveExpectedArchivedHistoryMessageCount() {
    final session = ref.read(sessionStateProvider.notifier).getSession(
          widget.sessionId,
        );
    var expectedMessageCount = _totalMessageCount;
    if (session != null) {
      final persistedMessageCount = session.latestUsage?.messageCount ?? 0;
      if (persistedMessageCount > expectedMessageCount) {
        expectedMessageCount = persistedMessageCount;
      }
    }
    return expectedMessageCount;
  }

  Future<void> _refreshArchivedMessageCount() async {
    if (!mounted) {
      return;
    }
    final summary = await ref
        .read(sessionStateProvider.notifier)
        .getSessionMessageArchiveSummary(widget.sessionId);
    if (!mounted) {
      return;
    }
    final expectedMessageCount = _resolveExpectedArchivedHistoryMessageCount();
    final isEffectivelyComplete = summary.isComplete &&
        (expectedMessageCount <= 0 ||
            summary.messageCount >= expectedMessageCount);
    _archivedMessageCountN.value = summary.messageCount;
    _archivedMessageHistoryCompleteN.value = isEffectivelyComplete;
    if (_scrollController.hasClients) {
      _handleScrollMetricsChanged();
    }
    _scheduleViewportStateRefresh();
  }

  Future<bool> _awaitArchivedMessageHistoryAccessible() async {
    if (!mounted) {
      return false;
    }
    final totalCount = _totalMessageCount;
    if (totalCount <= 0 || totalCount <= _messages.length) {
      _isHydratingArchiveHistoryN.value = false;
      return false;
    }

    await _refreshArchivedMessageCount();
    if (!mounted || _hasCompleteArchivedMessageHistory) {
      return _hasCompleteArchivedMessageHistory;
    }

    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    Logger.info(
      '[SessionArchive] ensure accessible start session=${widget.sessionId} '
      'loaded=${_messages.length} total=$totalCount '
      'archived=$_archivedMessageCount complete=$_isArchivedMessageHistoryComplete',
    );
    _isHydratingArchiveHistoryN.value = true;
    try {
      final hydrated =
          await sessionNotifier.ensureSessionMessageArchiveHydrated(
        widget.sessionId,
      );
      if (!mounted) {
        return false;
      }
      await _refreshArchivedMessageCount();
      if (hydrated) {
        _syncMessagesFromRepository();
        _scheduleViewportStateRefresh();
      }
      Logger.info(
        '[SessionArchive] ensure accessible end session=${widget.sessionId} '
        'hydrated=$hydrated archived=$_archivedMessageCount '
        'complete=$_isArchivedMessageHistoryComplete',
      );
      return _hasCompleteArchivedMessageHistory;
    } catch (error) {
      Logger.warning(
        'Auto archive hydration failed for ${widget.sessionId}: $error',
      );
      return false;
    } finally {
      if (mounted) {
        _isHydratingArchiveHistoryN.value = false;
      }
    }
  }

  Future<void> _ensureArchivedMessageHistoryAccessible() async {
    unawaited(_awaitArchivedMessageHistoryAccessible());
  }

  Future<void> _jumpToHistoryWindowOffsetAfterFrame(
    double Function(ScrollPosition position) resolveTarget,
  ) async {
    await _viewportController.runProgrammaticScroll(() async {
      await _awaitPostFrame();
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.effectivePosition;
      final clampedTarget = resolveTarget(position).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      final target = (clampedTarget as num).toDouble();
      if ((position.pixels - target).abs() >= 1) {
        _scrollController.jumpTo(target);
      }
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      _handleScrollMetricsChanged();
      _scheduleViewportStateRefresh();
    });
  }

  RenderBox? _messageListViewportRenderBox() {
    if (!_scrollController.hasClients) {
      return null;
    }
    final context =
        _scrollController.effectivePosition.context.notificationContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    return renderObject;
  }

  _MessageViewportAnchor? _captureMessageViewportAnchor({
    required bool alignToBottom,
  }) {
    final viewportBox = _messageListViewportRenderBox();
    if (viewportBox == null) {
      return null;
    }
    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + viewportBox.size.height;
    final turnGroups = _bodyPresenter.resolveTurnGroups(_messages);
    final flatItems = _bodyPresenter.resolveFlatItems(turnGroups);
    final candidates = alignToBottom ? flatItems.reversed : flatItems;

    for (final item in candidates) {
      final rowContext = _messageRowContext(item.renderId);
      final rowBounds = _renderBoxGlobalVerticalBounds(
        rowContext?.findRenderObject(),
      );
      if (rowBounds == null) {
        continue;
      }
      final top = rowBounds.$1;
      final bottom = rowBounds.$2;
      final isVisible = bottom > viewportTop && top < viewportBottom;
      if (!isVisible) {
        continue;
      }
      final anchor = _MessageViewportAnchor(
        messageId: item.message.id,
        rowId: item.renderId,
        distanceFromViewportEdge:
            alignToBottom ? viewportBottom - bottom : top - viewportTop,
        alignToBottom: alignToBottom,
        messageIndex:
            _messages.indexWhere((message) => message.id == item.message.id),
      );
      Logger.info(
        '[SessionAnchorDiag] capture session=${widget.sessionId} '
        'message=${anchor.messageId} alignToBottom=${anchor.alignToBottom} '
        'distance=${anchor.distanceFromViewportEdge.toStringAsFixed(1)} '
        '${_debugMessageWindowSummary()} ${_debugScrollSummary()} '
        '${_debugArchiveAccessSummary()} '
        '${_debugAnchorStateSummary(anchor.messageId, rowId: anchor.rowId)}',
      );
      return anchor;
    }
    Logger.info(
      '[SessionAnchorDiag] capture-miss session=${widget.sessionId} '
      'alignToBottom=$alignToBottom '
      '${_debugMessageWindowSummary()} ${_debugScrollSummary()} '
      '${_debugArchiveAccessSummary()}',
    );
    return null;
  }

  Future<void> _restoreMessageViewportAnchorAfterFrame(
    _MessageViewportAnchor? anchor, {
    double? fallbackOffset,
    double? fallbackMaxScrollExtent,
  }) async {
    if (anchor == null) {
      _handleScrollMetricsChanged();
      _scheduleViewportStateRefresh();
      return;
    }
    await _viewportController.runProgrammaticScroll(() async {
      const maxRestoreAttempts = 4;
      const restoreTolerance = 1.0;
      var restoredWithAnchor = false;
      for (var attempt = 0; attempt < maxRestoreAttempts; attempt++) {
        await _awaitPostFrame();
        if (!mounted || !_scrollController.hasClients) {
          return;
        }
        final viewportBox = _messageListViewportRenderBox();
        final rowContext = _messageRowContext(anchor.rowId);
        final rowBounds = _renderBoxGlobalVerticalBounds(
          rowContext?.findRenderObject(),
        );
        if (viewportBox is! RenderBox) {
          continue;
        }
        if (rowBounds == null) {
          continue;
        }
        final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
        final viewportBottom = viewportTop + viewportBox.size.height;
        final rowTop = rowBounds.$1;
        final rowBottom = rowBounds.$2;
        final desiredEdge = anchor.alignToBottom
            ? viewportBottom - anchor.distanceFromViewportEdge
            : viewportTop + anchor.distanceFromViewportEdge;
        final delta = anchor.alignToBottom
            ? rowBottom - desiredEdge
            : rowTop - desiredEdge;
        if (!delta.isFinite) {
          continue;
        }
        restoredWithAnchor = true;
        if (delta.abs() < restoreTolerance) {
          break;
        }
        final position = _scrollController.effectivePosition;
        final target = (_scrollController.offset + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        _scrollController.jumpTo((target as num).toDouble());
      }
      if (!restoredWithAnchor &&
          fallbackOffset != null &&
          fallbackMaxScrollExtent != null &&
          fallbackMaxScrollExtent > 0 &&
          mounted &&
          _scrollController.hasClients) {
        // Fallback: anchor context unavailable (message trimmed from window or
        // row registration lagged across multiple frames). Restore scroll
        // position using ratio-based estimation instead of silently giving up.
        final position = _scrollController.effectivePosition;
        final scrollRatio = fallbackOffset / fallbackMaxScrollExtent;
        final estimatedTarget = (scrollRatio * position.maxScrollExtent)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
        final target = (estimatedTarget as num).toDouble();
        if ((position.pixels - target).abs() >= restoreTolerance) {
          _scrollController.jumpTo(target);
        }
      }
      _viewportController._suspendEdgeAutoload(
        duration: const Duration(milliseconds: 180),
      );
      _handleScrollMetricsChanged();
      _scheduleViewportStateRefresh();
    });
  }
}
