part of 'session_screen.dart';

extension _SessionScreenStateStickyPrompt on _SessionScreenState {
  Future<void> _scrollToTurnReply(String turnId) async {
    if (!_scrollController.hasClients) {
      return;
    }

    final anchorContext = _turnReplyAnchorKey(turnId).currentContext;
    final anchorRender = anchorContext?.findRenderObject();
    if (anchorRender is! RenderObject) {
      return;
    }
    final viewport = RenderAbstractViewport.of(anchorRender);

    const replyRevealOffset = 12.0;
    final targetOffset =
        (viewport.getOffsetToReveal(anchorRender, 0).offset - replyRevealOffset)
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
        !_hasStickyTurnCandidates ||
        _visibleTurnGroups.isEmpty) {
      if (_stickyTurnId != null && mounted) {
        _updateState(() {
          _stickyTurnId = null;
        });
      }
      return;
    }

    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final viewportTop = position.pixels + 8;
    const stickyHeight = 44.0;
    String? nextStickyTurnId;

    for (final group in _visibleTurnGroups) {
      final prompt = group.userPrompt;
      if (prompt == null || group.messages.length <= 1) {
        continue;
      }

      final replyRender =
          _turnReplyAnchorKey(group.id).currentContext?.findRenderObject();
      final sectionRender =
          _turnSectionKey(group.id).currentContext?.findRenderObject();
      if (replyRender is! RenderObject || sectionRender is! RenderObject) {
        continue;
      }
      final viewport = RenderAbstractViewport.of(replyRender);

      final replyTop = viewport.getOffsetToReveal(replyRender, 0).offset;
      final sectionBottom = viewport.getOffsetToReveal(sectionRender, 1).offset;
      if (replyTop <= viewportTop &&
          sectionBottom > viewportTop + stickyHeight) {
        nextStickyTurnId = group.id;
        break;
      }
    }

    if (nextStickyTurnId == _stickyTurnId) {
      return;
    }

    _updateState(() {
      _stickyTurnId = nextStickyTurnId;
    });
  }
}
