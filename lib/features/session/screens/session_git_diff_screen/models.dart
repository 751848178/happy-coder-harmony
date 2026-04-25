part of 'session_git_diff_screen.dart';

enum _PatchLineType {
  meta,
  header,
  added,
  removed,
  context,
}

class _PatchLine {
  const _PatchLine({
    required this.type,
    required this.symbol,
    required this.content,
    this.leftNumber,
    this.rightNumber,
  });

  final _PatchLineType type;
  final String symbol;
  final String content;
  final int? leftNumber;
  final int? rightNumber;

  factory _PatchLine.meta(String content) {
    return _PatchLine(type: _PatchLineType.meta, symbol: '', content: content);
  }

  factory _PatchLine.header(String content) {
    return _PatchLine(
        type: _PatchLineType.header, symbol: '@', content: content);
  }

  factory _PatchLine.added({
    required String content,
    int? rightNumber,
  }) {
    return _PatchLine(
      type: _PatchLineType.added,
      symbol: '+',
      content: content,
      rightNumber: rightNumber,
    );
  }

  factory _PatchLine.removed({
    required String content,
    int? leftNumber,
  }) {
    return _PatchLine(
      type: _PatchLineType.removed,
      symbol: '-',
      content: content,
      leftNumber: leftNumber,
    );
  }

  factory _PatchLine.context({
    required String content,
    int? leftNumber,
    int? rightNumber,
  }) {
    return _PatchLine(
      type: _PatchLineType.context,
      symbol: ' ',
      content: content,
      leftNumber: leftNumber,
      rightNumber: rightNumber,
    );
  }
}
