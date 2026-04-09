part of 'session_screen.dart';

extension _SessionScreenViewInput on _SessionScreenState {
  Widget _buildInputArea(
    Session? session,
    List<_MessageTurnGroup> turnGroups, {
    required bool conversationBusy,
    required bool socketConnected,
    required bool commandPaletteEnabled,
    required bool agentInputEnterToSend,
    required List<_SlashCommandItem> slashCommands,
  }) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final flavor =
        _resolveFlavorLabel(session?.metadata?['flavor']?.toString());
    final sendTooltip = conversationBusy ? '加入待发送队列' : '发送消息';
    return ValueListenableBuilder<List<SessionInputTemplate>>(
      valueListenable: _customInputTemplatesN,
      builder: (_, __, ___) {
        final availableInputTemplates = _allInputTemplates();
        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            AppTheme.spacingSm,
            AppTheme.spacingMd,
            AppTheme.spacingMd,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              top: BorderSide(color: AppTheme.neutral200),
            ),
          ),
          child: SafeArea(
            top: false,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (context, composerValue, _) {
                final visibleSlashCommands = _visibleSlashCommands(
                  slashCommands,
                  enabled: commandPaletteEnabled,
                  value: composerValue,
                );
                final visibleInputTemplates = _visibleInputTemplates(
                  availableInputTemplates,
                  value: composerValue,
                );
                final hasComposerText = composerValue.text.trim().isNotEmpty;
                final canAbortCurrentResponse = _canAbortCurrentResponse(
                  session,
                  turnGroups,
                  socketConnected: socketConnected,
                );
                final showingSuggestionPanel = (commandPaletteEnabled &&
                        _shouldShowSlashCommands(
                          visibleSlashCommands,
                          value: composerValue,
                        )) ||
                    _shouldShowInputTemplates(
                      visibleInputTemplates,
                      value: composerValue,
                    );

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<List<QueuedComposerMessage>>(
                      valueListenable: _queuedMessagesN,
                      builder: (_, queuedMessages, __) {
                        if (queuedMessages.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildQueuedComposerPanel(
                              queuedMessages: queuedMessages,
                              busy: conversationBusy,
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      },
                    ),
                    if (session != null) ...[
                      _buildSessionControls(session, turnGroups),
                      const SizedBox(height: 8),
                    ],
                    if (commandPaletteEnabled &&
                        _shouldShowSlashCommands(
                          visibleSlashCommands,
                          value: composerValue,
                        ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildSlashCommandPanel(visibleSlashCommands),
                      ),
                    if (_shouldShowInputTemplates(
                      visibleInputTemplates,
                      value: composerValue,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildInputTemplatePanel(visibleInputTemplates),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _messageFocusNode,
                            maxLines: 5,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: conversationBusy
                                  ? 'AI 正在回复，继续发送会加入队列...'
                                  : '向$flavor发送消息...',
                              filled: true,
                              fillColor: AppTheme.neutral100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMd,
                                vertical: AppTheme.spacingSm,
                              ),
                            ),
                            keyboardType: TextInputType.multiline,
                            textInputAction: agentInputEnterToSend
                                ? TextInputAction.send
                                : TextInputAction.newline,
                            onSubmitted: agentInputEnterToSend
                                ? (_) => _handleSendAction(session, turnGroups)
                                : null,
                          ),
                        ),
                        if (canAbortCurrentResponse) ...[
                          const SizedBox(width: AppTheme.spacingSm),
                          ValueListenableBuilder<bool>(
                            valueListenable: _isAbortingN,
                            builder: (_, isAborting, __) {
                              return IconButton(
                                tooltip: isAborting
                                    ? '正在停止当前回复'
                                    : '停止当前回复',
                                onPressed: isAborting
                                    ? null
                                    : () => _handleAbortAction(
                                          session,
                                          turnGroups,
                                          socketConnected: socketConnected,
                                        ),
                                icon: isAborting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.stop_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.errorColor
                                      .withValues(alpha: 0.12),
                                  foregroundColor: AppTheme.errorColor,
                                  padding: const EdgeInsets.all(12),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(width: AppTheme.spacingSm),
                        ValueListenableBuilder<bool>(
                          valueListenable: _isSendingN,
                          builder: (_, isSending, __) {
                            return IconButton(
                              tooltip: sendTooltip,
                              onPressed: hasComposerText
                                  ? () => _handleSendAction(session, turnGroups)
                                  : null,
                              icon: isSending
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      conversationBusy
                                          ? Icons.playlist_add_rounded
                                          : Icons.send_rounded,
                                    ),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.brandColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    if ((commandPaletteEnabled &&
                            slashCommands.isNotEmpty) ||
                        availableInputTemplates.isNotEmpty)
                      if (!(keyboardVisible && showingSuggestionPanel))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              [
                                if (commandPaletteEnabled &&
                                    slashCommands.isNotEmpty)
                                  '输入 `/` 查看 ${slashCommands.length} 个可用指令',
                                if (availableInputTemplates.isNotEmpty)
                                  '输入 `^` 快速插入模板',
                              ].join(' · '),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.neutral600,
                              ),
                            ),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
