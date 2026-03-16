part of 'session_screen.dart';

extension _SessionScreenStateStickyPrompt on _SessionScreenState {
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
