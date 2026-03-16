part of 'session_screen.dart';

class _MarkdownTableBlock extends StatelessWidget {
  const _MarkdownTableBlock({
    required this.headers,
    required this.rows,
    required this.isUser,
    required this.textColor,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final bool isUser;
  final Color textColor;

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
        .map(
          (row) => List<String>.generate(
            headers.length,
            (index) => index < row.length ? row[index] : '',
          ),
        )
        .toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: {
            for (var index = 0; index < headers.length; index++)
              index: const IntrinsicColumnWidth(flex: 1),
          },
          border: TableBorder(
            horizontalInside: BorderSide(color: borderColor),
            verticalInside:
                BorderSide(color: borderColor.withValues(alpha: 0.55)),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerColor),
              children: [
                for (final header in headers)
                  _MarkdownTableCell(
                    text: header,
                    textColor: headerTextColor,
                    isHeader: true,
                  ),
              ],
            ),
            for (var rowIndex = 0; rowIndex < normalizedRows.length; rowIndex++)
              TableRow(
                decoration: BoxDecoration(
                  color: rowIndex.isEven
                      ? panelColor
                      : panelColor.withValues(alpha: isUser ? 0.07 : 0.72),
                ),
                children: [
                  for (final cell in normalizedRows[rowIndex])
                    _MarkdownTableCell(
                      text: cell,
                      textColor: textColor,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MarkdownTableCell extends StatelessWidget {
  const _MarkdownTableCell({
    required this.text,
    required this.textColor,
    this.isHeader = false,
  });

  final String text;
  final Color textColor;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SelectableText(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: isHeader ? 12.5 : 13,
          height: 1.45,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

