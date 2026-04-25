part of 'reducer.dart';

ReducerState createReducer() {
  return ReducerState.initial;
}

ReducerResult reducer(
  ReducerState reducerState,
  List<ReducerMessage> messages,
  Map<String, dynamic>? agentState,
) {
  final messagesMap = <String, ReducerMessage>{};
  for (final message in messages) {
    messagesMap[message.id] = message;
  }
  final toolCallStates =
      Map<String, ToolCallStatus>.from(reducerState.toolCallStates);
  for (final message in messages) {
    if (message.tool != null) {
      toolCallStates[message.tool!.id] =
          message.tool!.status ?? ToolCallStatus.pending;
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

ReducerState approveToolCall(ReducerState reducerState, String toolId) {
  final toolCallStates =
      Map<String, ToolCallStatus>.from(reducerState.toolCallStates);
  toolCallStates[toolId] = ToolCallStatus.approved;
  return reducerState.copyWith(toolCallStates: toolCallStates);
}

ReducerState rejectToolCall(ReducerState reducerState, String toolId) {
  final toolCallStates =
      Map<String, ToolCallStatus>.from(reducerState.toolCallStates);
  toolCallStates[toolId] = ToolCallStatus.rejected;
  return reducerState.copyWith(toolCallStates: toolCallStates);
}

class ReducerResult {
  ReducerResult({
    required this.messages,
    required this.messagesMap,
    required this.reducerState,
  });

  final List<ReducerMessage> messages;
  final Map<String, ReducerMessage> messagesMap;
  final ReducerState reducerState;
}
