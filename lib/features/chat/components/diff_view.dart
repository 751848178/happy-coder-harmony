import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';

/// Diff 视图组件
///
/// 显示文件修改的差异
class DiffView extends ConsumerStatefulWidget {
  const DiffView({
    super.key,
    required this.originalContent,
    required this.modifiedContent,
    this.filename = 'untitled',
  });

  final String originalContent;
  final String modifiedContent;
  final String filename;

  @override
  ConsumerState<DiffView> createState() => _DiffViewState();
}

class _DiffViewState extends ConsumerState<DiffView> {
  bool _showLineNumbers = true;
  bool _wrapLines = false;

  @override
  Widget build(BuildContext context) {
    final diffLines = _computeDiff(widget.originalContent, widget.modifiedContent);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        title: Text(widget.filename),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 折叠/展开按钮
          IconButton(
            icon: Icon(_wrapLines ? Icons.unfold_less : Icons.unfold_more),
            onPressed: () => setState(() => _wrapLines = !_wrapLines),
            tooltip: _wrapLines ? '折叠长行' : '显示完整行',
          ),
          // 行号显示按钮
          IconButton(
            icon: Icon(_showLineNumbers ? Icons.format_list_numbered : Icons.format_list_bulleted),
            onPressed: () => setState(() => _showLineNumbers = !_showLineNumbers),
            tooltip: _showLineNumbers ? '隐藏行号' : '显示行号',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 统计信息
            _buildStatsBar(context, diffLines),
            const Divider(),
            // Diff 内容
            ListView.builder(
              itemCount: diffLines.length,
              itemBuilder: (context, index) {
                return _buildDiffLine(diffLines[index], _showLineNumbers, _wrapLines);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计信息栏
  Widget _buildStatsBar(BuildContext context, List<DiffLine> diffLines) {
    final additions = diffLines.where((line) => line.type == DiffType.addition).length;
    final deletions = diffLines.where((line) => line.type == DiffType.deletion).length;
    final modifications = diffLines.where((line) => line.type == DiffType.modification).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        border: Border(
          bottom: BorderSide(color: AppTheme.neutral300),
        ),
      ),
      child: Row(
        children: [
          _buildStatItem('新增', additions, Colors.green),
          const SizedBox(width: 16),
          _buildStatItem('删除', deletions, Colors.red),
          const SizedBox(width: 16),
          _buildStatItem('修改', modifications, Colors.orange),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, int count, Color color) {
    return Row(
      children: [
        Icon(
          Icons.circle,
          size: 8,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.neutral600,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 构建差异行
  Widget _buildDiffLine(DiffLine line, bool showLineNumbers, bool wrapLines) {
    Color backgroundColor;
    Color textColor;

    switch (line.type) {
      case DiffType.context:
        backgroundColor = Colors.transparent;
        textColor = AppTheme.neutral600;
        break;
      case DiffType.addition:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case DiffType.deletion:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      case DiffType.modification:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
    }

    final contentWidget = Text(
      line.content,
      maxLines: wrapLines ? null : 1,
      overflow: wrapLines ? null : TextOverflow.ellipsis,
      style: TextStyle(
        color: textColor,
        fontSize: 13,
        fontFamily: 'IBMPlexMono',
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 行号
          if (showLineNumbers)
            Container(
              width: 50,
              child: Text(
                '${line.lineNumber}',
                style: TextStyle(
                  color: AppTheme.neutral400,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          const SizedBox(width: 8),
          // 符号
          if (line.type != DiffType.context)
            Text(
              line.symbol,
              style: TextStyle(
                color: AppTheme.neutral500,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          // 内容
          Expanded(child: contentWidget),
        ],
      ),
    );
  }

  /// 计算差异
  List<DiffLine> _computeDiff(String original, String modified) {
    final originalLines = original.split('\n');
    final modifiedLines = modified.split('\n');

    final diffLines = <DiffLine>[];
    int lineNumber = 1;

    // 使用简化的 diff 算法
    int originalIndex = 0;
    int modifiedIndex = 0;

    while (originalIndex < originalLines.length || modifiedIndex < modifiedLines.length) {
      final originalLine = originalIndex < originalLines.length
          ? originalLines[originalIndex]
          : '';
      final modifiedLine = modifiedIndex < modifiedLines.length
          ? modifiedLines[modifiedIndex]
          : '';

      if (originalLine == modifiedLine) {
        // 相同行
        diffLines.add(DiffLine(
          type: DiffType.context,
          lineNumber: lineNumber,
          symbol: ' ',
          content: originalLine,
        ));
        originalIndex++;
        modifiedIndex++;
      } else if (originalLine.isEmpty) {
        // 删除行
        diffLines.add(DiffLine(
          type: DiffType.addition,
          lineNumber: lineNumber,
          symbol: '+',
          content: modifiedLine,
        ));
        modifiedIndex++;
      } else if (modifiedLine.isEmpty) {
        // 新增行
        diffLines.add(DiffLine(
          type: DiffType.deletion,
          lineNumber: lineNumber,
          symbol: '-',
          content: originalLine,
        ));
        originalIndex++;
      } else {
        // 修改行
        diffLines.add(DiffLine(
          type: DiffType.modification,
          lineNumber: lineNumber,
          symbol: '~',
          content: modifiedLine,
        ));
        originalIndex++;
        modifiedIndex++;
      }

      lineNumber++;
    }

    return diffLines;
  }
}

/// 差异行
class DiffLine {
  final DiffType type;
  final int lineNumber;
  final String symbol;
  final String content;

  DiffLine({
    required this.type,
    required this.lineNumber,
    required this.symbol,
    required this.content,
  });
}

/// 差异类型
enum DiffType {
  context,
  addition,
  deletion,
  modification,
}
