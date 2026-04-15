part of 'session_screen.dart';

/// A flat list item representing a single message with turn-group metadata.
/// Used by [_buildMessageList] to virtualize at the per-message level instead
/// of per-turn-group level, avoiding the O(turn_size) Column layout for all
/// messages in a turn when only some are visible.
class _FlatMessageItem {
  const _FlatMessageItem({
    required this.message,
    required this.turnGroupId,
    required this.startsNewTurn,
    required this.isFirstReply,
    required this.turnIndex,
  });

  final ReducerMessage message;
  final String turnGroupId;
  final bool startsNewTurn;
  final bool isFirstReply;
  final int turnIndex;
}

/// ScrollController that supports synchronous position correction
/// when message content changes during edge loads.
///
/// Call [standbyForPrepend] before prepending older messages (adds items
/// above viewport). Call [standbyForAppend] before appending newer messages
/// (adds items below viewport with possible head-trim).
class _ChatScrollController extends ScrollController {
  double? _standbyPixels;
  double? _standbyMaxScrollExtent;
  bool _standbyAlignToBottom = false;

  /// Record scroll state before prepending older messages above viewport.
  void standbyForPrepend() {
    if (!hasClients) return;
    _standbyPixels = position.pixels;
    _standbyMaxScrollExtent = position.maxScrollExtent;
    _standbyAlignToBottom = false;
  }

  /// Record scroll state before appending newer messages below viewport.
  void standbyForAppend() {
    if (!hasClients) return;
    _standbyPixels = position.pixels;
    _standbyMaxScrollExtent = position.maxScrollExtent;
    _standbyAlignToBottom = true;
  }
}

/// ScrollPosition that corrects scroll offset synchronously during layout
/// when a standby is active on the owning [_ChatScrollController].
///
/// This eliminates the one-frame jitter caused by post-frame-callback-based
/// anchor restoration. Correction happens in [applyContentDimensions], which
/// is called during layout (before paint), so the user never sees the wrong
/// position.
class _ChatScrollPosition extends ScrollPositionWithSingleContext {
  _ChatScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  @override
  bool applyContentDimensions(double min, double max) {
    final ctrl = controller;
    if (ctrl is _ChatScrollController) {
      final standbyPixels = ctrl._standbyPixels;
      final standbyMax = ctrl._standbyMaxScrollExtent;
      if (standbyPixels != null && standbyMax != null) {
        // Consume standby state so correction fires only once.
        ctrl._standbyPixels = null;
        ctrl._standbyMaxScrollExtent = null;
        final delta = max - standbyMax;
        if (delta.abs() > 0.5) {
          final double corrected;
          if (ctrl._standbyAlignToBottom) {
            // Append mode: keep distance from bottom constant.
            corrected = (max - (standbyMax - standbyPixels)).clamp(min, max);
          } else {
            // Prepend mode: shift down by the height of new content above.
            corrected = (standbyPixels + delta).clamp(min, max);
          }
          forcePixels(corrected);
        }
      }
    }
    return super.applyContentDimensions(min, max);
  }
}

/// ScrollPhysics that creates [_ChatScrollPosition] instances for the
/// message list ListView.
class _ChatScrollPhysics extends ClampingScrollPhysics {
  const _ChatScrollPhysics({super.parent});

  @override
  ScrollPosition createScrollPosition(
    ScrollContext context,
    ScrollPhysics parent,
    ScrollPosition? oldPosition,
  ) {
    return _ChatScrollPosition(
      physics: parent,
      context: context,
      initialPixels: oldPosition?.pixels ?? initialPixels,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class _BuildContextAnchor extends StatefulWidget {
  const _BuildContextAnchor({
    required this.anchorId,
    required this.onAttach,
    required this.onDetach,
    required this.child,
  });

  final String anchorId;
  final void Function(String anchorId, BuildContext context) onAttach;
  final void Function(String anchorId, BuildContext context) onDetach;
  final Widget child;

  @override
  State<_BuildContextAnchor> createState() => _BuildContextAnchorState();
}

class _RenderObjectAnchor extends SingleChildRenderObjectWidget {
  const _RenderObjectAnchor({
    required this.anchorId,
    required this.onAttach,
    required this.onDetach,
    required super.child,
  });

  final String anchorId;
  final void Function(String anchorId, BuildContext context) onAttach;
  final void Function(String anchorId, BuildContext context) onDetach;

  @override
  SingleChildRenderObjectElement createElement() =>
      _RenderObjectAnchorElement(this);

  @override
  RenderProxyBox createRenderObject(BuildContext context) => RenderProxyBox();
}

class _RenderObjectAnchorElement extends SingleChildRenderObjectElement {
  _RenderObjectAnchorElement(_RenderObjectAnchor super.widget);

  _RenderObjectAnchor get _anchorWidget => widget as _RenderObjectAnchor;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    // Register synchronously so the anchor context is available immediately
    // for _captureMessageViewportAnchor in the same frame.  The previous
    // postFrameCallback caused a one-frame delay that made anchor restoration
    // fall through to coarse estimation or fail entirely.
    _anchorWidget.onAttach(_anchorWidget.anchorId, this);
  }

  @override
  void activate() {
    super.activate();
    _anchorWidget.onAttach(_anchorWidget.anchorId, this);
  }

  @override
  void update(covariant _RenderObjectAnchor newWidget) {
    final previousWidget = _anchorWidget;
    super.update(newWidget);
    if (previousWidget.anchorId != newWidget.anchorId) {
      previousWidget.onDetach(previousWidget.anchorId, this);
    }
    _anchorWidget.onAttach(_anchorWidget.anchorId, this);
  }

  @override
  void deactivate() {
    _anchorWidget.onDetach(_anchorWidget.anchorId, this);
    super.deactivate();
  }
}

class _BuildContextAnchorState extends State<_BuildContextAnchor>
    with AutomaticKeepAliveClientMixin<_BuildContextAnchor> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _RenderObjectAnchor(
      anchorId: widget.anchorId,
      onAttach: widget.onAttach,
      onDetach: widget.onDetach,
      child: widget.child,
    );
  }
}

extension _SessionScreenViewMessages on _SessionScreenState {
  Widget _buildMessageList({
    required List<ReducerMessage> messages,
    required List<_MessageTurnGroup> turnGroups,
    required bool autoApproveEnabled,
  }) {
    if (_collapseAllTurns && turnGroups.isNotEmpty) {
      return ValueListenableBuilder<List<_CollapsedTurnSummary>>(
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
            physics: const _ChatScrollPhysics(),
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
    return ListView.builder(
      controller: _scrollController,
      cacheExtent: 480,
      findChildIndexCallback: (key) {
        if (key is ValueKey<String>) {
          return _bodyPresenter.findFlatItemIndexByMessageId(key.value);
        }
        return null;
      },
      physics: const _ChatScrollPhysics(),
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
    );
  }

  /// Build a single flat message item with appropriate turn-group wrappers.
  Widget _buildFlatMessageItem(
    _FlatMessageItem item, {
    required bool autoApproveEnabled,
  }) {
    return KeyedSubtree(
      key: ValueKey<String>(item.message.id),
      child: Padding(
        padding: EdgeInsets.only(
          top: item.startsNewTurn && item.turnIndex > 0 ? 4 : 0,
        ),
        child: _BuildContextAnchor(
          anchorId: item.message.id,
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
    final filePathTapHandler = _createFilePathTapHandler();
    final tool = message.tool;
    if (tool == null) {
      return RepaintBoundary(
        child: _MessageBubble(
          message: message,
          autoApproveEnabled: autoApproveEnabled,
          interactionsEnabled: true,
          isToolActionPending: false,
          onApproveTool: _approveToolCall,
          onRejectTool: _rejectToolCall,
          onMessageActionChoice: (choice, actionText) =>
              _handleMessageActionChoice(
            choice: choice,
            actionText: actionText,
          ),
          onShowMessageActionSheet: (message, actionText) =>
              _showMessageActionSheet(
            message: message,
            actionText: actionText,
          ),
          onFilePathTap: filePathTapHandler,
        ),
      );
    }
    return ValueListenableBuilder<bool>(
      valueListenable: _toolActionPendingListenable(tool.id),
      builder: (context, isToolActionPending, _) {
        return RepaintBoundary(
          child: _MessageBubble(
            message: message,
            autoApproveEnabled: autoApproveEnabled,
            interactionsEnabled: true,
            isToolActionPending: isToolActionPending,
            onApproveTool: _approveToolCall,
            onRejectTool: _rejectToolCall,
            onMessageActionChoice: (choice, actionText) =>
                _handleMessageActionChoice(
              choice: choice,
              actionText: actionText,
            ),
            onShowMessageActionSheet: (message, actionText) =>
                _showMessageActionSheet(
              message: message,
              actionText: actionText,
            ),
            onFilePathTap: filePathTapHandler,
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

  void Function(String)? _createFilePathTapHandler() {
    final sessionId = widget.sessionId;
    if (sessionId.isEmpty) return null;
    return (String filePath) {
      final fileName = filePath.split('/').last;
      final uri = Uri.parse(
        AppRoutes.sessionFileDetail(sessionId) +
            '?path=${Uri.encodeComponent(filePath)}'
            '&name=${Uri.encodeComponent(fileName)}',
      );
      context.push(uri.toString());
    };
  }
}
