part of 'session_screen.dart';

class _MessageViewportAnchor {
  const _MessageViewportAnchor({
    required this.messageId,
    required this.distanceFromViewportEdge,
    required this.alignToBottom,
    this.messageIndex,
  });

  final String messageId;
  final double distanceFromViewportEdge;
  final bool alignToBottom;
  final int? messageIndex;
}

extension _SessionScreenStateRefresh on _SessionScreenState {
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
      final position = _scrollController.position;
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
    final context = _scrollController.position.context.notificationContext;
    final renderObject = context?.findRenderObject();
    return renderObject is RenderBox ? renderObject : null;
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
      final rowContext = _messageRowContext(item.message.id);
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
        '${_debugArchiveAccessSummary()} ${_debugAnchorStateSummary(anchor.messageId)}',
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
      for (var attempt = 1; attempt <= 3; attempt += 1) {
        await _awaitPostFrame();
        if (!mounted || !_scrollController.hasClients) {
          return;
        }
        final viewportBox = _messageListViewportRenderBox();
        final rowContext = _messageRowContext(anchor.messageId);
        final rowBounds = _renderBoxGlobalVerticalBounds(
          rowContext?.findRenderObject(),
        );
        if (viewportBox is RenderBox && rowBounds != null) {
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
          if (!delta.isFinite ||
              !viewportTop.isFinite ||
              !viewportBottom.isFinite) {
            Logger.info(
              '[SessionAnchorDiag] restore-invalid session=${widget.sessionId} '
              'message=${anchor.messageId} alignToBottom=${anchor.alignToBottom} '
              'attempt=$attempt delta=$delta viewportTop=$viewportTop '
              'viewportBottom=$viewportBottom rowTop=$rowTop rowBottom=$rowBottom '
              '${_debugMessageWindowSummary()} ${_debugScrollSummary()} '
              '${_debugArchiveAccessSummary()} '
              '${_debugAnchorStateSummary(anchor.messageId)}',
            );
            continue;
          }
          Logger.info(
            '[SessionAnchorDiag] restore session=${widget.sessionId} '
            'message=${anchor.messageId} alignToBottom=${anchor.alignToBottom} '
            'attempt=$attempt delta=${delta.toStringAsFixed(1)} '
            '${_debugMessageWindowSummary()} ${_debugScrollSummary()} '
            '${_debugArchiveAccessSummary()} ${_debugAnchorStateSummary(anchor.messageId)}',
          );
          if (delta.abs() >= 1) {
            final position = _scrollController.position;
            final target = (_scrollController.offset + delta).clamp(
              position.minScrollExtent,
              position.maxScrollExtent,
            );
            _scrollController.jumpTo((target as num).toDouble());
            await SchedulerBinding.instance.endOfFrame;
          }
          if (!mounted) {
            return;
          }
          _handleScrollMetricsChanged();
          _scheduleViewportStateRefresh();
          return;
        }
        final anchorStillInWindow = _messages.any(
          (message) => message.id == anchor.messageId,
        );
        Logger.info(
          '[SessionAnchorDiag] restore-wait session=${widget.sessionId} '
          'message=${anchor.messageId} attempt=$attempt '
          'hasViewport=${viewportBox is RenderBox} '
          'hasRow=${rowBounds != null} '
          'anchorStillInWindow=$anchorStillInWindow '
          '${_debugMessageWindowSummary()} ${_debugScrollSummary()} '
          '${_debugArchiveAccessSummary()} ${_debugAnchorStateSummary(anchor.messageId)}',
        );
        if (!anchorStillInWindow) {
          break;
        }
        if (_scrollController.hasClients) {
          final anchorIndex = _messages.indexWhere(
            (message) => message.id == anchor.messageId,
          );
          if (anchorIndex >= 0 && _messages.length > 1) {
            final position = _scrollController.position;
            final estimatedOffset = position.maxScrollExtent *
                (anchorIndex / (_messages.length - 1));
            final viewportBias = anchor.alignToBottom
                ? position.viewportDimension * 0.68
                : position.viewportDimension * 0.18;
            final coarseTarget = (estimatedOffset - viewportBias).clamp(
              position.minScrollExtent,
              position.maxScrollExtent,
            );
            final target = (coarseTarget as num).toDouble();
            if ((position.pixels - target).abs() >= 1) {
              Logger.info(
                '[SessionAnchorDiag] restore-coarse-jump session=${widget.sessionId} '
                'message=${anchor.messageId} attempt=$attempt '
                'anchorIndex=$anchorIndex target=${target.toStringAsFixed(1)} '
                '${_debugMessageWindowSummary()} ${_debugScrollSummary()}',
              );
              _scrollController.jumpTo(target);
              await SchedulerBinding.instance.endOfFrame;
            }
          }
        }
      }
      _viewportController._suspendEdgeAutoload(
        duration: const Duration(milliseconds: 180),
      );
      if (_scrollController.hasClients) {
        final position = _scrollController.position;
        final fallbackTarget = (fallbackOffset != null &&
                fallbackMaxScrollExtent != null &&
                fallbackOffset.isFinite &&
                fallbackMaxScrollExtent.isFinite)
            ? fallbackOffset +
                (position.maxScrollExtent - fallbackMaxScrollExtent)
            : _SessionViewportController._historyEdgeLoadTrigger + 36;
        final clampedTarget = fallbackTarget.clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        final target = (clampedTarget as num).toDouble();
        if ((position.pixels - target).abs() >= 1) {
          _scrollController.jumpTo(target);
          await SchedulerBinding.instance.endOfFrame;
        }
      }
      Logger.info(
        '[SessionAnchorDiag] restore-giveup session=${widget.sessionId} '
        'message=${anchor.messageId} ${_debugMessageWindowSummary()} '
        '${_debugScrollSummary()} ${_debugArchiveAccessSummary()} '
        '${_debugAnchorStateSummary(anchor.messageId)}',
      );
      _handleScrollMetricsChanged();
      _scheduleViewportStateRefresh();
    });
  }

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
    final beforeOffset =
        _scrollController.hasClients ? _scrollController.position.pixels : null;
    final beforeMaxScroll = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
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
      '${anchor == null ? "" : _debugAnchorStateSummary(anchor.messageId)}',
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
      // Synchronous scroll correction: record position before content
      // change so _ChatScrollPosition can correct during layout.
      (_scrollController as _ChatScrollController).standbyForPrepend();
      _syncMessagesFromRepository();
      final afterOffset = _scrollController.hasClients
          ? _scrollController.position.pixels
          : null;
      final afterMaxScroll = _scrollController.hasClients
          ? _scrollController.position.maxScrollExtent
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
        '${anchor == null ? "" : _debugAnchorStateSummary(anchor.messageId)}',
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
    final beforeOffset =
        _scrollController.hasClients ? _scrollController.position.pixels : null;
    final beforeMaxScroll = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
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
      '${anchor == null ? "" : _debugAnchorStateSummary(anchor.messageId)}',
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
      // Synchronous scroll correction: record position before content
      // change so _ChatScrollPosition can correct during layout.
      (_scrollController as _ChatScrollController).standbyForAppend();
      _syncMessagesFromRepository();
      final afterOffset = _scrollController.hasClients
          ? _scrollController.position.pixels
          : null;
      final afterMaxScroll = _scrollController.hasClients
          ? _scrollController.position.maxScrollExtent
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
        '${anchor == null ? "" : _debugAnchorStateSummary(anchor.messageId)}',
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

  /// Refresh button: fetch latest messages incrementally + reconnect socket.
  /// Uses force: false so only new messages after lastSeq are fetched,
  /// not a full reload.  The "sync all" menu item does full reload.
  Future<void> _refreshSessionState() async {
    if (_isRefreshingSessionState) {
      return;
    }

    final authState = ref.read(authStateProvider);
    final credentials = authState.credentials;
    if (credentials == null) {
      return;
    }

    _setSessionRefreshing(true);

    try {
      await Future.wait([
        ref.read(sessionStateProvider.notifier).loadSessions(force: true),
        ref
            .read(sessionStateProvider.notifier)
            .loadMachines(force: true, allowFailure: true),
        ref.read(socketStateProvider.notifier).initialize(
              machineId: credentials.machineId,
              token: credentials.token,
            ),
      ]);
      if (!_hasNewerMessages) {
        // Incremental fetch — only pulls messages after lastSeq.
        await ref.read(sessionStateProvider.notifier).loadSessionMessages(
              widget.sessionId,
              throwOnError: true,
              messageWindowSize: SessionServiceNotifier
                  .sessionDetailAutomaticMessageWindowSize,
            );
        _syncMessagesFromRepository();
        _scheduleScrollToLatest(force: true);
      }
      await _ensureArchivedMessageHistoryAccessible();
      _scheduleViewportStateRefresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      _setSessionRefreshing(false);
    }
  }

  /// "Sync all messages" menu item: full reload from server.
  /// Uses force: true (afterSeq = 0) to fetch every message.
  /// Shows independent loading state so it doesn't conflict with refresh button.
  Future<void> _syncSessionMessagesFromRemote() async {
    if (_isSyncingAllMessages) {
      return;
    }

    _isSyncingAllMessagesN.value = true;
    _setSessionRefreshing(true);
    try {
      await ref
          .read(sessionStateProvider.notifier)
          .syncFullSessionMessagesFromRemote(
            widget.sessionId,
            throwOnError: true,
          );
      _syncMessagesFromRepository();
      await _refreshArchivedMessageCount();
      _isHydratingArchiveHistoryN.value = false;
      await _maybeAutoApprovePendingTools();
      _scheduleScrollToLatest(force: true);
      _scheduleViewportStateRefresh();
      if (!mounted) {
        return;
      }
      final syncedCount = ref
              .read(sessionStateProvider.notifier)
              .getSessionMessages(widget.sessionId)
              ?.totalMessageCount ??
          0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已归档完整历史，共 $syncedCount 条；内存仅保留当前窗口'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步全部消息失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      _isSyncingAllMessagesN.value = false;
      _setSessionRefreshing(false);
    }
  }

  String _createLocalMessageId() {
    return 'msg_${DateTime.now().microsecondsSinceEpoch}';
  }
}
