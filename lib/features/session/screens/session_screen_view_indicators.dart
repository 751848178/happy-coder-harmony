part of 'session_screen.dart';

extension _SessionScreenViewIndicators on _SessionScreenState {
  bool get _hasScrollableActionTarget => true;

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
    _updateState(() {
      _scrollActionVerticalOffset =
          (_scrollActionVerticalOffset + details.delta.dy)
              .clamp(-maxRise, 0.0)
              .toDouble();
      if (!collapsed) {
        _scrollActionDragDx = (_scrollActionDragDx + details.delta.dx)
            .clamp(0.0, _sessionScrollActionDragTravel)
            .toDouble();
      }
    });
  }

  void _resetScrollActionDrag() {
    if (_scrollActionDragDx == 0) {
      return;
    }
    _updateState(() {
      _scrollActionDragDx = 0;
    });
  }

  void _collapseScrollActions() {
    _updateState(() {
      _scrollActionsCollapsed = true;
      _scrollActionDragDx = 0;
    });
  }

  void _expandScrollActions() {
    _updateState(() {
      _scrollActionsCollapsed = false;
      _scrollActionDragDx = 0;
    });
  }

  Widget _buildScrollActionsOverlay({
    required double viewportHeight,
    required Session? session,
    required List<_MessageTurnGroup> turnGroups,
  }) {
    if (!_hasScrollableActionTarget) {
      return const SizedBox.shrink();
    }

    final handleHiddenOffset =
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

  Widget _buildFloatingThinkingBadge(Session session) {
    final label = session.thinkingAt == null
        ? 'AI 思考中'
        : _formatThinkingLabel(session.thinkingAt!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.brandColor.withValues(alpha: 0.16)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.brandColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyTurnPrompt() {
    final stickyGroup =
        _visibleTurnGroups.cast<_MessageTurnGroup?>().firstWhere(
              (group) => group?.id == _stickyTurnId,
              orElse: () => null,
            );
    final prompt = stickyGroup?.userPrompt;
    if (stickyGroup == null || prompt == null) {
      return const SizedBox.shrink();
    }

    return Semantics(
      button: true,
      label: '跳转到这条消息的第一条回复',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _scrollToTurnReply(stickyGroup.id),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.neutral200),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 12,
                    color: AppTheme.brandColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prompt.text
                                ?.replaceAll(RegExp(r'\s+'), ' ')
                                .trim()
                                .isNotEmpty ==
                            true
                        ? prompt.text!.replaceAll(RegExp(r'\s+'), ' ').trim()
                        : stickyGroup.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 16,
                  color: AppTheme.neutral500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatThinkingLabel(DateTime since) {
    final duration = DateTime.now().difference(since);
    if (duration.inSeconds < 1) {
      return 'AI 思考中';
    }
    if (duration.inSeconds < 60) {
      return 'AI 思考 ${duration.inSeconds}s';
    }
    if (duration.inMinutes < 60) {
      return 'AI 思考 ${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return 'AI 思考 ${duration.inHours}h ${duration.inMinutes % 60}m';
  }

  bool _isThinkingActive(
    Session? session,
    List<_MessageTurnGroup> turnGroups,
  ) {
    final latestGroup = turnGroups.isNotEmpty ? turnGroups.last : null;
    return sessionTurnIsThinkingStillBlocking(
      session: session,
      messages: latestGroup?.messages ?? const <ReducerMessage>[],
      manualThinkingOverride: _manualThinkingOverride,
    );
  }

  void _applyManualThinkingOverride(bool? value) {
    if (!mounted) {
      return;
    }
    _updateState(() {
      _manualThinkingOverride = value;
      if (value != true) {
        _activeResponseLocalId = null;
      }
    });
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final session = sessionNotifier.getSession(widget.sessionId);
    final messages =
        sessionNotifier.getSessionMessages(widget.sessionId)?.messages ??
            const <ReducerMessage>[];
    _scheduleQueuedMessageReconciliation(session, messages);
  }

  Future<void> _showThinkingStateSheet(
    Session? session,
    List<_MessageTurnGroup> turnGroups,
  ) async {
    final effectiveThinking = _isThinkingActive(session, turnGroups);
    final override = _manualThinkingOverride;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI 思考状态',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.neutral900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                override == null
                    ? '当前为自动判断：${effectiveThinking ? "思考中" : "未思考"}'
                    : '当前为手动订正：${effectiveThinking ? "思考中" : "未思考"}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.neutral600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.psychology_alt_rounded),
                title: const Text('标记为思考中'),
                subtitle: const Text('用于 AI 仍在执行但状态没有及时更新时。'),
                onTap: () {
                  Navigator.pop(context);
                  _applyManualThinkingOverride(true);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline_rounded),
                title: const Text('标记为已结束'),
                subtitle: const Text('立即解除卡住的忙碌状态，并允许继续发送。'),
                onTap: () {
                  Navigator.pop(context);
                  _applyManualThinkingOverride(false);
                },
              ),
              if (override != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restart_alt_rounded),
                  title: const Text('恢复自动判断'),
                  subtitle: const Text('重新按会话事件和消息内容自动推断状态。'),
                  onTap: () {
                    Navigator.pop(context);
                    _applyManualThinkingOverride(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollActions(
    Session? session,
    List<_MessageTurnGroup> turnGroups,
  ) {
    final isThinking = _isThinkingActive(session, turnGroups);
    final hasOverride = _manualThinkingOverride != null;
    return Column(
      key: const ValueKey('session-scroll-actions-rail'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _ScrollActionButton(
          icon: Icons.vertical_align_top_rounded,
          tooltip: '回到顶部',
          enabled: _canScrollToTop,
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
          enabled: _canScrollToBottom,
          onTap: _scrollToBottom,
        ),
      ],
    );
  }

  /// 输入区域
}
