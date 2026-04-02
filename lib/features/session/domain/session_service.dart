import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/session_composer_queue_service.dart';
import '../data/session_data_key_store.dart';
import '../data/session_preferences_service.dart';
import '../data/session_repository.dart';
import '../data/session_ui_state_service.dart';
import '../../auth/data/token_storage_service.dart';
import '../../encryption/domain/crypto_service.dart';
import '../../socketio/data/socket_repository.dart';
import '../../storage/domain/storage_models.dart' as storage_models;
import '../../storage/domain/storage_service.dart';
import '../../../app/providers/app_providers.dart';
import '../../../app/services/api_service.dart';
import '../../../shared/utils/extensions.dart';
import 'reducer.dart' as domain;
import 'session_creation_options.dart';
import 'session_local_snapshot.dart';
import 'session_recency.dart';
import 'session_rpc_models.dart';

part 'session_service_agent_message_reducer.dart';
part 'session_service_loading_models.dart';
part 'session_service_acp_message_reducer.dart';
part 'session_service_agent_content_reducer.dart';
part 'session_service_machines.dart';
part 'session_service_message_parser.dart';
part 'session_service_message_reducer_helpers.dart';
part 'session_service_message_send.dart';
part 'session_service_messages.dart';
part 'session_service_metadata.dart';
part 'session_service_metadata_sync.dart';
part 'session_service_event_message_reducer.dart';
part 'session_service_output_message_reducer.dart';
part 'session_service_payload_helpers.dart';
part 'session_service_rpc.dart';
part 'session_service_session_bootstrap.dart';
part 'session_service_session_creation.dart';
part 'session_service_session_message_reducer.dart';
part 'session_service_session_parsing.dart';
part 'session_service_session_updates.dart';
part 'session_service_sidechain_reducer.dart';
part 'session_service_sessions.dart';
part 'session_service_state.dart';

class _CachedSessionRestoreResult {
  const _CachedSessionRestoreResult({
    this.sessions = const <Session>[],
    this.sessionMessagesById = const <String, SessionMessages>{},
    this.lastSeqBySessionId = const <String, int>{},
  });

  final List<Session> sessions;
  final Map<String, SessionMessages> sessionMessagesById;
  final Map<String, int> lastSeqBySessionId;

  bool get isEmpty => sessions.isEmpty;
}

class SessionServiceNotifier extends StateNotifier<SessionServiceState> {
  static const Object _sessionOverrideSentinel = Object();
  static const String _localSessionSnapshotKey = '__happyLocalSessionState';

  SessionServiceNotifier(this._repository)
      : super(SessionServiceState.initial) {
    _subscribeToChanges();
  }

  final SessionRepository _repository;
  final SessionPreferencesService _preferencesService =
      SessionPreferencesService.instance;
  final SessionComposerQueueService _composerQueueService =
      SessionComposerQueueService.instance;
  final SessionUiStateService _uiStateService = SessionUiStateService.instance;
  final TokenStorageService _tokenStorage = TokenStorageService.instance;
  final Map<String, Uint8List?> _sessionDataKeys = {};
  final Map<String, Uint8List?> _machineDataKeys = {};
  final Map<String, int> _sessionLastSeq = {};
  final Set<String> _lastRemoteSessionIds = <String>{};

  StreamSubscription<SessionStateChange>? _stateSubscription;
  Timer? _cachePersistDebounce;
  String? _accountSecret;
  String? _sessionMessagesApiPrefix;
  Future<void>? _loadSessionsInFlight;
  Future<void>? _loadMachinesInFlight;
  DateTime? _lastSessionsLoadedAt;
  DateTime? _lastMachinesLoadedAt;
  bool _emitScheduled = false;

  void _subscribeToChanges() {
    _stateSubscription = _repository.stateChanges.listen(_handleStateChange);
  }

  void _emitReadyState() {
    state = SessionServiceState.ready(
      sessions: _repository.sessionsMap,
      sessionMessages: _repository.sessionMessagesMap,
      machines: _repository.machinesMap,
    );
  }

  /// Schedule a coalesced _emitReadyState via microtask.
  /// Multiple rapid mutations (e.g. session restore fires applySessions +
  /// replaceMessages × N) will result in a single _emitReadyState call
  /// at the end of the current microtask queue, avoiding N+1 redundant
  /// state emissions and rebuilds.
  void _scheduleEmitReadyState() {
    if (_emitScheduled) return;
    _emitScheduled = true;
    scheduleMicrotask(() {
      _emitScheduled = false;
      _emitReadyState();
    });
  }

  void _emitLoadingState() {
    state = const _SessionServiceLoadingState();
  }

  void _emitErrorState(String message) {
    state = SessionServiceState.error(message);
  }

  void _handleStateChange(SessionStateChange change) {
    switch (change.type) {
      case SessionChangeType.sessionsUpdated:
      case SessionChangeType.permissionModeUpdated:
      case SessionChangeType.modelModeUpdated:
      case SessionChangeType.draftUpdated:
      case SessionChangeType.sessionDeleted:
        _scheduleEmitReadyState();
        _schedulePersistCachedSessions();
        break;
      case SessionChangeType.messagesUpdated:
        _scheduleEmitReadyState();
        _schedulePersistCachedSessions();
        break;
      case SessionChangeType.agentStateUpdated:
      case SessionChangeType.machinesUpdated:
      case SessionChangeType.toolCallApproved:
      case SessionChangeType.toolCallRejected:
        _scheduleEmitReadyState();
        break;
      case SessionChangeType.cleared:
        _cachePersistDebounce?.cancel();
        SessionDataKeyStore.instance.clear();
        state = SessionServiceState.initial;
        break;
    }
  }

  void _schedulePersistCachedSessions() {
    _cachePersistDebounce?.cancel();
    _cachePersistDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_persistCachedSessions(
        _repository.getAllSessions(),
        sessionMessagesById: _repository.sessionMessagesMap,
      ));
    });
  }

  Future<_CachedSessionRestoreResult> _restoreCachedSessions() async {
    try {
      final cachedSessions = await StorageService.instance.getAllSessions();
      final restoredSessions = <Session>[];
      final restoredSessionMessages = <String, SessionMessages>{};
      final restoredLastSeqs = <String, int>{};

      for (final cached in cachedSessions) {
        final localState =
            _extractLocalSessionStateFromMetadata(cached.metadata);
        final session = _sessionFromCache(cached, localState: localState);
        restoredSessions.add(session);

        final restoredMessages = restoreMessagesFromLocalSnapshot(localState);
        if (localSnapshotHasLoadedMessages(localState)) {
          final messages = restoredMessages ?? const <ReducerMessage>[];
          restoredSessionMessages[session.id] = SessionMessages(
            messages: messages,
            messagesMap: {
              for (final message in messages) message.id: message,
            },
            reducerState: domain.ReducerState.initial,
            isLoaded: true,
          );
        }

        final lastSeq = restoreSessionLastSeqFromLocalSnapshot(localState);
        if (lastSeq != null && lastSeq > 0) {
          restoredLastSeqs[session.id] = lastSeq;
        }
      }

      restoredSessions.sort(compareSessionsByRecency);
      return _CachedSessionRestoreResult(
        sessions: restoredSessions,
        sessionMessagesById: restoredSessionMessages,
        lastSeqBySessionId: restoredLastSeqs,
      );
    } catch (error) {
      Logger.warning('Failed to restore cached sessions: $error');
      return const _CachedSessionRestoreResult();
    }
  }

  Session _sessionFromCache(
    storage_models.SessionStorageModel cached, {
    Map<String, dynamic>? localState,
  }) {
    final metadata = cached.metadata == null
        ? null
        : Map<String, dynamic>.from(cached.metadata!);
    metadata?.remove(_localSessionSnapshotKey);
    return Session(
      id: cached.id,
      title: cached.title,
      messages: const [],
      createdAt: cached.createdAt,
      updatedAt: cached.updatedAt,
      active: localState?['active'] as bool? ?? !cached.isArchived,
      tag: cached.tag,
      path: metadata?['path']?.toString(),
      metadata: metadata,
      latestUsage: restoreLatestUsageFromLocalSnapshot(
        localState,
        fallbackTimestamp: cached.updatedAt,
      ),
      permissionMode: resolveSessionPermissionMode(
        metadata: metadata,
        persistedValue: localState?['permissionMode']?.toString(),
        metadataValue: metadata?['currentOperatingModeCode']?.toString(),
      ),
      modelMode: resolveSessionModelMode(
        metadata: metadata,
        persistedValue: localState?['modelMode']?.toString(),
        metadataValue: metadata?['currentModelCode']?.toString(),
        fallbackAgent: metadata?['flavor']?.toString(),
      ),
      draft: _normalizeOptionalValue(localState?['draft']?.toString()),
    );
  }

  Map<String, dynamic>? _extractLocalSessionStateFromMetadata(
    Map<String, dynamic>? metadata,
  ) {
    if (metadata == null) {
      return null;
    }
    return _asStringMap(metadata[_localSessionSnapshotKey]);
  }

  Future<void> _persistCachedSessions(
    List<Session> sessions, {
    Map<String, SessionMessages> sessionMessagesById = const {},
  }) async {
    try {
      final localStateBySessionId = <String, Map<String, dynamic>>{};
      for (final session in sessions) {
        final cachedMessages = sessionMessagesById[session.id];
        final isLoaded = cachedMessages?.isLoaded == true;
        localStateBySessionId[session.id] = buildLocalSessionSnapshot(
          session: session,
          loadedMessageCount: isLoaded ? cachedMessages!.messages.length : null,
          loadedMessages: isLoaded ? cachedMessages!.messages : null,
          messagesLoaded: isLoaded,
          lastSeq: _sessionLastSeq[session.id],
        );
      }
      await StorageService.instance.cacheRemoteSessions(
        sessions,
        localStateBySessionId: localStateBySessionId,
      );
    } catch (error) {
      Logger.warning('Failed to persist cached sessions: $error');
    }
  }

  Future<void> _persistSessionCacheImmediately(String sessionId) async {
    final session = _repository.getSession(sessionId);
    if (session == null) {
      await StorageService.instance.deleteSession(sessionId);
      return;
    }
    final sessionMessages = _repository.getSessionMessages(sessionId);
    await _persistCachedSessions(
      [session],
      sessionMessagesById: sessionMessages == null
          ? const <String, SessionMessages>{}
          : <String, SessionMessages>{sessionId: sessionMessages},
    );
  }

  List<Session> get sessions => _repository.getAllSessions();

  List<Session> get activeSessions => _repository.getActiveSessions();

  List<Machine> get machines => _repository.getAllMachines();

  Session? getSession(String sessionId) => _repository.getSession(sessionId);

  SessionMessages? getSessionMessages(String sessionId) =>
      _repository.getSessionMessages(sessionId);

  bool hasRemoteSession(String sessionId) =>
      _lastRemoteSessionIds.contains(sessionId);

  DateTime? get lastSessionsLoadedAt => _lastSessionsLoadedAt;

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _cachePersistDebounce?.cancel();
    super.dispose();
  }
}
