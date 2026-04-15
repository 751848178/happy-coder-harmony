part of 'session_screen.dart';

extension _SessionScreenMessageBubbleToolSections2 on _MessageBubbleState {
  void _addQuestionToolSections(
    List<Widget> sections, {
    required ToolInfo tool,
  }) {
    final prompt = _MessageBubbleState._bubblePresenter.firstNonEmpty([
      tool.arguments['question']?.toString(),
      tool.arguments['prompt']?.toString(),
      tool.description,
    ]);
    if (prompt != null) {
      sections.addAll([
        const SizedBox(height: 10),
        _ToolSection(
          title: '确认内容',
          child: _ToolSummaryCard(
            text: prompt,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
    final options = tool.arguments['options'];
    if (options is List && options.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map((entry) => _TurnMetaChip(label: entry.toString()))
              .toList(),
        ),
      ]);
    }
  }

  void _addTodoToolSections(
    List<Widget> sections, {
    required ToolInfo tool,
  }) {
    final todos = tool.arguments['todos'];
    if (todos is List && todos.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 10),
        _ToolSection(
          title: '待办状态',
          child: _ToolTodoList(items: todos),
        ),
      ]);
    }
  }

  void _addDefaultToolSections(
    List<Widget> sections, {
    required ToolInfo tool,
    required String? command,
    required String? diffPreview,
    required String? argumentsPreview,
    required String? resultPreview,
    required String resultLanguage,
  }) {
    if (command != null && command.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 10),
        _ToolSection(
          title: '命令',
          child: _InlineCodePanel(
            code: command,
            language: 'shell',
            isUser: false,
            collapsedLines: 6,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
    if (diffPreview != null && diffPreview.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 10),
        _ToolSection(
          title: '改动预览',
          child: _InlineCodePanel(
            code: diffPreview,
            language: 'diff',
            isUser: false,
            collapsedLines: 8,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
    if (argumentsPreview != null) {
      sections.addAll([
        const SizedBox(height: 10),
        _ToolSection(
          title: '输入参数',
          child: _InlineCodePanel(
            code: argumentsPreview,
            language: 'json',
            isUser: false,
            collapsedLines: 4,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
    if (resultPreview != null && resultPreview.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 10),
        _ToolSection(
          title: _MessageBubbleState._bubblePresenter.resultSectionTitle(tool.name),
          child: _ToolResultView(
            content: resultPreview,
            language: resultLanguage,
            preferCode: _MessageBubbleState._bubblePresenter.prefersCodeView(tool.name),
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
  }
}
