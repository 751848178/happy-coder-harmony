part of '../session_detail.dart';

extension _SessionScreenStateSocket on _SessionScreenState {
  bool _didSessionMessagesAdvance({
    required _SessionMessageViewState previousState,
  }) {
    final nextState = _messageViewStateN.value;
    return !identical(previousState.messages, nextState.messages) ||
        previousState.totalMessageCount != nextState.totalMessageCount ||
        previousState.hasLoadedMessages != nextState.hasLoadedMessages;
  }

  bool _shouldDeferIncrementalMessageRefresh() {
    return _userHasScrolledUp ||
        _isLoadingOlderMessages ||
        _isLoadingNewerMessages ||
        _viewportController.programmaticScrollActivity != 0 ||
        !_messageViewportReady;
  }

  bool _needsPostSyncLatestCorrection() {
    if (!_scrollController.hasClients) {
      return true;
    }
    final position = _scrollController.effectivePosition;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    return !distanceToBottom.isFinite || distanceToBottom > 24;
  }

  void _startMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) {
        if (!mounted) {
          return;
        }
        if (_hasNewerMessages) {
          return;
        }
        if (_shouldDeferIncrementalMessageRefresh()) {
          return;
        }
        // Never auto-scroll during polling if the user has manually scrolled up.
        // Show the "new messages" indicator instead.
        _scheduleMessageRefresh(
            autoScroll: !_userHasScrolledUp || _isNearBottom);
      },
    );
  }

  void _subscribeToSocketEvents() {
    final socketNotifier = ref.read(socketStateProvider.notifier);
    _socketEventSubscription = socketNotifier.eventStream.listen((event) {
      event.when(
        connecting: () {},
        connected: (_) {
          final sessionNotifier = ref.read(sessionStateProvider.notifier);
          unawaited(sessionNotifier.loadSessions(force: true));
          unawaited(
            sessionNotifier.loadMachines(force: true, allowFailure: true),
          );
          _scheduleMessageRefresh(
              autoScroll: !_userHasScrolledUp || _isNearBottom);
          unawaited(_maybeAutoApprovePendingTools());
        },
        disconnected: (_) {},
        error: (_) {},
        messageReceived: (message) {
          if (message.sessionId == widget.sessionId) {
            if (_hasNewerMessages || _shouldDeferIncrementalMessageRefresh()) {
              if (mounted) {
                _hasUnreadMessagesN.value = true;
              }
              return;
            }
            // Suppress auto-scroll if user has manually scrolled up.
            // Instead, show the "new messages" indicator.
            // Also auto-scroll if the user is near the bottom even if
            // _userHasScrolledUp was set from a transient state.
            final shouldAutoScroll = !_userHasScrolledUp || _isNearBottom;
            _scheduleMessageRefresh(autoScroll: shouldAutoScroll);
            if (!shouldAutoScroll && mounted) {
              _hasUnreadMessagesN.value = true;
            }
          }
        },
        reconnecting: (_) {
          final sessionNotifier = ref.read(sessionStateProvider.notifier);
          unawaited(sessionNotifier.loadSessions(force: true));
          unawaited(
            sessionNotifier.loadMachines(force: true, allowFailure: true),
          );
        },
      );
    });
  }

  void _scheduleMessageRefresh({bool autoScroll = false}) {
    _socketRefreshDebounce?.cancel();
    _socketRefreshDebounce = Timer(
      const Duration(milliseconds: 150),
      () async {
        if (!mounted) {
          return;
        }
        if (_hasNewerMessages || _shouldDeferIncrementalMessageRefresh()) {
          if (mounted) {
            _hasUnreadMessagesN.value = true;
          }
          return;
        }
        final previousState = _messageViewStateN.value;
        await ref.read(sessionStateProvider.notifier).loadSessionMessages(
              widget.sessionId,
              messageWindowSize: SessionServiceNotifier
                  .sessionDetailAutomaticMessageWindowSize,
            );
        if (!mounted) {
          return;
        }
        _syncMessagesFromRepository();
        final didMessagesAdvance = _didSessionMessagesAdvance(
          previousState: previousState,
        );
        await _maybeAutoApprovePendingTools();
        if (!mounted) {
          return;
        }
        if (autoScroll && didMessagesAdvance) {
          _handleScrollMetricsChanged();
          if (_needsPostSyncLatestCorrection()) {
            _scheduleScrollToLatest(animate: false, force: true);
          }
          if (mounted) {
            _hasUnreadMessagesN.value = false;
          }
        } else {
          _scheduleViewportStateRefresh();
        }
      },
    );
  }

  void _handleComposerChanged() {
    _draftPersistDebounce?.cancel();
    final draft =
        _messageController.text.trim().isEmpty ? null : _messageController.text;
    _draftPersistDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) {
        return;
      }
      ref.read(sessionStateProvider.notifier).updateDraft(
            widget.sessionId,
            draft,
          );
    });
  }

  void _handleScrollMetricsChanged() =>
      _viewportController.handleScrollMetricsChanged();
}
