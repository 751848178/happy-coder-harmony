import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'content_detection.dart';
import 'inline_code_panel.dart';
import 'markdown/markdown_message_content.dart';
import 'session_message_action_types.dart';
import 'tool_shared_widgets.dart';

/// Renders tool result content — auto-detects markdown vs code vs plain text.
class ToolResultView extends StatelessWidget {
  const ToolResultView({
    required this.content,
    required this.language,
    this.preferCode = false,
    this.onMessageAction,
  });

  final String content;
  final String language;
  final bool preferCode;
  final SessionMessageActionHandler? onMessageAction;

  @override
  Widget build(BuildContext context) {
    final resolvedLanguage =
        language.isNotEmpty ? language : detectStructuredLanguage(content);
    final looksLikeMarkdown = !preferCode &&
        resolvedLanguage.isEmpty &&
        looksLikeMarkdownContent(content);

    if (looksLikeMarkdown) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.neutral50,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: MarkdownMessageContent(
          content: content,
          isUser: false,
          textColor: AppTheme.textPrimary,
          onMessageAction: onMessageAction,
        ),
      );
    }

    if (!preferCode && resolvedLanguage.isEmpty) {
      return ToolSummaryCard(
        text: content,
        onMessageAction: onMessageAction,
      );
    }

    return InlineCodePanel(
      code: content,
      language: resolvedLanguage,
      isUser: false,
      collapsedLines: 8,
      onMessageAction: onMessageAction,
    );
  }
}
