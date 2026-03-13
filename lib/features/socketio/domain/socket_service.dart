import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/socket_repository.dart';
import '../../../shared/utils/extensions.dart';

// Re-export ToolCallRequest for UI usage
export '../data/socket_repository.dart' show ToolCallRequest;

/// Socket 连接状态
enum SocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Socket 消息类型
enum SocketMessageType {
  /// 服务器消息
  server,

  /// 用户消息
  user,

  /// 系统消息
  system,

  /// 工具调用
  tool,

  /// 错误消息
  error,
}

/// Socket 消息
class SocketMessage {
  final String id;
  final SocketMessageType type;
  final String content;
  final String? sessionId;
  final Map<String, dynamic>? metadata;
  final DateTime? timestamp;

  const SocketMessage({
    required this.id,
    required this.type,
    required this.content,
    this.sessionId,
    this.metadata,
    this.timestamp,
  });

  factory SocketMessage.fromJson(Map<String, dynamic> json) {
    return SocketMessage(
      id: json['id'] as String? ?? '',
      type: json['type'] != null
          ? SocketMessageType.values.firstWhere(
              (e) => e.name == json['type'],
              orElse: () => SocketMessageType.user,
            )
          : SocketMessageType.user,
      content: json['content'] as String? ?? '',
      sessionId: json['sessionId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      if (sessionId != null) 'sessionId': sessionId,
      if (metadata != null) 'metadata': metadata,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }
}

/// Socket 连接事件
abstract class SocketEvent {
  static SocketEvent connecting() => _SocketConnectingEvent();
  static SocketEvent connected(String socketId) =>
      _SocketConnectedEvent(socketId);
  static SocketEvent disconnected([String? reason]) =>
      _SocketDisconnectedEvent(reason);
  static SocketEvent error(String message) => _SocketErrorEvent(message);
  static SocketEvent messageReceived(SocketMessage message) =>
      _SocketMessageReceivedEvent(message);
  static SocketEvent reconnecting(int attempt) =>
      _SocketReconnectingEvent(attempt);

  T when<T>({
    T Function()? connecting,
    required T Function(String socketId) connected,
    required T Function(String?) disconnected,
    required T Function(String message) error,
    required T Function(SocketMessage message) messageReceived,
    required T Function(int attempt) reconnecting,
  }) {
    if (this is _SocketConnectingEvent) {
      if (connecting != null) return connecting();
    }
    if (this is _SocketConnectedEvent) {
      return connected((this as _SocketConnectedEvent).socketId);
    }
    if (this is _SocketDisconnectedEvent) {
      return disconnected((this as _SocketDisconnectedEvent).reason);
    }
    if (this is _SocketErrorEvent) {
      return error((this as _SocketErrorEvent).message);
    }
    if (this is _SocketMessageReceivedEvent) {
      return messageReceived((this as _SocketMessageReceivedEvent).message);
    }
    if (this is _SocketReconnectingEvent) {
      return reconnecting((this as _SocketReconnectingEvent).attempt);
    }
    throw UnimplementedError('Unknown SocketEvent type');
  }
}

class _SocketConnectingEvent extends SocketEvent {
  _SocketConnectingEvent();
}

class _SocketConnectedEvent extends SocketEvent {
  final String socketId;

  _SocketConnectedEvent(this.socketId);
}

class _SocketDisconnectedEvent extends SocketEvent {
  final String? reason;

  _SocketDisconnectedEvent([this.reason]);
}

class _SocketErrorEvent extends SocketEvent {
  final String message;

  _SocketErrorEvent(this.message);
}

class _SocketMessageReceivedEvent extends SocketEvent {
  final SocketMessage message;

  _SocketMessageReceivedEvent(this.message);
}

class _SocketReconnectingEvent extends SocketEvent {
  final int attempt;

  _SocketReconnectingEvent(this.attempt);
}

/// Socket 状态
class SocketState {
  const SocketState._();

  static const SocketState initial = SocketState._();

  static SocketState connecting() => const _SocketConnectingState();
  static SocketState connected(String socketId) =>
      _SocketConnectedState(socketId);
  static SocketState reconnecting(int attempt) =>
      _SocketReconnectingState(attempt);
  static SocketState error(String message) => _SocketErrorState(message);

  T when<T>({
    required T Function() initial,
    required T Function() connecting,
    required T Function(String socketId) connected,
    required T Function(int attempt) reconnecting,
    required T Function(String message) error,
  }) {
    if (identical(this, SocketState.initial)) {
      return initial();
    }
    if (this is _SocketConnectingState) {
      return connecting();
    }
    if (this is _SocketConnectedState) {
      return connected((this as _SocketConnectedState).socketId);
    }
    if (this is _SocketReconnectingState) {
      return reconnecting((this as _SocketReconnectingState).attempt);
    }
    if (this is _SocketErrorState) {
      return error((this as _SocketErrorState).message);
    }
    throw UnimplementedError('Unknown SocketState type');
  }

  String? get socketId => this is _SocketConnectedState
      ? (this as _SocketConnectedState).socketId
      : null;

  bool get isConnected => this is _SocketConnectedState;
  bool get isConnecting => this is _SocketConnectingState;
}

class _SocketConnectingState extends SocketState {
  const _SocketConnectingState() : super._();
}

class _SocketConnectedState extends SocketState {
  @override
  final String socketId;

  const _SocketConnectedState(this.socketId) : super._();
}

class _SocketReconnectingState extends SocketState {
  final int attempt;

  const _SocketReconnectingState(this.attempt) : super._();
}

class _SocketErrorState extends SocketState {
  final String message;

  const _SocketErrorState(this.message) : super._();
}

/// Socket Notifier
///
/// 管理 Socket.IO 连接状态和消息收发
class SocketNotifier extends StateNotifier<SocketState> {
  SocketNotifier(this._repository) : super(SocketState.initial);

  final SocketRepository _repository;
  StreamSubscription<SocketEvent>? _eventSubscription;

  /// 初始化 Socket 连接
  Future<void> initialize({
    required String machineId,
    required String token,
  }) async {
    state = SocketState.connecting();

    try {
      _subscribeToEvents();
      await _repository.initialize(
        machineId: machineId,
        token: token,
      );
      Logger.info('Socket initialization started');
    } catch (e) {
      state = SocketState.error('初始化失败: ${e.toString()}');
      Logger.error('Socket initialize error: $e');
    }
  }

  /// 发送消息
  Future<void> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    if (_repository.connectionState != SocketConnectionState.connected) {
      Logger.warning('Cannot send message: socket not connected');
      return;
    }

    try {
      await _repository.sendMessage(
        sessionId: sessionId,
        content: content,
        metadata: metadata,
      );
      Logger.info('Message sent to session: $sessionId');
    } catch (e) {
      Logger.error('Failed to send message: $e');
    }
  }

  /// 发送工具确认
  Future<void> approveToolCall({
    required String sessionId,
    required String toolId,
  }) async {
    try {
      await _repository.approveToolCall(
        sessionId: sessionId,
        toolId: toolId,
      );
      Logger.info('Tool call approved: $toolId');
    } catch (e) {
      Logger.error('Failed to approve tool call: $e');
      rethrow;
    }
  }

  /// 拒绝工具调用
  Future<void> rejectToolCall({
    required String sessionId,
    required String toolId,
    String? reason,
  }) async {
    try {
      await _repository.rejectToolCall(
        sessionId: sessionId,
        toolId: toolId,
        reason: reason,
      );
      Logger.info('Tool call rejected: $toolId');
    } catch (e) {
      Logger.error('Failed to reject tool call: $e');
      rethrow;
    }
  }

  /// 订阅会话事件
  void subscribeToSession(String sessionId) {
    _repository.subscribeToSession(sessionId);
    Logger.info('Subscribed to session: $sessionId');
  }

  /// 取消订阅会话事件
  void unsubscribeFromSession(String sessionId) {
    _repository.unsubscribeFromSession(sessionId);
    Logger.info('Unsubscribed from session: $sessionId');
  }

  /// 发送心跳
  Future<void> sendHeartbeat() async {
    try {
      await _repository.sendHeartbeat();
    } catch (e) {
      Logger.error('Heartbeat failed: $e');
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      await _unsubscribeFromEvents();
      await _repository.disconnect();
      state = SocketState.initial;
      Logger.info('Socket disconnected');
    } catch (e) {
      Logger.error('Disconnect error: $e');
    }
  }

  /// 获取消息流
  Stream<SocketMessage> get messageStream => _repository.messageStream;

  /// 获取事件流
  Stream<SocketEvent> get eventStream => _repository.eventStream;

  /// 获取工具调用请求流
  Stream<ToolCallRequest> get toolCallRequestStream =>
      _repository.toolCallRequestStream;

  /// 订阅 Socket 事件
  void _subscribeToEvents() {
    _unsubscribeFromEvents();
    _eventSubscription = _repository.eventStream.listen((event) {
      event.when(
        connected: (socketId) {
          state = SocketState.connected(_repository.socketId ?? 'unknown');
        },
        disconnected: (reason) {
          state = SocketState.initial;
        },
        error: (message) {
          state = SocketState.error(message);
        },
        messageReceived: (message) {
          // 消息由消息流处理，这里只做日志
          Logger.debug('Message received: ${message.id}');
        },
        reconnecting: (attempt) {
          state = SocketState.reconnecting(attempt);
        },
      );
    });
  }

  /// 取消订阅 Socket 事件
  Future<void> _unsubscribeFromEvents() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  @override
  void dispose() {
    _unsubscribeFromEvents();
    super.dispose();
  }
}
