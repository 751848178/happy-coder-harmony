part of 'diff_view.dart';

Widget _buildDiffViewScaffold(_DiffViewState state) {
  final diffLines = _computeDiffLines(
      state.widget.originalContent, state.widget.modifiedContent);
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: AppBar(
      title: Text(state.widget.filename),
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(state.context),
      ),
      actions: [
        IconButton(
          icon: Icon(state._wrapLines ? Icons.unfold_less : Icons.unfold_more),
          onPressed: () =>
              state._updateView(() => state._wrapLines = !state._wrapLines),
          tooltip: state._wrapLines ? '折叠长行' : '显示完整行',
        ),
        IconButton(
          icon: Icon(
            state._showLineNumbers
                ? Icons.format_list_numbered
                : Icons.format_list_bulleted,
          ),
          onPressed: () => state._updateView(
              () => state._showLineNumbers = !state._showLineNumbers),
          tooltip: state._showLineNumbers ? '隐藏行号' : '显示行号',
        ),
      ],
    ),
    body: SingleChildScrollView(
      child: Column(
        children: [
          _buildDiffStatsBar(diffLines),
          const Divider(),
          ListView.builder(
            itemCount: diffLines.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return _buildDiffLine(
                  diffLines[index], state._showLineNumbers, state._wrapLines);
            },
          ),
        ],
      ),
    ),
  );
}

Widget _buildDiffStatsBar(List<DiffLine> diffLines) {
  final additions =
      diffLines.where((line) => line.type == DiffType.addition).length;
  final deletions =
      diffLines.where((line) => line.type == DiffType.deletion).length;
  final modifications =
      diffLines.where((line) => line.type == DiffType.modification).length;
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.neutral100,
      border: Border(bottom: BorderSide(color: AppTheme.neutral300)),
    ),
    child: Row(
      children: [
        _buildDiffStatItem('新增', additions, Colors.green),
        const SizedBox(width: 16),
        _buildDiffStatItem('删除', deletions, Colors.red),
        const SizedBox(width: 16),
        _buildDiffStatItem('修改', modifications, Colors.orange),
      ],
    ),
  );
}

Widget _buildDiffStatItem(String label, int count, Color color) {
  return Row(
    children: [
      Icon(Icons.circle, size: 8, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: AppTheme.neutral600, fontSize: 12)),
      const SizedBox(width: 4),
      Text(
        '$count',
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

Widget _buildDiffLine(DiffLine line, bool showLineNumbers, bool wrapLines) {
  final (backgroundColor, textColor) = switch (line.type) {
    DiffType.context => (Colors.transparent, AppTheme.neutral600),
    DiffType.addition => (Colors.green.withValues(alpha: 0.1), Colors.green),
    DiffType.deletion => (Colors.red.withValues(alpha: 0.1), Colors.red),
    DiffType.modification => (
        Colors.orange.withValues(alpha: 0.1),
        Colors.orange
      ),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    color: backgroundColor,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLineNumbers)
          SizedBox(
            width: 50,
            child: Text(
              '${line.lineNumber}',
              style: TextStyle(
                  color: AppTheme.neutral400,
                  fontSize: 11,
                  fontFamily: 'monospace'),
            ),
          ),
        const SizedBox(width: 8),
        if (line.type != DiffType.context)
          Text(
            line.symbol,
            style: TextStyle(
                color: AppTheme.neutral500,
                fontSize: 12,
                fontFamily: 'monospace'),
          ),
        Expanded(
          child: Text(
            line.content,
            maxLines: wrapLines ? null : 1,
            overflow: wrapLines ? null : TextOverflow.ellipsis,
            style: TextStyle(
                color: textColor, fontSize: 13, fontFamily: 'IBMPlexMono'),
          ),
        ),
      ],
    ),
  );
}
