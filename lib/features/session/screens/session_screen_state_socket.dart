part of 'session_screen.dart';

extension _SessionScreenStateSocket on _SessionScreenState {
  void _startMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) {
        _scheduleMessageRefresh(autoScroll: _shouldStickToLatest);
      },
    );
  }

  void _subscribeToSocketEvents() {
    final socketNotifier = ref.read(socketStateProvider.notifier);
    _socketEventSubscription = socketNotifier.eventStream.listen((event) {
      event.when(
        connecting: () {},
        connected: (_) {
          _scheduleMessageRefresh(autoScroll: _shouldStickToLatest);
          unawaited(_maybeAutoApprovePendingTools());
        },
        disconnected: (_) {},
        error: (_) {},
        messageReceived: (message) {
          if (message.sessionId == widget.sessionId) {
            final shouldAutoScroll = _shouldStickToLatest;
            _scheduleMessageRefresh(autoScroll: shouldAutoScroll);
            if (!shouldAutoScroll && mounted) {
              _updateState(() {
                _hasUnreadMessages = true;
              });
            }
          }
        },
        reconnecting: (_) {},
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
            _updateState(() {
              _hasUnreadMessages = false;
            });
          }
        } else {
          _scheduleViewportStateRefresh();
        }
      },
    );
  }

  void _handleComposerChanged() {
    if (!mounted) {
      return;
    }
    _updateState(() {});
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
    final shouldUpdate = nextCanScrollToTop != _canScrollToTop ||
        nextCanScrollToBottom != _canScrollToBottom ||
        nextIsNearBottom != _isNearBottom ||
        nextShouldStickToLatest != _shouldStickToLatest;
    _scheduleViewportStateRefresh();
    if (!shouldUpdate) {
      return;
    }
    if (!mounted) {
      return;
    }
    _updateState(() {
      _canScrollToTop = nextCanScrollToTop;
      _canScrollToBottom = nextCanScrollToBottom;
      _isNearBottom = nextIsNearBottom;
      _shouldStickToLatest = nextShouldStickToLatest;
      if (nextIsNearBottom) {
        _hasUnreadMessages = false;
      }
    });
  }


}
