import 'package:flutter/material.dart';

import '../../domain/reducer.dart';
import '../../presentation/session_turn_status.dart';
import 'tool_classification.dart';
import 'tool_content_extraction.dart';
import 'tool_presentation_cache.dart';

/// Pure-logic presenter that formats tool call and text message data for
/// display in message-bubble widgets.
///
/// Stateless (const-constructable).  All methods are pure functions that
/// derive presentation values from [ReducerMessage] / [ToolInfo] inputs.
class SessionMessageBubblePresenter {
  const SessionMessageBubblePresenter();

  static const _classification = ToolClassification();
  static const _extraction = ToolContentExtraction();

  // ── Tool classification delegates ──────────────────────────────────────

  String toolPresentationKind(String toolName) =>
      _classification.toolPresentationKind(toolName);

  bool shouldDisplayArguments(String toolName) =>
      _classification.shouldDisplayArguments(toolName);

  bool prefersCodeView(String toolName) =>
      _classification.prefersCodeView(toolName);

  String toolCategory(String toolName) =>
      _classification.toolCategory(toolName);

  IconData toolIcon(String toolName) => _classification.toolIcon(toolName);

  String toolTitle(String toolName) => _classification.toolTitle(toolName);

  String resultSectionTitle(String toolName) =>
      _classification.resultSectionTitle(toolName);

  String messageKindLabel(String kind) =>
      _classification.messageKindLabel(kind);

  // ── Content extraction delegates ───────────────────────────────────────

  String? extractPrimaryPath(Map<String, dynamic> arguments) =>
      _extraction.extractPrimaryPath(arguments);

  String? extractCommand(Map<String, dynamic> arguments) =>
      _extraction.extractCommand(arguments);

  String? extractDiff(ToolInfo tool) => _extraction.extractDiff(tool);

  bool shouldShowRawArguments(
    Map<String, dynamic> arguments, {
    required String? command,
    required String? diff,
  }) =>
      _extraction.shouldShowRawArguments(
        arguments,
        command: command,
        diff: diff,
      );

  String? formatToolResult(String? result) =>
      _extraction.formatToolResult(result);

  String guessLanguageForResult(String? content, {required String toolName}) =>
      _extraction.guessLanguageForResult(content, toolName: toolName);

  String? formatToolArguments(Map<String, dynamic> arguments) =>
      _extraction.formatToolArguments(arguments);

  // ── Core presentation logic ───────────────────────────────────────────

  ToolPresentationCache? computeToolPresentation(ReducerMessage message) {
    final tool = message.tool;
    if (tool == null) return null;
    final command = extractCommand(tool.arguments);
    final diffPreview = extractDiff(tool);
    final canCollapse = looksLarge(command) ||
        looksLarge(diffPreview) ||
        rawArgumentsLookLarge(tool.arguments) ||
        rawResultLooksLarge(tool.result);
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
    return ToolPresentationCache(
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
    ToolPresentationCache? toolPresentationCache,
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
    ToolPresentationCache? toolPresentationCache,
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
    if (normalized.isEmpty) return false;
    final lineCount = '\n'.allMatches(normalized).length + 1;
    return normalized.length > 320 || lineCount > 9;
  }

  bool looksLarge(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final normalized = value.trimRight();
    final lineCount = '\n'.allMatches(normalized).length + 1;
    return normalized.length > 240 || lineCount > 6;
  }

  bool shouldResetCollapsedState(ReducerMessage previous, ReducerMessage next) {
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
    if (tool == null) return '';
    final arguments = tool.arguments;
    final keys = arguments.keys.map((key) => key.toString()).toList()..sort();
    final keyArguments = <String>[
      for (final key in keys.take(8))
        '$key=${_collapseValueSignature(arguments[key])}',
      if (keys.length > 8) 'extra=${keys.length - 8}',
    ].join('\u0001');
    return [
      tool.id,
      tool.name,
      tool.status?.name ?? '',
      _collapseValueSignature(tool.result),
      _collapseValueSignature(tool.error),
      _collapseValueSignature(tool.description),
      keyArguments,
    ].join('\u0002');
  }

  String _collapseValueSignature(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return '';
    return '${text.length}:${text.hashCode}';
  }

  String plainTextPreview(String text) {
    final normalized = text
        .replaceAll(RegExp(r'```[\s\S]*?```'), '[代码片段]')
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.length <= 160) return normalized;
    return '${normalized.substring(0, 160)}...';
  }

  String? toolSummaryText(ToolInfo tool, {required String? resultPreview}) {
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
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
