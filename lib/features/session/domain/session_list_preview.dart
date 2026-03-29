import 'reducer.dart';
import 'session_models.dart';

enum SessionListActivityPhase {
  syncing,
  ready,
  empty,
}

enum SessionListStatusKind {
  running,
  thinking,
  waitingPermission,
  failed,
  interrupted,
  completed,
  inactive,
}

class SessionListActivitySnapshot {
  const SessionListActivitySnapshot({
    required this.previewText,
    required this.phase,
    this.lastMessageAt,
  });

  final String previewText;
  final SessionListActivityPhase phase;
  final DateTime? lastMessageAt;

  bool get isSyncing => phase == SessionListActivityPhase.syncing;
}

class SessionListStatusSnapshot {
  const SessionListStatusSnapshot({
    required this.kind,
    required this.label,
  });

  final SessionListStatusKind kind;
  final String label;

  bool get isThinking => kind == SessionListStatusKind.thinking;
}

String resolveSessionListTitle(Session session) {
  final explicitTitle = _firstNonBlank([
    session.metadata?['name']?.toString(),
    session.metadata?['title']?.toString(),
  ]);
  if (explicitTitle != null) {
    return explicitTitle;
  }

  final derivedPathTitle = _resolveSessionPathTitle(session);
  final currentTitle = _normalizeSessionPreviewText(session.title);
  final summary = _resolveSessionSummaryText(session);

  if (derivedPathTitle != null) {
    return derivedPathTitle;
  }
  if (currentTitle != null) {
    return currentTitle;
  }
  if (summary != null) {
    return _truncateSessionPreview(summary, maxLength: 36);
  }
  return '未命名会话';
}

SessionListActivitySnapshot resolveSessionListActivitySnapshot({
  required Session session,
  List<ReducerMessage>? messages,
  bool hasLoadedMessages = false,
}) {
  if (!hasLoadedMessages) {
    return const SessionListActivitySnapshot(
      previewText: '最近消息待同步',
      phase: SessionListActivityPhase.syncing,
    );
  }

  final latestMessageAt = _resolveLatestMessageAt(messages);
  final latestPreview = _resolveLatestMessagePreview(messages);
  if (latestPreview != null || latestMessageAt != null) {
    return SessionListActivitySnapshot(
      previewText: latestPreview ?? '最近消息暂不支持预览',
      phase: SessionListActivityPhase.ready,
      lastMessageAt: latestMessageAt,
    );
  }

  return const SessionListActivitySnapshot(
    previewText: '等待第一条消息',
    phase: SessionListActivityPhase.empty,
  );
}

String resolveSessionListPreview({
  required Session session,
  List<ReducerMessage>? messages,
  bool hasLoadedMessages = false,
}) {
  return resolveSessionListActivitySnapshot(
    session: session,
    messages: messages,
    hasLoadedMessages: hasLoadedMessages,
  ).previewText;
}

DateTime? resolveSessionListLastActivityAt({
  required Session session,
  List<ReducerMessage>? messages,
  bool hasLoadedMessages = false,
}) {
  return resolveSessionListActivitySnapshot(
    session: session,
    messages: messages,
    hasLoadedMessages: hasLoadedMessages,
  ).lastMessageAt;
}

SessionListStatusSnapshot? resolveSessionListStatusSnapshot({
  List<ReducerMessage>? messages,
  required bool isThinking,
  required bool isActive,
}) {
  final resolvedKind = _resolveLatestSessionStatusKind(messages);
  if (resolvedKind != null) {
    return _buildSessionStatusSnapshot(resolvedKind);
  }
  if (isThinking) {
    return const SessionListStatusSnapshot(
      kind: SessionListStatusKind.thinking,
      label: '思考中',
    );
  }
  if (!isActive) {
    return const SessionListStatusSnapshot(
      kind: SessionListStatusKind.inactive,
      label: '已关闭',
    );
  }
  return null;
}

String resolveSessionListAgent(Session session) {
  final explicit = _normalizeSessionAgent(
    session.metadata?['flavor']?.toString() ??
        session.agentState?['flavor']?.toString(),
  );
  if (explicit != null) {
    return explicit;
  }

  final modelHint = _normalizeSessionPreviewText(
    session.modelMode ??
        session.metadata?['currentModelCode']?.toString() ??
        session.metadata?['model']?.toString(),
  )?.toLowerCase();
  if (modelHint != null) {
    if (modelHint.contains('gpt') || modelHint.contains('codex')) {
      return 'codex';
    }
    if (modelHint.contains('gemini')) {
      return 'gemini';
    }
  }
  return 'claude';
}

String? _resolveLatestMessagePreview(List<ReducerMessage>? messages) {
  if (messages == null || messages.isEmpty) {
    return null;
  }

  String? fallbackText;
  for (final message in messages.reversed) {
    if (!message.isText && !message.isError) {
      continue;
    }
    final normalized = _normalizeSessionPreviewText(message.text);
    if (normalized == null) {
      continue;
    }
    final preview = _truncateSessionPreview(normalized);
    final role = message.metadata?['role']?.toString();
    if (role == 'user') {
      return preview;
    }
    fallbackText ??= preview;
  }
  return fallbackText;
}

DateTime? _resolveLatestMessageAt(List<ReducerMessage>? messages) {
  if (messages == null || messages.isEmpty) {
    return null;
  }

  var latest = messages.first.createdAt;
  for (final message in messages.skip(1)) {
    if (message.createdAt.isAfter(latest)) {
      latest = message.createdAt;
    }
  }
  return latest;
}

SessionListStatusSnapshot _buildSessionStatusSnapshot(
  SessionListStatusKind kind,
) {
  switch (kind) {
    case SessionListStatusKind.waitingPermission:
      return const SessionListStatusSnapshot(
        kind: SessionListStatusKind.waitingPermission,
        label: '等待权限',
      );
    case SessionListStatusKind.running:
      return const SessionListStatusSnapshot(
        kind: SessionListStatusKind.running,
        label: '执行中',
      );
    case SessionListStatusKind.thinking:
      return const SessionListStatusSnapshot(
        kind: SessionListStatusKind.thinking,
        label: '思考中',
      );
    case SessionListStatusKind.failed:
      return const SessionListStatusSnapshot(
        kind: SessionListStatusKind.failed,
        label: '失败',
      );
    case SessionListStatusKind.interrupted:
      return const SessionListStatusSnapshot(
        kind: SessionListStatusKind.interrupted,
        label: '已中止',
      );
    case SessionListStatusKind.completed:
      return const SessionListStatusSnapshot(
        kind: SessionListStatusKind.completed,
        label: '已完成',
      );
    case SessionListStatusKind.inactive:
      return const SessionListStatusSnapshot(
        kind: SessionListStatusKind.inactive,
        label: '已关闭',
      );
  }
}

SessionListStatusKind? _resolveLatestSessionStatusKind(
  List<ReducerMessage>? messages,
) {
  if (messages == null || messages.isEmpty) {
    return null;
  }

  for (final message in messages.reversed) {
    if (_isUserTextMessage(message)) {
      return null;
    }
    if (message.isPermissionRequest) {
      return SessionListStatusKind.waitingPermission;
    }

    final status = message.tool?.status;
    if (status == ToolCallStatus.pending) {
      return SessionListStatusKind.waitingPermission;
    }
    if (status == ToolCallStatus.approved ||
        status == ToolCallStatus.executing) {
      return SessionListStatusKind.running;
    }
    if (status == ToolCallStatus.failed || status == ToolCallStatus.rejected) {
      return SessionListStatusKind.failed;
    }
    if (status == ToolCallStatus.completed) {
      return SessionListStatusKind.completed;
    }

    if (message.isError) {
      return SessionListStatusKind.failed;
    }
    if (message.isTurnClose) {
      final reason = message.turnClose?.reason?.toLowerCase();
      if (message.turnClose?.abandoned == true ||
          reason == 'cancelled' ||
          reason == 'canceled' ||
          reason == 'aborted' ||
          reason == 'turn_aborted') {
        return SessionListStatusKind.interrupted;
      }
      if (reason == 'failed' || reason == 'error') {
        return SessionListStatusKind.failed;
      }
      return SessionListStatusKind.completed;
    }
    if (message.isAgentEvent) {
      final eventType =
          message.metadata?['eventType']?.toString().toLowerCase();
      if (eventType == 'turn_aborted') {
        return SessionListStatusKind.interrupted;
      }
      if (eventType == 'task_failed' || eventType == 'error') {
        return SessionListStatusKind.failed;
      }
      if (eventType == 'task_complete' ||
          eventType == 'ready' ||
          eventType == 'stop') {
        return SessionListStatusKind.completed;
      }
    }
  }
  return null;
}

bool _isUserTextMessage(ReducerMessage message) {
  if (!message.isText) {
    return false;
  }
  final role = message.metadata?['role']?.toString();
  final sourceRole = message.metadata?['sourceRole']?.toString();
  return role == 'user' || sourceRole == 'user';
}

String? _resolveSessionSummaryText(Session session) {
  final metadataSummary = session.metadata?['summary'];
  if (metadataSummary is Map) {
    final text = metadataSummary['text']?.toString();
    if (text != null && text.trim().isNotEmpty) {
      return text;
    }
  }

  final agentStateSummary = session.agentState?['summary'];
  if (agentStateSummary is Map) {
    final text = agentStateSummary['text']?.toString();
    if (text != null && text.trim().isNotEmpty) {
      return text;
    }
  }

  return null;
}

String? _resolveSessionPathTitle(Session session) {
  final rawPath =
      session.path?.trim() ?? session.metadata?['path']?.toString().trim();
  if (rawPath == null || rawPath.isEmpty) {
    return null;
  }

  final normalized = rawPath.replaceAll('\\', '/');
  final parts = normalized.split('/').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return null;
  }
  return parts.last;
}

String? _normalizeSessionPreviewText(String? text) {
  if (text == null) {
    return null;
  }
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return normalized.isEmpty ? null : normalized;
}

String _truncateSessionPreview(String text, {int maxLength = 72}) {
  if (text.length <= maxLength) {
    return text;
  }
  return '${text.substring(0, maxLength)}...';
}

String? _firstNonBlank(Iterable<String?> values) {
  for (final value in values) {
    final normalized = _normalizeSessionPreviewText(value);
    if (normalized != null) {
      return normalized;
    }
  }
  return null;
}

String? _normalizeSessionAgent(String? agent) {
  final normalized = _normalizeSessionPreviewText(agent)?.toLowerCase();
  switch (normalized) {
    case 'codex':
      return 'codex';
    case 'gemini':
      return 'gemini';
    case 'claude':
    case 'claude code':
      return 'claude';
    default:
      return null;
  }
}
