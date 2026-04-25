part of '../session_detail.dart';

extension _SessionScreenDebugging on _SessionScreenState {
  String _debugMessageWindowSummary() {
    final firstMessage = _messages.isEmpty ? null : _messages.first;
    final lastMessage = _messages.isEmpty ? null : _messages.last;
    return 'window(start=$_messageWindowStartIndex loaded=${_messages.length} '
        'total=$_totalMessageCount older=$_hasOlderMessages newer=$_hasNewerMessages '
        'first=${firstMessage?.id ?? "none"} last=${lastMessage?.id ?? "none"})';
  }

  String _debugScrollSummary() {
    if (!_scrollController.hasClients) {
      return 'scroll(no-clients)';
    }
    final position = _scrollController.effectivePosition;
    return 'scroll(offset=${position.pixels.toStringAsFixed(1)} '
        'min=${position.minScrollExtent.toStringAsFixed(1)} '
        'max=${position.maxScrollExtent.toStringAsFixed(1)} '
        'viewport=${position.viewportDimension.toStringAsFixed(1)})';
  }

  String _debugVisibleMessageSummary() {
    if (!_scrollController.hasClients || _messages.isEmpty) {
      return 'visible(first=none last=none count=0)';
    }
    final viewportBox = _messageListViewportRenderBox();
    if (viewportBox == null) {
      return 'visible(first=unknown last=unknown count=0)';
    }
    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + viewportBox.size.height;
    final turnGroups = _bodyPresenter.resolveTurnGroups(_messages);
    final flatItems = _bodyPresenter.resolveFlatItems(turnGroups);
    String? firstVisibleId;
    String? lastVisibleId;
    var visibleCount = 0;
    for (final item in flatItems) {
      final rowContext = _messageRowContext(item.renderId);
      final bounds = _renderBoxGlobalVerticalBounds(
        rowContext?.findRenderObject(),
      );
      if (bounds == null) {
        continue;
      }
      final top = bounds.$1;
      final bottom = bounds.$2;
      if (bottom <= viewportTop || top >= viewportBottom) {
        continue;
      }
      visibleCount += 1;
      firstVisibleId ??= item.message.id;
      lastVisibleId = item.message.id;
    }
    return 'visible(first=${firstVisibleId ?? "none"} '
        'last=${lastVisibleId ?? "none"} count=$visibleCount)';
  }

  (double, double)? _renderBoxGlobalVerticalBounds(RenderObject? renderObject) {
    if (renderObject is! RenderBox || !renderObject.attached) {
      return null;
    }
    if (!renderObject.hasSize) {
      return null;
    }
    final size = renderObject.size;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    final top = topLeft.dy;
    final bottom = top + size.height;
    if (!top.isFinite ||
        !bottom.isFinite ||
        !size.height.isFinite ||
        size.height < 0) {
      return null;
    }
    return (top, bottom);
  }

  String _debugArchiveAccessSummary() {
    return 'archive(localOlder=$_hasLocallyAccessibleOlderArchivedMessages '
        'localNewer=$_hasLocallyAccessibleNewerArchivedMessages '
        'canJumpEarliest=$_canJumpToEarliestArchivedBoundary '
        'archived=$_archivedMessageCount complete=$_hasCompleteArchivedMessageHistory '
        'loadingOlder=$_isLoadingOlderMessages loadingNewer=$_isLoadingNewerMessages '
        'hydrating=$_isHydratingArchiveHistory)';
  }

  String _debugAnchorStateSummary(String messageId, {String? rowId}) {
    final index = _messages.indexWhere((message) => message.id == messageId);
    final hasContext =
        rowId == null ? false : _messageRowContexts.containsKey(rowId);
    final previousId = index > 0 && index < _messages.length
        ? _messages[index - 1].id
        : 'none';
    final nextId = index >= 0 && index < (_messages.length - 1)
        ? _messages[index + 1].id
        : 'none';
    return 'anchor(id=$messageId row=${rowId ?? "none"} '
        'index=$index hasContext=$hasContext '
        'prev=$previousId next=$nextId rowContexts=${_messageRowContexts.length})';
  }

  ValueNotifier<bool> _toolActionPendingListenable(String toolId) {
    return _toolActionPendingNotifiers.putIfAbsent(
      toolId,
      () => ValueNotifier<bool>(_toolActionsInFlight.contains(toolId)),
    );
  }

  bool _isToolActionPending(String toolId) {
    return _toolActionPendingNotifiers[toolId]?.value == true ||
        _toolActionsInFlight.contains(toolId);
  }

  void _setToolActionPending(String toolId, bool pending) {
    final changed = pending
        ? _toolActionsInFlight.add(toolId)
        : _toolActionsInFlight.remove(toolId);
    final notifier = _toolActionPendingListenable(toolId);
    if (notifier.value != pending) {
      notifier.value = pending;
    }
    if (!changed && notifier.value == pending) {
      return;
    }
  }

  void _logDuplicateMessageIds(
    List<ReducerMessage> messages, {
    required String stage,
  }) {
    if (messages.length < 2) {
      return;
    }
    final seen = <String>{};
    final duplicates = <String>[];
    for (final message in messages) {
      if (!seen.add(message.id)) {
        duplicates.add(message.id);
      }
    }
    if (duplicates.isEmpty) {
      return;
    }
    Logger.error(
      '[SessionDuplicate] session=${widget.sessionId} stage=$stage '
      'duplicates=${duplicates.join(",")} ${_debugMessageWindowSummary()}',
    );
  }
}
