part of 'diff_view.dart';

List<DiffLine> _computeDiffLines(String original, String modified) {
  final originalLines = original.split('\n');
  final modifiedLines = modified.split('\n');
  final diffLines = <DiffLine>[];
  var lineNumber = 1;
  var originalIndex = 0;
  var modifiedIndex = 0;

  while (originalIndex < originalLines.length ||
      modifiedIndex < modifiedLines.length) {
    final originalLine = originalIndex < originalLines.length
        ? originalLines[originalIndex]
        : '';
    final modifiedLine = modifiedIndex < modifiedLines.length
        ? modifiedLines[modifiedIndex]
        : '';
    if (originalLine == modifiedLine) {
      diffLines.add(DiffLine(
          type: DiffType.context,
          lineNumber: lineNumber,
          symbol: ' ',
          content: originalLine));
      originalIndex++;
      modifiedIndex++;
    } else if (originalLine.isEmpty) {
      diffLines.add(DiffLine(
          type: DiffType.addition,
          lineNumber: lineNumber,
          symbol: '+',
          content: modifiedLine));
      modifiedIndex++;
    } else if (modifiedLine.isEmpty) {
      diffLines.add(DiffLine(
          type: DiffType.deletion,
          lineNumber: lineNumber,
          symbol: '-',
          content: originalLine));
      originalIndex++;
    } else {
      diffLines.add(DiffLine(
          type: DiffType.modification,
          lineNumber: lineNumber,
          symbol: '~',
          content: modifiedLine));
      originalIndex++;
      modifiedIndex++;
    }
    lineNumber++;
  }

  return diffLines;
}

class DiffLine {
  DiffLine({
    required this.type,
    required this.lineNumber,
    required this.symbol,
    required this.content,
  });

  final DiffType type;
  final int lineNumber;
  final String symbol;
  final String content;
}

enum DiffType {
  context,
  addition,
  deletion,
  modification,
}
