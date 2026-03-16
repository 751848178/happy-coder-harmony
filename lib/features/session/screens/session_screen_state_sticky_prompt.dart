part of 'session_screen.dart';

extension _SessionScreenStateStickyPrompt on _SessionScreenState {
  Future<void> _scrollToTurnReply(String turnId) async {
    if (!_scrollController.hasClients) {
      return;
    }

    final anchorContext = _turnReplyAnchorKey(turnId).currentContext;
    final viewportContext = _messageListViewportKey.currentContext;
    final anchorRender = anchorContext?.findRenderObject();
    final viewportRender = viewportContext?.findRenderObject();
    if (anchorRender is! RenderBox || viewportRender is! RenderBox) {
      return;
    }

    const replyRevealOffset = 12.0;
    final viewportTop = viewportRender.localToGlobal(Offset.zero).dy;
    final anchorTop = anchorRender.localToGlobal(Offset.zero).dy;
    final delta = anchorTop - (viewportTop + replyRevealOffset);
    final targetOffset = (_scrollController.offset + delta).clamp(
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
    if (!mounted || _collapseAllTurns || _visibleTurnGroups.isEmpty) {
      if (_stickyTurnId != null && mounted) {
        _updateState(() {
          _stickyTurnId = null;
        });
      }
      return;
    }

    final viewportContext = _messageListViewportKey.currentContext;
    final viewportRender = viewportContext?.findRenderObject();
    if (viewportRender is! RenderBox) {
      return;
    }

    final viewportTop = viewportRender.localToGlobal(Offset.zero).dy + 8;
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
      if (replyRender is! RenderBox || sectionRender is! RenderBox) {
        continue;
      }

      final replyTop = replyRender.localToGlobal(Offset.zero).dy;
      final sectionBottom =
          sectionRender.localToGlobal(Offset(0, sectionRender.size.height)).dy;
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
