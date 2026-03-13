import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../domain/socket_service.dart';
import '../../session/data/session_repository.dart';
import '../../session/domain/session_models.dart';
import '../../auth/data/token_storage_service.dart';
import '../../encryption/domain/crypto_service.dart';
import '../../../shared/utils/extensions.dart';
import '../../../core/config/app_config.dart';
import '../../../harmony/harmony_bridge.dart';

/// 工具调用请求
class ToolCallRequest {
  final String id;
  final String sessionId;
  final String toolName;
  final String? toolDescription;
  final Map<String, dynamic>? parameters;

  const ToolCallRequest({
    required this.id,
    required this.sessionId,
    required this.toolName,
    this.toolDescription,
    this.parameters,
  });
}

/// Socket.IO 数据仓库
///
/// 处理与 Socket.IO 服务器的连接和通信
class SocketRepository {
  SocketRepository._();

  static final SocketRepository instance = SocketRepository._();

  io.Socket? _socket;
  Completer<void>? _connectionCompleter;

  String? _token;
  final SessionRepository _sessionRepository = SessionRepository.instance;
  final TokenStorageService _tokenStorage = TokenStorageService.instance;

  /// 消息流控制器
  final StreamController<SocketMessage> _messageController =
      StreamController<SocketMessage>.broadcast();

  /// 事件流控制器
  final StreamController<SocketEvent> _eventController =
      StreamController<SocketEvent>.broadcast();

  /// 工具调用请求流控制器
  final StreamController<ToolCallRequest> _toolCallRequestController =
      StreamController<ToolCallRequest>.broadcast();

  /// 消息去重集合
  final Set<String> _deduplicationSet = {};

  /// 去重清理定时器
  Timer? _deduplicationTimer;

  /// 心跳定时器
  Timer? _heartbeatTimer;

  /// 重连定时器
  Timer? _reconnectTimer;

  /// 重连尝试次数
  int _reconnectAttempts = 0;

  /// 会话 activity 更新节流时间
  final Map<String, DateTime> _lastEphemeralSessionApplyAt = {};

  /// 最大重连次数
  static const int _maxReconnectAttempts = 10;

  /// 消息流
  Stream<SocketMessage> get messageStream => _messageController.stream;

  /// 事件流
  Stream<SocketEvent> get eventStream => _eventController.stream;

  /// 工具调用请求流
  Stream<ToolCallRequest> get toolCallRequestStream =>
      _toolCallRequestController.stream;

  /// 连接状态
  SocketConnectionState get connectionState {
    if (_socket == null) return SocketConnectionState.disconnected;
    switch (_socket!.connected) {
      case true:
        return SocketConnectionState.connected;
      case false:
        return SocketConnectionState.disconnected;
    }
  }

  /// Socket ID
  String? get socketId => _socket?.id;

  /// 初始化 Socket 连接
  Future<void> initialize({
    required String machineId,
    required String token,
  }) async {
    final tokenChanged = _token != null && _token != token;
    _token = token;

    if (_socket != null) {
      if (_socket!.connected && !tokenChanged) {
        return;
      }

      if (tokenChanged) {
        await disconnect();
      } else {
        _prepareConnectionCompleter();
        _socket!.connect();
        await _awaitConnection();
        return;
      }
    }

    await _connect(waitForReady: true);
  }

  Future<void> ensureConnected({
    required String token,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final tokenChanged = _token != null && _token != token;
    _token = token;

    if (_socket != null) {
      if (_socket!.connected && !tokenChanged) {
        return;
      }
      if (tokenChanged) {
        await disconnect();
      } else {
        _prepareConnectionCompleter();
        _socket!.connect();
        await _awaitConnection(timeout: timeout);
        return;
      }
    }

    await _connect(waitForReady: true, timeout: timeout);
  }

  /// 连接到服务器
  Future<void> _connect({
    bool waitForReady = false,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      _eventController.add(SocketEvent.connecting());
      _prepareConnectionCompleter();

      _socket = io.io(
        AppConfig.socketUrl,
        io.OptionBuilder()
            .setPath(AppConfig.socketPath)
            .setTransports(AppConfig.socketTransports)
            .setAuth({
              'token': _token,
              'clientType': 'user-scoped',
            })
            .enableAutoConnect()
            .setReconnectionAttempts(_maxReconnectAttempts)
            .setReconnectionDelay(AppConfig.socketReconnectDelay)
            .setTimeout(AppConfig.socketTimeout)
            .build(),
      );

      _setupSocketListeners();

      _socket!.connect();

      _startDeduplicationTimer();

      if (waitForReady) {
        await _awaitConnection(timeout: timeout);
      }

      Logger.info('Socket connect requested');
    } catch (e) {
      Logger.error('Socket connection error: $e');
      _eventController.add(SocketEvent.error('连接失败: ${e.toString()}'));
      _scheduleReconnect();
    }
  }

  /// 设置 Socket 事件监听器
  void _setupSocketListeners() {
    if (_socket == null) return;

    // 连接成功
    _socket!.on('connect', (_) {
      Logger.info('Socket connected');
      final pendingConnection = _connectionCompleter;
      if (pendingConnection != null && !pendingConnection.isCompleted) {
        pendingConnection.complete();
      }
      _reconnectAttempts = 0;
      _startHeartbeatTimer();
      _eventController.add(SocketEvent.connected(_socket?.id ?? ''));
    });

    // 断开连接
    _socket!.on('disconnect', (reason) {
      Logger.warning('Socket disconnected: $reason');
      _eventController.add(SocketEvent.disconnected(reason?.toString()));
      _scheduleReconnect();
    });

    // 连接错误
    _socket!.on('connect_error', (error) {
      Logger.error('Socket connect error: $error');
      _eventController.add(SocketEvent.error(error.toString()));
    });

    // 收到历史兼容消息
    _socket!.on('message', (data) {
      _handleIncomingMessage(data);
    });

    // 收到服务器消息
    _socket!.on('server_message', (data) {
      _handleIncomingMessage(data, type: SocketMessageType.server);
    });

    // 工具调用请求
    _socket!.on('tool_call_request', (data) {
      _handleToolCallRequest(data);
    });

    _socket!.on('update', (data) {
      _handleUpdatePayload(data);
    });

    _socket!.on('ephemeral', (data) {
      _handleEphemeralPayload(data);
    });

    // 错误消息
    _socket!.on('error', (data) {
      Logger.error('Socket error: $data');
      _eventController.add(SocketEvent.error(data.toString()));
    });

    // 心跳响应
    _socket!.on('pong', (data) {
      Logger.debug('Heartbeat received');
    });
  }

  /// 处理收到的消息
  void _handleIncomingMessage(dynamic data,
      {SocketMessageType type = SocketMessageType.user}) {
    try {
      if (data == null || data is! Map) return;

      final messageData = data as Map<String, dynamic>;
      final messageId = messageData['id'] as String?;

      if (messageId == null) return;

      // 消息去重
      if (_deduplicationSet.contains(messageId)) {
        Logger.debug('Duplicate message ignored: $messageId');
        return;
      }

      // 添加到去重集合
      _deduplicationSet.add(messageId);

      final message = SocketMessage(
        id: messageId,
        type: type,
        content: messageData['content'] as String? ?? '',
        sessionId: messageData['sessionId'] as String?,
        metadata: messageData['metadata'] as Map<String, dynamic>?,
        timestamp: messageData['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                messageData['timestamp'] as int,
              )
            : DateTime.now(),
      );

      _messageController.add(message);
      _eventController.add(SocketEvent.messageReceived(message));
    } catch (e) {
      Logger.error('Failed to handle incoming message: $e');
    }
  }

  void _handleUpdatePayload(dynamic data) {
    try {
      final payload = _asStringMap(data);
      final body = _asStringMap(payload?['body']);
      final updateType = body?['t'] as String?;

      switch (updateType) {
        case 'new-session':
          final sessionJson = <String, dynamic>{
            'id': body?['id'] ?? body?['sessionId'],
            'seq': body?['seq'],
            'createdAt': body?['createdAt'] ?? payload?['createdAt'],
            'updatedAt': body?['updatedAt'] ?? payload?['createdAt'],
            'active': body?['active'],
            'activeAt': body?['activeAt'],
            'metadata': body?['metadata'],
            'metadataVersion': body?['metadataVersion'],
            'agentState': body?['agentState'],
            'agentStateVersion': body?['agentStateVersion'],
            'dataEncryptionKey': body?['dataEncryptionKey'],
          };
          _sessionRepository.applySessions([Session.fromJson(sessionJson)]);
          break;
        case 'update-session':
          final sessionId = body?['id'] as String?;
          if (sessionId == null) {
            return;
          }
          final existing = _sessionRepository.getSession(sessionId);
          if (existing == null) {
            return;
          }
          final metadataUpdate = _asStringMap(body?['metadata']);
          final agentStateUpdate = _asStringMap(body?['agentState']);
          final nextMetadata = _decodeMaybeJsonMap(metadataUpdate?['value']) ??
              existing.metadata;
          final nextAgentState =
              _decodeMaybeJsonMap(agentStateUpdate?['value']) ??
                  existing.agentState;
          final nextTitle = nextMetadata?['name']?.toString() ??
              nextMetadata?['title']?.toString() ??
              existing.title;
          _sessionRepository.applySessions([
            existing.copyWith(
              title: nextTitle,
              metadata: nextMetadata,
              metadataVersion: metadataUpdate?['version'] as int? ??
                  existing.metadataVersion,
              agentState: nextAgentState,
              agentStateVersion: agentStateUpdate?['version'] as int? ??
                  existing.agentStateVersion,
              updatedAt:
                  _parseDateTime(payload?['createdAt']) ?? existing.updatedAt,
            ),
          ]);
          break;
        case 'delete-session':
          final sessionId = body?['sid'] as String?;
          if (sessionId != null) {
            _sessionRepository.deleteSession(sessionId);
          }
          break;
        case 'new-message':
          final sessionId = body?['sid'] as String?;
          final messageJson = _asStringMap(body?['message']);
          if (sessionId == null || messageJson == null) {
            return;
          }
          final socketMessage = SocketMessage(
            id: messageJson['id']?.toString() ??
                payload?['id']?.toString() ??
                '',
            type: SocketMessageType.server,
            content: '',
            sessionId: sessionId,
            metadata: const {'source': 'new-message'},
            timestamp:
                _parseDateTime(messageJson['createdAt']) ?? DateTime.now(),
          );
          _messageController.add(socketMessage);
          _eventController.add(SocketEvent.messageReceived(socketMessage));
          break;
      }
    } catch (e) {
      Logger.error('Failed to handle update payload: $e');
    }
  }

  void _handleEphemeralPayload(dynamic data) {
    try {
      final payload = _asStringMap(data);
      final eventType = payload?['type'] as String?;
      if (eventType != 'activity') {
        return;
      }

      final sessionId = payload?['id'] as String?;
      if (sessionId == null) {
        return;
      }

      final existing = _sessionRepository.getSession(sessionId);
      if (existing == null) {
        return;
      }

      final activeAt =
          _parseDateTime(payload?['activeAt']) ?? existing.activeAt;
      final thinking = payload?['thinking'] as bool?;
      final nextActive = payload?['active'] as bool? ?? existing.active;
      final nextThinking = thinking ?? existing.thinking;
      final nextThinkingAt = thinking == true ? activeAt : existing.thinkingAt;
      final lastAppliedAt = _lastEphemeralSessionApplyAt[sessionId];
      final onlyHeartbeatAdvance = existing.active == nextActive &&
          existing.thinking == nextThinking &&
          existing.activeAt != null &&
          activeAt != null &&
          activeAt.isAfter(existing.activeAt!);

      if (existing.active == nextActive &&
          existing.activeAt == activeAt &&
          existing.thinking == nextThinking &&
          existing.thinkingAt == nextThinkingAt) {
        return;
      }

      if (onlyHeartbeatAdvance &&
          lastAppliedAt != null &&
          DateTime.now().difference(lastAppliedAt) <
              const Duration(seconds: 2)) {
        return;
      }

      _lastEphemeralSessionApplyAt[sessionId] = DateTime.now();

      _sessionRepository.applySessions([
        existing.copyWith(
          active: nextActive,
          activeAt: activeAt,
          thinking: nextThinking,
          thinkingAt: nextThinkingAt,
        ),
      ]);
    } catch (e) {
      Logger.error('Failed to handle ephemeral payload: $e');
    }
  }

  /// 处理工具调用请求
  void _handleToolCallRequest(dynamic data) {
    try {
      if (data == null || data is! Map) return;

      final toolData = data as Map<String, dynamic>;
      final toolId = toolData['id'] as String?;
      final sessionId = toolData['sessionId'] as String?;
      final toolName = toolData['name'] as String? ?? 'unknown';
      final toolDescription = toolData['description'] as String?;
      final parameters = toolData['parameters'] as Map<String, dynamic>?;

      if (toolId == null || sessionId == null) return;

      Logger.info(
          'Tool call request: $toolId ($toolName) for session: $sessionId');

      // 发送工具调用请求到流，UI 可以监听此流并显示权限对话框
      final request = ToolCallRequest(
        id: toolId,
        sessionId: sessionId,
        toolName: toolName,
        toolDescription: toolDescription,
        parameters: parameters,
      );
      _toolCallRequestController.add(request);
    } catch (e) {
      Logger.error('Failed to handle tool call request: $e');
    }
  }

  /// 发送消息
  Future<void> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }

    final messageId = StringExtension.generateId();

    final messageData = {
      'sid': sessionId,
      'message': content,
      'localId': messageId,
    };

    _socket!.emit('message', messageData);
    Logger.debug('Message sent: $messageId');
  }

  /// 批准工具调用
  Future<void> approveToolCall({
    required String sessionId,
    required String toolId,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }
    throw UnimplementedError(
      'Use sessionRpc(permission) instead: $sessionId/$toolId',
    );
  }

  /// 拒绝工具调用
  Future<void> rejectToolCall({
    required String sessionId,
    required String toolId,
    String? reason,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }
    throw UnimplementedError(
      'Use sessionRpc(permission) instead: $sessionId/$toolId/$reason',
    );
  }

  Future<Map<String, dynamic>> updateSessionMetadata({
    required String sessionId,
    required String metadata,
    required int expectedVersion,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }

    final completer = Completer<Map<String, dynamic>>();
    _socket!.emitWithAck(
      'update-metadata',
      {
        'sid': sessionId,
        'metadata': metadata,
        'expectedVersion': expectedVersion,
      },
      ack: (dynamic response) {
        final responseMap = _asStringMap(response);
        if (responseMap == null) {
          completer.completeError(Exception('Invalid metadata response'));
          return;
        }
        completer.complete(responseMap);
      },
    );
    return completer.future;
  }

  Future<Map<String, dynamic>> sessionRpc({
    required String sessionId,
    required String method,
    required String encryptedParams,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }

    final completer = Completer<Map<String, dynamic>>();
    _socket!.emitWithAck(
      'rpc-call',
      {
        'method': '$sessionId:$method',
        'params': encryptedParams,
      },
      ack: (dynamic response) {
        final responseMap = _asStringMap(response);
        if (responseMap == null) {
          completer.completeError(Exception('Invalid RPC response'));
          return;
        }
        completer.complete(responseMap);
      },
    );

    final responseMap = await completer.future;
    if (responseMap['ok'] != true) {
      throw Exception(responseMap['error']?.toString() ?? 'RPC call failed');
    }
    return responseMap;
  }

  Future<dynamic> machineRpc({
    required String machineId,
    required String method,
    required Map<String, dynamic> payload,
    Uint8List? dataEncryptionKey,
    String? accountSecret,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }

    final encryptedParams = await _encryptMachineRpcPayload(
      payload: payload,
      dataEncryptionKey: dataEncryptionKey,
      accountSecret: accountSecret,
    );

    final completer = Completer<Map<String, dynamic>>();
    _socket!.emitWithAck(
      'rpc-call',
      {
        'method': '$machineId:$method',
        'params': encryptedParams,
      },
      ack: (dynamic response) {
        final responseMap = _asStringMap(response);
        if (responseMap == null) {
          completer.completeError(Exception('Invalid machine RPC response'));
          return;
        }
        completer.complete(responseMap);
      },
    );

    final responseMap = await completer.future;
    if (responseMap['ok'] != true) {
      throw Exception(
        responseMap['error']?.toString() ?? 'Machine RPC call failed',
      );
    }

    final encryptedResult = responseMap['result'];
    if (encryptedResult is! String || encryptedResult.isEmpty) {
      return encryptedResult;
    }

    return _decryptMachineRpcPayload(
      encryptedPayload: encryptedResult,
      dataEncryptionKey: dataEncryptionKey,
      accountSecret: accountSecret,
    );
  }

  Future<String> _encryptMachineRpcPayload({
    required Map<String, dynamic> payload,
    Uint8List? dataEncryptionKey,
    String? accountSecret,
  }) async {
    final crypto = await CryptoService.instance;
    if (dataEncryptionKey != null) {
      return crypto.encryptHappyCoderAesGcmJson(payload, dataEncryptionKey);
    }

    if (accountSecret != null && accountSecret.isNotEmpty) {
      return crypto.encryptHappyCoderLegacyJson(payload, accountSecret);
    }

    final machineKey = await _tokenStorage.getMachineKey();
    if (machineKey == null || machineKey.isEmpty) {
      throw Exception('Missing machine encryption key');
    }

    final encrypted = await HarmonyBridge.encrypt(jsonEncode(payload), machineKey);
    if (encrypted == null || encrypted.isEmpty) {
      throw Exception('Failed to encrypt machine RPC payload');
    }
    return encrypted;
  }

  Future<dynamic> _decryptMachineRpcPayload({
    required String encryptedPayload,
    Uint8List? dataEncryptionKey,
    String? accountSecret,
  }) async {
    final crypto = await CryptoService.instance;
    if (dataEncryptionKey != null) {
      final decrypted =
          await crypto.decryptHappyCoderAesGcmJson(encryptedPayload, dataEncryptionKey);
      if (decrypted != null) {
        return decrypted;
      }
    }

    if (accountSecret != null && accountSecret.isNotEmpty) {
      final decrypted =
          await crypto.decryptHappyCoderLegacyJson(encryptedPayload, accountSecret);
      if (decrypted != null) {
        return decrypted;
      }
    }

    final machineKey = await _tokenStorage.getMachineKey();
    if (machineKey == null || machineKey.isEmpty) {
      throw Exception('Missing machine encryption key');
    }

    final decrypted = await HarmonyBridge.decrypt(encryptedPayload, machineKey);
    if (decrypted == null || decrypted.isEmpty) {
      throw Exception('Failed to decrypt machine RPC response');
    }

    try {
      return jsonDecode(decrypted);
    } catch (_) {
      return decrypted;
    }
  }

  /// 订阅会话
  void subscribeToSession(String sessionId) {
    Logger.info('Session subscription uses user-scoped socket: $sessionId');
  }

  /// 取消订阅会话
  void unsubscribeFromSession(String sessionId) {
    Logger.info('Session unsubscription uses user-scoped socket: $sessionId');
  }

  /// 发送心跳
  Future<void> sendHeartbeat() async {
    if (_socket == null || !_socket!.connected) {
      return;
    }

    _socket!.emit('ping', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 计划重连
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      Logger.error('Max reconnection attempts reached');
      _eventController.add(SocketEvent.error('连接失败，请检查网络'));
      return;
    }

    _reconnectAttempts++;

    final delay = AppConfig.socketReconnectDelay * _reconnectAttempts;

    Logger.info(
        'Scheduling reconnect in ${delay}ms (attempt $_reconnectAttempts)');

    _eventController.add(SocketEvent.reconnecting(_reconnectAttempts));

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      if (_socket != null && !_socket!.connected) {
        _connect();
      }
    });
  }

  /// 启动去重定时器
  void _startDeduplicationTimer() {
    _deduplicationTimer?.cancel();
    _deduplicationTimer = Timer.periodic(
      const Duration(milliseconds: AppConfig.deduplicationWindow),
      (_) {
        _deduplicationSet.clear();
      },
    );
  }

  /// 启动心跳定时器
  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: AppConfig.sessionHeartbeatInterval),
      (_) {
        sendHeartbeat();
      },
    );
  }

  /// 断开连接
  Future<void> disconnect() async {
    _deduplicationTimer?.cancel();
    _deduplicationTimer = null;

    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _deduplicationSet.clear();
    _lastEphemeralSessionApplyAt.clear();

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectionCompleter = null;

    _reconnectAttempts = 0;

    Logger.info('Socket disconnected');
  }

  void _prepareConnectionCompleter() {
    if (_connectionCompleter == null || _connectionCompleter!.isCompleted) {
      _connectionCompleter = Completer<void>();
    }
  }

  Future<void> _awaitConnection({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    _prepareConnectionCompleter();
    await _connectionCompleter!.future.timeout(
      timeout,
      onTimeout: () => throw Exception('Socket connection timed out'),
    );
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _messageController.close();
    _eventController.close();
    _toolCallRequestController.close();
  }
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

DateTime? _parseDateTime(dynamic value) {
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

Map<String, dynamic>? _decodeMaybeJsonMap(dynamic value) {
  final asMap = _asStringMap(value);
  if (asMap != null) {
    return asMap;
  }
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      return _asStringMap(decoded);
    } catch (_) {
      return null;
    }
  }
  return null;
}
