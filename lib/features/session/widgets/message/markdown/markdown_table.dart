import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../message_action_context_menu.dart';
import '../session_message_action_types.dart';

class MarkdownTableBlock extends StatelessWidget {
  const MarkdownTableBlock({
    required this.headers,
    required this.rows,
    required this.isUser,
    required this.textColor,
    this.onMessageAction,
  });
  final List<String> headers;
  final List<List<String>> rows;
  final bool isUser;
  final Color textColor;
  final SessionMessageActionHandler? onMessageAction;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isUser ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0);
    final panelColor =
        isUser ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFFCFDFF);
    final headerColor =
        isUser ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFF1F5F9);
    final headerTextColor = isUser ? Colors.white : const Color(0xFF334155);
    final normalizedRows = rows
        .map((row) => List<String>.generate(
            headers.length, (i) => i < row.length ? row[i] : ''))
        .toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: borderColor)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: {
            for (var i = 0; i < headers.length; i++)
              i: const IntrinsicColumnWidth(flex: 1)
          },
          border: TableBorder(
              horizontalInside: BorderSide(color: borderColor),
              verticalInside:
                  BorderSide(color: borderColor.withValues(alpha: 0.55))),
          children: [
            TableRow(decoration: BoxDecoration(color: headerColor), children: [
              for (final h in headers)
                _MarkdownTableCell(
                    text: h,
                    textColor: headerTextColor,
                    isHeader: true,
                    onMessageAction: onMessageAction),
            ]),
            for (var ri = 0; ri < normalizedRows.length; ri++)
              TableRow(
                  decoration: BoxDecoration(
                      color: ri.isEven
                          ? panelColor
                          : panelColor.withValues(alpha: isUser ? 0.07 : 0.72)),
                  children: [
                    for (final cell in normalizedRows[ri])
                      _MarkdownTableCell(
                          text: cell,
                          textColor: textColor,
                          onMessageAction: onMessageAction),
                  ]),
          ],
        ),
      ),
    );
  }
}

class _MarkdownTableCell extends StatelessWidget {
  const _MarkdownTableCell(
      {required this.text,
      required this.textColor,
      this.isHeader = false,
      this.onMessageAction});
  final String text;
  final Color textColor;
  final bool isHeader;
  final SessionMessageActionHandler? onMessageAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SelectableText(text,
          contextMenuBuilder: buildMessageActionContextMenu(onMessageAction),
          style: TextStyle(
              color: textColor,
              fontSize: isHeader ? 12.5 : 13,
              height: 1.45,
              fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500)),
    );
  }
}
