import 'package:flutter/material.dart';

/// Stateless classification of tool names into categories, icons, and titles.
class ToolClassification {
  const ToolClassification();

  String toolPresentationKind(String toolName) {
    final lower = toolName.toLowerCase();
    if (lower.contains('bash') ||
        lower.contains('shell') ||
        lower.contains('execute')) {
      return 'bash';
    }
    if (lower.contains('read') || lower == 'file') return 'read';
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
    if (lower.contains('askuserquestion')) return 'question';
    if (lower.contains('todo')) return 'todo';
    if (lower.contains('task')) return 'task';
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
    if (lower.contains('web')) return '网页访问';
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
    if (lower.contains('web')) return Icons.public_rounded;
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

  String resultSectionTitle(String toolName) {
    final lower = toolName.toLowerCase();
    if (lower.contains('bash') ||
        lower.contains('shell') ||
        lower.contains('execute')) {
      return '命令输出';
    }
    if (lower.contains('read')) return '文件内容';
    if (lower.contains('search') ||
        lower.contains('grep') ||
        lower.contains('glob') ||
        lower.contains('ls')) {
      return '搜索结果';
    }
    return '输出结果';
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
