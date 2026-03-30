part of 'session_screen.dart';

class _ToolSection extends StatelessWidget {
  const _ToolSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.neutral700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ToolSummaryCard extends StatelessWidget {
  const _ToolSummaryCard({
    required this.text,
    this.onMessageAction,
  });

  final String text;
  final _SessionMessageActionHandler? onMessageAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: SelectableText(
        text,
        contextMenuBuilder: _buildMessageActionContextMenuBuilder(
          onMessageAction,
        ),
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: AppTheme.neutral800,
        ),
      ),
    );
  }
}

class _ToolTodoList extends StatelessWidget {
  const _ToolTodoList({
    required this.items,
  });

  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _ToolTodoRow(item: items[index]),
            if (index != items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ToolTodoRow extends StatelessWidget {
  const _ToolTodoRow({
    required this.item,
  });

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final map = item is Map ? item : const <String, dynamic>{};
    final content = map['content']?.toString() ?? item.toString();
    final status = map['status']?.toString() ?? 'pending';
    final color = switch (status) {
      'completed' => AppTheme.successColor,
      'in_progress' => AppTheme.infoColor,
      _ => AppTheme.neutral500,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            status == 'completed'
                ? Icons.check_circle_rounded
                : status == 'in_progress'
                    ? Icons.timelapse_rounded
                    : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppTheme.neutral800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolResultView extends StatelessWidget {
  const _ToolResultView({
    required this.content,
    required this.language,
    this.preferCode = false,
    this.onMessageAction,
  });

  final String content;
  final String language;
  final bool preferCode;
  final _SessionMessageActionHandler? onMessageAction;

  @override
  Widget build(BuildContext context) {
    final resolvedLanguage =
        language.isNotEmpty ? language : _detectStructuredLanguage(content);
    final looksLikeMarkdown = !preferCode &&
        resolvedLanguage.isEmpty &&
        _looksLikeMarkdownContentValue(content);

    if (looksLikeMarkdown) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.neutral50,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: _MarkdownMessageContent(
          content: content,
          isUser: false,
          textColor: AppTheme.textPrimary,
          onMessageAction: onMessageAction,
        ),
      );
    }

    if (!preferCode && resolvedLanguage.isEmpty) {
      return _ToolSummaryCard(
        text: content,
        onMessageAction: onMessageAction,
      );
    }

    return _InlineCodePanel(
      code: content,
      language: resolvedLanguage,
      isUser: false,
      collapsedLines: 8,
      onMessageAction: onMessageAction,
    );
  }
}
