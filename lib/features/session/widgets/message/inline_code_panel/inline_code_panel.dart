import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';

import '../../../../../core/theme/app_theme.dart';
import '../message_action_context_menu.dart';
import '../session_message_action_types.dart';

part 'helpers.dart';

class InlineCodePanel extends StatefulWidget {
  const InlineCodePanel({
    required this.code,
    required this.language,
    required this.isUser,
    this.collapsedLines = 8,
    this.onMessageAction,
  });
  final String code;
  final String language;
  final bool isUser;
  final int collapsedLines;
  final SessionMessageActionHandler? onMessageAction;

  @override
  State<InlineCodePanel> createState() => _InlineCodePanelState();
}

class _InlineCodePanelState extends State<InlineCodePanel> {
  bool _expanded = false;
  Widget? _cachedCodeBody;
  String? _cachedCodeBodyKey;

  @override
  void didUpdateWidget(covariant InlineCodePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code ||
        oldWidget.language != widget.language ||
        oldWidget.collapsedLines != widget.collapsedLines) {
      _expanded = false;
      _clearCachedCodeBody();
    } else if (oldWidget.onMessageAction != widget.onMessageAction) {
      _clearCachedCodeBody();
    }
  }

  void _clearCachedCodeBody() {
    _cachedCodeBody = null;
    _cachedCodeBodyKey = null;
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final normalizedCode = widget.code.trimRight();
    final lines = normalizedCode.split('\n');
    final shouldCollapse =
        lines.length > widget.collapsedLines || widget.code.length > 320;
    final visibleLines = !_expanded && shouldCollapse
        ? lines.take(widget.collapsedLines).toList()
        : lines;
    final visibleCode =
        !_expanded && shouldCollapse ? visibleLines.join('\n') : normalizedCode;
    final isDiff = _isDiffLanguage(widget.language);
    final isTerminal = _isTerminalLanguage(widget.language);
    final backgroundColor = widget.isUser
        ? const Color(0xFF1F2937)
        : isTerminal
            ? const Color(0xFF0D1117)
            : const Color(0xFF1E1E1E);
    final borderColor = widget.isUser
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFF30363D);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(lines, isTerminal, shouldCollapse, normalizedCode),
          const SizedBox(height: 8),
          _buildCodeContainer(visibleCode, visibleLines, isDiff, isTerminal,
              shouldCollapse, lines),
          if (shouldCollapse && !_expanded) ...[
            const SizedBox(height: 6),
            Text('还有 ${lines.length - widget.collapsedLines} 行',
                style: TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ],
      ),
    );
  }
}
