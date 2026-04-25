part of '../session_detail.dart';

extension _SessionScreenStateTurns on _SessionScreenState {
  List<_MessageTurnGroup> _resolveTurnGroups(List<ReducerMessage> messages) =>
      _bodyPresenter.resolveTurnGroups(messages);

  List<_CollapsedTurnSummary> _collapsedTurnSummariesFromGroups(
    List<_MessageTurnGroup> groups,
  ) {
    return List<_CollapsedTurnSummary>.unmodifiable(
      groups.map(_CollapsedTurnSummary.fromTurnGroup),
    );
  }

  Future<void> _ensureCollapsedTurnSummariesLoaded(
    List<_MessageTurnGroup> groups,
  ) async {
    if (!_collapseAllTurns) {
      return;
    }
    final fallback = _collapsedTurnSummariesFromGroups(groups);
    if (!_hasCompleteArchivedMessageHistory ||
        _totalMessageCount <= _messages.length) {
      _collapsedTurnSummariesN.value = fallback;
      return;
    }
    if (_collapsedTurnSummaries.isNotEmpty) {
      return;
    }
    _collapsedTurnSummariesN.value = fallback;
    try {
      final summaries = await ref
          .read(sessionStateProvider.notifier)
          .loadSessionMessageArchiveTurnSummaries(widget.sessionId);
      if (!mounted || !_collapseAllTurns) {
        return;
      }
      if (summaries.isEmpty) {
        _collapsedTurnSummariesN.value = fallback;
        return;
      }
      _collapsedTurnSummariesN.value = List<_CollapsedTurnSummary>.unmodifiable(
        summaries.map(_CollapsedTurnSummary.fromArchivedSummary),
      );
    } catch (error) {
      Logger.warning(
        'Failed to load archived turn summaries for ${widget.sessionId}: $error',
      );
      if (mounted && _collapseAllTurns) {
        _collapsedTurnSummariesN.value = fallback;
      }
    }
  }

  Future<void> _openCollapsedTurnSummary(_CollapsedTurnSummary summary) async {
    final anchorArchiveIndex = summary.promptArchiveIndex;
    if (anchorArchiveIndex == null) {
      return;
    }
    final scrollRatio = _captureScrollPositionRatio();
    final loaded = await ref
        .read(sessionStateProvider.notifier)
        .loadSessionMessageArchiveWindowAround(
          widget.sessionId,
          anchorArchiveIndex: anchorArchiveIndex,
        );
    if (!mounted || !loaded) {
      return;
    }
    _syncMessagesFromRepository();
    final loadedGroups = _resolveTurnGroups(_messages);
    final loadedGroup = loadedGroups.where((group) => group.id == summary.id);
    _updateState(() {
      _expandedTurnIds
        ..clear()
        ..addAll(loadedGroup.map((group) => group.id));
    });
    _scheduleRestoreScrollPosition(
      scrollRatio: scrollRatio,
      forcePinToLatest: false,
    );
  }

  void _toggleAllTurns(List<_MessageTurnGroup> groups) {
    if (groups.isEmpty) {
      return;
    }
    final nextCollapseAllTurns = !_collapseAllTurns;
    final shouldPinLatest = _shouldStickToLatest || _isNearBottom;

    // 修复白屏问题：在折叠/展开前保存当前滚动位置比例，以便恢复相对位置
    final scrollRatio = _captureScrollPositionRatio();

    _updateState(() {
      _collapseAllTurns = nextCollapseAllTurns;
      _expandedTurnIds.clear();
      if (!_collapseAllTurns) {
        _expandedTurnIds.addAll(groups.map((group) => group.id));
      }
    });
    unawaited(_persistSessionUiState());
    if (nextCollapseAllTurns) {
      unawaited(_ensureCollapsedTurnSummariesLoaded(groups));
    } else {
      _collapsedTurnSummariesN.value = const <_CollapsedTurnSummary>[];
    }

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

  void _scheduleViewportStateRefresh() =>
      _viewportController.scheduleViewportStateRefresh();

  /// 修复白屏问题：捕获当前滚动位置的比例（0.0 到 1.0）
  /// 用于在列表高度变化后恢复相对滚动位置
  double? _captureScrollPositionRatio() =>
      _viewportController.captureScrollPositionRatio();

  /// 修复白屏问题：使用比例恢复滚动位置
  /// 确保在折叠/展开轮次后，视口不会落在无效区域
  void _scheduleRestoreScrollPosition({
    double? scrollRatio,
    bool forcePinToLatest = false,
  }) =>
      _viewportController.scheduleRestoreScrollPosition(
        scrollRatio: scrollRatio,
        forcePinToLatest: forcePinToLatest,
      );
}
