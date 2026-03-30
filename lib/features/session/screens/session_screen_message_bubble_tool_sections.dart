part of 'session_screen.dart';

extension _SessionScreenMessageBubbleToolSections on _MessageBubbleState {
  List<Widget> _buildToolDetailSections({
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
        _addBashToolSections(
          sections,
          command: command,
          resultPreview: resultPreview,
          resultLanguage: resultLanguage,
        );
        break;
      case 'read':
      case 'search':
        _addReadSearchToolSections(
          sections,
          presentation: presentation,
          toolName: tool.name,
          resultPreview: resultPreview,
          resultLanguage: resultLanguage,
          summaryText: summaryText,
        );
        break;
      case 'edit':
        _addEditToolSections(
          sections,
          toolName: tool.name,
          diffPreview: diffPreview,
          resultPreview: resultPreview,
          resultLanguage: resultLanguage,
        );
        break;
      case 'question':
        _addQuestionToolSections(sections, tool: tool);
        break;
      case 'todo':
        _addTodoToolSections(sections, tool: tool);
        break;
      default:
        _addDefaultToolSections(
          sections,
          tool: tool,
          command: command,
          diffPreview: diffPreview,
          argumentsPreview: argumentsPreview,
          resultPreview: resultPreview,
          resultLanguage: resultLanguage,
        );
        break;
    }

    if (sections.isEmpty && summaryText != null && summaryText.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 10),
        _ToolSection(
          title: '摘要',
          child: _ToolSummaryCard(
            text: summaryText,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }

    return sections;
  }

  void _addBashToolSections(
    List<Widget> sections, {
    required String? command,
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
    if (resultPreview != null && resultPreview.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 10),
        _ToolSection(
          title: '终端输出',
          child: _ToolResultView(
            content: resultPreview,
            language: resultLanguage.isEmpty ? 'shell' : resultLanguage,
            preferCode: true,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
  }

  void _addReadSearchToolSections(
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
        _ToolSection(
          title: presentation == 'read' ? '读取摘要' : '结果摘要',
          child: _ToolSummaryCard(
            text: summaryText,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
    if (resultPreview != null && resultPreview.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 10),
        _ToolSection(
          title: _resultSectionTitle(toolName),
          child: _ToolResultView(
            content: resultPreview,
            language: resultLanguage,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
  }

  void _addEditToolSections(
    List<Widget> sections, {
    required String toolName,
    required String? diffPreview,
    required String? resultPreview,
    required String resultLanguage,
  }) {
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
    if (resultPreview != null &&
        resultPreview.isNotEmpty &&
        resultPreview != diffPreview) {
      sections.addAll([
        const SizedBox(height: 10),
        _ToolSection(
          title: '结果',
          child: _ToolResultView(
            content: resultPreview,
            language: resultLanguage,
            preferCode: true,
            onMessageAction: onMessageAction,
          ),
        ),
      ]);
    }
  }
}
