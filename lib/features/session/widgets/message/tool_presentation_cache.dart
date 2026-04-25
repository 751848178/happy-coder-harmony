/// Cached presentation data computed by [SessionMessageBubblePresenter].
///
/// Extracted from session_screen's private namespace so that independent
/// tool-bubble widgets can accept pre-computed tool metadata.

class ToolPresentationCache {
  ToolPresentationCache({
    required this.command,
    required this.diffPreview,
    required this.canCollapse,
    required this.argumentsPreview,
    required this.resultPreview,
  });

  final String? command;
  final String? diffPreview;
  final bool canCollapse;
  final String? argumentsPreview;
  final String? resultPreview;
}
