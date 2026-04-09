part of 'session_screen.dart';

extension _SessionScreenMessageBubbleToolHelpers2 on _MessageBubbleState {
  String _toolTitle(String toolName) =>
      _MessageBubbleState._bubblePresenter.toolTitle(toolName);

  String? _extractPrimaryPath(Map<String, dynamic> arguments) =>
      _MessageBubbleState._bubblePresenter.extractPrimaryPath(arguments);

  String? _extractCommand(Map<String, dynamic> arguments) =>
      _MessageBubbleState._bubblePresenter.extractCommand(arguments);

  String? _extractDiff(ToolInfo tool) =>
      _MessageBubbleState._bubblePresenter.extractDiff(tool);
}
