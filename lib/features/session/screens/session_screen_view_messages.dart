part of 'session_screen.dart';

extension _SessionScreenViewMessages on _SessionScreenState {
  Widget _buildMessageList({
    required List<ReducerMessage> messages,
    required List<_MessageTurnGroup> turnGroups,
    required bool autoApproveEnabled,
  }) {
    if (_collapseAllTurns && turnGroups.isNotEmpty) {
      return ListView.builder(
        key: _messageListViewportKey,
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMd,
          12,
          AppTheme.spacingMd,
          12,
        ),
        itemCount: turnGroups.length,
        itemBuilder: (context, index) {
          final group = turnGroups[index];
          return _buildTurnGroupCard(
            group,
            expanded: _expandedTurnIds.contains(group.id),
            autoApproveEnabled: autoApproveEnabled,
          );
        },
      );
    }

    return ListView(
      key: _messageListViewportKey,
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        12,
        AppTheme.spacingMd,
        12,
      ),
      children: [
        for (final group in turnGroups)
          _buildExpandedTurnSection(
            group,
            autoApproveEnabled: autoApproveEnabled,
          ),
      ],
    );
  }

  Widget _buildExpandedTurnSection(
    _MessageTurnGroup group, {
    required bool autoApproveEnabled,
  }) {
    final prompt = group.userPrompt;
    final remainingMessages = prompt == null
        ? group.messages
        : group.messages
            .where((message) => message.id != prompt.id)
            .toList(growable: false);

    return KeyedSubtree(
      key: _turnSectionKey(group.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (prompt != null)
              _buildMessageBubble(
                prompt,
                autoApproveEnabled: autoApproveEnabled,
              ),
            if (remainingMessages.isNotEmpty)
              SizedBox(
                key: _turnReplyAnchorKey(group.id),
                height: 0,
              ),
            for (final message in remainingMessages)
              _buildMessageBubble(
                message,
                autoApproveEnabled: autoApproveEnabled,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ReducerMessage message, {
    required bool autoApproveEnabled,
  }) {
    return _MessageBubble(
      key: ValueKey(message.id),
      message: message,
      autoApproveEnabled: autoApproveEnabled,
      isToolActionPending: message.tool != null &&
          _toolActionsInFlight.contains(message.tool!.id),
      onApproveTool: _approveToolCall,
      onRejectTool: _rejectToolCall,
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
                  for (final message in group.messages)
                    _buildMessageBubble(
                      message,
                      autoApproveEnabled: autoApproveEnabled,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
