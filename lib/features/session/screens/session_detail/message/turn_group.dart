part of '../session_detail.dart';

class _CollapsedTurnSummary {
  const _CollapsedTurnSummary({
    required this.id,
    required this.promptMessageId,
    required this.preview,
    required this.createdAt,
    this.promptArchiveIndex,
  });

  final String id;
  final String promptMessageId;
  final String preview;
  final DateTime createdAt;
  final int? promptArchiveIndex;

  factory _CollapsedTurnSummary.fromTurnGroup(_MessageTurnGroup group) {
    final prompt = group.userPrompt ?? group.messages.first;
    final metadata = prompt.metadata;
    final rawArchiveIndex = metadata?['archiveIndex'];
    final promptArchiveIndex = rawArchiveIndex is int
        ? rawArchiveIndex
        : rawArchiveIndex is String
            ? int.tryParse(rawArchiveIndex)
            : rawArchiveIndex is double
                ? rawArchiveIndex.toInt()
                : null;
    return _CollapsedTurnSummary(
      id: group.id,
      promptMessageId: prompt.id,
      preview: group.preview,
      createdAt: group.createdAt,
      promptArchiveIndex: promptArchiveIndex,
    );
  }

  factory _CollapsedTurnSummary.fromArchivedSummary(
    storage_models.SessionArchivedTurnSummary summary,
  ) {
    return _CollapsedTurnSummary(
      id: summary.id,
      promptMessageId: summary.promptMessageId,
      preview: summary.preview,
      createdAt: summary.createdAt,
      promptArchiveIndex: summary.archiveIndex,
    );
  }
}

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
    var groupStart = 0;
    ReducerMessage? currentPrompt;

    void flushCurrent(int end) {
      if (groupStart >= end) {
        return;
      }
      final groupMessages =
          List<ReducerMessage>.unmodifiable(messages.sublist(groupStart, end));
      final first = messages[groupStart];
      groups.add(
        _MessageTurnGroup(
          id: currentPrompt?.id ?? first.id,
          messages: groupMessages,
          preview: _previewFor(
            currentPrompt,
            fallback: first,
          ),
          createdAt: first.createdAt,
          userPrompt: currentPrompt,
        ),
      );
      groupStart = end;
      currentPrompt = null;
    }

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final isUserText = startsNewTurn(message);
      if (isUserText) {
        flushCurrent(i);
        currentPrompt = message;
      }
    }
    flushCurrent(messages.length);

    return groups;
  }

  static final RegExp _whitespacePattern = RegExp(r'\s+');

  static String _previewFor(
    ReducerMessage? prompt, {
    required ReducerMessage fallback,
  }) {
    final source = (prompt?.text ?? fallback.text ?? fallback.kind).trim();
    if (source.isEmpty) {
      return '空消息';
    }
    final normalized = source.replaceAll(_whitespacePattern, ' ');
    if (normalized.length <= 56) {
      return normalized;
    }
    return '${normalized.substring(0, 56)}...';
  }
}
