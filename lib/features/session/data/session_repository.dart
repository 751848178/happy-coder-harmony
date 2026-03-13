import 'dart:convert';
import 'dart:async';

import '../domain/reducer.dart' as domain;
import '../domain/session_models.dart';
import '../../../shared/utils/extensions.dart';

/// 会话数据仓库
///
/// 处理会话的 CRUD 操作和状态管理
class SessionRepository {
  SessionRepository._();

  /// 会话存储
  final Map<String, Session> _sessions = {};

  /// 会话消息存储
  final Map<String, SessionMessages> _sessionMessages = {};

  /// 机器存储
  final Map<String, Machine> _machines = {};

  /// 状态变化流控制器
  final StreamController<SessionStateChange> _stateController =
      StreamController<SessionStateChange>.broadcast();

  /// 获取单例
  static final SessionRepository instance = SessionRepository._();

  /// 状态变化流
  Stream<SessionStateChange> get stateChanges => _stateController.stream;

  /// 获取所有会话
  List<Session> getAllSessions() {
    return _sessions.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// 获取活跃会话
  List<Session> getActiveSessions() {
    return _sessions.values.where((s) => s.active).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// 获取会话
  Session? getSession(String sessionId) {
    return _sessions[sessionId];
  }

  /// 获取会话消息
  SessionMessages? getSessionMessages(String sessionId) {
    return _sessionMessages[sessionId];
  }

  /// 应用会话列表
  void applySessions(List<Session> sessions) {
    var changedCount = 0;
    for (final session in sessions) {
      final existing = _sessions[session.id];
      if (existing != null &&
          jsonEncode(existing.toJson()) == jsonEncode(session.toJson())) {
        continue;
      }
      _sessions[session.id] = session;
      changedCount++;
    }
    if (changedCount == 0) {
      return;
    }
    _stateController.add(
      SessionStateChange(type: SessionChangeType.sessionsUpdated),
    );
  }

  /// 应用消息
  void applyMessages(String sessionId, List<domain.ReducerMessage> messages) {
    final existing = _sessionMessages[sessionId];

    if (existing == null) {
      // 首次加载
      final messagesMap = <String, domain.ReducerMessage>{};
      for (var m in messages) {
        messagesMap[m.id] = m;
      }

      _sessionMessages[sessionId] = SessionMessages(
        messages: messages,
        messagesMap: messagesMap,
        reducerState: domain.ReducerState.initial,
        isLoaded: true,
      );
    } else {
      // 更新现有消息
      final mergedMessagesMap = Map<String, domain.ReducerMessage>.from(
        existing.messagesMap,
      );
      for (var m in messages) {
        final localId = m.metadata?['localId']?.toString();
        if (localId != null && localId.isNotEmpty) {
          final optimisticMessageId =
              _findMessageIdByLocalId(mergedMessagesMap, localId);
          if (optimisticMessageId != null && optimisticMessageId != m.id) {
            mergedMessagesMap.remove(optimisticMessageId);
          }
        }
        final previous = mergedMessagesMap[m.id];
        mergedMessagesMap[m.id] = _mergeMessage(previous, m);
      }

      final messagesArray = mergedMessagesMap.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _sessionMessages[sessionId] = SessionMessages(
        messages: messagesArray,
        messagesMap: mergedMessagesMap,
        reducerState: existing.reducerState,
        isLoaded: existing.isLoaded,
      );
    }
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.messagesUpdated,
        sessionId: sessionId,
      ),
    );
    Logger.info('Applied ${messages.length} messages to session: $sessionId');
  }

  String? _findMessageIdByLocalId(
    Map<String, domain.ReducerMessage> messagesMap,
    String localId,
  ) {
    if (messagesMap.containsKey(localId)) {
      return localId;
    }
    for (final entry in messagesMap.entries) {
      final candidate = entry.value.metadata?['localId']?.toString();
      if (candidate == localId) {
        return entry.key;
      }
    }
    return null;
  }

  domain.ReducerMessage _mergeMessage(
    domain.ReducerMessage? previous,
    domain.ReducerMessage incoming,
  ) {
    if (previous == null) {
      return incoming;
    }

    if (previous.isToolCall &&
        incoming.isToolCall &&
        previous.tool != null &&
        incoming.tool != null &&
        previous.tool!.id == incoming.tool!.id) {
      final previousStatus =
          previous.tool!.status ?? domain.ToolCallStatus.pending;
      final incomingStatus =
          incoming.tool!.status ?? domain.ToolCallStatus.pending;

      final mergedStatus =
          _resolveMergedToolStatus(previousStatus, incomingStatus);
      return previous.copyWith(
        createdAt: previous.createdAt,
        metadata: {
          ...?previous.metadata,
          ...?incoming.metadata,
        },
        tool: previous.tool!.copyWith(
          name: _resolveToolName(previous.tool!.name, incoming.tool!.name),
          arguments: {
            ...previous.tool!.arguments,
            ...incoming.tool!.arguments,
          },
          status: mergedStatus,
          result: incoming.tool!.result ?? previous.tool!.result,
          error: incoming.tool!.error ?? previous.tool!.error,
          description: incoming.tool!.description ?? previous.tool!.description,
        ),
      );
    }

    return incoming;
  }

  domain.ToolCallStatus _resolveMergedToolStatus(
    domain.ToolCallStatus previous,
    domain.ToolCallStatus incoming,
  ) {
    if (previous != domain.ToolCallStatus.pending &&
        incoming == domain.ToolCallStatus.pending) {
      return previous == domain.ToolCallStatus.approved
          ? domain.ToolCallStatus.executing
          : previous;
    }

    const terminalStatuses = <domain.ToolCallStatus>{
      domain.ToolCallStatus.completed,
      domain.ToolCallStatus.failed,
      domain.ToolCallStatus.rejected,
    };
    if (terminalStatuses.contains(previous) &&
        !terminalStatuses.contains(incoming)) {
      return previous;
    }
    return incoming;
  }

  String _resolveToolName(String previous, String incoming) {
    if (incoming.isEmpty || incoming == 'unknown') {
      return previous;
    }
    return incoming;
  }

  /// 应用 Agent 状态
  void applyAgentState(String sessionId, Map<String, dynamic>? agentState) {
    final existing = _sessionMessages[sessionId];
    if (existing == null) {
      // 首次加载 - 创建基础消息
      _sessionMessages[sessionId] = SessionMessages(
        messages: const [],
        messagesMap: const {},
        reducerState: domain.ReducerState.initial,
        isLoaded: true,
      );
    } else {
      // 更新现有状态 - 不改变消息列表
      _sessionMessages[sessionId] = SessionMessages(
        messages: existing.messages,
        messagesMap: existing.messagesMap,
        reducerState: existing.reducerState,
        isLoaded: existing.isLoaded,
      );
    }
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.agentStateUpdated,
        sessionId: sessionId,
      ),
    );
    Logger.info('Applied agent state to session: $sessionId');
  }

  /// 批准工具调用
  void approveToolCall(String sessionId, String toolId) {
    final existing = _sessionMessages[sessionId];
    if (existing == null) return;

    final updatedMessages = <domain.ReducerMessage>[];
    for (final msg in existing.messages) {
      if (msg.tool != null && msg.tool!.id == toolId) {
        updatedMessages.add(msg.copyWith(
          tool: msg.tool!.copyWith(
            status: domain.ToolCallStatus.approved,
          ),
        ));
      } else {
        updatedMessages.add(msg);
      }
    }

    final updatedMessagesMap = {
      for (final message in updatedMessages) message.id: message,
    };

    _sessionMessages[sessionId] = SessionMessages(
      messages: updatedMessages,
      messagesMap: updatedMessagesMap,
      reducerState: existing.reducerState,
      isLoaded: existing.isLoaded,
    );

    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.toolCallApproved,
        sessionId: sessionId,
        toolId: toolId,
      ),
    );
  }

  /// 拒绝工具调用
  void rejectToolCall(String sessionId, String toolId, {String? reason}) {
    final existing = _sessionMessages[sessionId];
    if (existing == null) return;

    final updatedMessages = <domain.ReducerMessage>[];
    for (final msg in existing.messages) {
      if (msg.tool != null && msg.tool!.id == toolId) {
        updatedMessages.add(msg.copyWith(
          tool: msg.tool!.copyWith(
            status: domain.ToolCallStatus.rejected,
            error: reason ?? 'Rejected by user',
          ),
        ));
      } else {
        updatedMessages.add(msg);
      }
    }

    final updatedMessagesMap = {
      for (final message in updatedMessages) message.id: message,
    };

    _sessionMessages[sessionId] = SessionMessages(
      messages: updatedMessages,
      messagesMap: updatedMessagesMap,
      reducerState: existing.reducerState,
      isLoaded: existing.isLoaded,
    );

    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.toolCallRejected,
        sessionId: sessionId,
        toolId: toolId,
      ),
    );
  }

  /// 添加会话草稿
  void updateSessionDraft(String sessionId, String? draft) {
    final existing = _sessions[sessionId];
    if (existing == null) return;

    _sessions[sessionId] = existing.copyWith(draft: draft);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.draftUpdated,
        sessionId: sessionId,
      ),
    );
  }

  /// 更新会话权限模式
  void updateSessionPermissionMode(String sessionId, String mode) {
    final existing = _sessions[sessionId];
    if (existing == null) return;

    _sessions[sessionId] = existing.copyWith(permissionMode: mode);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.permissionModeUpdated,
        sessionId: sessionId,
      ),
    );
  }

  /// 更新会话模型模式
  void updateSessionModelMode(String sessionId, String mode) {
    final existing = _sessions[sessionId];
    if (existing == null) return;

    _sessions[sessionId] = existing.copyWith(modelMode: mode);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.modelModeUpdated,
        sessionId: sessionId,
      ),
    );
  }

  /// 删除会话
  void deleteSession(String sessionId) {
    _sessions.remove(sessionId);
    _sessionMessages.remove(sessionId);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.sessionDeleted,
        sessionId: sessionId,
      ),
    );
    Logger.info('Deleted session: $sessionId');
  }

  /// 清空会话消息
  void clearSessionMessages(String sessionId) {
    final existing = _sessionMessages[sessionId];
    if (existing != null) {
      _sessionMessages[sessionId] = SessionMessages(
        messages: const [],
        messagesMap: const {},
        reducerState: existing.reducerState,
        isLoaded: existing.isLoaded,
      );
      _stateController.add(
        SessionStateChange(
          type: SessionChangeType.messagesUpdated,
          sessionId: sessionId,
        ),
      );
      Logger.info('Cleared messages for session: $sessionId');
    }
  }

  void removeMessage(String sessionId, String messageId) {
    final existing = _sessionMessages[sessionId];
    if (existing == null) {
      return;
    }

    final nextMessagesMap = Map<String, domain.ReducerMessage>.from(
      existing.messagesMap,
    );
    var removed = nextMessagesMap.remove(messageId) != null;
    if (!removed) {
      final optimisticMessageId = _findMessageIdByLocalId(
        nextMessagesMap,
        messageId,
      );
      if (optimisticMessageId != null) {
        nextMessagesMap.remove(optimisticMessageId);
        removed = true;
      }
    }
    if (!removed) {
      return;
    }

    final nextMessages = nextMessagesMap.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    _sessionMessages[sessionId] = SessionMessages(
      messages: nextMessages,
      messagesMap: nextMessagesMap,
      reducerState: existing.reducerState,
      isLoaded: existing.isLoaded,
    );
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.messagesUpdated,
        sessionId: sessionId,
      ),
    );
  }

  /// 应用机器列表
  void applyMachines(List<Machine> machines, {bool replace = false}) {
    var changed = false;
    if (replace) {
      final nextIds = machines.map((machine) => machine.id).toSet();
      final staleIds = _machines.keys
          .where((machineId) => !nextIds.contains(machineId))
          .toList();
      for (final staleId in staleIds) {
        _machines.remove(staleId);
        changed = true;
      }
    }

    for (final machine in machines) {
      final existing = _machines[machine.id];
      if (existing != null &&
          jsonEncode(existing.toJson()) == jsonEncode(machine.toJson())) {
        continue;
      }
      _machines[machine.id] = machine;
      changed = true;
    }

    if (!changed) {
      return;
    }

    _stateController.add(
      SessionStateChange(type: SessionChangeType.machinesUpdated),
    );
    Logger.info('Applied ${machines.length} machines');
  }

  /// 获取机器
  Machine? getMachine(String machineId) {
    return _machines[machineId];
  }

  /// 获取所有机器
  List<Machine> getAllMachines() {
    return _machines.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 获取所有会话 Map（内部使用）
  Map<String, Session> get sessionsMap => Map.from(_sessions);

  /// 获取所有消息 Map（内部使用）
  Map<String, SessionMessages> get sessionMessagesMap =>
      Map.from(_sessionMessages);

  /// 获取所有机器 Map（内部使用）
  Map<String, Machine> get machinesMap => Map.from(_machines);

  /// 清空所有数据
  void clearAll() {
    _sessions.clear();
    _sessionMessages.clear();
    _machines.clear();
    _stateController.add(
      SessionStateChange(type: SessionChangeType.cleared),
    );
    Logger.info('Cleared all session data');
  }

  /// 释放资源
  void dispose() {
    _stateController.close();
  }
}

/// 会话消息
class SessionMessages {
  final List<domain.ReducerMessage> messages;
  final Map<String, domain.ReducerMessage> messagesMap;
  final domain.ReducerState reducerState;
  final bool isLoaded;

  SessionMessages({
    required this.messages,
    required this.messagesMap,
    required this.reducerState,
    this.isLoaded = false,
  });
}

/// 会话状态变化
class SessionStateChange {
  final SessionChangeType type;
  final String? sessionId;
  final String? toolId;

  SessionStateChange({
    required this.type,
    this.sessionId,
    this.toolId,
  });
}

/// 会话变化类型
enum SessionChangeType {
  sessionsUpdated,
  messagesUpdated,
  agentStateUpdated,
  toolCallApproved,
  toolCallRejected,
  draftUpdated,
  permissionModeUpdated,
  modelModeUpdated,
  sessionDeleted,
  machinesUpdated,
  cleared,
}
