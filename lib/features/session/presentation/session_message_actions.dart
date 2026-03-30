import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../domain/reducer.dart';

const String sessionMessageContextMenuForwardLabel = '转发';
const String sessionMessageContextMenuSaveTemplateLabel = '存模板';
const String sessionMessageContextMenuInsertLabel = '插入';

String? resolveSessionMessageActionText(ReducerMessage message) {
  final text = message.text;
  if (message.isText || message.isError || message.isAgentEvent) {
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    return text;
  }
  if (message.isPermissionRequest) {
    final permission = message.permission;
    if (permission == null) {
      return null;
    }
    return [
      '权限请求',
      '工具: ${permission.tool}',
      if (permission.reason != null && permission.reason!.trim().isNotEmpty)
        permission.reason!.trim(),
    ].join('\n');
  }
  if (message.isTurnClose) {
    final turnClose = message.turnClose;
    if (turnClose == null) {
      return null;
    }
    return turnClose.abandoned ? '回合已终止' : '回合已结束';
  }
  if (message.isToolCall) {
    final tool = message.tool;
    if (tool == null) {
      return null;
    }
    return _buildToolActionText(tool);
  }
  if (text != null && text.trim().isNotEmpty) {
    return text;
  }
  return '消息类型: ${message.kind}';
}

List<ContextMenuButtonItem> buildSessionMessageContextMenuButtonItems({
  required List<ContextMenuButtonItem> baseItems,
  required VoidCallback onForward,
  required VoidCallback onSaveTemplate,
  required VoidCallback onInsertIntoComposer,
}) {
  final items = List<ContextMenuButtonItem>.from(baseItems);
  final customItems = <ContextMenuButtonItem>[
    ContextMenuButtonItem(
      onPressed: onForward,
      label: sessionMessageContextMenuForwardLabel,
    ),
    ContextMenuButtonItem(
      onPressed: onSaveTemplate,
      label: sessionMessageContextMenuSaveTemplateLabel,
    ),
    ContextMenuButtonItem(
      onPressed: onInsertIntoComposer,
      label: sessionMessageContextMenuInsertLabel,
    ),
  ];
  final copyIndex = items.indexWhere(
    (item) => item.type == ContextMenuButtonType.copy,
  );
  final insertIndex = copyIndex >= 0 ? copyIndex + 1 : items.length;
  items.insertAll(insertIndex, customItems);
  return items;
}

String _buildToolActionText(ToolInfo tool) {
  String normalize(Object? value) {
    if (value == null) {
      return '';
    }
    final raw = value is String ? value : jsonEncode(value);
    return raw.trim();
  }

  final lines = <String>[
    '工具调用: ${tool.name}',
    if (tool.description != null && tool.description!.trim().isNotEmpty)
      tool.description!.trim(),
  ];
  final arguments = normalize(tool.arguments);
  final result = normalize(tool.result);
  final error = normalize(tool.error);
  if (arguments.isNotEmpty && arguments != '{}') {
    lines.add('参数:\n$arguments');
  }
  if (result.isNotEmpty) {
    lines.add('结果:\n$result');
  }
  if (error.isNotEmpty) {
    lines.add('错误:\n$error');
  }
  return lines.join('\n\n');
}

String mergeForwardedMessageIntoDraft({
  required String? existingDraft,
  required String forwardedText,
}) {
  final normalizedForwarded = forwardedText.trim();
  if (normalizedForwarded.isEmpty) {
    return existingDraft?.trimRight() ?? '';
  }

  final currentDraft = existingDraft ?? '';
  if (currentDraft.trim().isEmpty) {
    return normalizedForwarded;
  }

  final separator = currentDraft.endsWith('\n\n')
      ? ''
      : currentDraft.endsWith('\n')
          ? '\n'
          : '\n\n';
  return '$currentDraft$separator$normalizedForwarded';
}

TextEditingValue replaceComposerTextRange({
  required TextEditingValue currentValue,
  required int start,
  required int end,
  required String replacement,
}) {
  final text = currentValue.text;
  final normalizedStart = math.max(0, math.min(start, text.length));
  final normalizedEnd = math.max(
    normalizedStart,
    math.min(end, text.length),
  );
  final nextText = text.replaceRange(
    normalizedStart,
    normalizedEnd,
    replacement,
  );
  final selectionOffset = normalizedStart + replacement.length;
  return TextEditingValue(
    text: nextText,
    selection: TextSelection.collapsed(offset: selectionOffset),
  );
}

TextEditingValue insertComposerTextAtSelection({
  required TextEditingValue currentValue,
  required String insertion,
}) {
  final text = currentValue.text;
  final selection = currentValue.selection;
  if (!selection.isValid) {
    return replaceComposerTextRange(
      currentValue: currentValue,
      start: text.length,
      end: text.length,
      replacement: insertion,
    );
  }
  final start = math.min(selection.start, selection.end);
  final end = math.max(selection.start, selection.end);
  return replaceComposerTextRange(
    currentValue: currentValue,
    start: start,
    end: end,
    replacement: insertion,
  );
}

String suggestSessionInputTemplateLabel(String content) {
  final normalized = content.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) {
    return '新模板';
  }
  if (normalized.length <= 18) {
    return normalized;
  }
  return '${normalized.substring(0, 18)}...';
}
