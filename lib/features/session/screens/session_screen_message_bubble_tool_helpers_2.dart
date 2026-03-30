part of 'session_screen.dart';

extension _SessionScreenMessageBubbleToolHelpers2 on _MessageBubbleState {
  String _toolTitle(String toolName) {
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
        return '子任务';
      case 'TodoWrite':
        return '待办更新';
      case 'AskUserQuestion':
        return '用户确认';
      default:
        return '工具调用 · $toolName';
    }
  }

  String? _extractPrimaryPath(Map<String, dynamic> arguments) {
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

  String? _extractCommand(Map<String, dynamic> arguments) {
    final value = arguments['command'] ?? arguments['cmd'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  String? _extractDiff(ToolInfo tool) {
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
}
