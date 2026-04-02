part of 'session_screen.dart';

extension _SessionScreenStateSocket on _SessionScreenState {
  void _startMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) {
        // Never auto-scroll during polling if the user has manually scrolled up.
        // Show the "new messages" indicator instead.
        _scheduleMessageRefresh(autoScroll: !_userHasScrolledUp && _shouldStickToLatest);
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
          _scheduleMessageRefresh(autoScroll: !_userHasScrolledUp && _shouldStickToLatest);
          unawaited(_maybeAutoApprovePendingTools());
        },
        disconnected: (_) {},
        error: (_) {},
        messageReceived: (message) {
          if (message.sessionId == widget.sessionId) {
            // Suppress auto-scroll if user has manually scrolled up.
            // Instead, show the "new messages" indicator.
            final shouldAutoScroll = !_userHasScrolledUp && _shouldStickToLatest;
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
        await ref.read(sessionStateProvider.notifier).loadSessionMessages(
              widget.sessionId,
            );
        await _maybeAutoApprovePendingTools();
        if (autoScroll) {
          _scheduleScrollToLatest(animate: true, force: true);
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
      ref.read(sessionStateProvider.notifier).updateDraft(
            widget.sessionId,
            draft,
          );
    });
  }

  void _handleScrollMetricsChanged() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    final nextCanScrollToTop = position.pixels > 32;
    final nextCanScrollToBottom = distanceToBottom > 32;
    final nextIsNearBottom = distanceToBottom < 72;
    final nextShouldStickToLatest = distanceToBottom <= 8;
    // Detect user scrolling up: if we're far from bottom and haven't set
    // the flag yet, mark it so auto-scroll is suppressed.
    if (distanceToBottom > 72 && !_userHasScrolledUp && _hasScrolledToLatest) {
      _userHasScrolledUp = true;
    }
    // When user scrolls back near bottom, clear the user-scroll flag so
    // auto-scroll resumes naturally.
    if (nextShouldStickToLatest && _userHasScrolledUp) {
      _userHasScrolledUp = false;
    }
    final shouldUpdate = nextCanScrollToTop != _canScrollToTop ||
        nextCanScrollToBottom != _canScrollToBottom ||
        nextIsNearBottom != _isNearBottom ||
        nextShouldStickToLatest != _shouldStickToLatest;
    if (_hasStickyTurnCandidates || _stickyTurnId != null) {
      _scheduleViewportStateRefresh();
    }
    if (!shouldUpdate) {
      return;
    }
    if (!mounted) {
      return;
    }
    // Update ValueNotifiers directly — no full-screen setState needed.
    _canScrollToTopN.value = nextCanScrollToTop;
    _canScrollToBottomN.value = nextCanScrollToBottom;
    _isNearBottomN.value = nextIsNearBottom;
    _shouldStickToLatestN.value = nextShouldStickToLatest;
    if (nextIsNearBottom) {
      _hasUnreadMessagesN.value = false;
    }
  }
}
