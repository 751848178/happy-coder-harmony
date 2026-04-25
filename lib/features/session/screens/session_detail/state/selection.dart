part of '../session_detail.dart';

class _SessionScreenSelection {
  const _SessionScreenSelection({
    required this.session,
    required this.hasLoadedSessions,
    required this.isReady,
  });

  const _SessionScreenSelection.initial()
      : this(
          session: null,
          hasLoadedSessions: false,
          isReady: false,
        );

  final Session? session;
  final bool hasLoadedSessions;
  final bool isReady;

  /// Compare sessions by fields the detail page actually uses.
  /// Excludes preview-only fields (previewText, lastMessageAt,
  /// listStatusKind, latestUsage) which change on every message
  /// update but are only consumed by the session list page.
  /// Without this, every streaming chunk triggers a full rebuild.
  static bool _sessionStableEqual(Session? a, Session? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.id == b.id &&
        a.title == b.title &&
        a.active == b.active &&
        a.thinking == b.thinking &&
        a.thinkingAt == b.thinkingAt &&
        a.draft == b.draft &&
        a.permissionMode == b.permissionMode &&
        a.modelMode == b.modelMode &&
        a.path == b.path &&
        a.presence == b.presence &&
        identical(a.metadata, b.metadata);
  }

  @override
  bool operator ==(Object other) {
    return other is _SessionScreenSelection &&
        _sessionStableEqual(session, other.session) &&
        hasLoadedSessions == other.hasLoadedSessions &&
        isReady == other.isReady;
  }

  @override
  int get hashCode => Object.hash(
        session?.id,
        session?.title,
        session?.active,
        session?.thinking,
        hasLoadedSessions,
        isReady,
      );
}
