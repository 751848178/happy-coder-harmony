part of 'session_screen.dart';

extension _SessionScreenStateTurns on _SessionScreenState {
  List<_MessageTurnGroup> _resolveTurnGroups(List<ReducerMessage> messages) {
    if (identical(_cachedTurnGroupMessages, messages)) {
      return _cachedTurnGroups;
    }
    final previousMessages = _cachedTurnGroupMessages;
    final groups = _canAppendTurnGroups(
      previousMessages: previousMessages,
      nextMessages: messages,
    )
        ? _appendTurnGroups(
            previousMessages: previousMessages!,
            nextMessages: messages,
          )
        : _MessageTurnGroup.build(messages);
    _cachedTurnGroupMessages = messages;
    _cachedTurnGroups = groups;
    return groups;
  }

  bool _canAppendTurnGroups({
    required List<ReducerMessage>? previousMessages,
    required List<ReducerMessage> nextMessages,
  }) {
    if (previousMessages == null ||
        previousMessages.isEmpty ||
        nextMessages.length <= previousMessages.length) {
      return false;
    }
    for (var index = 0; index < previousMessages.length; index++) {
      if (!identical(previousMessages[index], nextMessages[index])) {
        return false;
      }
    }
    return true;
  }

  List<_MessageTurnGroup> _appendTurnGroups({
    required List<ReducerMessage> previousMessages,
    required List<ReducerMessage> nextMessages,
  }) {
    final groups = List<_MessageTurnGroup>.from(_cachedTurnGroups);
    for (var index = previousMessages.length;
        index < nextMessages.length;
        index++) {
      final message = nextMessages[index];
      if (groups.isEmpty || _MessageTurnGroup.startsNewTurn(message)) {
        groups.add(_MessageTurnGroup.single(message));
        continue;
      }
      final lastGroup = groups.removeLast();
      groups.add(lastGroup.append(message));
    }
    return List<_MessageTurnGroup>.unmodifiable(groups);
  }

  void _toggleAllTurns(List<_MessageTurnGroup> groups) {
    if (groups.isEmpty) {
      return;
    }
    final shouldPinLatest = _shouldStickToLatest || _isNearBottom;

    // 修复白屏问题：在折叠/展开前保存当前滚动位置比例，以便恢复相对位置
    final scrollRatio = _captureScrollPositionRatio();

    _updateState(() {
      _collapseAllTurns = !_collapseAllTurns;
      _expandedTurnIds.clear();
      if (!_collapseAllTurns) {
        _expandedTurnIds.addAll(groups.map((group) => group.id));
      }
    });
    unawaited(_persistSessionUiState());

    // 修复白屏问题：使用比例恢复滚动位置，确保视口不会落在无效区域
    _scheduleRestoreScrollPosition(
      scrollRatio: scrollRatio,
      forcePinToLatest: shouldPinLatest,
    );
  }

  void _toggleTurnGroup(_MessageTurnGroup group) {
    final isLatestGroup =
        _visibleTurnGroups.isNotEmpty && _visibleTurnGroups.last.id == group.id;
    final shouldPinLatest =
        _shouldStickToLatest || (_isNearBottom && isLatestGroup);

    // 修复白屏问题：在折叠/展开前保存当前滚动位置比例
    final scrollRatio = _captureScrollPositionRatio();

    _updateState(() {
      if (_expandedTurnIds.contains(group.id)) {
        _expandedTurnIds.remove(group.id);
      } else {
        _expandedTurnIds.add(group.id);
      }
    });
    unawaited(_persistSessionUiState());

    // 修复白屏问题：使用比例恢复滚动位置，确保视口不会落在无效区域
    _scheduleRestoreScrollPosition(
      scrollRatio: scrollRatio,
      forcePinToLatest: shouldPinLatest,
    );
  }

  GlobalKey _turnSectionKey(String turnId) {
    return _turnSectionKeys.putIfAbsent(
      turnId,
      () => GlobalKey(debugLabel: 'turn-section-$turnId'),
    );
  }

  GlobalKey _turnReplyAnchorKey(String turnId) {
    return _turnReplyAnchorKeys.putIfAbsent(
      turnId,
      () => GlobalKey(debugLabel: 'turn-reply-$turnId'),
    );
  }

  void _scheduleViewportStateRefresh() {
    if (_viewportUpdateScheduled) {
      return;
    }
    _viewportUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewportUpdateScheduled = false;
      _refreshStickyTurnPrompt();
    });
  }

  /// 修复白屏问题：捕获当前滚动位置的比例（0.0 到 1.0）
  /// 用于在列表高度变化后恢复相对滚动位置
  double? _captureScrollPositionRatio() {
    if (!_scrollController.hasClients) {
      return null;
    }
    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    if (maxScroll <= 0) {
      return null;
    }
    return position.pixels / maxScroll;
  }

  /// 修复白屏问题：使用比例恢复滚动位置
  /// 确保在折叠/展开轮次后，视口不会落在无效区域
  void _scheduleRestoreScrollPosition({
    double? scrollRatio,
    bool forcePinToLatest = false,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final position = _scrollController.position;
      final maxScroll = position.maxScrollExtent;

      // 如果需要强制滚动到底部
      if (forcePinToLatest) {
        final alreadyAtBottom = (position.pixels - maxScroll).abs() < 1;
        if (!alreadyAtBottom) {
          _scheduleScrollToLatest(force: true);
        }
        return;
      }

      // 否则，使用保存的比例恢复滚动位置
      if (scrollRatio != null && maxScroll > 0) {
        final targetOffset = scrollRatio * maxScroll;
        // 确保目标在有效范围内
        final clampedTarget = targetOffset.clamp(
          position.minScrollExtent,
          maxScroll,
        );
        // 只当位置变化足够大时才滚动
        if ((position.pixels - clampedTarget).abs() >= 1) {
          _scrollController.jumpTo(clampedTarget);
        }
      }

      // 最终确保滚动位置在有效范围内（fallback）
      final finalTarget = position.pixels.clamp(
        position.minScrollExtent,
        maxScroll,
      );
      if ((position.pixels - finalTarget).abs() >= 1) {
        _scrollController.jumpTo(finalTarget);
      }

      _handleScrollMetricsChanged();
    });
  }
}
