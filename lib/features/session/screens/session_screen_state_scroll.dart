part of 'session_screen.dart';

extension _SessionScreenStateScroll on _SessionScreenState {
  void _scrollToBottom() {
    _scheduleScrollToLatest(animate: true, force: true);
  }

  void _scheduleScrollToLatest({
    bool animate = false,
    bool force = false,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      if (_hasScrolledToLatest && !force) {
        return;
      }
      final position = _scrollController.position;
      final target = position.maxScrollExtent;
      final alreadyAtLatest = (position.pixels - target).abs() < 1;
      if (animate) {
        if (!alreadyAtLatest) {
          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        }
      } else {
        if (!alreadyAtLatest) {
          _scrollController.jumpTo(target);
        }
      }
      if (mounted) {
        _updateState(() {
          _hasScrolledToLatest = true;
          _shouldStickToLatest = true;
          _hasUnreadMessages = false;
        });
      } else {
        _hasScrolledToLatest = true;
        _shouldStickToLatest = true;
        _hasUnreadMessages = false;
      }
      _handleScrollMetricsChanged();
    });
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    final target = _scrollController.position.minScrollExtent;
    if ((_scrollController.position.pixels - target).abs() < 1) {
      return;
    }
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _scheduleQueuedMessageReconciliation() {
    if (_queueReconcileScheduled) {
      return;
    }
    _queueReconcileScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queueReconcileScheduled = false;
      if (!mounted) {
        return;
      }
      unawaited(_reconcileQueuedMessageState());
    });
  }
}
