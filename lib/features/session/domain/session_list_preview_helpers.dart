import 'reducer.dart';
import 'session_models.dart';
import 'session_list_preview.dart';

String? resolveLatestMessagePreview(List<ReducerMessage>? messages) {
  if (messages == null || messages.isEmpty) {
    return null;
  }

  String? fallbackText;
  for (final message in messages.reversed) {
    if (!message.isText && !message.isError) {
      continue;
    }
    final normalized = normalizeSessionPreviewText(message.text);
    if (normalized == null) {
      continue;
    }
    final preview = truncateSessionPreview(normalized);
    final role = message.metadata?['role']?.toString();
    if (role == 'user') {
      return preview;
    }
    fallbackText ??= preview;
  }
  return fallbackText;
}

DateTime? resolveLatestMessageAt(List<ReducerMessage>? messages) {
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

SessionListStatusSnapshot buildSessionStatusSnapshot(
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

SessionListStatusKind? resolveLatestSessionStatusKind(
  List<ReducerMessage>? messages,
) {
  if (messages == null || messages.isEmpty) {
    return null;
  }

  for (final message in messages.reversed) {
    if (isUserTextMessage(message)) {
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

bool isUserTextMessage(ReducerMessage message) {
  if (!message.isText) {
    return false;
  }
  final role = message.metadata?['role']?.toString();
  final sourceRole = message.metadata?['sourceRole']?.toString();
  return role == 'user' || sourceRole == 'user';
}

String? resolveSessionSummaryText(Session session) {
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

String? resolveSessionPathTitle(Session session) {
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

String? normalizeSessionPreviewText(String? text) {
  if (text == null) {
    return null;
  }
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return normalized.isEmpty ? null : normalized;
}

String truncateSessionPreview(String text, {int maxLength = 72}) {
  if (text.length <= maxLength) {
    return text;
  }
  return '${text.substring(0, maxLength)}...';
}

String? firstNonBlank(Iterable<String?> values) {
  for (final value in values) {
    final normalized = normalizeSessionPreviewText(value);
    if (normalized != null) {
      return normalized;
    }
  }
  return null;
}

String? normalizeSessionAgent(String? agent) {
  final normalized = normalizeSessionPreviewText(agent)?.toLowerCase();
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
