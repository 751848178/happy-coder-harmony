part of '../session_detail.dart';

extension _SessionScreenViewIndicators on _SessionScreenState {
  bool get _hasScrollableActionTarget => true;

  double _resolveScrollActionsViewportHeight(BuildContext context) {
    if (_scrollController.hasClients) {
      final position = _scrollController.effectivePositionOrNull;
      if (position != null && position.hasViewportDimension) {
        final viewport = position.viewportDimension;
        if (viewport.isFinite && viewport > 0) {
          return viewport;
        }
      }
    }
    final viewportBox = _messageListViewportRenderBox();
    if (viewportBox != null) {
      final height = viewportBox.size.height;
      if (height.isFinite && height > 0) {
        return height;
      }
    }
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery != null) {
      final fallbackHeight = mediaQuery.size.height -
          mediaQuery.padding.top -
          mediaQuery.padding.bottom;
      if (fallbackHeight.isFinite && fallbackHeight > 0) {
        return fallbackHeight;
      }
    }
    return 0;
  }

  double _maxScrollActionRise(double viewportHeight) {
    final availableHeight = viewportHeight -
        _sessionScrollActionBottomInset -
        _sessionScrollActionRailHeight -
        _sessionScrollActionTopClearance;
    return availableHeight > 0 ? availableHeight : 0;
  }

  void _handleScrollActionsDragUpdate(
    DragUpdateDetails details, {
    required double viewportHeight,
    required bool collapsed,
  }) {
    final maxRise = _maxScrollActionRise(viewportHeight);
    _scrollActionVerticalOffsetN.value =
        (_scrollActionVerticalOffset + details.delta.dy)
            .clamp(-maxRise, 0.0)
            .toDouble();
    if (!collapsed) {
      _scrollActionDragDxN.value = (_scrollActionDragDx + details.delta.dx)
          .clamp(0.0, _sessionScrollActionDragTravel)
          .toDouble();
    }
  }

  void _resetScrollActionDrag() {
    if (_scrollActionDragDx == 0) {
      return;
    }
    _scrollActionDragDxN.value = 0;
  }

  void _collapseScrollActions() {
    _scrollActionsCollapsedN.value = true;
    _scrollActionDragDxN.value = 0;
  }

  void _expandScrollActions() {
    _scrollActionsCollapsedN.value = false;
    _scrollActionDragDxN.value = 0;
  }

  Widget _buildScrollActionsOverlay({
    required double viewportHeight,
    required Session? session,
    required List<_MessageTurnGroup> turnGroups,
  }) {
    if (!_hasScrollableActionTarget) {
      return const SizedBox.shrink();
    }

    const handleHiddenOffset =
        _sessionScrollActionHandleWidth - _sessionScrollActionHandlePeekWidth;
    final effectiveVerticalOffset = _scrollActionVerticalOffset
        .clamp(-_maxScrollActionRise(viewportHeight), 0.0)
        .toDouble();

    return Positioned(
      key: const ValueKey('session-scroll-actions'),
      right: AppTheme.spacingMd,
      bottom: _sessionScrollActionBottomInset,
      child: Transform.translate(
        offset: Offset(
          _scrollActionsCollapsed ? handleHiddenOffset : _scrollActionDragDx,
          effectiveVerticalOffset,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (details) => _handleScrollActionsDragUpdate(
            details,
            viewportHeight: viewportHeight,
            collapsed: _scrollActionsCollapsed,
          ),
          onPanEnd: (_) {
            if (_scrollActionsCollapsed) {
              return;
            }
            if (_scrollActionDragDx >= _sessionScrollActionHideThreshold) {
              _collapseScrollActions();
              return;
            }
            _resetScrollActionDrag();
          },
          onPanCancel: _resetScrollActionDrag,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _scrollActionsCollapsed
                ? _ScrollActionHandle(
                    key: const ValueKey('session-scroll-actions-handle'),
                    onTap: _expandScrollActions,
                  )
                : _buildScrollActions(session, turnGroups),
          ),
        ),
      ),
    );
  }

  Widget _buildNewMessageIndicator() {
    return FilledButton.icon(
      onPressed: _scrollToBottom,
      icon: const Icon(Icons.arrow_downward_rounded, size: 16),
      label: const Text('有新消息'),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.brandColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        elevation: 3,
      ),
    );
  }

  Widget _buildScrollActions(
    Session? session,
    List<_MessageTurnGroup> turnGroups,
  ) {
    final isThinking = _isThinkingActive(session, turnGroups);
    final hasOverride = _manualThinkingOverride != null;
    final topActionEnabled = _canScrollToTop &&
        !_isLoadingOlderMessages &&
        !_isHydratingArchiveHistory;
    final bottomActionEnabled = _canScrollToBottom &&
        !_isLoadingNewerMessages &&
        !_isHydratingArchiveHistory;
    return Column(
      key: const ValueKey('session-scroll-actions-rail'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _ScrollActionButton(
          icon: Icons.vertical_align_top_rounded,
          tooltip: '回到顶部',
          enabled: topActionEnabled,
          onTap: _scrollToTop,
        ),
        const SizedBox(height: _sessionScrollActionGap),
        _ScrollActionButton(
          icon: isThinking
              ? Icons.psychology_alt_rounded
              : Icons.psychology_alt_outlined,
          tooltip: hasOverride ? '已手动订正 AI 思考状态' : '订正 AI 思考状态',
          enabled: true,
          foregroundColor: hasOverride
              ? (isThinking ? AppTheme.brandColor : AppTheme.successColor)
              : null,
          onTap: () => _showThinkingStateSheet(session, turnGroups),
        ),
        const SizedBox(height: _sessionScrollActionGap),
        _ScrollActionButton(
          icon: Icons.vertical_align_bottom_rounded,
          tooltip: '回到最新消息',
          enabled: bottomActionEnabled,
          onTap: _scrollToBottom,
        ),
      ],
    );
  }

  /// 输入区域
}
