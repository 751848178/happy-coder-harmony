part of 'session_screen.dart';

extension _SessionScreenMessageBubbleToolHelpers on _MessageBubbleState {
  String _toolPresentationKind(String toolName) =>
      _MessageBubbleState._bubblePresenter.toolPresentationKind(toolName);

  bool _shouldDisplayArguments(String toolName) =>
      _MessageBubbleState._bubblePresenter.shouldDisplayArguments(toolName);

  bool _prefersCodeView(String toolName) =>
      _MessageBubbleState._bubblePresenter.prefersCodeView(toolName);

  String? _toolSummaryText(
    ToolInfo tool, {
    required String? resultPreview,
  }) => _MessageBubbleState._bubblePresenter.toolSummaryText(
        tool,
        resultPreview: resultPreview,
      );

  String? _firstNonEmpty(List<String?> values) =>
      _MessageBubbleState._bubblePresenter.firstNonEmpty(values);

  String _toolCategory(String toolName) =>
      _MessageBubbleState._bubblePresenter.toolCategory(toolName);

  IconData _toolIcon(String toolName) =>
      _MessageBubbleState._bubblePresenter.toolIcon(toolName);
}
