part of 'session_screen.dart';

typedef _SessionMessageActionHandler = Future<void> Function(
  _SessionMessageActionChoice choice,
);

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    required this.message,
    required this.autoApproveEnabled,
    required this.isToolActionPending,
    this.onApproveTool,
    this.onRejectTool,
    required this.onMessageActionChoice,
    required this.onShowMessageActionSheet,
    this.onFilePathTap,
  });

  final ReducerMessage message;
  final bool autoApproveEnabled;
  final bool isToolActionPending;
  final Future<void> Function(String)? onApproveTool;
  final Future<void> Function(String, String?)? onRejectTool;
  final Future<void> Function(
    _SessionMessageActionChoice choice,
    String actionText,
  ) onMessageActionChoice;
  final Future<void> Function(
    ReducerMessage message,
    String actionText,
  ) onShowMessageActionSheet;
  final void Function(String filePath)? onFilePathTap;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  static const _bubblePresenter = _SessionMessageBubblePresenter();

  bool _collapsed = true;
  // Cached collapse eligibility — computed once in initState / didUpdateWidget
  // to avoid running _shouldCollapseTextMessage (O(n) trimRight + regex) on
  // every build().
  bool _canCollapse = false;
  // Lazily computed — only resolved when the user actually long-presses.
  // Avoids running jsonEncode on every tool message during first frame.
  String? _actionText;
  bool _actionTextComputed = false;
  _SessionMessageActionHandler? _onMessageAction;
  Future<void> Function()? _onLongPressMessage;
  _ToolPresentationCache? _toolPresentationCache;

  ReducerMessage get message => widget.message;
  bool get autoApproveEnabled => widget.autoApproveEnabled;
  bool get isToolActionPending => widget.isToolActionPending;
  Future<void> Function(String)? get onApproveTool => widget.onApproveTool;
  Future<void> Function(String, String?)? get onRejectTool =>
      widget.onRejectTool;
  void Function(String)? get onFilePathTap => widget.onFilePathTap;
  _SessionMessageActionHandler? get onMessageAction {
    _ensureActionState();
    return _onMessageAction;
  }

  Future<void> Function()? get onLongPressMessage {
    _ensureActionState();
    return _onLongPressMessage;
  }

  @override
  void initState() {
    super.initState();
    _toolPresentationCache = _computeToolPresentation(message);
    _collapsed = _shouldStartCollapsed(message);
    _canCollapse = _computeCanCollapse(message);
    // NOTE: _ensureActionState() deferred to first access via getters.
    // Avoids running jsonEncode on every tool message during first frame.
  }

  @override
  void didUpdateWidget(covariant _MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fast path: if the message reference is the same, nothing has changed.
    // During streaming or parent rebuild, the parent creates new _MessageBubble
    // widgets even for unchanged messages. Without this check, every bubble
    // pays for _shouldResetCollapsedState + _toolCollapseSignature comparisons.
    if (identical(oldWidget.message, widget.message)) {
      return;
    }
    _toolPresentationCache = _computeToolPresentation(message);
    _actionTextComputed = false;
    // NOTE: _ensureActionState() deferred to first access via getters.
    if (_shouldResetCollapsedState(oldWidget.message, message)) {
      _collapsed = _shouldStartCollapsed(message);
      _canCollapse = _computeCanCollapse(message);
    }
  }

  /// Resolve action text lazily — only when needed for display or interaction.
  void _ensureActionState() {
    if (_actionTextComputed) return;
    _actionTextComputed = true;
    _actionText = resolveSessionMessageActionText(message);
    if (_actionText == null) {
      _onMessageAction = null;
      _onLongPressMessage = null;
      return;
    }
    final actionText = _actionText!;
    final msg = message;
    _onMessageAction = (choice) async {
      await widget.onMessageActionChoice(choice, actionText);
    };
    _onLongPressMessage = () async {
      await widget.onShowMessageActionSheet(msg, actionText);
    };
  }

  _ToolPresentationCache? _computeToolPresentation(ReducerMessage msg) =>
      _bubblePresenter.computeToolPresentation(msg);

  bool _canLongPressMessageActions() {
    if (message.isText || message.isError || message.isAgentEvent) {
      final text = message.text;
      return text != null && text.trim().isNotEmpty;
    }
    if (message.isPermissionRequest) {
      return message.permission != null;
    }
    if (message.isTurnClose) {
      return message.turnClose != null;
    }
    if (message.isToolCall) {
      return message.tool != null;
    }
    final text = message.text;
    return text != null && text.trim().isNotEmpty;
  }

  Future<void> _handleLongPressMessageTrigger() async {
    _ensureActionState();
    final handler = _onLongPressMessage;
    if (handler == null) {
      return;
    }
    await handler();
  }

  bool _shouldStartCollapsed(ReducerMessage value) =>
      _bubblePresenter.shouldStartCollapsed(value, _toolPresentationCache);

  /// Compute whether this message's content is large enough to warrant
  /// collapsing. Cached in [_canCollapse] to avoid O(n) work on every build.
  bool _computeCanCollapse(ReducerMessage value) =>
      _bubblePresenter.computeCanCollapse(value, _toolPresentationCache);

  bool _shouldCollapseToolMessage(ToolInfo tool) {
    return _toolPresentationCache?.canCollapse ?? false;
  }

  bool _shouldResetCollapsedState(
    ReducerMessage previous,
    ReducerMessage next,
  ) =>
      _bubblePresenter.shouldResetCollapsedState(previous, next);

  void _toggleCollapsed() {
    setState(() => _collapsed = !_collapsed);
  }

  Widget _buildCollapseButton({
    required Color color,
    required String collapsedLabel,
    required String expandedLabel,
  }) {
    return InkWell(
      onTap: _toggleCollapsed,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          _collapsed ? collapsedLabel : expandedLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  String _plainTextPreview(String text) =>
      _bubblePresenter.plainTextPreview(text);

  @override
  Widget build(BuildContext context) {
    Widget child;
    // 根据消息类型渲染不同的气泡
    if (message.isText) {
      child = _buildTextMessage(context);
    } else if (message.isAgentEvent) {
      child = _buildAgentEventMessage();
    } else if (message.isPermissionRequest) {
      child = _buildPermissionRequestMessage();
    } else if (message.isTurnClose) {
      child = _buildTurnCloseMessage();
    } else if (message.isError) {
      child = _buildErrorMessage();
    } else if (message.isToolCall && message.tool != null) {
      child = _buildToolCallMessage(message.tool!);
    } else {
      child = Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.neutral100,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Text(
          _bubblePresenter.messageKindLabel(message.kind),
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.neutral600,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    if (!_canLongPressMessageActions()) {
      return child;
    }
    return ImmediateLongPressRegion(
      enabled: true,
      longPressDelay: _sessionMessageImmediateLongPressDelay,
      moveSlop: _sessionMessageLongPressMoveSlop,
      onLongPress: _handleLongPressMessageTrigger,
      child: child,
    );
  }
}

class _ToolPresentationCache {
  _ToolPresentationCache({
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
