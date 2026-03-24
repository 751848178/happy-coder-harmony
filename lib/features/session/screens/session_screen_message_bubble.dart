part of 'session_screen.dart';

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.autoApproveEnabled,
    required this.isToolActionPending,
    required this.onApproveTool,
    required this.onRejectTool,
  });

  final ReducerMessage message;
  final bool autoApproveEnabled;
  final bool isToolActionPending;
  final Future<void> Function(String) onApproveTool;
  final Future<void> Function(String, String?) onRejectTool;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with AutomaticKeepAliveClientMixin<_MessageBubble> {
  bool _collapsed = true;

  ReducerMessage get message => widget.message;
  bool get autoApproveEnabled => widget.autoApproveEnabled;
  bool get isToolActionPending => widget.isToolActionPending;
  Future<void> Function(String) get onApproveTool => widget.onApproveTool;
  Future<void> Function(String, String?) get onRejectTool =>
      widget.onRejectTool;

  @override
  void initState() {
    super.initState();
    _collapsed = _shouldStartCollapsed(message);
    updateKeepAlive();
  }

  @override
  void didUpdateWidget(covariant _MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    final contentChanged =
        jsonEncode(oldWidget.message.toJson()) != jsonEncode(message.toJson());
    if (oldWidget.message.id != widget.message.id || contentChanged) {
      _collapsed = _shouldStartCollapsed(message);
      updateKeepAlive();
    }
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
    final command = _extractCommand(tool.arguments);
    final diff = _extractDiff(tool);
    final argumentsPreview = _formatToolArguments(tool.arguments);
    final result = _formatToolResult(tool.result);
    return _looksLarge(command) ||
        _looksLarge(diff) ||
        _looksLarge(argumentsPreview) ||
        _looksLarge(result);
  }

  bool _looksLarge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }
    final normalized = value.trimRight();
    final lineCount = '\n'.allMatches(normalized).length + 1;
    return normalized.length > 240 || lineCount > 6;
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
    // 根据消息类型渲染不同的气泡
    if (message.isText) {
      return _buildTextMessage(context);
    } else if (message.isAgentEvent) {
      return _buildAgentEventMessage();
    } else if (message.isPermissionRequest) {
      return _buildPermissionRequestMessage();
    } else if (message.isTurnClose) {
      return _buildTurnCloseMessage();
    } else if (message.isError) {
      return _buildErrorMessage();
    } else if (message.isToolCall && message.tool != null) {
      return _buildToolCallMessage(message.tool!);
    } else {
      return _buildDefaultMessage();
    }
  }
}
