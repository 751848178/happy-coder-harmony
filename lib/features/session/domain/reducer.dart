/// 工具调用状态
enum ToolCallStatus {
  pending,
  approved,
  rejected,
  executing,
  completed,
  failed,
}

/// 消息类型
enum MessageType {
  text,
  toolCall,
  permissionRequest,
  turnClose,
  agentEvent,
  error,
}

/// Reducer 消息
class ReducerMessage {
  final String id;
  final String kind;
  final DateTime createdAt;
  final String? text;
  final Map<String, dynamic>? metadata;
  final ToolInfo? tool;
  final PermissionRequest? permission;
  final TurnClose? turnClose;

  ReducerMessage({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.text,
    this.metadata,
    this.tool,
    this.permission,
    this.turnClose,
  });

  bool get isText => kind == 'text';
  bool get isToolCall => kind == 'tool-call';
  bool get isPermissionRequest => kind == 'permission-request';
  bool get isTurnClose => kind == 'turn-close';
  bool get isAgentEvent => kind == 'agent-event';
  bool get isError => kind == 'error';

  ReducerMessage copyWith({
    String? id,
    String? kind,
    DateTime? createdAt,
    String? text,
    Map<String, dynamic>? metadata,
    ToolInfo? tool,
    PermissionRequest? permission,
    TurnClose? turnClose,
  }) {
    return ReducerMessage(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      text: text ?? this.text,
      metadata: metadata ?? this.metadata,
      tool: tool ?? this.tool,
      permission: permission ?? this.permission,
      turnClose: turnClose ?? this.turnClose,
    );
  }

  factory ReducerMessage.fromJson(Map<String, dynamic> json) {
    final content = json['content'];
    return ReducerMessage(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? 'text',
      createdAt: json['createdAt'] != null
          ? _parseMessageDateTime(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      text: json['text'] as String? ?? _extractMessageText(content),
      metadata: _asStringMap(json['metadata']),
      tool: json['tool'] != null
          ? ToolInfo.fromJson(json['tool'] as Map<String, dynamic>)
          : null,
      permission: json['permission'] != null
          ? PermissionRequest.fromJson(
              json['permission'] as Map<String, dynamic>)
          : null,
      turnClose: json['turnClose'] != null
          ? TurnClose.fromJson(json['turnClose'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind,
      'createdAt': createdAt.toIso8601String(),
      if (text != null) 'text': text,
      if (metadata != null) 'metadata': metadata,
      if (tool != null) 'tool': tool!.toJson(),
      if (permission != null) 'permission': permission!.toJson(),
      if (turnClose != null) 'turnClose': turnClose!.toJson(),
    };
  }
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

String? _extractMessageText(dynamic content) {
  if (content == null) {
    return null;
  }
  if (content is String) {
    return content;
  }
  if (content is Map<String, dynamic>) {
    final encryptedContent = content['c'];
    if (encryptedContent is String && encryptedContent.isNotEmpty) {
      return encryptedContent;
    }
    final text = content['text'];
    if (text is String && text.isNotEmpty) {
      return text;
    }
  }
  if (content is Map) {
    final encryptedContent = content['c'];
    if (encryptedContent is String && encryptedContent.isNotEmpty) {
      return encryptedContent;
    }
    final text = content['text'];
    if (text is String && text.isNotEmpty) {
      return text;
    }
  }
  return null;
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

/// 工具信息
class ToolInfo {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;
  final ToolCallStatus? status;
  final String? result;
  final String? error;
  final String? description;

  ToolInfo({
    required this.id,
    required this.name,
    required this.arguments,
    this.status,
    this.result,
    this.error,
    this.description,
  });

  factory ToolInfo.fromJson(Map<String, dynamic> json) {
    return ToolInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      arguments: _asStringMap(json['arguments']) ?? const <String, dynamic>{},
      status: json['status'] != null
          ? ToolCallStatus.values.firstWhere(
              (e) => e.name == json['status'] as String,
              orElse: () => ToolCallStatus.pending,
            )
          : null,
      result: json['result'] as String?,
      error: json['error'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'arguments': arguments,
      if (status != null) 'status': status!.name,
      if (result != null) 'result': result,
      if (error != null) 'error': error,
      if (description != null) 'description': description,
    };
  }

  ToolInfo copyWith({
    String? id,
    String? name,
    Map<String, dynamic>? arguments,
    ToolCallStatus? status,
    String? result,
    String? error,
    String? description,
  }) {
    return ToolInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      arguments: arguments ?? this.arguments,
      status: status ?? this.status,
      result: result ?? this.result,
      error: error ?? this.error,
      description: description ?? this.description,
    );
  }
}

/// 权限请求
class PermissionRequest {
  final String tool;
  final Map<String, dynamic> arguments;
  final String? reason;

  PermissionRequest({
    required this.tool,
    required this.arguments,
    this.reason,
  });

  factory PermissionRequest.fromJson(Map<String, dynamic> json) {
    return PermissionRequest(
      tool: json['tool'] as String? ?? '',
      arguments: _asStringMap(json['arguments']) ?? const <String, dynamic>{},
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tool': tool,
      'arguments': arguments,
      if (reason != null) 'reason': reason,
    };
  }
}

/// 回合关闭
class TurnClose {
  final bool abandoned;
  final String? reason;

  TurnClose({
    this.abandoned = false,
    this.reason,
  });

  factory TurnClose.fromJson(Map<String, dynamic> json) {
    return TurnClose(
      abandoned: json['abandoned'] as bool? ?? false,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'abandoned': abandoned,
      if (reason != null) 'reason': reason,
    };
  }
}

/// 待办事项
class Todo {
  final String id;
  final String title;
  final String? description;
  final bool completed;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final List<String>? tags;

  Todo({
    required this.id,
    required this.title,
    this.description,
    this.completed = false,
    this.createdAt,
    this.completedAt,
    this.tags,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      completed: json['completed'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'completed': completed,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (tags != null) 'tags': tags,
    };
  }

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    DateTime? createdAt,
    DateTime? completedAt,
    List<String>? tags,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? this.tags,
    );
  }
}

/// 最新使用
class LatestUsage {
  final String? tool;
  final String? function;
  final DateTime? lastUsed;

  LatestUsage({
    this.tool,
    this.function,
    this.lastUsed,
  });

  factory LatestUsage.fromJson(Map<String, dynamic> json) {
    return LatestUsage(
      tool: json['tool'] as String?,
      function: json['function'] as String?,
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (tool != null) 'tool': tool,
      if (function != null) 'function': function,
      if (lastUsed != null) 'lastUsed': lastUsed!.toIso8601String(),
    };
  }
}

/// 当前回合
class OpenTurn {
  final String id;
  final DateTime startedAt;
  final String? status;
  final List<ReducerMessage>? messages;

  OpenTurn({
    required this.id,
    required this.startedAt,
    this.status,
    this.messages,
  });

  factory OpenTurn.fromJson(Map<String, dynamic> json) {
    return OpenTurn(
      id: json['id'] as String? ?? '',
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : DateTime.now(),
      status: json['status'] as String?,
      messages: (json['messages'] as List<dynamic>?)
          ?.map((e) => ReducerMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      if (status != null) 'status': status,
      if (messages != null)
        'messages': messages!.map((e) => e.toJson()).toList(),
    };
  }
}

/// Reducer 状态
///
/// 管理会话消息、工具调用、待办事项等
class ReducerState {
  const ReducerState._();

  static const ReducerState initial = _ReducerStateInitialState();

  static ReducerState ready({
    required List<ReducerMessage> messages,
    required Map<String, ReducerMessage> messagesMap,
    required Map<String, String> toolIdToMessageId,
    required Map<String, ToolCallStatus> toolCallStates,
    List<Todo>? todos,
    LatestUsage? latestUsage,
    OpenTurn? currentTurn,
  }) =>
      _ReducerStateReady(
        messages: messages,
        messagesMap: messagesMap,
        toolIdToMessageId: toolIdToMessageId,
        toolCallStates: toolCallStates,
        todos: todos,
        latestUsage: latestUsage,
        currentTurn: currentTurn,
      );

  List<ReducerMessage> get messages => this is _ReducerStateReady
      ? (this as _ReducerStateReady).messages
      : const [];

  Map<String, ReducerMessage> get messagesMap => this is _ReducerStateReady
      ? (this as _ReducerStateReady).messagesMap
      : const {};

  Map<String, String> get toolIdToMessageId => this is _ReducerStateReady
      ? (this as _ReducerStateReady).toolIdToMessageId
      : const {};

  Map<String, ToolCallStatus> get toolCallStates => this is _ReducerStateReady
      ? (this as _ReducerStateReady).toolCallStates
      : const {};

  List<Todo>? get todos =>
      this is _ReducerStateReady ? (this as _ReducerStateReady).todos : null;

  LatestUsage? get latestUsage => this is _ReducerStateReady
      ? (this as _ReducerStateReady).latestUsage
      : null;

  OpenTurn? get currentTurn => this is _ReducerStateReady
      ? (this as _ReducerStateReady).currentTurn
      : null;

  bool get isReady => this is _ReducerStateReady;

  ReducerState copyWith({
    List<ReducerMessage>? messages,
    Map<String, ReducerMessage>? messagesMap,
    Map<String, String>? toolIdToMessageId,
    Map<String, ToolCallStatus>? toolCallStates,
  }) {
    if (this is _ReducerStateReady) {
      final readyState = this as _ReducerStateReady;
      return ReducerState.ready(
        messages: messages ?? readyState.messages,
        messagesMap: messagesMap ?? readyState.messagesMap,
        toolIdToMessageId: toolIdToMessageId ?? readyState.toolIdToMessageId,
        toolCallStates: toolCallStates ?? readyState.toolCallStates,
        todos: readyState.todos,
        latestUsage: readyState.latestUsage,
        currentTurn: readyState.currentTurn,
      );
    }
    return ReducerState.initial;
  }

  Map<String, dynamic> toJson() {
    return {
      'messages': messages.map((e) => e.toJson()).toList(),
      'messagesMap': messagesMap.map((k, v) => MapEntry(k, v.toJson())),
      'toolIdToMessageId': toolIdToMessageId,
      'toolCallStates': toolCallStates.map((k, v) => MapEntry(k, v.name)),
      if (todos != null) 'todos': todos!.map((e) => e.toJson()).toList(),
      if (latestUsage != null) 'latestUsage': latestUsage!.toJson(),
      if (currentTurn != null) 'currentTurn': currentTurn!.toJson(),
    };
  }

  static ReducerState fromJson(Map<String, dynamic> json) {
    final messagesList = (json['messages'] as List<dynamic>?)
            ?.map((e) => ReducerMessage.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final messagesMap = (json['messagesMap'] as Map<String, dynamic>?)?.map((k,
                v) =>
            MapEntry(k, ReducerMessage.fromJson(v as Map<String, dynamic>))) ??
        {};
    final toolIdToMessageId =
        (json['toolIdToMessageId'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            {};
    final toolCallStatesMap = <String, ToolCallStatus>{};
    if (json['toolCallStates'] is Map<String, dynamic>) {
      final rawMap = json['toolCallStates'] as Map<String, dynamic>;
      rawMap.forEach((k, v) {
        final value = v as String?;
        if (value != null) {
          toolCallStatesMap[k] = ToolCallStatus.values.firstWhere(
            (e) => e.name == value,
            orElse: () => ToolCallStatus.pending,
          );
        }
      });
    }
    final todos = (json['todos'] as List<dynamic>?)
        ?.map((e) => Todo.fromJson(e as Map<String, dynamic>))
        .toList();
    final latestUsage = json['latestUsage'] != null
        ? LatestUsage.fromJson(json['latestUsage'] as Map<String, dynamic>)
        : null;
    final currentTurn = json['currentTurn'] != null
        ? OpenTurn.fromJson(json['currentTurn'] as Map<String, dynamic>)
        : null;
    return ReducerState.ready(
      messages: messagesList,
      messagesMap: messagesMap,
      toolIdToMessageId: toolIdToMessageId,
      toolCallStates: toolCallStatesMap,
      todos: todos,
      latestUsage: latestUsage,
      currentTurn: currentTurn,
    );
  }
}

class _ReducerStateInitialState extends ReducerState {
  const _ReducerStateInitialState() : super._();
}

class _ReducerStateReady extends ReducerState {
  @override
  final List<ReducerMessage> messages;
  @override
  final Map<String, ReducerMessage> messagesMap;
  @override
  final Map<String, String> toolIdToMessageId;
  @override
  final Map<String, ToolCallStatus> toolCallStates;
  @override
  final List<Todo>? todos;
  @override
  final LatestUsage? latestUsage;
  @override
  final OpenTurn? currentTurn;

  const _ReducerStateReady({
    required this.messages,
    required this.messagesMap,
    required this.toolIdToMessageId,
    required this.toolCallStates,
    this.todos,
    this.latestUsage,
    this.currentTurn,
  }) : super._();
}

/// Reducer 辅助函数
///
/// 这些函数用于与旧版 SessionRepository 的兼容性

/// 创建新的 Reducer 状态
ReducerState createReducer() {
  return ReducerState.initial;
}

/// Reducer 函数 - 处理消息和状态更新
ReducerResult reducer(
  ReducerState reducerState,
  List<ReducerMessage> messages,
  Map<String, dynamic>? agentState,
) {
  final messagesMap = <String, ReducerMessage>{};
  for (var m in messages) {
    messagesMap[m.id] = m;
  }

  // 更新工具调用状态
  final toolCallStates =
      Map<String, ToolCallStatus>.from(reducerState.toolCallStates);

  for (final msg in messages) {
    if (msg.tool != null) {
      toolCallStates[msg.tool!.id] = msg.tool!.status ?? ToolCallStatus.pending;
    }
  }

  return ReducerResult(
    messages: messages,
    messagesMap: messagesMap,
    reducerState: reducerState.copyWith(
      messages: messages,
      messagesMap: messagesMap,
      toolCallStates: toolCallStates,
    ),
  );
}

/// 批准工具调用
ReducerState approveToolCall(ReducerState reducerState, String toolId) {
  final toolCallStates =
      Map<String, ToolCallStatus>.from(reducerState.toolCallStates);
  toolCallStates[toolId] = ToolCallStatus.approved;

  return reducerState.copyWith(toolCallStates: toolCallStates);
}

/// 拒绝工具调用
ReducerState rejectToolCall(ReducerState reducerState, String toolId) {
  final toolCallStates =
      Map<String, ToolCallStatus>.from(reducerState.toolCallStates);
  toolCallStates[toolId] = ToolCallStatus.rejected;

  return reducerState.copyWith(toolCallStates: toolCallStates);
}

/// Reducer 结果
class ReducerResult {
  final List<ReducerMessage> messages;
  final Map<String, ReducerMessage> messagesMap;
  final ReducerState reducerState;

  ReducerResult({
    required this.messages,
    required this.messagesMap,
    required this.reducerState,
  });
}
