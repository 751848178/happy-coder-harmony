part of 'session_screen.dart';

class _SessionMessageBubblePresenter {
  const _SessionMessageBubblePresenter();

  _ToolPresentationCache? computeToolPresentation(ReducerMessage message) {
    final tool = message.tool;
    if (tool == null) return null;
    final command = extractCommand(tool.arguments);
    final diffPreview = extractDiff(tool);
    final canCollapse = looksLarge(command) ||
        looksLarge(diffPreview) ||
        rawArgumentsLookLarge(tool.arguments) ||
        rawResultLooksLarge(tool.result);
    // Compute previews eagerly — the presenter owns all formatting logic,
    // so there is no reason to defer to the widget state via _owner.
    String? argumentsPreview;
    if (shouldShowRawArguments(
      tool.arguments,
      command: command,
      diff: diffPreview,
    ) &&
        shouldDisplayArguments(tool.name)) {
      argumentsPreview = formatToolArguments(tool.arguments);
    }
    final resultPreview = formatToolResult(tool.result);
    return _ToolPresentationCache(
      command: command,
      diffPreview: diffPreview,
      canCollapse: canCollapse,
      argumentsPreview: argumentsPreview,
      resultPreview: resultPreview,
    );
  }

  bool rawArgumentsLookLarge(Map<String, dynamic> arguments) {
    if (arguments.isEmpty) return false;
    var total = 0;
    for (final entry in arguments.entries) {
      total += entry.key.length + (entry.value?.toString().length ?? 0);
      if (total > 240) return true;
    }
    return false;
  }

  bool rawResultLooksLarge(String? result) {
    if (result == null || result.trim().isEmpty) return false;
    final trimmed = result.trimRight();
    final lineCount = '\n'.allMatches(trimmed).length + 1;
    return trimmed.length > 240 || lineCount > 6;
  }

  bool shouldStartCollapsed(
    ReducerMessage value,
    _ToolPresentationCache? toolPresentationCache,
  ) {
    if (value.isToolCall && value.tool != null) {
      return toolPresentationCache?.canCollapse ?? false;
    }
    if (value.isText || value.isError) {
      return shouldCollapseTextMessage(value.text ?? '');
    }
    return false;
  }

  bool computeCanCollapse(
    ReducerMessage value,
    _ToolPresentationCache? toolPresentationCache,
  ) {
    if (value.isToolCall && value.tool != null) {
      return toolPresentationCache?.canCollapse ?? false;
    }
    if (value.isText || value.isError) {
      return shouldCollapseTextMessage(value.text ?? '');
    }
    return false;
  }

  bool shouldCollapseTextMessage(String text) {
    final normalized = text.trimRight();
    if (normalized.isEmpty) {
      return false;
    }
    final lineCount = '\n'.allMatches(normalized).length + 1;
    return normalized.length > 320 || lineCount > 9;
  }

  bool looksLarge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }
    final normalized = value.trimRight();
    final lineCount = '\n'.allMatches(normalized).length + 1;
    return normalized.length > 240 || lineCount > 6;
  }

  bool shouldResetCollapsedState(
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
      return toolCollapseSignature(previous.tool) !=
          toolCollapseSignature(next.tool);
    }
    return false;
  }

  String toolCollapseSignature(ToolInfo? tool) {
    if (tool == null) {
      return '';
    }
    final arguments = tool.arguments;
    final keys = arguments.keys.map((key) => key.toString()).toList()..sort();
    final keyArguments = <String>[
      for (final key in keys.take(8))
        '$key=${toolCollapseValueSignature(arguments[key])}',
      if (keys.length > 8) 'extra=${keys.length - 8}',
    ].join('\u0001');
    return [
      tool.id,
      tool.name,
      tool.status?.name ?? '',
      toolCollapseValueSignature(tool.result),
      toolCollapseValueSignature(tool.error),
      toolCollapseValueSignature(tool.description),
      keyArguments,
    ].join('\u0002');
  }

  String toolCollapseValueSignature(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return '';
    }
    return '${text.length}:${text.hashCode}';
  }

  String plainTextPreview(String text) {
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

  String toolPresentationKind(String toolName) {
    final lower = toolName.toLowerCase();
    if (lower.contains('bash') ||
        lower.contains('shell') ||
        lower.contains('execute')) {
      return 'bash';
    }
    if (lower.contains('read') || lower == 'file') {
      return 'read';
    }
    if (lower.contains('grep') ||
        lower.contains('glob') ||
        lower.contains('search') ||
        lower == 'ls') {
      return 'search';
    }
    if (lower.contains('edit') ||
        lower.contains('write') ||
        lower.contains('patch') ||
        lower.contains('diff')) {
      return 'edit';
    }
    if (lower.contains('askuserquestion')) {
      return 'question';
    }
    if (lower.contains('todo')) {
      return 'todo';
    }
    if (lower.contains('task')) {
      return 'task';
    }
    return 'generic';
  }

  bool shouldDisplayArguments(String toolName) {
    const compactKinds = {
      'read',
      'write',
      'edit',
      'multiedit',
      'notebookedit',
      'bash',
      'codexbash',
      'geminibash',
      'glob',
      'grep',
      'ls',
      'search',
      'toolsearch',
      'askuserquestion',
      'todowrite',
      'task',
      'codexpatch',
      'geminipatch',
      'codexdiff',
      'geminidiff',
      'file',
    };
    return !compactKinds.contains(toolName.toLowerCase());
  }

  bool prefersCodeView(String toolName) {
    final lower = toolName.toLowerCase();
    return lower.contains('read') ||
        lower.contains('bash') ||
        lower.contains('edit') ||
        lower.contains('write') ||
        lower.contains('patch') ||
        lower.contains('diff') ||
        lower.contains('grep') ||
        lower.contains('search') ||
        lower == 'file';
  }

  String? toolSummaryText(
    ToolInfo tool, {
    required String? resultPreview,
  }) {
    final presentation = toolPresentationKind(tool.name);
    switch (presentation) {
      case 'read':
        return firstNonEmpty([
          tool.arguments['path']?.toString(),
          tool.arguments['file_path']?.toString(),
          tool.description,
        ]);
      case 'search':
        return firstNonEmpty([
          tool.arguments['pattern']?.toString(),
          tool.arguments['query']?.toString(),
          tool.arguments['path']?.toString(),
          resultPreview == null ? null : plainTextPreview(resultPreview),
        ]);
      case 'task':
        return firstNonEmpty([
          tool.arguments['prompt']?.toString(),
          tool.arguments['description']?.toString(),
          resultPreview == null ? null : plainTextPreview(resultPreview),
        ]);
      default:
        return null;
    }
  }

  String? firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String toolCategory(String toolName) {
    final lower = toolName.toLowerCase();
    if (lower.contains('bash') ||
        lower.contains('shell') ||
        lower.contains('execute')) {
      return '命令执行';
    }
    if (lower.contains('read') ||
        lower.contains('ls') ||
        lower.contains('glob') ||
        lower.contains('grep') ||
        lower.contains('search')) {
      return '读取与搜索';
    }
    if (lower.contains('edit') ||
        lower.contains('write') ||
        lower.contains('patch') ||
        lower.contains('diff')) {
      return '文件改动';
    }
    if (lower.contains('reason') ||
        lower.contains('task') ||
        lower.contains('todo') ||
        lower.contains('plan') ||
        lower.contains('think')) {
      return '规划与推理';
    }
    if (lower.contains('web')) {
      return '网页访问';
    }
    return '工具调用';
  }

  IconData toolIcon(String toolName) {
    final lower = toolName.toLowerCase();
    if (lower.contains('bash') ||
        lower.contains('shell') ||
        lower.contains('execute')) {
      return Icons.terminal_rounded;
    }
    if (lower.contains('read') || lower.contains('ls')) {
      return Icons.description_outlined;
    }
    if (lower.contains('glob') ||
        lower.contains('grep') ||
        lower.contains('search')) {
      return Icons.search_rounded;
    }
    if (lower.contains('edit') ||
        lower.contains('write') ||
        lower.contains('patch') ||
        lower.contains('diff')) {
      return Icons.edit_note_rounded;
    }
    if (lower.contains('web')) {
      return Icons.public_rounded;
    }
    if (lower.contains('todo') ||
        lower.contains('task') ||
        lower.contains('plan')) {
      return Icons.checklist_rounded;
    }
    return Icons.handyman_outlined;
  }

  String toolTitle(String toolName) {
    switch (toolName) {
      case 'Bash':
      case 'CodexBash':
      case 'GeminiBash':
      case 'shell':
      case 'execute':
        return '命令执行';
      case 'Read':
      case 'read':
      case 'NotebookRead':
        return '读取文件';
      case 'Edit':
      case 'edit':
      case 'MultiEdit':
      case 'Write':
      case 'NotebookEdit':
        return '修改文件';
      case 'CodexDiff':
      case 'GeminiDiff':
      case 'CodexPatch':
      case 'GeminiPatch':
        return '代码改动';
      case 'Glob':
      case 'Grep':
      case 'LS':
      case 'search':
      case 'ToolSearch':
        return '搜索内容';
      case 'WebFetch':
      case 'WebSearch':
        return '网页检索';
      case 'Task':
      case 'Agent':
        return '子任务';
      case 'TodoWrite':
        return '待办更新';
      case 'AskUserQuestion':
        return '用户确认';
      default:
        return '工具调用 · $toolName';
    }
  }

  String? extractPrimaryPath(Map<String, dynamic> arguments) {
    const keys = [
      'file_path',
      'path',
      'cwd',
      'root',
      'uri',
      'target_file',
    ];
    for (final key in keys) {
      final value = arguments[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    final locations = arguments['locations'];
    if (locations is List && locations.isNotEmpty) {
      final first = locations.first;
      if (first is Map && first['path'] is String) {
        return first['path'] as String;
      }
    }
    return null;
  }

  String? extractCommand(Map<String, dynamic> arguments) {
    final value = arguments['command'] ?? arguments['cmd'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  String? extractDiff(ToolInfo tool) {
    final arguments = tool.arguments;
    final directPatch = arguments['patch'] ?? arguments['diff'];
    if (directPatch is String && directPatch.trim().isNotEmpty) {
      return directPatch.trimRight();
    }

    final oldString = arguments['old_string'] ?? arguments['oldText'];
    final newString = arguments['new_string'] ?? arguments['newText'];
    if (oldString is String && newString is String) {
      return [
        '--- 旧内容',
        oldString,
        '+++ 新内容',
        newString,
      ].join('\n');
    }

    final edits = arguments['edits'];
    if (edits is List && edits.isNotEmpty) {
      final buffer = StringBuffer();
      for (final edit in edits.whereType<Map>()) {
        final oldValue = edit['old_string']?.toString() ?? '';
        final newValue = edit['new_string']?.toString() ?? '';
        if (oldValue.isEmpty && newValue.isEmpty) {
          continue;
        }
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.writeln('--- 旧内容');
        buffer.writeln(oldValue);
        buffer.writeln('+++ 新内容');
        buffer.writeln(newValue);
      }
      if (buffer.isNotEmpty) {
        return buffer.toString().trimRight();
      }
    }

    final result = tool.result;
    if (result != null &&
        (result.contains('@@') ||
            result.contains('diff --git') ||
            result.contains('*** Begin Patch'))) {
      return result.trimRight();
    }
    return null;
  }

  bool shouldShowRawArguments(
    Map<String, dynamic> arguments, {
    required String? command,
    required String? diff,
  }) {
    const excludedArgumentKeys = <String>{
      'command',
      'cmd',
      'patch',
      'diff',
      'old_string',
      'new_string',
      'oldText',
      'newText',
      'edits',
    };
    if (arguments.isEmpty) {
      return false;
    }
    if (command == null && diff == null) {
      return true;
    }
    for (final key in arguments.keys) {
      if (!excludedArgumentKeys.contains(key)) {
        return true;
      }
    }
    return false;
  }

  String? formatToolResult(String? result) {
    if (result == null || result.trim().isEmpty) {
      return null;
    }
    final trimmed = result.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return trimmed;
      }
    }
    return trimmed;
  }

  String guessLanguageForResult(
    String? content, {
    required String toolName,
  }) {
    if (content == null || content.isEmpty) {
      return '';
    }
    final lowerTool = toolName.toLowerCase();
    if (content.startsWith('{') || content.startsWith('[')) {
      return 'json';
    }
    if (content.contains('diff --git') || content.contains('@@')) {
      return 'diff';
    }
    final detected = _detectStructuredLanguage(content);
    if (detected.isNotEmpty) {
      return detected;
    }
    if (lowerTool.contains('bash') ||
        lowerTool.contains('shell') ||
        lowerTool.contains('execute')) {
      return 'shell';
    }
    if (lowerTool.contains('read') ||
        lowerTool.contains('write') ||
        lowerTool.contains('edit')) {
      return 'text';
    }
    return '';
  }

  String resultSectionTitle(String toolName) {
    final lower = toolName.toLowerCase();
    if (lower.contains('bash') ||
        lower.contains('shell') ||
        lower.contains('execute')) {
      return '命令输出';
    }
    if (lower.contains('read')) {
      return '文件内容';
    }
    if (lower.contains('search') ||
        lower.contains('grep') ||
        lower.contains('glob') ||
        lower.contains('ls')) {
      return '搜索结果';
    }
    return '输出结果';
  }

  String? formatToolArguments(Map<String, dynamic> arguments) {
    if (arguments.isEmpty) {
      return null;
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(arguments);
    } catch (_) {
      return arguments.toString();
    }
  }

  String messageKindLabel(String kind) {
    switch (kind) {
      case 'text':
        return '文本消息';
      case 'tool-call':
        return '工具调用';
      case 'permission-request':
        return '权限请求';
      case 'turn-close':
        return '回合结束';
      case 'agent-event':
        return '状态事件';
      case 'error':
        return '错误消息';
      default:
        return kind;
    }
  }
}
