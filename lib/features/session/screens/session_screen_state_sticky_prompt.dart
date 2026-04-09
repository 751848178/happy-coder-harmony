part of 'session_screen.dart';

extension _SessionScreenStateStickyPrompt on _SessionScreenState {
  bool _isRenderableViewportTarget(RenderObject? renderObject) {
    if (renderObject == null || !renderObject.attached) {
      return false;
    }
    if (renderObject is RenderBox) {
      return renderObject.hasSize;
    }
    return false;
  }

  Future<void> _scrollToTurnReply(String turnId) async {
    if (!_scrollController.hasClients) {
      return;
    }

    final anchorContext = _turnReplyContext(turnId);
    final anchorRender = anchorContext?.findRenderObject();
    if (!_isRenderableViewportTarget(anchorRender)) {
      return;
    }
    final anchorTarget = anchorRender!;
    final viewport = RenderAbstractViewport.maybeOf(anchorTarget);
    if (viewport == null) {
      return;
    }

    const replyRevealOffset = 12.0;
    final targetOffset =
        (viewport.getOffsetToReveal(anchorTarget, 0).offset - replyRevealOffset)
            .clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    final target = (targetOffset as num).toDouble();
    if ((_scrollController.offset - target).abs() < 1) {
      return;
    }

    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _refreshStickyTurnPrompt() {
    if (!mounted ||
        _collapseAllTurns ||
        !_cachedHasStickyCandidates ||
        _visibleTurnGroups.isEmpty) {
      if (_stickyTurnIdN.value != null && mounted) {
        _stickyTurnIdN.value = null;
      }
      return;
    }

    if (!_scrollController.hasClients) {
      return;
    }

    final stopwatch = Stopwatch()..start();
    final position = _scrollController.position;
    final viewportTop = position.pixels + 8;
    const stickyHeight = 44.0;
    String? nextStickyTurnId;

    // Use a limited sliding window around the current viewport instead of
    // scanning all turn groups.  With 264 messages (~132 turn groups), calling
    // findRenderObject() + getOffsetToReveal() on every group each frame is
    // the dominant cost (each call walks the render tree).  By only checking
    // groups near the current scroll offset we cut the cost from O(t) to ~O(1).
    final totalGroups = _visibleTurnGroups.length;
    final estimatedGroupHeight = 320.0;
    final scrollOffset = position.pixels;

    // Estimate which group index the viewport center is at, then check a
    // window of candidates around it.
    final estimatedCenterIndex = (scrollOffset / estimatedGroupHeight).floor();
    final windowRadius = 4;
    final startIndex = (estimatedCenterIndex - windowRadius)
        .clamp(0, totalGroups > 0 ? totalGroups - 1 : 0);
    final endIndex =
        (estimatedCenterIndex + windowRadius + 1).clamp(0, totalGroups);

    for (var i = startIndex; i < endIndex; i++) {
      final group = _visibleTurnGroups[i];
      final prompt = group.userPrompt;
      if (prompt == null || group.messages.length <= 1) {
        continue;
      }

      final replyRender = _turnReplyContext(group.id)?.findRenderObject();
      final sectionRender = _turnSectionContext(group.id)?.findRenderObject();
      if (!_isRenderableViewportTarget(replyRender) ||
          !_isRenderableViewportTarget(sectionRender)) {
        continue;
      }
      final replyTarget = replyRender!;
      final sectionTarget = sectionRender!;
      final viewport = RenderAbstractViewport.maybeOf(replyTarget);
      if (viewport == null) {
        continue;
      }

      final replyTop = viewport.getOffsetToReveal(replyTarget, 0).offset;
      final sectionBottom = viewport.getOffsetToReveal(sectionTarget, 1).offset;
      if (!replyTop.isFinite || !sectionBottom.isFinite) {
        continue;
      }
      if (replyTop <= viewportTop &&
          sectionBottom > viewportTop + stickyHeight) {
        nextStickyTurnId = group.id;
        break;
      }
    }

    stopwatch.stop();
    if (_sessionVerbosePerfLogging && stopwatch.elapsedMilliseconds >= 8) {
      Logger.info(
        '[SessionPerf][sticky] session=${widget.sessionId} '
        'visibleGroups=${_visibleTurnGroups.length} '
        'window=$startIndex-$endIndex '
        'next=${nextStickyTurnId ?? "none"} '
        'cost=${stopwatch.elapsedMilliseconds}ms',
      );
    }
    _stickyTurnIdN.value = nextStickyTurnId;
  }
}
