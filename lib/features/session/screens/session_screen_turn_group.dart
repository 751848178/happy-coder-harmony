part of 'session_screen.dart';

class _MessageTurnGroup {
  const _MessageTurnGroup({
    required this.id,
    required this.messages,
    required this.preview,
    required this.createdAt,
    this.userPrompt,
  });

  final String id;
  final List<ReducerMessage> messages;
  final String preview;
  final DateTime createdAt;
  final ReducerMessage? userPrompt;

  static bool startsNewTurn(ReducerMessage message) {
    return message.isText && sessionMessageIsUserAuthored(message);
  }

  factory _MessageTurnGroup.single(ReducerMessage message) {
    final prompt = startsNewTurn(message) ? message : null;
    return _MessageTurnGroup(
      id: prompt?.id ?? message.id,
      messages: <ReducerMessage>[message],
      preview: _previewFor(prompt, fallback: message),
      createdAt: message.createdAt,
      userPrompt: prompt,
    );
  }

  _MessageTurnGroup append(ReducerMessage message) {
    return _MessageTurnGroup(
      id: id,
      messages: List<ReducerMessage>.from(messages)..add(message),
      preview: preview,
      createdAt: createdAt,
      userPrompt: userPrompt,
    );
  }

  static List<_MessageTurnGroup> build(List<ReducerMessage> messages) {
    if (messages.isEmpty) {
      return const [];
    }

    final groups = <_MessageTurnGroup>[];
    final currentMessages = <ReducerMessage>[];
    ReducerMessage? currentPrompt;

    void flushCurrent() {
      if (currentMessages.isEmpty) {
        return;
      }
      groups.add(
        _MessageTurnGroup(
          id: currentPrompt?.id ?? currentMessages.first.id,
          messages: List<ReducerMessage>.from(currentMessages),
          preview: _previewFor(
            currentPrompt,
            fallback: currentMessages.first,
          ),
          createdAt: currentMessages.first.createdAt,
          userPrompt: currentPrompt,
        ),
      );
      currentMessages.clear();
      currentPrompt = null;
    }

    for (final message in messages) {
      final isUserText = startsNewTurn(message);
      if (isUserText) {
        flushCurrent();
        currentPrompt = message;
      }
      currentMessages.add(message);
    }
    flushCurrent();

    return groups;
  }

  static String _previewFor(
    ReducerMessage? prompt, {
    required ReducerMessage fallback,
  }) {
    final source = (prompt?.text ?? fallback.text ?? fallback.kind).trim();
    if (source.isEmpty) {
      return '空消息';
    }
    final normalized = source.replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 56) {
      return normalized;
    }
    return '${normalized.substring(0, 56)}...';
  }
}
