part of '../session_detail.dart';

extension _SessionScreenViewMessages on _SessionScreenState {
  Widget _buildMessageList({
    required List<ReducerMessage> messages,
    required List<_MessageTurnGroup> turnGroups,
    required bool autoApproveEnabled,
  }) {
    if (_collapseAllTurns && turnGroups.isNotEmpty) {
      return KeyedSubtree(
        key: const ValueKey('message-list-collapsed'),
        child: ValueListenableBuilder<List<_CollapsedTurnSummary>>(
          valueListenable: _collapsedTurnSummariesN,
          builder: (_, summaries, __) {
            final effectiveSummaries = summaries.isNotEmpty
                ? summaries
                : List<_CollapsedTurnSummary>.unmodifiable(
                    turnGroups.map(_CollapsedTurnSummary.fromTurnGroup),
                  );
            final loadedGroupsById = <String, _MessageTurnGroup>{
              for (final group in turnGroups) group.id: group,
            };
            final summaryIndexes = <String, int>{
              for (var index = 0; index < effectiveSummaries.length; index++)
                effectiveSummaries[index].id: index,
            };
            return ListView.builder(
              controller: _scrollController,
              findChildIndexCallback: (key) {
                if (key is ValueKey<String>) {
                  return summaryIndexes[key.value];
                }
                return null;
              },
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                _sessionMessageListTopPadding,
                AppTheme.spacingMd,
                _sessionMessageListBottomPadding,
              ),
              itemCount: effectiveSummaries.length,
              itemBuilder: (context, index) {
                final summary = effectiveSummaries[index];
                final loadedGroup = loadedGroupsById[summary.id];
                return KeyedSubtree(
                  key: ValueKey<String>(summary.id),
                  child: _buildCollapsedTurnSummaryCard(
                    summary,
                    loadedGroup: loadedGroup,
                    autoApproveEnabled: autoApproveEnabled,
                  ),
                );
              },
            );
          },
        ),
      );
    }

    // Per-message virtualization: each message is its own ListView item.
    // This avoids building all messages in a turn group when only some are
    // visible (especially during streaming when the last turn grows large).
    final flatItems = _bodyPresenter.resolveFlatItems(turnGroups);
    _logDuplicateMessageIds(
      flatItems.map((item) => item.message).toList(growable: false),
      stage: 'flat-items',
    );
    return KeyedSubtree(
      key: const ValueKey('message-list-flat'),
      child: ListView.builder(
        controller: _scrollController,
        cacheExtent: 480,
        findChildIndexCallback: (key) {
          if (key is ValueKey<String>) {
            return _bodyPresenter.findFlatItemIndexByRenderId(key.value);
          }
          return null;
        },
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMd,
          _sessionMessageListTopPadding,
          AppTheme.spacingMd,
          _sessionMessageListBottomPadding,
        ),
        itemCount: flatItems.length,
        itemBuilder: (context, index) {
          final item = flatItems[index];
          return _buildFlatMessageItem(
            item,
            autoApproveEnabled: autoApproveEnabled,
          );
        },
      ),
    );
  }

  /// Build a single flat message item with appropriate turn-group wrappers.
  Widget _buildFlatMessageItem(
    _FlatMessageItem item, {
    required bool autoApproveEnabled,
  }) {
    return KeyedSubtree(
      key: ValueKey<String>(item.renderId),
      child: Padding(
        padding: EdgeInsets.only(
          top: item.startsNewTurn && item.turnIndex > 0 ? 4 : 0,
        ),
        child: _BuildContextAnchor(
          anchorId: item.renderId,
          onAttach: _registerMessageRowContext,
          onDetach: _unregisterMessageRowContext,
          child: ValueListenableBuilder<bool>(
            valueListenable: _messageInteractionsEnabledN,
            builder: (_, interactionsEnabled, __) {
              return IgnorePointer(
                ignoring: !interactionsEnabled,
                child: _buildMessageBubble(
                  item.message,
                  autoApproveEnabled: autoApproveEnabled,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ReducerMessage message, {
    required bool autoApproveEnabled,
  }) {
    final isTool = message.isToolCall && message.tool != null;
    final onMessageActionChoice =
        (SessionMessageActionChoice choice, String actionText) =>
            _handleMessageActionChoice(choice: choice, actionText: actionText);
    final onShowMessageActionSheet = (ReducerMessage msg, String actionText) =>
        _showMessageActionSheet(message: msg, actionText: actionText);

    if (!isTool) {
      return RepaintBoundary(
        child: _MessageBubble(
          message: message,
          autoApproveEnabled: autoApproveEnabled,
          isToolActionPending: false,
          onApproveTool: null,
          onRejectTool: null,
          onMessageActionChoice: onMessageActionChoice,
          onShowMessageActionSheet: onShowMessageActionSheet,
          onFilePathTap: _createFilePathTapHandler(),
        ),
      );
    }
    return ValueListenableBuilder<bool>(
      valueListenable: _toolActionPendingListenable(message.tool!.id),
      builder: (context, isToolActionPending, _) {
        return RepaintBoundary(
          child: _MessageBubble(
            message: message,
            autoApproveEnabled: autoApproveEnabled,
            isToolActionPending: isToolActionPending,
            onApproveTool: _approveToolCall,
            onRejectTool: _rejectToolCall,
            onMessageActionChoice: onMessageActionChoice,
            onShowMessageActionSheet: onShowMessageActionSheet,
            onFilePathTap: null,
          ),
        );
      },
    );
  }

  Widget _buildTurnGroupCard(
    _MessageTurnGroup group, {
    required bool expanded,
    required bool autoApproveEnabled,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: expanded ? 8 : 2),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleTurnGroup(group),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppTheme.neutral500,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.neutral200),
              ),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Column(
                children: [
                  for (final msg in group.messages)
                    _buildMessageBubble(
                      msg,
                      autoApproveEnabled: autoApproveEnabled,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsedTurnSummaryCard(
    _CollapsedTurnSummary summary, {
    required _MessageTurnGroup? loadedGroup,
    required bool autoApproveEnabled,
  }) {
    if (loadedGroup != null) {
      return _buildTurnGroupCard(
        loadedGroup,
        expanded: _expandedTurnIds.contains(summary.id),
        autoApproveEnabled: autoApproveEnabled,
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Column(
        children: [
          InkWell(
            onTap: () => unawaited(_openCollapsedTurnSummary(summary)),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      summary.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppTheme.neutral500,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
