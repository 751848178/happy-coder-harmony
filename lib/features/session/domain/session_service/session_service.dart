import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/session_composer_queue_service.dart';
import '../../data/session_data_key_store.dart';
import '../../data/session_preferences_service.dart';
import '../../data/session_repository.dart';
import '../../data/session_ui_state_service.dart';
import '../../../auth/data/token_storage_service.dart';
import '../../../encryption/domain/crypto_service.dart';
import '../../../socketio/data/socket_repository.dart';
import '../../../storage/domain/storage_models.dart' as storage_models;
import '../../../storage/domain/storage_service.dart';
import '../../../../app/providers/app_providers.dart';
import '../../../../app/services/api_service.dart';
import '../../../../core/network/http_proxy_models.dart';
import '../../../../shared/utils/extensions.dart';
import '../session_creation_options.dart';
import '../session_local_snapshot.dart';
import '../session_recency.dart';
import '../session_rpc_models.dart';

part 'agent_message_reducer.dart';
part 'loading_models.dart';
part 'acp_message_reducer.dart';
part 'agent_content_reducer.dart';
part 'machines.dart';
part 'message_parser.dart';
part 'message_reducer_helpers.dart';
part 'message_archive_coordinator.dart';
part 'message_archive_helpers.dart';
part 'message_archive_queries.dart';
part 'message_archive_range.dart';
part 'message_archive_remote_sync.dart';
part 'message_archive_window_load.dart';
part 'message_archive_window_shift.dart';
part 'message_send.dart';
part 'messages.dart';
part 'metadata.dart';
part 'metadata_sync.dart';
part 'event_message_reducer.dart';
part 'output_message_reducer.dart';
part 'payload_helpers.dart';
part 'cache_coordinator.dart';
part 'catalog_coordinator.dart';
part 'message_coordinator.dart';
part 'rpc.dart';
part 'http_proxy.dart';
part 'bootstrap.dart';
part 'creation.dart';
part 'message_reducer.dart';
part 'parsing.dart';
part 'updates.dart';
part 'sidechain_reducer.dart';
part 'sessions.dart';
part 'state.dart';

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
  static const int sessionDetailAutomaticMessageWindowSize = 30;
  static const int sessionDetailResidentMessageWindowSize = 288;
  static const int sessionDetailArchiveWindowShiftSize = 30;

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
  late final _SessionServiceCacheCoordinator _cacheCoordinator =
      _SessionServiceCacheCoordinator(this);
  late final _SessionServiceCatalogCoordinator _catalogCoordinator =
      _SessionServiceCatalogCoordinator(this);
  late final _SessionServiceMessageCoordinator _messageCoordinator =
      _SessionServiceMessageCoordinator(this);
  late final _SessionServiceMessageArchiveCoordinator
      _messageArchiveCoordinator =
      _SessionServiceMessageArchiveCoordinator(this);

  StreamSubscription<SessionStateChange>? _stateSubscription;
  Timer? _cachePersistDebounce;
  String? _accountSecret;
  String? _sessionMessagesApiPrefix;
  Future<void>? _loadSessionsInFlight;
  Future<void>? _loadMachinesInFlight;
  final Map<String, Future<void>> _archiveHydrationInFlight =
      <String, Future<void>>{};
  final Map<String, Future<void>> _loadMessagesInFlight =
      <String, Future<void>>{};
  DateTime? _lastSessionsLoadedAt;
  DateTime? _lastMachinesLoadedAt;
  bool _emitScheduled = false;

  void _subscribeToChanges() {
    _stateSubscription = _repository.stateChanges.listen(_handleStateChange);
  }

  /// Expose a filtered stream of message-update events for [sessionId].
  /// Per-session screens use this to reactively sync local message state
  /// without depending on the global sessionMessagesMap.
  Stream<void> messageChangesFor(String sessionId) {
    return _repository.stateChanges
        .where((c) =>
            c.type == SessionChangeType.messagesUpdated &&
            c.sessionId == sessionId)
        .map((_) {});
  }

  void _emitReadyState() {
    // Messages are managed per-session (not globally) — session detail
    // screens use local ValueNotifier + stateChanges subscription.
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
    return _cacheCoordinator.restoreCachedSessions();
  }

  Future<void> _persistCachedSessions(
    List<Session> sessions, {
    Map<String, SessionMessages> sessionMessagesById = const {},
  }) =>
      _cacheCoordinator.persistCachedSessions(
        sessions,
        sessionMessagesById: sessionMessagesById,
      );

  Future<void> _persistSessionCacheImmediately(String sessionId) =>
      _cacheCoordinator.persistSessionCacheImmediately(sessionId);

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
