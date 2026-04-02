part of 'session_screen.dart';

typedef _SessionMessageActionHandler = Future<void> Function(
  _SessionMessageActionChoice choice,
);

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.autoApproveEnabled,
    required this.isToolActionPending,
    required this.onApproveTool,
    required this.onRejectTool,
    required this.onMessageActionChoice,
    required this.onShowMessageActionSheet,
  });

  final ReducerMessage message;
  final bool autoApproveEnabled;
  final bool isToolActionPending;
  final Future<void> Function(String) onApproveTool;
  final Future<void> Function(String, String?) onRejectTool;
  final Future<void> Function(
    _SessionMessageActionChoice choice,
    String actionText,
  ) onMessageActionChoice;
  final Future<void> Function(
    ReducerMessage message,
    String actionText,
  ) onShowMessageActionSheet;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with AutomaticKeepAliveClientMixin<_MessageBubble> {
  bool _collapsed = true;
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
  Future<void> Function(String) get onApproveTool => widget.onApproveTool;
  Future<void> Function(String, String?) get onRejectTool =>
      widget.onRejectTool;
  _SessionMessageActionHandler? get onMessageAction => _onMessageAction;
  Future<void> Function()? get onLongPressMessage => _onLongPressMessage;

  @override
  void initState() {
    super.initState();
    _toolPresentationCache = _computeToolPresentation(message)?.._owner = this;
    _collapsed = _shouldStartCollapsed(message);
    _ensureActionState();
    updateKeepAlive();
  }

  @override
  void didUpdateWidget(covariant _MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.message, widget.message)) {
      _toolPresentationCache = _computeToolPresentation(message)?.._owner = this;
      _actionTextComputed = false;
      _ensureActionState();
    }
    if (_shouldResetCollapsedState(oldWidget.message, message)) {
      _collapsed = _shouldStartCollapsed(message);
      updateKeepAlive();
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

  _ToolPresentationCache? _computeToolPresentation(ReducerMessage msg) {
    final tool = msg.tool;
    if (tool == null) return null;
    final command = _extractCommand(tool.arguments);
    final diffPreview = _extractDiff(tool);
    // Use lightweight size heuristics for canCollapse decision instead of
    // running expensive _formatToolArguments / _formatToolResult (which do
    // jsonEncode/jsonDecode).  We only need to know IF it's large, not the
    // actual formatted string — that can be deferred to when the bubble is
    // actually expanded.
    final canCollapse = _looksLarge(command) ||
        _looksLarge(diffPreview) ||
        _rawArgumentsLookLarge(tool.arguments) ||
        _rawResultLooksLarge(tool.result);
    return _ToolPresentationCache(
      command: command,
      diffPreview: diffPreview,
      canCollapse: canCollapse,
      // Defer expensive formatting — computed on first access via getters.
      argumentsPreview: null,
      resultPreview: null,
    );
  }

  /// Lightweight check: are the raw tool arguments large enough to warrant
  /// collapsing, without formatting them as JSON?
  bool _rawArgumentsLookLarge(Map<String, dynamic> arguments) {
    if (arguments.isEmpty) return false;
    // Approximate: sum key+value string lengths.
    var total = 0;
    for (final entry in arguments.entries) {
      total += entry.key.length + (entry.value?.toString().length ?? 0);
      if (total > 240) return true;
    }
    return false;
  }

  /// Lightweight check: is the raw tool result large enough to warrant
  /// collapsing, without JSON-decode+re-encode?
  bool _rawResultLooksLarge(String? result) {
    if (result == null || result.trim().isEmpty) return false;
    final trimmed = result.trimRight();
    final lineCount = '\n'.allMatches(trimmed).length + 1;
    return trimmed.length > 240 || lineCount > 6;
  }

  @override
  bool get wantKeepAlive => !_collapsed;

  bool _shouldStartCollapsed(ReducerMessage value) {
    if (value.isToolCall && value.tool != null) {
      return _shouldCollapseToolMessage(value.tool!);
    }
    if (value.isText) {
      return _shouldCollapseTextMessage(value.text ?? '');
    }
    if (value.isError) {
      return _shouldCollapseTextMessage(value.text ?? '');
    }
    return false;
  }

  bool _shouldCollapseTextMessage(String text) {
    final normalized = text.trimRight();
    if (normalized.isEmpty) {
      return false;
    }
    final lineCount = '\n'.allMatches(normalized).length + 1;
    return normalized.length > 320 || lineCount > 9;
  }

  bool _shouldCollapseToolMessage(ToolInfo tool) {
    return _toolPresentationCache?.canCollapse ?? false;
  }

  bool _looksLarge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }
    final normalized = value.trimRight();
    final lineCount = '\n'.allMatches(normalized).length + 1;
    return normalized.length > 240 || lineCount > 6;
  }

  bool _shouldResetCollapsedState(
    ReducerMessage previous,
    ReducerMessage next,
  ) {
    if (previous.id != next.id ||
        previous.kind != next.kind ||
        previous.createdAt != next.createdAt) {
      return true;
    }
    if (previous.isText || previous.isError || next.isText || next.isError) {
      return previous.text != next.text ||
          sessionMessageIsUserAuthored(previous) !=
              sessionMessageIsUserAuthored(next) ||
          previous.metadata?['outputType'] != next.metadata?['outputType'] ||
          previous.metadata?['optimistic'] != next.metadata?['optimistic'];
    }
    if (previous.isToolCall || next.isToolCall) {
      return _toolCollapseSignature(previous.tool) !=
          _toolCollapseSignature(next.tool);
    }
    return false;
  }

  String _toolCollapseSignature(ToolInfo? tool) {
    if (tool == null) {
      return '';
    }
    final arguments = tool.arguments;
    final keys = arguments.keys.map((key) => key.toString()).toList()..sort();
    final keyArguments = <String>[
      for (final key in keys.take(8))
        '$key=${_toolCollapseValueSignature(arguments[key])}',
      if (keys.length > 8) 'extra=${keys.length - 8}',
    ].join('\u0001');
    return [
      tool.id,
      tool.name,
      tool.status?.name ?? '',
      _toolCollapseValueSignature(tool.result),
      _toolCollapseValueSignature(tool.error),
      _toolCollapseValueSignature(tool.description),
      keyArguments,
    ].join('\u0002');
  }

  String _toolCollapseValueSignature(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return '';
    }
    return '${text.length}:${text.hashCode}';
  }

  void _toggleCollapsed() {
    setState(() => _collapsed = !_collapsed);
    updateKeepAlive();
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

  String _plainTextPreview(String text) {
    final normalized = text
        .replaceAll(RegExp(r'```[\s\S]*?```'), '[代码片段]')
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.length <= 160) {
      return normalized;
    }
    return '${normalized.substring(0, 160)}...';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
      child = _buildDefaultMessage();
    }
    if (onLongPressMessage == null) {
      return child;
    }
    return ImmediateLongPressRegion(
      longPressDelay: _sessionMessageImmediateLongPressDelay,
      moveSlop: _sessionMessageLongPressMoveSlop,
      onLongPress: onLongPressMessage!,
      child: child,
    );
  }
}

class _ToolPresentationCache {
  _ToolPresentationCache({
    required this.command,
    required this.diffPreview,
    required this.canCollapse,
    required String? argumentsPreview,
    required String? resultPreview,
  })  : _argumentsPreview = argumentsPreview,
        _resultPreview = resultPreview;

  final String? command;
  final String? diffPreview;
  final bool canCollapse;

  // Expensive fields — may be lazily computed on first access.
  String? _argumentsPreview;
  String? _resultPreview;
  bool _argumentsComputed = false;
  bool _resultComputed = false;

  /// The _MessageBubbleState that owns this cache (set after construction).
  _MessageBubbleState? _owner;

  String? get argumentsPreview {
    if (!_argumentsComputed) {
      _argumentsComputed = true;
      if (_owner != null && _argumentsPreview == null) {
        final tool = _owner!.message.tool;
        if (tool != null &&
            _owner!._shouldShowRawArguments(
              tool.arguments,
              command: command,
              diff: diffPreview,
            ) &&
            _owner!._shouldDisplayArguments(tool.name)) {
          _argumentsPreview = _owner!._formatToolArguments(tool.arguments);
        }
      }
    }
    return _argumentsPreview;
  }

  String? get resultPreview {
    if (!_resultComputed) {
      _resultComputed = true;
      if (_owner != null && _resultPreview == null) {
        final tool = _owner!.message.tool;
        if (tool != null) {
          _resultPreview = _owner!._formatToolResult(tool.result);
        }
      }
    }
    return _resultPreview;
  }
}
