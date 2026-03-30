part of 'session_screen.dart';

extension _SessionScreenMessageBubbleToolHelpers on _MessageBubbleState {
  String _toolPresentationKind(String toolName) {
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

  bool _shouldDisplayArguments(String toolName) {
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

  bool _prefersCodeView(String toolName) {
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

  String? _toolSummaryText(
    ToolInfo tool, {
    required String? resultPreview,
  }) {
    final presentation = _toolPresentationKind(tool.name);
    switch (presentation) {
      case 'read':
        return _firstNonEmpty([
          tool.arguments['path']?.toString(),
          tool.arguments['file_path']?.toString(),
          tool.description,
        ]);
      case 'search':
        return _firstNonEmpty([
          tool.arguments['pattern']?.toString(),
          tool.arguments['query']?.toString(),
          tool.arguments['path']?.toString(),
          resultPreview == null ? null : _plainTextPreview(resultPreview),
        ]);
      case 'task':
        return _firstNonEmpty([
          tool.arguments['prompt']?.toString(),
          tool.arguments['description']?.toString(),
          resultPreview == null ? null : _plainTextPreview(resultPreview),
        ]);
      default:
        return null;
    }
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String _toolCategory(String toolName) {
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

  IconData _toolIcon(String toolName) {
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
}
