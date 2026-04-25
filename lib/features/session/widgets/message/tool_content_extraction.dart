import 'dart:convert';

import '../../domain/reducer.dart';
import 'content_detection.dart';

/// Stateless extraction and formatting of tool call arguments and results.
class ToolContentExtraction {
  const ToolContentExtraction();

  String? extractPrimaryPath(Map<String, dynamic> arguments) {
    const keys = ['file_path', 'path', 'cwd', 'root', 'uri', 'target_file'];
    for (final key in keys) {
      final value = arguments[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    final locations = arguments['locations'];
    if (locations is List && locations.isNotEmpty) {
      final first = locations.first;
      if (first is Map && first['path'] is String)
        return first['path'] as String;
    }
    return null;
  }

  String? extractCommand(Map<String, dynamic> arguments) {
    final value = arguments['command'] ?? arguments['cmd'];
    if (value is String && value.trim().isNotEmpty) return value.trim();
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
      return ['--- 旧内容', oldString, '+++ 新内容', newString].join('\n');
    }
    final edits = arguments['edits'];
    if (edits is List && edits.isNotEmpty) {
      final buffer = StringBuffer();
      for (final edit in edits.whereType<Map>()) {
        final oldValue = edit['old_string']?.toString() ?? '';
        final newValue = edit['new_string']?.toString() ?? '';
        if (oldValue.isEmpty && newValue.isEmpty) continue;
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.writeln('--- 旧内容');
        buffer.writeln(oldValue);
        buffer.writeln('+++ 新内容');
        buffer.writeln(newValue);
      }
      if (buffer.isNotEmpty) return buffer.toString().trimRight();
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
    const excludedKeys = <String>{
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
    if (arguments.isEmpty) return false;
    if (command == null && diff == null) return true;
    for (final key in arguments.keys) {
      if (!excludedKeys.contains(key)) return true;
    }
    return false;
  }

  String? formatToolResult(String? result) {
    if (result == null || result.trim().isEmpty) return null;
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

  String guessLanguageForResult(String? content, {required String toolName}) {
    if (content == null || content.isEmpty) return '';
    final lowerTool = toolName.toLowerCase();
    if (content.startsWith('{') || content.startsWith('[')) return 'json';
    if (content.contains('diff --git') || content.contains('@@')) return 'diff';
    final detected = detectStructuredLanguage(content);
    if (detected.isNotEmpty) return detected;
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

  String? formatToolArguments(Map<String, dynamic> arguments) {
    if (arguments.isEmpty) return null;
    try {
      return const JsonEncoder.withIndent('  ').convert(arguments);
    } catch (_) {
      return arguments.toString();
    }
  }
}
