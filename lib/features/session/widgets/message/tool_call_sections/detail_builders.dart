part of 'tool_call_sections.dart';

extension _ToolCallSectionDetailBuilders on ToolCallSectionBuilder {
  void _addBashSections(
    List<Widget> sections, {
    required String? command,
    required String? resultPreview,
    required String resultLanguage,
  }) {
    if (command != null && command.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 10),
        ToolSection(
          title: '命令',
          child: InlineCodePanel(
            code: command,
            language: 'shell',
            isUser: false,
            collapsedLines: 6,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
    if (resultPreview != null && resultPreview.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 10),
        ToolSection(
          title: '终端输出',
          child: ToolResultView(
            content: resultPreview,
            language: resultLanguage.isEmpty ? 'shell' : resultLanguage,
            preferCode: true,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
  }

  void _addReadSearchSections(
    List<Widget> sections, {
    required String presentation,
    required String toolName,
    required String? resultPreview,
    required String resultLanguage,
    required String? summaryText,
  }) {
    if (summaryText != null && summaryText.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 10),
        ToolSection(
          title: presentation == 'read' ? '读取摘要' : '结果摘要',
          child: ToolSummaryCard(
            text: summaryText,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
    if (resultPreview != null && resultPreview.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 10),
        ToolSection(
          title: presenter.resultSectionTitle(toolName),
          child: ToolResultView(
            content: resultPreview,
            language: resultLanguage,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
  }

  void _addEditSections(
    List<Widget> sections, {
    required String toolName,
    required String? diffPreview,
    required String? resultPreview,
    required String resultLanguage,
  }) {
    if (diffPreview != null && diffPreview.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 10),
        ToolSection(
          title: '改动预览',
          child: InlineCodePanel(
            code: diffPreview,
            language: 'diff',
            isUser: false,
            collapsedLines: 8,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
    if (resultPreview != null &&
        resultPreview.isNotEmpty &&
        resultPreview != diffPreview) {
      sections.addAll([
        const SizedBox(height: 10),
        ToolSection(
          title: '结果',
          child: ToolResultView(
            content: resultPreview,
            language: resultLanguage,
            preferCode: true,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
  }

  void _addQuestionSections(
    List<Widget> sections, {
    required ToolInfo tool,
  }) {
    final prompt = presenter.firstNonEmpty([
      tool.arguments['question']?.toString(),
      tool.arguments['prompt']?.toString(),
      tool.description,
    ]);
    if (prompt != null) {
      sections.addAll([
        const SizedBox(height: 10),
        ToolSection(
          title: '确认内容',
          child: ToolSummaryCard(
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
              .map((entry) => TurnMetaChip(label: entry.toString()))
              .toList(),
        ),
      ]);
    }
  }

  void _addTodoSections(
    List<Widget> sections, {
    required ToolInfo tool,
  }) {
    final todos = tool.arguments['todos'];
    if (todos is List && todos.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 10),
        ToolSection(
          title: '待办状态',
          child: ToolTodoList(items: todos),
        ),
      ]);
    }
  }

  void _addDefaultSections(
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
        ToolSection(
          title: '命令',
          child: InlineCodePanel(
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
        ToolSection(
          title: '改动预览',
          child: InlineCodePanel(
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
        ToolSection(
          title: '输入参数',
          child: InlineCodePanel(
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
        ToolSection(
          title: presenter.resultSectionTitle(tool.name),
          child: ToolResultView(
            content: resultPreview,
            language: resultLanguage,
            preferCode: presenter.prefersCodeView(tool.name),
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
  }
}
