part of 'reducer.dart';

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
  }) {
    return _ReducerStateReady(
      messages: messages,
      messagesMap: messagesMap,
      toolIdToMessageId: toolIdToMessageId,
      toolCallStates: toolCallStates,
      todos: todos,
      latestUsage: latestUsage,
      currentTurn: currentTurn,
    );
  }

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
    if (this is! _ReducerStateReady) {
      return ReducerState.initial;
    }
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

  Map<String, dynamic> toJson() {
    return {
      'messages': messages.map((message) => message.toJson()).toList(),
      'messagesMap': messagesMap.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'toolIdToMessageId': toolIdToMessageId,
      'toolCallStates': toolCallStates.map(
        (key, value) => MapEntry(key, value.name),
      ),
      if (todos != null) 'todos': todos!.map((todo) => todo.toJson()).toList(),
      if (latestUsage != null) 'latestUsage': latestUsage!.toJson(),
      if (currentTurn != null) 'currentTurn': currentTurn!.toJson(),
    };
  }

  static ReducerState fromJson(Map<String, dynamic> json) {
    final messagesList = (json['messages'] as List<dynamic>?)
            ?.map(
                (item) => ReducerMessage.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];
    final messagesMap = (json['messagesMap'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
              key, ReducerMessage.fromJson(value as Map<String, dynamic>)),
        ) ??
        {};
    final toolIdToMessageId =
        (json['toolIdToMessageId'] as Map<String, dynamic>?)
                ?.map((key, value) => MapEntry(key, value as String)) ??
            {};
    final toolCallStatesMap = <String, ToolCallStatus>{};
    if (json['toolCallStates'] is Map<String, dynamic>) {
      final rawMap = json['toolCallStates'] as Map<String, dynamic>;
      rawMap.forEach((key, value) {
        final statusValue = value as String?;
        if (statusValue != null) {
          toolCallStatesMap[key] = ToolCallStatus.values.firstWhere(
            (candidate) => candidate.name == statusValue,
            orElse: () => ToolCallStatus.pending,
          );
        }
      });
    }
    return ReducerState.ready(
      messages: messagesList,
      messagesMap: messagesMap,
      toolIdToMessageId: toolIdToMessageId,
      toolCallStates: toolCallStatesMap,
      todos: (json['todos'] as List<dynamic>?)
          ?.map((item) => Todo.fromJson(item as Map<String, dynamic>))
          .toList(),
      latestUsage: json['latestUsage'] != null
          ? LatestUsage.fromJson(json['latestUsage'] as Map<String, dynamic>)
          : null,
      currentTurn: json['currentTurn'] != null
          ? OpenTurn.fromJson(json['currentTurn'] as Map<String, dynamic>)
          : null,
    );
  }
}

class _ReducerStateInitialState extends ReducerState {
  const _ReducerStateInitialState() : super._();
}

class _ReducerStateReady extends ReducerState {
  const _ReducerStateReady({
    required this.messages,
    required this.messagesMap,
    required this.toolIdToMessageId,
    required this.toolCallStates,
    this.todos,
    this.latestUsage,
    this.currentTurn,
  }) : super._();

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
}
