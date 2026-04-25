part of 'session_git_diff_screen.dart';

extension on _SessionGitDiffScreenState {
  List<Widget> _buildAppBarActions(String diff) {
    return [
      if (diff.trim().isNotEmpty)
        IconButton(
          icon: const Icon(Icons.copy_all_outlined),
          tooltip: '复制 diff',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: diff));
          },
        ),
      IconButton(
        icon: const Icon(Icons.description_outlined),
        tooltip: '查看当前文件完整内容',
        onPressed: () {
          final uri = Uri(
            path: AppRoutes.sessionFileDetail(widget.sessionId),
            queryParameters: {
              if (widget.file.fileId != null && widget.file.fileId!.isNotEmpty)
                'fileId': widget.file.fileId!,
              'path': widget.file.path,
              'name': widget.file.fileName,
            },
          );
          context.push(uri.toString());
        },
      ),
    ];
  }

  Widget _buildDisplayModeBar({required _GitFileDisplayMode mode}) {
    final hasDiff = (_diffContent ?? '').trim().isNotEmpty;
    final hasFile = _fileContent != null || _isBinary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(
          top: BorderSide(color: Color(0xFF1F2937)),
          bottom: BorderSide(color: Color(0xFF1F2937)),
        ),
      ),
      child: Row(
        children: [
          if (hasDiff)
            _ModeButton(
              label: 'Diff',
              selected: mode == _GitFileDisplayMode.diff,
              onPressed: () => _setDisplayMode(_GitFileDisplayMode.diff),
            ),
          if (hasDiff && hasFile) const SizedBox(width: 8),
          if (hasFile)
            _ModeButton(
              label: '当前文件',
              selected: mode == _GitFileDisplayMode.file,
              onPressed: () => _setDisplayMode(_GitFileDisplayMode.file),
            ),
        ],
      ),
    );
  }
}
