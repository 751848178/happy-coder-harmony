part of 'sessions_screen.dart';

const ListEquality<_SessionsScreenLayoutSession>
    _sessionsScreenLayoutListEquality =
    ListEquality<_SessionsScreenLayoutSession>();

class _SessionsScreenViewData {
  const _SessionsScreenViewData({
    required this.body,
  });

  final Widget body;
}

class _SessionsScreenLayoutSelection {
  const _SessionsScreenLayoutSelection({
    required this.sessions,
  });

  const _SessionsScreenLayoutSelection.empty()
      : sessions = const <_SessionsScreenLayoutSession>[];

  final List<_SessionsScreenLayoutSession> sessions;

  factory _SessionsScreenLayoutSelection.fromSessions(
    Iterable<Session> sessions,
  ) {
    return _SessionsScreenLayoutSelection(
      sessions: List<_SessionsScreenLayoutSession>.unmodifiable(
        sessions.map(_SessionsScreenLayoutSession.fromSession),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _SessionsScreenLayoutSelection &&
        _sessionsScreenLayoutListEquality.equals(sessions, other.sessions);
  }

  @override
  int get hashCode => _sessionsScreenLayoutListEquality.hash(sessions);
}

class _SessionsScreenLayoutSession {
  const _SessionsScreenLayoutSession({
    required this.id,
    required this.seq,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.active,
    required this.thinking,
    required this.tag,
    required this.path,
    required this.machineId,
  });

  factory _SessionsScreenLayoutSession.fromSession(Session session) {
    return _SessionsScreenLayoutSession(
      id: session.id,
      seq: session.seq,
      title: session.title,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
      active: session.active,
      thinking: session.thinking,
      tag: session.tag,
      path: session.path,
      machineId: session.metadata?['machineId']?.toString().trim(),
    );
  }

  final String id;
  final int? seq;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool active;
  final bool? thinking;
  final String? tag;
  final String? path;
  final String? machineId;

  @override
  bool operator ==(Object other) {
    return other is _SessionsScreenLayoutSession &&
        id == other.id &&
        seq == other.seq &&
        title == other.title &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        active == other.active &&
        thinking == other.thinking &&
        tag == other.tag &&
        path == other.path &&
        machineId == other.machineId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        seq,
        title,
        createdAt,
        updatedAt,
        active,
        thinking,
        tag,
        path,
        machineId,
      );
}

class _SessionListItemSelection {
  const _SessionListItemSelection({
    required this.session,
    required this.messages,
    required this.hasLoadedMessages,
    required this.isReady,
  });

  final Session session;
  final List<ReducerMessage>? messages;
  final bool hasLoadedMessages;
  final bool isReady;

  @override
  bool operator ==(Object other) {
    return other is _SessionListItemSelection &&
        identical(session, other.session) &&
        identical(messages, other.messages) &&
        hasLoadedMessages == other.hasLoadedMessages &&
        isReady == other.isReady;
  }

  @override
  int get hashCode =>
      Object.hash(session, messages, hasLoadedMessages, isReady);
}

class _SessionListItemViewModel {
  const _SessionListItemViewModel({
    required this.session,
    required this.titleText,
    required this.activitySnapshot,
    required this.statusSnapshot,
  });

  final Session session;
  final String titleText;
  final SessionListActivitySnapshot activitySnapshot;
  final SessionListStatusSnapshot? statusSnapshot;
}

_SessionListItemViewModel _buildSessionListItemViewModel(
  _SessionListItemSelection selection,
) {
  final session = selection.session;
  final activitySnapshot = resolveSessionListActivitySnapshot(
    session: session,
    messages: selection.messages,
    hasLoadedMessages: selection.hasLoadedMessages,
  );
  final titleText = resolveSessionListTitle(session);
  final isThinking = selection.isReady
      ? sessionTurnIsThinkingStillBlocking(
          session: session,
          messages: selection.messages ?? const <ReducerMessage>[],
        )
      : session.thinking == true;
  final statusSnapshot = selection.hasLoadedMessages
      ? resolveSessionListStatusSnapshot(
          messages: selection.messages,
          isThinking: isThinking,
          isActive: session.active,
        )
      : resolveSessionListStatusSnapshotFromPreview(session);
  return _SessionListItemViewModel(
    session: session,
    titleText: titleText,
    activitySnapshot: activitySnapshot,
    statusSnapshot: statusSnapshot,
  );
}
