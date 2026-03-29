part of 'session_screen.dart';

extension _SessionScreenStateScroll on _SessionScreenState {
  void _scrollToBottom() {
    _scheduleScrollToLatest(animate: true, force: true);
  }

  void _scheduleScrollToLatest({
    bool animate = false,
    bool force = false,
  }) {
    if (_scrollToLatestScheduled && !force) {
      return;
    }
    _scrollToLatestScheduled = true;
    final requestId = ++_scrollToLatestRequestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLatestScheduled = false;
      unawaited(
        _scrollToLatestUntilSettled(
          requestId,
          animate: animate,
          force: force,
        ),
      );
    });
  }

  Future<void> _scrollToLatestUntilSettled(
    int requestId, {
    required bool animate,
    required bool force,
  }) async {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }
    if (_hasScrolledToLatest && !force) {
      return;
    }

    var previousMaxScrollExtent = -1.0;
    var animated = false;

    for (var attempt = 0; attempt < 8; attempt++) {
      if (!mounted ||
          !_scrollController.hasClients ||
          requestId != _scrollToLatestRequestId) {
        return;
      }

      final position = _scrollController.position;
      final target = position.maxScrollExtent;
      final alreadyAtLatest = (position.pixels - target).abs() < 1;

      if (!alreadyAtLatest) {
        if (animate && !animated) {
          animated = true;
          await _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(target);
        }
      }

      await SchedulerBinding.instance.endOfFrame;

      if (!mounted ||
          !_scrollController.hasClients ||
          requestId != _scrollToLatestRequestId) {
        return;
      }

      final settledPosition = _scrollController.position;
      final settledMaxScrollExtent = settledPosition.maxScrollExtent;
      final distanceToBottom =
          (settledPosition.pixels - settledMaxScrollExtent).abs();
      final extentStable =
          (settledMaxScrollExtent - previousMaxScrollExtent).abs() < 1;

      if (distanceToBottom < 1 && extentStable) {
        break;
      }
      previousMaxScrollExtent = settledMaxScrollExtent;
    }

    if (!mounted || requestId != _scrollToLatestRequestId) {
      return;
    }

    _updateState(() {
      _hasScrolledToLatest = true;
      _shouldStickToLatest = true;
      _hasUnreadMessages = false;
    });
    _handleScrollMetricsChanged();
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
}
