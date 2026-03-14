import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/session_preferences_service.dart';
import '../data/session_repository.dart';
import '../data/session_composer_queue_service.dart';
import '../data/session_ui_state_service.dart';
import '../../socketio/data/socket_repository.dart';
import '../../../shared/utils/extensions.dart';
import '../../../app/services/api_service.dart';
import '../../../app/providers/app_providers.dart';
import '../../encryption/domain/crypto_service.dart';
import '../../auth/data/token_storage_service.dart';
import '../../storage/domain/storage_service.dart';
import '../../storage/domain/storage_models.dart' as storage_models;
import 'session_rpc_models.dart';
import 'session_creation_options.dart';

/// 会话状态
class SessionServiceState {
  const SessionServiceState._();

  static const SessionServiceState initial = _SessionServiceInitialState();

  static const SessionServiceState loading = _SessionServiceLoadingState();

  static SessionServiceState ready({
    required Map<String, Session> sessions,
    required Map<String, SessionMessages> sessionMessages,
    required Map<String, Machine> machines,
  }) =>
      _SessionServiceReadyState(
        sessions: sessions,
        sessionMessages: sessionMessages,
        machines: machines,
      );

  static SessionServiceState error(String message) =>
      _SessionServiceErrorState(message);

  T whenOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(
            Map<String, Session> sessions,
            Map<String, SessionMessages> sessionMessages,
            Map<String, Machine> machines)?
        ready,
    T Function(String message)? error,
  }) {
    if (this is _SessionServiceReadyState && ready != null) {
      final state = this as _SessionServiceReadyState;
      return ready(state.sessions, state.sessionMessages, state.machines);
    }
    if (this is _SessionServiceLoadingState && loading != null) {
      return loading();
    }
    if (this is _SessionServiceErrorState && error != null) {
      return error((this as _SessionServiceErrorState).message);
    }
    if (initial != null) {
      return initial();
    }
    return null as T;
  }

  T when<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(
            Map<String, Session> sessions,
            Map<String, SessionMessages> sessionMessages,
            Map<String, Machine> machines)?
        ready,
    T Function(String message)? error,
  }) {
    return whenOrNull(
      initial: initial ?? () => throw Exception('Unhandled initial state'),
      loading: loading ?? () => throw Exception('Unhandled loading state'),
      ready: ready ??
          (sessions, sessionMessages, machines) =>
              throw Exception('Unhandled ready state'),
      error: error ?? (message) => throw Exception('Unhandled error state'),
    )!;
  }
}

class _SessionServiceInitialState extends SessionServiceState {
  const _SessionServiceInitialState() : super._();
}

class _SessionServiceLoadingState extends SessionServiceState {
  const _SessionServiceLoadingState() : super._();
}

class _SessionServiceReadyState extends SessionServiceState {
  final Map<String, Session> sessions;
  final Map<String, SessionMessages> sessionMessages;
  final Map<String, Machine> machines;

  const _SessionServiceReadyState({
    required this.sessions,
    required this.sessionMessages,
    required this.machines,
  }) : super._();
}

class _SessionServiceErrorState extends SessionServiceState {
  final String message;

  const _SessionServiceErrorState(this.message) : super._();
}

class SessionSpawnResult {
  const SessionSpawnResult._({
    this.sessionId,
    this.directoryApprovalPath,
    this.errorMessage,
  });

  const SessionSpawnResult.success(String sessionId)
      : this._(sessionId: sessionId);

  const SessionSpawnResult.directoryApproval(String directory)
      : this._(directoryApprovalPath: directory);

  const SessionSpawnResult.error(String message)
      : this._(errorMessage: message);

  final String? sessionId;
  final String? directoryApprovalPath;
  final String? errorMessage;

  bool get isSuccess => sessionId != null && sessionId!.isNotEmpty;

  bool get requiresDirectoryApproval =>
      directoryApprovalPath != null && directoryApprovalPath!.isNotEmpty;
}

/// 会话服务 Notifier
///
/// 管理会话状态和操作
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
  StreamSubscription<SessionStateChange>? _stateSubscription;
  Timer? _cachePersistDebounce;
  String? _accountSecret;
  Future<void>? _loadSessionsInFlight;
  Future<void>? _loadMachinesInFlight;
  DateTime? _lastSessionsLoadedAt;
  DateTime? _lastMachinesLoadedAt;

  void _emitReadyState() {
    state = SessionServiceState.ready(
      sessions: _repository.sessionsMap,
      sessionMessages: _repository.sessionMessagesMap,
      machines: _repository.machinesMap,
    );
  }

  /// 订阅状态变化
  void _subscribeToChanges() {
    _stateSubscription = _repository.stateChanges.listen((change) {
      _handleStateChange(change);
    });
  }

  /// 处理状态变化
  void _handleStateChange(SessionStateChange change) {
    switch (change.type) {
      case SessionChangeType.sessionsUpdated:
        _emitReadyState();
        _schedulePersistCachedSessions();
        break;
      case SessionChangeType.messagesUpdated:
      case SessionChangeType.agentStateUpdated:
        _emitReadyState();
        break;
      case SessionChangeType.machinesUpdated:
      case SessionChangeType.permissionModeUpdated:
      case SessionChangeType.modelModeUpdated:
      case SessionChangeType.draftUpdated:
        _emitReadyState();
        _schedulePersistCachedSessions();
        break;
      case SessionChangeType.toolCallApproved:
      case SessionChangeType.toolCallRejected:
        _emitReadyState();
        break;
      case SessionChangeType.sessionDeleted:
        _emitReadyState();
        _schedulePersistCachedSessions();
        break;
      case SessionChangeType.cleared:
        _cachePersistDebounce?.cancel();
        state = SessionServiceState.initial;
        break;
    }
  }

  void _schedulePersistCachedSessions() {
    _cachePersistDebounce?.cancel();
    _cachePersistDebounce = Timer(
      const Duration(milliseconds: 450),
      () {
        unawaited(
          _persistCachedSessions(_repository.getAllSessions()),
        );
      },
    );
  }

  /// 加载会话列表
  Future<void> loadSessions({bool force = false}) async {
    if (_loadSessionsInFlight != null) {
      return _loadSessionsInFlight!;
    }

    var hasCachedSessions = _repository.sessionsMap.isNotEmpty;
    if (!hasCachedSessions) {
      final restoredSessions = await _restoreCachedSessions();
      if (restoredSessions.isNotEmpty) {
        _repository.applySessions(restoredSessions);
        _emitReadyState();
        hasCachedSessions = true;
      }
    }

    if (!force &&
        hasCachedSessions &&
        _lastSessionsLoadedAt != null &&
        DateTime.now().difference(_lastSessionsLoadedAt!) <
            const Duration(seconds: 2)) {
      return;
    }

    final completer = Completer<void>();
    _loadSessionsInFlight = completer.future;

    try {
      if (!hasCachedSessions) {
        state = const _SessionServiceLoadingState();
      }
      final response = await ApiService.instance.get<Map<String, dynamic>>(
        '/v1/sessions',
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      final sessionItems = _extractListPayload(response, 'sessions');
      final sessionPreferences = await _preferencesService.loadAll();
      final secretKey = await _tokenStorage.getSecretKey();
      _accountSecret = secretKey;
      final crypto = secretKey != null && secretKey.isNotEmpty
          ? await CryptoService.instance
          : null;
      final machinesFuture = loadMachines(
        force: force || _repository.machinesMap.isEmpty,
        allowFailure: true,
      );

      final sessionsMap = <String, Session>{};
      _sessionDataKeys.clear();
      for (final item in sessionItems) {
        final sessionJson = _asStringMap(item);
        if (sessionJson == null) {
          continue;
        }
        try {
          final encryptedDataKey = sessionJson['dataEncryptionKey'] as String?;
          final dataKey = secretKey != null &&
                  secretKey.isNotEmpty &&
                  crypto != null &&
                  encryptedDataKey != null &&
                  encryptedDataKey.isNotEmpty
              ? await crypto.decryptHappyCoderDataEncryptionKey(
                  encryptedDataKey,
                  secretKey,
                )
              : null;

          final metadata = await _decodeEncryptedJsonMap(
            sessionJson['metadata'],
            dataKey: dataKey,
            secretKey: secretKey,
          );
          final agentState = await _decodeEncryptedJsonMap(
            sessionJson['agentState'],
            dataKey: dataKey,
            secretKey: secretKey,
          );

          final parsedSession = Session.fromJson(sessionJson);
          final nextMetadata = metadata ?? parsedSession.metadata;
          final summary = _asStringMap(nextMetadata?['summary']);
          final resolvedPath =
              nextMetadata?['path']?.toString() ?? parsedSession.path;
          final preferences = sessionPreferences[parsedSession.id];
          final session = parsedSession.copyWith(
            title: _resolveSessionTitle(
              path: resolvedPath,
              summary: summary?['text']?.toString(),
              name: preferences?.alias ?? nextMetadata?['name']?.toString(),
              title: nextMetadata?['title']?.toString(),
              fallback: parsedSession.title,
            ),
            path: resolvedPath,
            metadata: nextMetadata,
            agentState: agentState ?? parsedSession.agentState,
            permissionMode: _resolveLocalSessionMode(
              preferred: preferences?.permissionMode,
              explicit: parsedSession.permissionMode,
              metadataValue:
                  nextMetadata?['currentOperatingModeCode']?.toString(),
            ),
            modelMode: _resolveLocalSessionMode(
              preferred: preferences?.modelMode,
              explicit: parsedSession.modelMode,
              metadataValue: nextMetadata?['currentModelCode']?.toString(),
            ),
          );
          sessionsMap[session.id] = session;
          _sessionDataKeys[session.id] = dataKey;
        } catch (e) {
          Logger.warning('Failed to parse session: $e');
        }
      }

      _repository.applySessions(sessionsMap.values.toList());
      _lastSessionsLoadedAt = DateTime.now();
      _schedulePersistCachedSessions();
      await machinesFuture;
      _emitReadyState();
      unawaited(_warmSessionPreviewData(sessionsMap.values.toList()));

      Logger.info('Sessions loaded: ${sessionsMap.length}');
    } catch (e) {
      if (_repository.sessionsMap.isEmpty) {
        final restoredSessions = await _restoreCachedSessions();
        if (restoredSessions.isNotEmpty) {
          _repository.applySessions(restoredSessions);
        }
      }

      if (_repository.sessionsMap.isNotEmpty) {
        _emitReadyState();
        Logger.warning('Load sessions failed, using cached sessions: $e');
      } else {
        state = SessionServiceState.error('加载会话失败: ${e.toString()}');
        Logger.error('Load sessions error: $e');
      }
    } finally {
      _loadSessionsInFlight = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<void> loadMachines({
    bool force = false,
    bool allowFailure = false,
  }) async {
    if (_loadMachinesInFlight != null) {
      return _loadMachinesInFlight!;
    }

    final hasCachedMachines = _repository.machinesMap.isNotEmpty;
    if (!force &&
        hasCachedMachines &&
        _lastMachinesLoadedAt != null &&
        DateTime.now().difference(_lastMachinesLoadedAt!) <
            const Duration(seconds: 2)) {
      return;
    }

    final completer = Completer<void>();
    _loadMachinesInFlight = completer.future;

    try {
      final response = await ApiService.instance.get<dynamic>('/v1/machines');
      final machineItems = response is List
          ? response
          : _extractListPayload(_asStringMap(response), 'machines');
      final secretKey = _accountSecret ?? await _tokenStorage.getSecretKey();
      _accountSecret = secretKey;
      final crypto = secretKey != null && secretKey.isNotEmpty
          ? await CryptoService.instance
          : null;

      final nextKeys = <String, Uint8List?>{};
      final machines = <Machine>[];

      for (final item in machineItems) {
        final machineJson = _asStringMap(item);
        if (machineJson == null) {
          continue;
        }

        try {
          final encryptedDataKey = machineJson['dataEncryptionKey']?.toString();
          final dataKey = secretKey != null &&
                  secretKey.isNotEmpty &&
                  crypto != null &&
                  encryptedDataKey != null &&
                  encryptedDataKey.isNotEmpty
              ? await crypto.decryptHappyCoderDataEncryptionKey(
                  encryptedDataKey,
                  secretKey,
                )
              : null;

          final metadata = await _decodeEncryptedJsonMap(
            machineJson['metadata'],
            dataKey: dataKey,
            secretKey: secretKey,
          );

          final parsedMachine = Machine.fromJson({
            ...machineJson,
            if (metadata != null) 'metadata': metadata,
          });
          machines.add(parsedMachine.copyWith(
              metadata: metadata ?? parsedMachine.metadata));
          nextKeys[parsedMachine.id] = dataKey;
        } catch (error) {
          Logger.warning('Failed to parse machine: $error');
        }
      }

      _machineDataKeys
        ..clear()
        ..addAll(nextKeys);
      _repository.applyMachines(machines, replace: true);
      _lastMachinesLoadedAt = DateTime.now();
    } catch (error) {
      Logger.error('Load machines error: $error');
      if (!allowFailure) {
        rethrow;
      }
    } finally {
      _loadMachinesInFlight = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  /// 加载会话消息
  Future<void> loadSessionMessages(String sessionId) async {
    try {
      final sessionKey = _sessionDataKeys[sessionId];
      final existing = _repository.getSessionMessages(sessionId);
      var afterSeq = existing == null ? 0 : (_sessionLastSeq[sessionId] ?? 0);
      var hasMore = true;
      final messages = <ReducerMessage>[];

      while (hasMore) {
        final response = await ApiService.instance.get<Map<String, dynamic>>(
          '/v3/sessions/$sessionId/messages',
          queryParameters: {
            'after_seq': afterSeq,
            'limit': 100,
          },
        );
        final messageItems = _extractListPayload(response, 'messages');
        var maxSeq = afterSeq;

        for (final item in messageItems) {
          final messageJson = _asStringMap(item);
          if (messageJson == null) {
            continue;
          }

          final seq = _parseSeq(messageJson['seq']);
          if (seq != null && seq > maxSeq) {
            maxSeq = seq;
          }

          try {
            final parsedMessages = await _parseServerMessages(
              messageJson,
              sessionKey: sessionKey,
              secretKey: _accountSecret,
            );
            messages.addAll(parsedMessages);
          } catch (e) {
            Logger.warning('Failed to parse message: $e');
          }
        }

        hasMore = response['hasMore'] == true;
        if (maxSeq == afterSeq) {
          hasMore = false;
        }
        afterSeq = maxSeq;
      }

      _sessionLastSeq[sessionId] = afterSeq;
      if (messages.isNotEmpty || existing == null) {
        _repository.applyMessages(sessionId, messages);
      }
      Logger.info(
          'Session messages loaded: $sessionId (${messages.length} messages)');
    } catch (e) {
      Logger.error('Load session messages error: $e');
    }
  }

  Future<void> _warmSessionPreviewData(List<Session> sessions) async {
    final previewSessions = sessions.take(3);
    for (final session in previewSessions) {
      final existing = _repository.getSessionMessages(session.id);
      if (existing?.isLoaded == true) {
        continue;
      }
      try {
        await loadSessionMessages(session.id);
      } catch (e) {
        Logger.warning('Failed to warm preview data for ${session.id}: $e');
      }
    }
  }

  /// 创建新会话
  Future<String?> createSession({
    String? title,
    String? tag,
    String? path,
    Map<String, dynamic>? metadata,
    String? permissionMode,
    String? modelMode,
  }) async {
    try {
      final resolvedTitle = (title?.trim().isNotEmpty ?? false)
          ? title!.trim()
          : (tag?.trim().isNotEmpty ?? false)
              ? tag!.trim()
              : '新建会话';
      final resolvedTag = (tag?.trim().isNotEmpty ?? false)
          ? tag!.trim()
          : 'session_${DateTime.now().millisecondsSinceEpoch}';
      final requestMetadata = <String, dynamic>{
        'name': resolvedTitle,
        if (path != null && path.isNotEmpty) 'path': path,
        if (permissionMode != null) 'permissionMode': permissionMode,
        if (modelMode != null) 'modelMode': modelMode,
        ...?metadata,
      };
      final response = await ApiService.instance.post<Map<String, dynamic>>(
        '/v1/sessions',
        data: {
          'tag': resolvedTag,
          'metadata': jsonEncode(requestMetadata),
          'agentState': null,
          'dataEncryptionKey': null,
        },
      );
      final sessionJson = _asStringMap(response['session']) ?? response;

      if (sessionJson.isNotEmpty && sessionJson.containsKey('id')) {
        final newSession = Session.fromJson(sessionJson);
        _repository.applySessions([newSession]);
        await _persistSessionCreationModes(
          sessionId: newSession.id,
          permissionMode: permissionMode,
          modelMode: modelMode,
        );

        Logger.info('Session created: ${newSession.id}');
        return newSession.id;
      }

      return null;
    } catch (e) {
      Logger.error('Create session error: $e');
      return null;
    }
  }

  Future<SessionSpawnResult> spawnSession({
    required String machineId,
    required String directory,
    required String agent,
    bool approvedNewDirectoryCreation = false,
    Map<String, String>? environmentVariables,
    String? permissionMode,
    String? modelMode,
  }) async {
    try {
      await _ensureMachineRpcContext(machineId);
      final normalizedAgent = normalizeSessionAgent(agent);
      final result = await SocketRepository.instance.machineRpc(
        machineId: machineId,
        method: 'spawn-happy-session',
        payload: {
          'type': 'spawn-in-directory',
          'directory': directory,
          'approvedNewDirectoryCreation': approvedNewDirectoryCreation,
          'agent': normalizedAgent,
          if (environmentVariables != null && environmentVariables.isNotEmpty)
            'environmentVariables': environmentVariables,
        },
        dataEncryptionKey: _machineDataKeys[machineId],
        accountSecret: _accountSecret,
      );
      final response = _asStringMap(result);
      final type = response?['type']?.toString();
      switch (type) {
        case 'success':
          final sessionId = response?['sessionId']?.toString();
          if (sessionId == null || sessionId.isEmpty) {
            return const SessionSpawnResult.error('创建会话失败：缺少会话 ID');
          }
          final sessionLoaded = await _awaitSessionAvailable(sessionId);
          if (!sessionLoaded) {
            _seedLocalSpawnedSession(
              sessionId: sessionId,
              machineId: machineId,
              directory: directory,
              agent: normalizedAgent,
              permissionMode: permissionMode,
              modelMode: modelMode,
            );
            unawaited(
              loadSessions(force: true).catchError((Object error) {
                Logger.warning(
                  'Failed to refresh sessions after spawn for $sessionId: $error',
                );
              }),
            );
          }
          await _persistSessionCreationModes(
            sessionId: sessionId,
            permissionMode: permissionMode,
            modelMode: modelMode,
          );
          return SessionSpawnResult.success(sessionId);
        case 'requestToApproveDirectoryCreation':
          final approvalPath = response?['directory']?.toString() ?? directory;
          return SessionSpawnResult.directoryApproval(approvalPath);
        case 'error':
          return SessionSpawnResult.error(
            response?['errorMessage']?.toString() ?? '创建会话失败',
          );
        default:
          return SessionSpawnResult.error(
            response?['errorMessage']?.toString() ?? '创建会话失败',
          );
      }
    } catch (e) {
      Logger.error('Spawn session error: $e');
      return SessionSpawnResult.error(e.toString());
    }
  }

  /// 发送消息
  Future<void> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? metadata,
    String? localId,
  }) async {
    final resolvedLocalId =
        localId ?? 'msg_${DateTime.now().microsecondsSinceEpoch}';
    try {
      final session = _repository.getSession(sessionId);
      if (session == null) {
        throw Exception('Session not found: $sessionId');
      }

      _repository.applyMessages(sessionId, [
        ReducerMessage(
          id: resolvedLocalId,
          kind: 'text',
          createdAt: DateTime.now(),
          text: content,
          metadata: {
            'role': 'user',
            'localId': resolvedLocalId,
            'optimistic': true,
            ...?metadata,
          },
        ),
      ]);

      final encryptedContent = await _encryptSessionMessage(
        sessionId: sessionId,
        rawRecord: _buildOutboundRawRecord(
          session: session,
          text: content,
          metadata: metadata,
        ),
      );

      await ApiService.instance.post<Map<String, dynamic>>(
        '/v3/sessions/$sessionId/messages',
        data: {
          'messages': [
            {
              'content': encryptedContent,
              'localId': resolvedLocalId,
            },
          ],
        },
      );
      unawaited(
        loadSessionMessages(sessionId).catchError((Object error) {
          Logger.warning(
              'Failed to refresh session messages after send: $error');
        }),
      );

      Logger.info('Message sent to session: $sessionId');
    } catch (e) {
      _repository.removeMessage(sessionId, resolvedLocalId);
      Logger.error('Send message error: $e');
      rethrow;
    }
  }

  List<dynamic> _extractListPayload(
      Map<String, dynamic>? response, String key) {
    if (response == null) {
      return const [];
    }
    final value = response[key];
    if (value is List<dynamic>) {
      return value;
    }
    return const [];
  }

  Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(key.toString(), mapValue),
      );
    }
    return null;
  }

  /// 批准工具调用
  void approveToolCall(String sessionId, String toolId) {
    _repository.approveToolCall(sessionId, toolId);
    Logger.info('Tool call approved: $toolId');
  }

  /// 拒绝工具调用
  void rejectToolCall(String sessionId, String toolId, {String? reason}) {
    _repository.rejectToolCall(sessionId, toolId, reason: reason);
    Logger.info('Tool call rejected: $toolId');
  }

  Future<void> submitToolApproval({
    required String sessionId,
    required String toolId,
  }) async {
    approveToolCall(sessionId, toolId);
    final session = _repository.getSession(sessionId);
    final flavor = session?.metadata?['flavor']?.toString();
    await _submitPermissionDecision(
      sessionId: sessionId,
      request: {
        'id': toolId,
        'approved': true,
        if (flavor == 'codex') 'decision': 'approved',
      },
    );
    await loadSessionMessages(sessionId);
    unawaited(loadSessions(force: true));
  }

  Future<void> submitToolRejection({
    required String sessionId,
    required String toolId,
    String? reason,
  }) async {
    rejectToolCall(sessionId, toolId, reason: reason);
    final session = _repository.getSession(sessionId);
    final flavor = session?.metadata?['flavor']?.toString();
    await _submitPermissionDecision(
      sessionId: sessionId,
      request: {
        'id': toolId,
        'approved': false,
        if (flavor == 'codex') 'decision': 'abort',
      },
    );
    await loadSessionMessages(sessionId);
    unawaited(loadSessions(force: true));
  }

  /// 删除会话
  Future<void> deleteSession(String sessionId) async {
    try {
      await ApiService.instance.delete<Map<String, dynamic>>(
        '/v1/sessions/$sessionId',
      );
    } catch (e) {
      final errorText = e.toString();
      if (!errorText.contains('404')) {
        rethrow;
      }
    }

    await _purgeLocalSession(sessionId);
  }

  /// 清空会话消息
  void clearSessionMessages(String sessionId) {
    _sessionLastSeq.remove(sessionId);
    _repository.clearSessionMessages(sessionId);
  }

  /// 更新会话草稿
  void updateDraft(String sessionId, String? draft) {
    _repository.updateSessionDraft(sessionId, draft);
  }

  /// 更新权限模式
  void updatePermissionMode(String sessionId, String mode) {
    _repository.updateSessionPermissionMode(sessionId, mode);
    unawaited(
      _preferencesService
          .update(
        sessionId: sessionId,
        permissionMode: mode,
      )
          .catchError((Object error, StackTrace stackTrace) {
        Logger.warning('Failed to persist permission mode: $error');
      }),
    );
    unawaited(
      _syncSessionMetadata(
        sessionId: sessionId,
        permissionMode: mode,
      ).catchError((Object error, StackTrace stackTrace) {
        Logger.warning('Failed to sync permission mode: $error');
      }),
    );
  }

  /// 更新模型模式
  void updateModelMode(String sessionId, String mode) {
    _repository.updateSessionModelMode(sessionId, mode);
    unawaited(
      _preferencesService
          .update(
        sessionId: sessionId,
        modelMode: mode,
      )
          .catchError((Object error, StackTrace stackTrace) {
        Logger.warning('Failed to persist model mode: $error');
      }),
    );
    unawaited(
      _syncSessionMetadata(
        sessionId: sessionId,
        modelMode: mode,
      ).catchError((Object error, StackTrace stackTrace) {
        Logger.warning('Failed to sync model mode: $error');
      }),
    );
  }

  Future<void> renameSession({
    required String sessionId,
    required String alias,
  }) async {
    final session = _repository.getSession(sessionId);
    if (session == null) {
      throw Exception('Session not found: $sessionId');
    }

    final normalizedAlias = _normalizeOptionalValue(alias);
    final fallbackMetadata = Map<String, dynamic>.from(
      session.metadata ?? const <String, dynamic>{},
    )
      ..remove('name')
      ..remove('title');
    final nextTitle = normalizedAlias ??
        _resolveSessionTitle(
          path: session.path ?? fallbackMetadata['path']?.toString(),
          summary:
              _asStringMap(fallbackMetadata['summary'])?['text']?.toString(),
          name: fallbackMetadata['name']?.toString(),
          title: fallbackMetadata['title']?.toString(),
          fallback: session.title,
        );

    _repository.applySessions([
      session.copyWith(title: nextTitle),
    ]);

    await _preferencesService.update(
      sessionId: sessionId,
      alias: normalizedAlias,
    );

    try {
      await _syncSessionMetadata(
        sessionId: sessionId,
        alias: normalizedAlias,
      );
    } catch (e) {
      Logger.warning('Failed to sync session alias to server: $e');
    }

    unawaited(loadSessions(force: true));
  }

  Future<bool> _awaitSessionAvailable(String sessionId) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        await loadSessions(force: true);
      } catch (error) {
        Logger.warning(
          'Failed to refresh sessions while waiting for $sessionId: $error',
        );
      }
      if (_repository.getSession(sessionId) != null) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return false;
  }

  Future<void> _persistSessionCreationModes({
    required String sessionId,
    String? permissionMode,
    String? modelMode,
  }) async {
    final normalizedPermissionMode = _normalizeOptionalValue(permissionMode);
    final normalizedModelMode = _normalizeOptionalValue(modelMode);

    await _preferencesService.update(
      sessionId: sessionId,
      permissionMode: normalizedPermissionMode,
      modelMode: normalizedModelMode,
    );

    if (normalizedPermissionMode != null) {
      _repository.updateSessionPermissionMode(
          sessionId, normalizedPermissionMode);
      unawaited(
        _syncSessionMetadata(
          sessionId: sessionId,
          permissionMode: normalizedPermissionMode,
        ).catchError((Object error, StackTrace stackTrace) {
          Logger.warning(
              'Failed to sync created session permission mode: $error');
        }),
      );
    }

    if (normalizedModelMode != null) {
      _repository.updateSessionModelMode(sessionId, normalizedModelMode);
      unawaited(
        _syncSessionMetadata(
          sessionId: sessionId,
          modelMode: normalizedModelMode,
        ).catchError((Object error, StackTrace stackTrace) {
          Logger.warning('Failed to sync created session model mode: $error');
        }),
      );
    }
  }

  Future<void> _purgeLocalSession(String sessionId) async {
    _sessionDataKeys.remove(sessionId);
    _sessionLastSeq.remove(sessionId);
    await _composerQueueService.clearSession(sessionId);
    await _preferencesService.clearSession(sessionId);
    await _uiStateService.clearSession(sessionId);
    await StorageService.instance.deleteSession(sessionId);
    SocketRepository.instance.unsubscribeFromSession(sessionId);
    _repository.deleteSession(sessionId);
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
      activeAt: _parseMessageDateTime(localState?['activeAt']),
      tag: cached.tag,
      path: metadata?['path']?.toString(),
      metadata: metadata,
      permissionMode:
          _normalizeOptionalValue(localState?['permissionMode']?.toString()),
      modelMode: _normalizeOptionalValue(localState?['modelMode']?.toString()),
      thinking: localState?['thinking'] as bool?,
      thinkingAt: _parseMessageDateTime(localState?['thinkingAt']),
    );
  }

  Future<void> _persistCachedSessions(List<Session> sessions) async {
    try {
      await StorageService.instance.cacheRemoteSessions(sessions);
    } catch (error) {
      Logger.warning('Failed to persist cached sessions: $error');
    }
  }

  /// 获取会话列表
  List<Session> get sessions => _repository.getAllSessions();

  /// 获取活跃会话
  List<Session> get activeSessions => _repository.getActiveSessions();

  /// 获取所有机器
  List<Machine> get machines => _repository.getAllMachines();

  /// 获取会话
  Session? getSession(String sessionId) => _repository.getSession(sessionId);

  /// 获取会话消息
  SessionMessages? getSessionMessages(String sessionId) =>
      _repository.getSessionMessages(sessionId);

  Future<SessionBashResponse> executeSessionBash({
    required String sessionId,
    required String command,
    String? cwd,
    int? timeout,
  }) async {
    try {
      final result = await _callSessionRpcDecoded(
        sessionId: sessionId,
        method: 'bash',
        payload: SessionBashRequest(
          command: command,
          cwd: cwd,
          timeout: timeout,
        ).toJson(),
      );
      final map = _asStringMap(result);
      if (map == null) {
        return const SessionBashResponse(
          success: false,
          error: '无效的 bash 响应',
        );
      }
      return SessionBashResponse.fromJson(map);
    } catch (e) {
      Logger.warning('Session bash RPC failed: $e');
      return SessionBashResponse(
        success: false,
        stderr: e.toString(),
        error: e.toString(),
      );
    }
  }

  Future<SessionReadFileResponse> readSessionFile({
    required String sessionId,
    required String path,
  }) async {
    try {
      final result = await _callSessionRpcDecoded(
        sessionId: sessionId,
        method: 'readFile',
        payload: {
          'path': path,
        },
      );
      final map = _asStringMap(result);
      if (map == null) {
        return const SessionReadFileResponse(
          success: false,
          error: '无效的文件读取响应',
        );
      }
      return SessionReadFileResponse.fromJson(map);
    } catch (e) {
      Logger.warning('Session readFile RPC failed: $e');
      return SessionReadFileResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<SessionRipgrepResponse> executeSessionRipgrep({
    required String sessionId,
    required List<String> args,
    String? cwd,
  }) async {
    try {
      final result = await _callSessionRpcDecoded(
        sessionId: sessionId,
        method: 'ripgrep',
        payload: SessionRipgrepRequest(
          args: args,
          cwd: cwd,
        ).toJson(),
      );
      final map = _asStringMap(result);
      if (map == null) {
        return const SessionRipgrepResponse(
          success: false,
          error: '无效的 ripgrep 响应',
        );
      }
      return SessionRipgrepResponse.fromJson(map);
    } catch (e) {
      Logger.warning('Session ripgrep RPC failed: $e');
      return SessionRipgrepResponse(
        success: false,
        stderr: e.toString(),
        error: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>?> _decodeEncryptedJsonMap(
    dynamic rawValue, {
    Uint8List? dataKey,
    String? secretKey,
  }) async {
    if (rawValue == null) {
      return null;
    }
    if (rawValue is Map<String, dynamic>) {
      return rawValue;
    }
    if (rawValue is Map) {
      return _asStringMap(rawValue);
    }
    if (rawValue is! String || rawValue.trim().isEmpty) {
      return null;
    }

    final maybeJson = _decodeMaybeJsonMap(rawValue);
    if (maybeJson != null) {
      return maybeJson;
    }

    if (!_looksLikeBase64(rawValue)) {
      return null;
    }

    final crypto = await CryptoService.instance;
    if (dataKey != null) {
      final decrypted =
          await crypto.decryptHappyCoderAesGcmJson(rawValue, dataKey);
      final decoded = _asStringMap(decrypted);
      if (decoded != null) {
        return decoded;
      }
    }

    if (secretKey != null && secretKey.isNotEmpty) {
      final decrypted =
          await crypto.decryptHappyCoderLegacyJson(rawValue, secretKey);
      final decoded = _asStringMap(decrypted);
      if (decoded != null) {
        return decoded;
      }
    }

    return null;
  }

  Future<List<ReducerMessage>> _parseServerMessages(
    Map<String, dynamic> messageJson, {
    Uint8List? sessionKey,
    String? secretKey,
  }) async {
    final createdAt = messageJson['createdAt'] != null
        ? _parseMessageDateTime(messageJson['createdAt']) ?? DateTime.now()
        : DateTime.now();
    final messageId = messageJson['id'] as String? ?? '';
    final localId = messageJson['localId']?.toString();
    final content = _asStringMap(messageJson['content']);
    final payload = content?['c'];
    final contentType = content?['t']?.toString();

    if (payload is String && payload.isNotEmpty) {
      final rawRecord = await _decodeEncryptedJsonMap(
        payload,
        dataKey: sessionKey,
        secretKey: secretKey,
      );
      if (rawRecord != null) {
        final reduced = _reduceRawRecordMessages(
          rawRecord,
          id: messageId,
          createdAt: createdAt,
          localId: localId,
        );
        if (reduced.isNotEmpty) {
          return reduced;
        }
      }

      if (contentType == 'encrypted' && _looksLikeBase64(payload)) {
        return const <ReducerMessage>[];
      }

      return <ReducerMessage>[
        ReducerMessage(
          id: messageId,
          kind: 'text',
          createdAt: createdAt,
          text: payload,
          metadata: {
            ...?_asStringMap(messageJson['metadata']),
            if (localId != null && localId.isNotEmpty) 'localId': localId,
          },
        ),
      ];
    }

    return <ReducerMessage>[ReducerMessage.fromJson(messageJson)];
  }

  List<ReducerMessage> _reduceRawRecordMessages(
    Map<String, dynamic> rawRecord, {
    required String id,
    required DateTime createdAt,
    String? localId,
  }) {
    final role = rawRecord['role']?.toString();
    final meta = _asStringMap(rawRecord['meta']);
    final content = _asStringMap(rawRecord['content']);

    switch (role) {
      case 'user':
        final text = content?['text']?.toString();
        if (text == null || text.isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: id,
            createdAt: createdAt,
            text: text,
            metadata: {
              ...?meta,
              'role': 'user',
              if (localId != null && localId.isNotEmpty) 'localId': localId,
            },
          ),
        ];
      case 'session':
        return _reduceSessionEnvelopeMessages(
          envelope: _asStringMap(content?['data']),
          id: id,
          createdAt: createdAt,
          localId: localId,
          meta: meta,
        );
      case 'agent':
        final contentType = content?['type']?.toString();
        if (contentType == 'codex') {
          return _reduceCodexMessages(
            codexData: _asStringMap(content?['data']),
            id: id,
            createdAt: createdAt,
            localId: localId,
            meta: meta,
          );
        }

        if (contentType == 'acp') {
          return _reduceAcpMessages(
            acpData: _asStringMap(content?['data']),
            provider: content?['provider']?.toString(),
            id: id,
            createdAt: createdAt,
            localId: localId,
            meta: meta,
          );
        }

        if (contentType == 'output') {
          return _reduceOutputMessages(
            outputData: _asStringMap(content?['data']),
            id: id,
            createdAt: createdAt,
            localId: localId,
            meta: meta,
          );
        }
        return const <ReducerMessage>[];
      default:
        return const <ReducerMessage>[];
    }
  }

  List<ReducerMessage> _reduceSessionEnvelopeMessages({
    required Map<String, dynamic>? envelope,
    required String id,
    required DateTime createdAt,
    required String? localId,
    required Map<String, dynamic>? meta,
  }) {
    if (envelope == null) {
      return const <ReducerMessage>[];
    }

    final event = _asStringMap(envelope['ev']);
    final eventType = event?['t']?.toString();
    final envelopeRole = envelope['role']?.toString() ?? 'agent';
    final normalizedRole = envelopeRole == 'user' ? 'agent' : envelopeRole;
    final metadata = {
      ...?meta,
      'role': normalizedRole,
      'sourceRole': envelopeRole,
      if (localId != null && localId.isNotEmpty) 'localId': localId,
      if (eventType != null) 'eventType': eventType,
    };

    switch (eventType) {
      case 'text':
        final text = event?['text']?.toString();
        if (text == null || text.isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:session:text',
            createdAt: createdAt,
            text: text,
            metadata: {
              ...metadata,
              if (event?['thinking'] == true) 'outputType': 'thinking',
            },
          ),
        ];
      case 'service':
        final text = event?['text']?.toString();
        if (text == null || text.isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildEventReducerMessage(
            id: '$id:session:service',
            createdAt: createdAt,
            text: text,
            metadata: metadata,
          ),
        ];
      case 'start':
        final title = event?['title']?.toString();
        return title == null || title.isEmpty
            ? const <ReducerMessage>[]
            : <ReducerMessage>[
                _buildEventReducerMessage(
                  id: '$id:session:start',
                  createdAt: createdAt,
                  text: title,
                  metadata: metadata,
                ),
              ];
      case 'stop':
        return <ReducerMessage>[
          _buildEventReducerMessage(
            id: '$id:session:stop',
            createdAt: createdAt,
            text: '任务已结束',
            metadata: metadata,
          ),
        ];
      case 'turn-start':
        return const <ReducerMessage>[];
      case 'tool-call-start':
        final toolId = event?['call']?.toString() ?? id;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: event?['name']?.toString() ?? 'unknown',
            arguments:
                _asStringMap(event?['args']) ?? const <String, dynamic>{},
            status: ToolCallStatus.pending,
            metadata: metadata,
            description: _firstNonEmptyString([
              event?['description']?.toString(),
              event?['title']?.toString(),
            ]),
          ),
        ];
      case 'tool-call-end':
        final toolId = event?['call']?.toString() ?? id;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: event?['name']?.toString() ?? 'unknown',
            arguments: const <String, dynamic>{},
            status: ToolCallStatus.completed,
            metadata: metadata,
          ),
        ];
      case 'file':
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: '$id:file',
            createdAt: createdAt,
            toolId: id,
            name: 'file',
            arguments: {
              'ref': event?['ref'],
              'name': event?['name'],
              'size': event?['size'],
              if (event?['image'] != null) 'image': event?['image'],
            },
            status: ToolCallStatus.completed,
            metadata: metadata,
          ),
        ];
      case 'turn-end':
        final status = event?['status']?.toString();
        return <ReducerMessage>[
          ReducerMessage(
            id: '$id:turn-end',
            kind: 'turn-close',
            createdAt: createdAt,
            metadata: metadata,
            turnClose: TurnClose(
              abandoned: status == 'failed' || status == 'cancelled',
              reason: status,
            ),
          ),
        ];
      default:
        return const <ReducerMessage>[];
    }
  }

  List<ReducerMessage> _reduceCodexMessages({
    required Map<String, dynamic>? codexData,
    required String id,
    required DateTime createdAt,
    required String? localId,
    required Map<String, dynamic>? meta,
  }) {
    if (codexData == null) {
      return const <ReducerMessage>[];
    }

    final codexType = codexData['type']?.toString();
    final metadata = {
      ...?meta,
      'role': 'agent',
      'provider': 'codex',
      if (localId != null && localId.isNotEmpty) 'localId': localId,
      if (codexType != null) 'outputType': codexType,
    };

    switch (codexType) {
      case 'message':
      case 'reasoning':
        final text = codexData['message']?.toString();
        if (text == null || text.isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:codex:$codexType',
            createdAt: createdAt,
            text: text,
            metadata: {
              ...metadata,
              if (codexType == 'reasoning') 'outputType': 'thinking',
            },
          ),
        ];
      case 'tool-call':
        final toolId = codexData['callId']?.toString() ??
            codexData['id']?.toString() ??
            id;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: codexData['name']?.toString() ?? 'unknown',
            arguments: _asStringMap(codexData['input']) ?? const {},
            status: ToolCallStatus.pending,
            metadata: metadata,
          ),
        ];
      case 'tool-call-result':
        final toolId = codexData['callId']?.toString() ??
            codexData['id']?.toString() ??
            id;
        final result = _stringifyStructuredContent(codexData['output']);
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: codexData['name']?.toString() ?? 'unknown',
            arguments: const <String, dynamic>{},
            status: ToolCallStatus.completed,
            metadata: metadata,
            result: result,
          ),
        ];
      default:
        return const <ReducerMessage>[];
    }
  }

  List<ReducerMessage> _reduceAcpMessages({
    required Map<String, dynamic>? acpData,
    required String? provider,
    required String id,
    required DateTime createdAt,
    required String? localId,
    required Map<String, dynamic>? meta,
  }) {
    if (acpData == null) {
      return const <ReducerMessage>[];
    }

    final acpType = acpData['type']?.toString();
    final metadata = {
      ...?meta,
      'role': 'agent',
      if (provider != null && provider.isNotEmpty) 'provider': provider,
      if (localId != null && localId.isNotEmpty) 'localId': localId,
      if (acpType != null) 'outputType': acpType,
    };

    switch (acpType) {
      case 'message':
      case 'reasoning':
        final text = acpData['message']?.toString();
        if (text == null || text.isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:acp:$acpType',
            createdAt: createdAt,
            text: text,
            metadata: {
              ...metadata,
              if (acpType == 'reasoning') 'outputType': 'thinking',
            },
          ),
        ];
      case 'thinking':
        final text = acpData['text']?.toString();
        if (text == null || text.isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:acp:thinking',
            createdAt: createdAt,
            text: text,
            metadata: {
              ...metadata,
              'outputType': 'thinking',
            },
          ),
        ];
      case 'tool-call':
        final toolId =
            acpData['callId']?.toString() ?? acpData['id']?.toString() ?? id;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: acpData['name']?.toString() ?? 'unknown',
            arguments: _asStringMap(acpData['input']) ?? const {},
            status: ToolCallStatus.pending,
            metadata: metadata,
          ),
        ];
      case 'tool-result':
      case 'tool-call-result':
        final toolId =
            acpData['callId']?.toString() ?? acpData['id']?.toString() ?? id;
        final isError =
            acpData['isError'] == true || acpData['is_error'] == true;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: acpData['name']?.toString() ?? 'unknown',
            arguments: const <String, dynamic>{},
            status: isError ? ToolCallStatus.failed : ToolCallStatus.completed,
            metadata: metadata,
            result: _stringifyStructuredContent(acpData['output']),
            error:
                isError ? _stringifyStructuredContent(acpData['output']) : null,
          ),
        ];
      case 'file-edit':
        final toolId = acpData['id']?.toString() ?? id;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: 'Edit',
            arguments: {
              'file_path': acpData['filePath'],
              if (acpData['diff'] != null) 'diff': acpData['diff'],
              if (acpData['oldContent'] != null)
                'old_string': acpData['oldContent'],
              if (acpData['newContent'] != null)
                'new_string': acpData['newContent'],
            },
            status: ToolCallStatus.completed,
            metadata: metadata,
            description: acpData['description']?.toString(),
          ),
        ];
      case 'terminal-output':
        final toolId = acpData['callId']?.toString() ?? id;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: 'Bash',
            arguments: const <String, dynamic>{},
            status: ToolCallStatus.completed,
            metadata: metadata,
            result: acpData['data']?.toString(),
          ),
        ];
      case 'permission-request':
        final toolId = acpData['permissionId']?.toString() ?? id;
        return <ReducerMessage>[
          _buildToolReducerMessage(
            id: _toolMessageId(toolId),
            createdAt: createdAt,
            toolId: toolId,
            name: acpData['toolName']?.toString() ?? 'unknown',
            arguments:
                _asStringMap(acpData['options']) ?? const <String, dynamic>{},
            status: ToolCallStatus.pending,
            metadata: metadata,
            description: acpData['description']?.toString(),
          ),
        ];
      case 'task_started':
        return <ReducerMessage>[
          _buildEventReducerMessage(
            id: '$id:acp:task-started',
            createdAt: createdAt,
            text: '子任务开始',
            metadata: metadata,
          ),
        ];
      case 'task_complete':
        return <ReducerMessage>[
          _buildEventReducerMessage(
            id: '$id:acp:task-complete',
            createdAt: createdAt,
            text: '子任务完成',
            metadata: metadata,
          ),
        ];
      case 'turn_aborted':
        return <ReducerMessage>[
          _buildEventReducerMessage(
            id: '$id:acp:turn-aborted',
            createdAt: createdAt,
            text: '回合已中止',
            metadata: metadata,
          ),
        ];
      default:
        return const <ReducerMessage>[];
    }
  }

  List<ReducerMessage> _reduceOutputMessages({
    required Map<String, dynamic>? outputData,
    required String id,
    required DateTime createdAt,
    required String? localId,
    required Map<String, dynamic>? meta,
  }) {
    if (outputData == null) {
      return const <ReducerMessage>[];
    }

    final outputType = outputData['type']?.toString();
    final baseMetadata = {
      ...?meta,
      'role': 'agent',
      if (localId != null && localId.isNotEmpty) 'localId': localId,
      if (outputType != null) 'outputType': outputType,
    };

    switch (outputType) {
      case 'message':
      case 'reasoning':
        final text = outputData['message']?.toString();
        if (text == null || text.isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:output:$outputType',
            createdAt: createdAt,
            text: text,
            metadata: {
              ...baseMetadata,
              if (outputType == 'reasoning') 'outputType': 'thinking',
            },
          ),
        ];
      case 'summary':
        final summary = outputData['summary']?.toString();
        if (summary == null || summary.isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:output:summary',
            createdAt: createdAt,
            text: summary,
            metadata: baseMetadata,
          ),
        ];
      case 'assistant':
      case 'user':
        final message = _asStringMap(outputData['message']);
        final content = message?['content'];
        final parts = _normalizeAgentContentParts(content);
        if (parts.isNotEmpty) {
          return _reduceAgentContentParts(
            parts,
            baseId: id,
            createdAt: createdAt,
            meta: {
              ...baseMetadata,
              if (outputType == 'user') 'sourceRole': 'user',
            },
            role: 'agent',
          );
        }
        final directText =
            content is String ? content : message?['content']?.toString();
        if (directText == null || directText.trim().isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: '$id:output:$outputType',
            createdAt: createdAt,
            text: directText,
            metadata: {
              ...baseMetadata,
              if (outputType == 'user') 'sourceRole': 'user',
            },
          ),
        ];
      default:
        final message = _asStringMap(outputData['message']);
        final content = message?['content'];
        final parts = _normalizeAgentContentParts(content);
        if (parts.isNotEmpty) {
          return _reduceAgentContentParts(
            parts,
            baseId: id,
            createdAt: createdAt,
            meta: baseMetadata,
            role: 'agent',
          );
        }
        return const <ReducerMessage>[];
    }
  }

  List<ReducerMessage> _reduceAgentContentParts(
    List<Map<String, dynamic>> parts, {
    required String baseId,
    required DateTime createdAt,
    required Map<String, dynamic>? meta,
    required String role,
  }) {
    final messages = <ReducerMessage>[];

    for (var index = 0; index < parts.length; index++) {
      final part = parts[index];
      final partType = part['type']?.toString();
      switch (partType) {
        case 'text':
          final text = part['text']?.toString();
          if (text != null && text.isNotEmpty) {
            messages.add(
              _buildTextReducerMessage(
                id: '$baseId:text:$index',
                createdAt: createdAt,
                text: text,
                metadata: {
                  ...?meta,
                  'role': role,
                },
              ),
            );
          }
          break;
        case 'thinking':
          final thinking = part['thinking']?.toString();
          if (thinking != null && thinking.isNotEmpty) {
            messages.add(
              _buildTextReducerMessage(
                id: '$baseId:thinking:$index',
                createdAt: createdAt,
                text: thinking,
                metadata: {
                  ...?meta,
                  'role': role,
                  'outputType': 'thinking',
                },
              ),
            );
          }
          break;
        case 'tool_use':
        case 'tool-call':
          final toolId = part['id']?.toString() ??
              part['callId']?.toString() ??
              '$baseId:$index';
          messages.add(
            _buildToolReducerMessage(
              id: _toolMessageId(toolId),
              createdAt: createdAt,
              toolId: toolId,
              name: part['name']?.toString() ?? 'unknown',
              arguments:
                  _asStringMap(part['input']) ?? const <String, dynamic>{},
              status: ToolCallStatus.pending,
              metadata: meta,
              description: part['description']?.toString(),
            ),
          );
          break;
        case 'tool_result':
        case 'tool-call-result':
          final toolId = part['tool_use_id']?.toString() ??
              part['callId']?.toString() ??
              '$baseId:$index';
          final isError = part['is_error'] == true || part['isError'] == true;
          final permissions = _asStringMap(part['permissions']);
          messages.add(
            _buildToolReducerMessage(
              id: _toolMessageId(toolId),
              createdAt: createdAt,
              toolId: toolId,
              name: part['name']?.toString() ?? 'unknown',
              arguments: const <String, dynamic>{},
              status: isError || permissions?['result']?.toString() == 'denied'
                  ? ToolCallStatus.failed
                  : ToolCallStatus.completed,
              metadata: {
                ...?meta,
                if (permissions != null) 'permission': permissions,
              },
              result: _stringifyStructuredContent(
                part.containsKey('content') ? part['content'] : part['output'],
              ),
              error: isError
                  ? _stringifyStructuredContent(
                      part.containsKey('content')
                          ? part['content']
                          : part['output'],
                    )
                  : null,
            ),
          );
          break;
        case 'summary':
          final summary = part['summary']?.toString();
          if (summary != null && summary.isNotEmpty) {
            messages.add(
              _buildTextReducerMessage(
                id: '$baseId:summary:$index',
                createdAt: createdAt,
                text: summary,
                metadata: {
                  ...?meta,
                  'role': role,
                },
              ),
            );
          }
          break;
        case 'sidechain':
          messages.add(
            _buildEventReducerMessage(
              id: '$baseId:sidechain:$index',
              createdAt: createdAt,
              text: '子任务分支',
              metadata: meta,
            ),
          );
          break;
      }
    }

    return messages;
  }

  List<Map<String, dynamic>> _normalizeAgentContentParts(dynamic content) {
    if (content is! List) {
      return const <Map<String, dynamic>>[];
    }
    return content.map(_asStringMap).whereType<Map<String, dynamic>>().toList();
  }

  ReducerMessage _buildTextReducerMessage({
    required String id,
    required DateTime createdAt,
    required String text,
    required Map<String, dynamic>? metadata,
  }) {
    return ReducerMessage(
      id: id,
      kind: 'text',
      createdAt: createdAt,
      text: text,
      metadata: metadata,
    );
  }

  ReducerMessage _buildEventReducerMessage({
    required String id,
    required DateTime createdAt,
    required String text,
    required Map<String, dynamic>? metadata,
  }) {
    return ReducerMessage(
      id: id,
      kind: 'agent-event',
      createdAt: createdAt,
      text: text,
      metadata: {
        ...?metadata,
        'role': 'agent',
      },
    );
  }

  ReducerMessage _buildToolReducerMessage({
    required String id,
    required DateTime createdAt,
    required String toolId,
    required String name,
    required Map<String, dynamic> arguments,
    required ToolCallStatus status,
    required Map<String, dynamic>? metadata,
    String? result,
    String? error,
    String? description,
  }) {
    return ReducerMessage(
      id: id,
      kind: 'tool-call',
      createdAt: createdAt,
      metadata: {
        ...?metadata,
        'role': 'agent',
      },
      tool: ToolInfo(
        id: toolId,
        name: name,
        arguments: arguments,
        status: status,
        result: result,
        error: error,
        description: description,
      ),
    );
  }

  String _toolMessageId(String toolId) => 'tool:$toolId';

  String? _stringifyStructuredContent(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      final trimmed = value.trimRight();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    if (value is List) {
      final textParts = <String>[];
      for (final entry in value) {
        final map = _asStringMap(entry);
        final text = map?['text']?.toString();
        if (text != null && text.isNotEmpty) {
          textParts.add(text);
        }
      }
      if (textParts.isNotEmpty) {
        return textParts.join('\n');
      }
      try {
        return const JsonEncoder.withIndent('  ').convert(value);
      } catch (_) {
        return value.toString();
      }
    }
    if (value is Map) {
      try {
        return const JsonEncoder.withIndent('  ').convert(value);
      } catch (_) {
        return value.toString();
      }
    }
    return value.toString();
  }

  String? _firstNonEmptyString(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  DateTime? _parseMessageDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      if (value.isEmpty) return null;
      final asInt = int.tryParse(value);
      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      }
      return DateTime.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic>? _decodeMaybeJsonMap(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
      return null;
    }
    try {
      final decoded = jsonDecode(trimmed);
      return _asStringMap(decoded);
    } catch (_) {
      return null;
    }
  }

  bool _looksLikeBase64(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return false;
    }
    return RegExp(r'^[A-Za-z0-9+/=_-]+$').hasMatch(normalized);
  }

  int? _parseSeq(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) {
      return value.toInt();
    }
    return null;
  }

  String _resolveSessionTitle({
    required String? path,
    required String? summary,
    required String? name,
    required String? title,
    required String fallback,
  }) {
    for (final candidate in [summary, name, title]) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    if (path != null && path.trim().isNotEmpty) {
      final segments = path.split('/').where((segment) => segment.isNotEmpty);
      if (segments.isNotEmpty) {
        return segments.last;
      }
    }
    return fallback;
  }

  String? _resolveLocalSessionMode({
    required String? preferred,
    required String? explicit,
    required String? metadataValue,
  }) {
    for (final candidate in [preferred, explicit, metadataValue]) {
      final normalized = _normalizeOptionalValue(candidate);
      if (normalized != null) {
        return normalized;
      }
    }
    return null;
  }

  String? _normalizeOptionalValue(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> _buildOutboundRawRecord({
    required Session session,
    required String text,
    Map<String, dynamic>? metadata,
  }) {
    final modeMeta = _resolveMessageModeMeta(session);
    return {
      'role': 'user',
      'content': {
        'type': 'text',
        'text': text,
      },
      'meta': {
        'sentFrom': _resolveSentFrom(),
        'permissionMode': modeMeta.$1,
        'model': modeMeta.$2,
        'fallbackModel': null,
        ...?metadata,
      },
    };
  }

  (String, String?) _resolveMessageModeMeta(Session session) {
    final sandbox = _asStringMap(session.metadata?['sandbox']);
    final sandboxEnabled = sandbox?['enabled'] == true;
    final permissionMode = session.permissionMode != null &&
            session.permissionMode!.isNotEmpty &&
            session.permissionMode != 'default'
        ? session.permissionMode!
        : (sandboxEnabled ? 'bypassPermissions' : 'default');
    final modelMode = session.modelMode != null &&
            session.modelMode!.isNotEmpty &&
            session.modelMode != 'default'
        ? session.modelMode
        : null;
    return (permissionMode, modelMode);
  }

  String _resolveSentFrom() {
    if (kIsWeb) {
      return 'web';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return 'mac';
    }
    return 'android';
  }

  Future<String> _encryptSessionMessage({
    required String sessionId,
    required Map<String, dynamic> rawRecord,
  }) async {
    final crypto = await CryptoService.instance;
    final sessionKey = _sessionDataKeys[sessionId];
    if (sessionKey != null) {
      return crypto.encryptHappyCoderAesGcmJson(rawRecord, sessionKey);
    }

    final secretKey = _accountSecret ?? await _tokenStorage.getSecretKey();
    if (secretKey != null && secretKey.isNotEmpty) {
      return crypto.encryptHappyCoderLegacyJson(rawRecord, secretKey);
    }

    throw Exception('Missing session encryption key');
  }

  Future<String> _encodeSessionMetadataPayload({
    required String sessionId,
    required Map<String, dynamic> metadata,
  }) async {
    final crypto = await CryptoService.instance;
    final sessionKey = _sessionDataKeys[sessionId];
    if (sessionKey != null) {
      return crypto.encryptHappyCoderAesGcmJson(metadata, sessionKey);
    }

    final secretKey = _accountSecret ?? await _tokenStorage.getSecretKey();
    if (secretKey != null && secretKey.isNotEmpty) {
      return crypto.encryptHappyCoderLegacyJson(metadata, secretKey);
    }

    return jsonEncode(metadata);
  }

  Future<void> _syncSessionMetadata({
    required String sessionId,
    Object? alias = _sessionOverrideSentinel,
    Object? permissionMode = _sessionOverrideSentinel,
    Object? modelMode = _sessionOverrideSentinel,
  }) async {
    final session = _repository.getSession(sessionId);
    if (session == null) {
      return;
    }

    final nextMetadata = Map<String, dynamic>.from(
      session.metadata ?? const <String, dynamic>{},
    );

    if (!identical(alias, _sessionOverrideSentinel)) {
      final normalizedAlias = _normalizeOptionalValue(alias as String?);
      if (normalizedAlias == null) {
        nextMetadata.remove('name');
        nextMetadata.remove('title');
      } else {
        nextMetadata['name'] = normalizedAlias;
        nextMetadata['title'] = normalizedAlias;
      }
    }

    if (!identical(permissionMode, _sessionOverrideSentinel)) {
      final normalizedPermissionMode =
          _normalizeOptionalValue(permissionMode as String?);
      if (normalizedPermissionMode == null) {
        nextMetadata.remove('currentOperatingModeCode');
      } else {
        nextMetadata['currentOperatingModeCode'] = normalizedPermissionMode;
      }
    }

    if (!identical(modelMode, _sessionOverrideSentinel)) {
      final normalizedModelMode = _normalizeOptionalValue(modelMode as String?);
      if (normalizedModelMode == null) {
        nextMetadata.remove('currentModelCode');
      } else {
        nextMetadata['currentModelCode'] = normalizedModelMode;
      }
    }

    final encodedMetadata = await _encodeSessionMetadataPayload(
      sessionId: sessionId,
      metadata: nextMetadata,
    );
    final expectedVersion = session.metadataVersion ?? 0;
    final response = await SocketRepository.instance.updateSessionMetadata(
      sessionId: sessionId,
      metadata: encodedMetadata,
      expectedVersion: expectedVersion,
    );
    final result = response['result']?.toString();
    if (result == 'version-mismatch') {
      await loadSessions(force: true);
      return;
    }
    if (result != null && result != 'success') {
      throw Exception('update-metadata failed: $result');
    }

    final nextVersion = _parseSeq(response['version']) ?? expectedVersion + 1;
    _repository.applySessions([
      session.copyWith(
        title: _resolveSessionTitle(
          path: nextMetadata['path']?.toString() ?? session.path,
          summary: _asStringMap(nextMetadata['summary'])?['text']?.toString(),
          name: nextMetadata['name']?.toString(),
          title: nextMetadata['title']?.toString(),
          fallback: session.title,
        ),
        metadata: nextMetadata,
        metadataVersion: nextVersion,
        permissionMode: _resolveLocalSessionMode(
          preferred: !identical(permissionMode, _sessionOverrideSentinel)
              ? permissionMode as String?
              : session.permissionMode,
          explicit: session.permissionMode,
          metadataValue: nextMetadata['currentOperatingModeCode']?.toString(),
        ),
        modelMode: _resolveLocalSessionMode(
          preferred: !identical(modelMode, _sessionOverrideSentinel)
              ? modelMode as String?
              : session.modelMode,
          explicit: session.modelMode,
          metadataValue: nextMetadata['currentModelCode']?.toString(),
        ),
      ),
    ]);
  }

  Future<void> _submitPermissionDecision({
    required String sessionId,
    required Map<String, dynamic> request,
  }) async {
    final encryptedRequest = await _encryptSessionRpcPayload(
      sessionId: sessionId,
      payload: request,
    );
    await SocketRepository.instance.sessionRpc(
      sessionId: sessionId,
      method: 'permission',
      encryptedParams: encryptedRequest,
    );
  }

  Future<dynamic> _callSessionRpcDecoded({
    required String sessionId,
    required String method,
    required Map<String, dynamic> payload,
  }) async {
    await _ensureSessionRpcContext(sessionId);
    final encryptedRequest = await _encryptSessionRpcPayload(
      sessionId: sessionId,
      payload: payload,
    );
    final response = await SocketRepository.instance.sessionRpc(
      sessionId: sessionId,
      method: method,
      encryptedParams: encryptedRequest,
    );
    return _decryptSessionRpcResult(
      sessionId: sessionId,
      payload: response['result'],
    );
  }

  Future<void> _ensureSessionRpcContext(String sessionId) async {
    if (_repository.getSession(sessionId) == null ||
        !_sessionDataKeys.containsKey(sessionId)) {
      await loadSessions(force: true);
    }
  }

  Future<void> _ensureMachineRpcContext(String machineId) async {
    if (_repository.getMachine(machineId) == null) {
      await loadMachines(force: true, allowFailure: true);
    }
    _accountSecret ??= await _tokenStorage.getSecretKey();
  }

  void _seedLocalSpawnedSession({
    required String sessionId,
    required String machineId,
    required String directory,
    required String agent,
    String? permissionMode,
    String? modelMode,
  }) {
    if (_repository.getSession(sessionId) != null) {
      return;
    }

    final machine = _repository.getMachine(machineId);
    final machineMetadata = machine?.metadata ?? const <String, dynamic>{};
    final resolvedPermissionMode = _resolveLocalSessionMode(
      preferred: permissionMode,
      explicit: null,
      metadataValue: null,
    );
    final resolvedModelMode = _resolveLocalSessionMode(
      preferred: modelMode,
      explicit: null,
      metadataValue: null,
    );
    final metadata = <String, dynamic>{
      'machineId': machineId,
      'path': directory,
      'flavor': agent,
      if ((machineMetadata['host']?.toString() ?? '').isNotEmpty)
        'host': machineMetadata['host'].toString()
      else if (machine != null)
        'host': machine.name,
      if ((machineMetadata['homeDir']?.toString() ?? '').isNotEmpty)
        'homeDir': machineMetadata['homeDir'].toString(),
      if ((machineMetadata['platform']?.toString() ?? '').isNotEmpty)
        'platform': machineMetadata['platform'].toString(),
      if ((machineMetadata['version']?.toString() ?? '').isNotEmpty)
        'version': machineMetadata['version'].toString(),
      if (resolvedPermissionMode != null)
        'currentOperatingModeCode': resolvedPermissionMode,
      if (resolvedModelMode != null) 'currentModelCode': resolvedModelMode,
    };
    final now = DateTime.now();
    final fallbackId =
        sessionId.length > 8 ? sessionId.substring(0, 8) : sessionId;

    _repository.applySessions([
      Session(
        id: sessionId,
        title: _resolveSessionTitle(
          path: directory,
          summary: null,
          name: null,
          title: null,
          fallback: '会话 $fallbackId',
        ),
        messages: const [],
        createdAt: now,
        updatedAt: now,
        active: true,
        tag: 'session',
        path: directory,
        metadata: metadata,
        permissionMode: resolvedPermissionMode,
        modelMode: resolvedModelMode,
      ),
    ]);
  }

  Future<dynamic> _decryptSessionRpcResult({
    required String sessionId,
    required dynamic payload,
  }) async {
    if (payload == null) {
      return null;
    }
    if (payload is! String || payload.trim().isEmpty) {
      return payload;
    }

    final crypto = await CryptoService.instance;
    final sessionKey = _sessionDataKeys[sessionId];
    if (sessionKey != null) {
      final decrypted =
          await crypto.decryptHappyCoderAesGcmJson(payload, sessionKey);
      if (decrypted != null) {
        return decrypted;
      }
    }

    final secretKey = _accountSecret ?? await _tokenStorage.getSecretKey();
    if (secretKey != null && secretKey.isNotEmpty) {
      final decrypted =
          await crypto.decryptHappyCoderLegacyJson(payload, secretKey);
      if (decrypted != null) {
        return decrypted;
      }
    }

    return _decodeMaybeJsonValue(payload) ?? payload;
  }

  Future<String> _encryptSessionRpcPayload({
    required String sessionId,
    required Map<String, dynamic> payload,
  }) async {
    final crypto = await CryptoService.instance;
    final sessionKey = _sessionDataKeys[sessionId];
    if (sessionKey != null) {
      return crypto.encryptHappyCoderAesGcmJson(payload, sessionKey);
    }

    final secretKey = _accountSecret ?? await _tokenStorage.getSecretKey();
    if (secretKey != null && secretKey.isNotEmpty) {
      return crypto.encryptHappyCoderLegacyJson(payload, secretKey);
    }

    throw Exception('Missing session encryption key');
  }

  dynamic _decodeMaybeJsonValue(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _cachePersistDebounce?.cancel();
    super.dispose();
  }
}
