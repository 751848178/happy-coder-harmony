import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/session_composer_queue_service.dart';
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
import 'session_creation_options.dart';
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
part 'session_service_output_message_reducer.dart';
part 'session_service_payload_helpers.dart';
part 'session_service_rpc.dart';
part 'session_service_session_bootstrap.dart';
part 'session_service_session_creation.dart';
part 'session_service_session_message_reducer.dart';
part 'session_service_session_parsing.dart';
part 'session_service_session_updates.dart';
part 'session_service_sessions.dart';
part 'session_service_state.dart';

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
        _emitReadyState();
        _schedulePersistCachedSessions();
        break;
      case SessionChangeType.messagesUpdated:
      case SessionChangeType.agentStateUpdated:
      case SessionChangeType.machinesUpdated:
      case SessionChangeType.toolCallApproved:
      case SessionChangeType.toolCallRejected:
        _emitReadyState();
        break;
      case SessionChangeType.cleared:
        _cachePersistDebounce?.cancel();
        state = SessionServiceState.initial;
        break;
    }
  }

  void _schedulePersistCachedSessions() {
    _cachePersistDebounce?.cancel();
    _cachePersistDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_persistCachedSessions(_repository.getAllSessions()));
    });
  }

  Future<List<Session>> _restoreCachedSessions() async {
    try {
      final cachedSessions = await StorageService.instance.getAllSessions();
      return cachedSessions.map(_sessionFromCache).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (error) {
      Logger.warning('Failed to restore cached sessions: $error');
      return const <Session>[];
    }
  }

  Session _sessionFromCache(storage_models.SessionStorageModel cached) {
    final metadata = cached.metadata == null
        ? null
        : Map<String, dynamic>.from(cached.metadata!);
    final localState = metadata == null
        ? null
        : _asStringMap(metadata.remove(_localSessionSnapshotKey));
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
      permissionMode:
          _normalizeOptionalValue(localState?['permissionMode']?.toString()),
      modelMode: _normalizeOptionalValue(localState?['modelMode']?.toString()),
    );
  }

  Future<void> _persistCachedSessions(List<Session> sessions) async {
    try {
      await StorageService.instance.cacheRemoteSessions(sessions);
    } catch (error) {
      Logger.warning('Failed to persist cached sessions: $error');
    }
  }

  List<Session> get sessions => _repository.getAllSessions();

  List<Session> get activeSessions => _repository.getActiveSessions();

  List<Machine> get machines => _repository.getAllMachines();

  Session? getSession(String sessionId) => _repository.getSession(sessionId);

  SessionMessages? getSessionMessages(String sessionId) =>
      _repository.getSessionMessages(sessionId);

  bool hasRemoteSession(String sessionId) =>
      _lastRemoteSessionIds.contains(sessionId);

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _cachePersistDebounce?.cancel();
    super.dispose();
  }
}
