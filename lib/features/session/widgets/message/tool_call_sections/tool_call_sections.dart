import 'package:flutter/material.dart';

import '../../../domain/reducer.dart';
import '../inline_code_panel.dart';
import '../session_message_action_types.dart';
import '../session_message_bubble_presenter.dart';
import '../tool_result_view.dart';
import '../tool_shared_widgets.dart';

part 'detail_builders.dart';

/// Builds the expanded detail sections for a tool call based on its presentation kind.
class ToolCallSectionBuilder {
  const ToolCallSectionBuilder({
    required this.presenter,
    this.onMessageAction,
  });

  final SessionMessageBubblePresenter presenter;
  final SessionMessageActionHandler? onMessageAction;

  List<Widget> build({
    required ToolInfo tool,
    required String presentation,
    required String? command,
    required String? diffPreview,
    required String? argumentsPreview,
    required String? resultPreview,
    required String resultLanguage,
    required String? summaryText,
  }) {
    final sections = <Widget>[];

    switch (presentation) {
      case 'bash':
        _addBashSections(
          sections,
          command: command,
          resultPreview: resultPreview,
          resultLanguage: resultLanguage,
        );
      case 'read':
      case 'search':
        _addReadSearchSections(
          sections,
          presentation: presentation,
          toolName: tool.name,
          resultPreview: resultPreview,
          resultLanguage: resultLanguage,
          summaryText: summaryText,
        );
      case 'edit':
        _addEditSections(
          sections,
          toolName: tool.name,
          diffPreview: diffPreview,
          resultPreview: resultPreview,
          resultLanguage: resultLanguage,
        );
      case 'question':
        _addQuestionSections(sections, tool: tool);
      case 'todo':
        _addTodoSections(sections, tool: tool);
      default:
        _addDefaultSections(
          sections,
          tool: tool,
          command: command,
          diffPreview: diffPreview,
          argumentsPreview: argumentsPreview,
          resultPreview: resultPreview,
          resultLanguage: resultLanguage,
        );
    }

    if (sections.isEmpty && summaryText != null && summaryText.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 10),
        ToolSection(
          title: '摘要',
          child: ToolSummaryCard(
            text: summaryText,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }

    return sections;
  }
}
