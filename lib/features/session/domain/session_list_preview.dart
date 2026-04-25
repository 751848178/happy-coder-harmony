import 'package:collection/collection.dart';

import 'reducer.dart';
import 'session_models.dart';
import 'session_list_preview_helpers.dart';

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
  final explicitTitle = firstNonBlank([
    session.metadata?['name']?.toString(),
    session.metadata?['title']?.toString(),
  ]);
  if (explicitTitle != null) {
    return explicitTitle;
  }

  final derivedPathTitle = resolveSessionPathTitle(session);
  final currentTitle = normalizeSessionPreviewText(session.title);
  final summary = resolveSessionSummaryText(session);

  if (derivedPathTitle != null) {
    return derivedPathTitle;
  }
  if (currentTitle != null) {
    return currentTitle;
  }
  if (summary != null) {
    return truncateSessionPreview(summary, maxLength: 36);
  }
  return '未命名会话';
}

SessionListActivitySnapshot resolveSessionListActivitySnapshot({
  required Session session,
  List<ReducerMessage>? messages,
  bool hasLoadedMessages = false,
}) {
  if (!hasLoadedMessages) {
    if (session.previewText != null || session.lastMessageAt != null) {
      return resolveSessionListActivitySnapshotFromPreview(session);
    }
    return const SessionListActivitySnapshot(
      previewText: '最近消息待同步',
      phase: SessionListActivityPhase.syncing,
    );
  }

  final latestMessageAt = resolveLatestMessageAt(messages);
  final latestPreview = resolveLatestMessagePreview(messages);
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
  final resolvedKind = resolveLatestSessionStatusKind(messages);
  if (resolvedKind != null) {
    return buildSessionStatusSnapshot(resolvedKind);
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
  final explicit = normalizeSessionAgent(
    session.metadata?['flavor']?.toString() ??
        session.agentState?['flavor']?.toString(),
  );
  if (explicit != null) {
    return explicit;
  }

  final modelHint = normalizeSessionPreviewText(
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

/// Resolve activity snapshot directly from Session's pre-computed preview fields.
/// Used by session list items to avoid loading all messages.
SessionListActivitySnapshot resolveSessionListActivitySnapshotFromPreview(
  Session session,
) {
  final previewText = session.previewText;
  final lastMessageAt = session.lastMessageAt;

  if (previewText != null || lastMessageAt != null) {
    return SessionListActivitySnapshot(
      previewText: previewText ?? '最近消息暂不支持预览',
      phase: SessionListActivityPhase.ready,
      lastMessageAt: lastMessageAt,
    );
  }

  if ((session.latestUsage?.messageCount ?? 0) > 0) {
    return const SessionListActivitySnapshot(
      previewText: '最近消息待同步',
      phase: SessionListActivityPhase.syncing,
    );
  }

  return const SessionListActivitySnapshot(
    previewText: '等待第一条消息',
    phase: SessionListActivityPhase.empty,
  );
}

/// Resolve status snapshot directly from Session's pre-computed preview fields.
/// Used by session list items to avoid loading all messages.
SessionListStatusSnapshot? resolveSessionListStatusSnapshotFromPreview(
  Session session,
) {
  if (session.listStatusKind != null) {
    final kind = SessionListStatusKind.values
        .firstWhereOrNull((k) => k.name == session.listStatusKind);
    if (kind != null) {
      return buildSessionStatusSnapshot(kind);
    }
  }
  if (session.thinking == true) {
    return const SessionListStatusSnapshot(
      kind: SessionListStatusKind.thinking,
      label: '思考中',
    );
  }
  if (!session.active) {
    return const SessionListStatusSnapshot(
      kind: SessionListStatusKind.inactive,
      label: '已关闭',
    );
  }
  return null;
}
