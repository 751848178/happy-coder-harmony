import 'dart:async';
import 'dart:convert';

import '../../socketio/domain/socket_service.dart';
import '../../socketio/data/socket_repository.dart';
import '../domain/reducer.dart';
import '../domain/session_service.dart';
import '../../../shared/utils/extensions.dart';

/// Socket.IO 与会话集成
///
/// 处理 Socket.IO 消息与会话状态的同步
class SocketIntegration {
  SocketIntegration._();

  static final SocketIntegration instance = SocketIntegration._();

  final SocketRepository _socketRepository = SocketRepository.instance;
  SessionServiceNotifier? _sessionService;

  StreamSubscription<SocketEvent>? _eventSubscription;
  StreamSubscription<SocketMessage>? _messageSubscription;

  String? _currentSessionId;

  /// 设置 SessionServiceNotifier
  void setSessionService(SessionServiceNotifier sessionService) {
    _sessionService = sessionService;
  }

  /// 初始化集成
  void initialize() {
    _subscribeToEvents();
    Logger.info('Socket-Session integration initialized');
  }

  /// 订阅 Socket.IO 事件
  void _subscribeToEvents() {
    // 订阅 Socket 事件
    _eventSubscription = _socketRepository.eventStream.listen((event) {
      event.when(
        connecting: () {
          Logger.info('Socket connecting...');
        },
        connected: (socketId) {
          _handleConnected();
        },
        disconnected: (reason) {
          _handleDisconnected(reason);
        },
        error: (message) {
          Logger.error('Socket error: $message');
        },
        messageReceived: (message) {
          _handleMessageReceived(message);
        },
        reconnecting: (attempt) {
          Logger.info('Socket reconnecting: attempt $attempt');
        },
      );
    });

    // 订阅 Socket 消息
    _messageSubscription = _socketRepository.messageStream.listen((message) {
      _handleMessageReceived(message);
    });
  }

  /// 处理连接成功
  void _handleConnected() {
    Logger.info('Socket connected, subscribing to sessions');

    // 订阅当前会话（如果有）
    if (_currentSessionId != null) {
      _socketRepository.subscribeToSession(_currentSessionId!);
    }
  }

  /// 处理断开连接
  void _handleDisconnected(String? reason) {
    Logger.warning('Socket disconnected: $reason');
  }

  /// 处理收到的消息
  void _handleMessageReceived(SocketMessage socketMessage) {
    // 将 Socket 消息转换为 Reducer 消息
    final reducerMessage = _convertToReducerMessage(socketMessage);

    // Socket 更新到达后，触发会话消息刷新。
    // 这里不能再调用 sendMessage，否则会把服务端消息重新发回服务端。
    if (reducerMessage != null && socketMessage.sessionId != null) {
      if (_sessionService != null) {
        _sessionService!.loadSessionMessages(socketMessage.sessionId!);
      }
    }
  }

  /// 设置当前会话
  void setCurrentSession(String sessionId) {
    _currentSessionId = sessionId;

    // 订阅会话事件
    _socketRepository.subscribeToSession(sessionId);

    Logger.info('Current session set to: $sessionId');
  }

  /// 清除当前会话
  void clearCurrentSession() {
    if (_currentSessionId != null) {
      _socketRepository.unsubscribeFromSession(_currentSessionId!);
      _currentSessionId = null;
    }

    Logger.info('Current session cleared');
  }

  /// 发送消息
  Future<void> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    await _socketRepository.sendMessage(
      sessionId: sessionId,
      content: content,
      metadata: metadata,
    );
  }

  /// 批准工具调用
  Future<void> approveToolCall({
    required String sessionId,
    required String toolId,
  }) async {
    if (_sessionService != null) {
      await _sessionService!.submitToolApproval(
        sessionId: sessionId,
        toolId: toolId,
      );
      return;
    }
    throw UnsupportedError('SessionService is not initialized');
  }

  /// 拒绝工具调用
  Future<void> rejectToolCall({
    required String sessionId,
    required String toolId,
    String? reason,
  }) async {
    if (_sessionService != null) {
      await _sessionService!.submitToolRejection(
        sessionId: sessionId,
        toolId: toolId,
        reason: reason,
      );
      return;
    }
    throw UnsupportedError('SessionService is not initialized');
  }

  /// 转换 Socket 消息为 Reducer 消息
  ReducerMessage? _convertToReducerMessage(SocketMessage socketMessage) {
    final messageId = socketMessage.id;
    final content = socketMessage.content;
    final timestamp = socketMessage.timestamp ?? DateTime.now();

    switch (socketMessage.type) {
      case SocketMessageType.user:
        return ReducerMessage(
          id: messageId,
          kind: 'text',
          createdAt: timestamp,
          text: content,
          metadata: socketMessage.metadata,
        );

      case SocketMessageType.server:
        // 服务器消息可能是 Agent 状态或系统消息
        return _parseServerMessage(
            messageId, content, timestamp, socketMessage.metadata);

      case SocketMessageType.system:
        return ReducerMessage(
          id: messageId,
          kind: 'text',
          createdAt: timestamp,
          text: content,
          metadata: socketMessage.metadata,
        );

      case SocketMessageType.tool:
        return _parseToolMessage(
            messageId, content, timestamp, socketMessage.metadata);

      case SocketMessageType.error:
        return ReducerMessage(
          id: messageId,
          kind: 'text',
          createdAt: timestamp,
          text: 'Error: $content',
          metadata: socketMessage.metadata,
        );
    }
  }

  /// 解析服务器消息
  ReducerMessage? _parseServerMessage(
    String id,
    String content,
    DateTime timestamp,
    Map<String, dynamic>? metadata,
  ) {
    try {
      // 尝试解析 JSON
      final json = jsonDecode(content) as Map<String, dynamic>?;

      if (json == null) {
        // 纯文本消息
        return ReducerMessage(
          id: id,
          kind: 'text',
          createdAt: timestamp,
          text: content,
          metadata: metadata,
        );
      }

      // 处理 Agent 状态更新
      final messageType = json['type'] as String?;

      switch (messageType) {
        case 'agent_thinking':
          return ReducerMessage(
            id: id,
            kind: 'agent-state',
            createdAt: timestamp,
            metadata: {
              'state': 'thinking',
              'content': json['content'] as String? ?? '',
              ...?metadata,
            },
          );
        case 'agent_processing':
          return ReducerMessage(
            id: id,
            kind: 'agent-state',
            createdAt: timestamp,
            metadata: {
              'state': 'processing',
              'content': json['content'] as String? ?? '',
              ...?metadata,
            },
          );
        case 'agent_complete':
          return ReducerMessage(
            id: id,
            kind: 'agent-state',
            createdAt: timestamp,
            metadata: {
              'state': 'complete',
              'content': json['content'] as String? ?? '',
              'result': json['result'],
              ...?metadata,
            },
          );
        case 'agent_error':
          return ReducerMessage(
            id: id,
            kind: 'agent-state',
            createdAt: timestamp,
            text: json['error'] as String? ?? 'An error occurred',
            metadata: {
              'state': 'error',
              'error': json['error'],
              ...?metadata,
            },
          );
        case 'tool_start':
          return ReducerMessage(
            id: id,
            kind: 'tool-start',
            createdAt: timestamp,
            metadata: {
              'tool': json['tool'],
              'status': 'running',
              ...?metadata,
            },
          );
        case 'tool_complete':
          return ReducerMessage(
            id: id,
            kind: 'tool-complete',
            createdAt: timestamp,
            metadata: {
              'tool': json['tool'],
              'status': 'complete',
              'result': json['result'],
              ...?metadata,
            },
          );
        case 'tool_error':
          return ReducerMessage(
            id: id,
            kind: 'tool-error',
            createdAt: timestamp,
            text: json['error'] as String? ?? 'Tool error',
            metadata: {
              'tool': json['tool'],
              'error': json['error'],
              ...?metadata,
            },
          );
        default:
          // 默认作为文本消息处理
          return ReducerMessage(
            id: id,
            kind: 'text',
            createdAt: timestamp,
            text: content,
            metadata: metadata,
          );
      }
    } catch (e) {
      Logger.error('Failed to parse server message: $e');
      return ReducerMessage(
        id: id,
        kind: 'text',
        createdAt: timestamp,
        text: content,
        metadata: metadata,
      );
    }
  }

  /// 解析工具消息
  ReducerMessage? _parseToolMessage(
    String id,
    String content,
    DateTime timestamp,
    Map<String, dynamic>? metadata,
  ) {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>?;

      if (json == null) {
        return null;
      }

      final toolName = json['name'] as String?;
      final toolArguments = json['arguments'] as Map<String, dynamic>? ?? {};
      final toolId = json['id'] as String?;

      if (toolId == null) {
        return null;
      }

      return ReducerMessage(
        id: id,
        kind: 'tool-call',
        createdAt: timestamp,
        tool: ToolInfo(
          id: toolId,
          name: toolName ?? 'unknown',
          arguments: toolArguments,
        ),
        metadata: metadata,
      );
    } catch (e) {
      Logger.error('Failed to parse tool message: $e');
      return null;
    }
  }

  /// 释放资源
  void dispose() {
    _eventSubscription?.cancel();
    _messageSubscription?.cancel();
    Logger.info('Socket-Session integration disposed');
  }
}
