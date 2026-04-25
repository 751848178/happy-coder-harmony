part of '../session_detail.dart';

extension _SessionScreenStateQueueManagement on _SessionScreenState {
  Future<void> _maybeSendNextQueuedMessage(
    Session? session,
    List<_MessageTurnGroup> turnGroups,
  ) async {
    if (session == null) {
      return;
    }
    if (_queuedMessages.isEmpty || _isConversationBusy(session, turnGroups)) {
      return;
    }
    if (_isAutoSendingQueuedMessage) {
      return;
    }

    final nextMessage = _queuedMessages.first;
    final remaining = List<QueuedComposerMessage>.from(_queuedMessages)
      ..removeAt(0);

    _updateState(() {
      _isAutoSendingQueuedMessage = true;
    });
    _queuedMessagesN.value = remaining;

    try {
      try {
        await _composerQueueService.replace(widget.sessionId, remaining);
      } catch (error) {
        if (mounted) {
          final restoredQueue = <QueuedComposerMessage>[
            nextMessage,
            ..._queuedMessages,
          ];
          _queuedMessagesN.value = restoredQueue;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('更新待发送消息失败: $error'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }
      final sent = await _dispatchMessage(
        nextMessage.content,
        restoreComposerOnError: false,
      );
      if (!sent && mounted) {
        final restoredQueue = <QueuedComposerMessage>[
          nextMessage,
          ..._queuedMessages,
        ];
        _queuedMessagesN.value = restoredQueue;
        await _composerQueueService.replace(widget.sessionId, restoredQueue);
      }
    } finally {
      if (mounted) {
        _updateState(() {
          _isAutoSendingQueuedMessage = false;
        });
      }
    }
  }

  Future<void> _enqueueComposerMessage(String content, {int? insertAt}) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final nextMessage = _composerQueueService.createDraft(trimmed);
    final nextQueue = List<QueuedComposerMessage>.from(_queuedMessages);
    final targetIndex = insertAt == null
        ? nextQueue.length
        : insertAt.clamp(0, nextQueue.length);
    nextQueue.insert(targetIndex, nextMessage);
    await _storeQueuedComposerMessages(nextQueue);
  }

  Future<void> _removeQueuedComposerMessage(String messageId) async {
    final nextQueue = _queuedMessages
        .where((message) => message.id != messageId)
        .toList(growable: false);
    await _storeQueuedComposerMessages(nextQueue);
  }

  Future<void> _editQueuedComposerMessage(QueuedComposerMessage message) async {
    final index = _queuedMessages.indexWhere((item) => item.id == message.id);
    if (index < 0) {
      return;
    }
    final currentDraft = _messageController.text.trim();
    final nextQueue = List<QueuedComposerMessage>.from(_queuedMessages)
      ..removeAt(index);
    if (currentDraft.isNotEmpty && currentDraft != message.content.trim()) {
      final preservedDraft = _composerQueueService.createDraft(currentDraft);
      nextQueue.insert(index, preservedDraft);
    }
    await _storeQueuedComposerMessages(nextQueue);
    _setComposerText(message.content);
    _messageFocusNode.requestFocus();
  }

  void _setComposerText(String text) {
    _messageController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
