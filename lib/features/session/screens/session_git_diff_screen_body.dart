part of 'session_git_diff_screen.dart';

class _SessionGitDiffAppBarTitle extends StatelessWidget {
  const _SessionGitDiffAppBarTitle({
    required this.file,
  });

  final SessionGitFile file;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          file.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        Text(
          file.path,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}

class _SessionGitDiffBody extends StatelessWidget {
  const _SessionGitDiffBody({
    required this.state,
    required this.diff,
    required this.displayMode,
  });

  final _SessionGitDiffScreenState state;
  final String diff;
  final _GitFileDisplayMode displayMode;

  @override
  Widget build(BuildContext context) {
    final lines = parseSessionGitPatch(diff);
    if (state._isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.brandColor),
      );
    }
    if (state._error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state._error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFCBD5E1), height: 1.6),
          ),
        ),
      );
    }
    if (displayMode == _GitFileDisplayMode.file) {
      return _SessionGitFileContentView(
        content: state._fileContent,
        isBinary: state._isBinary,
      );
    }
    if (lines.isEmpty) {
      return const Center(
        child: Text(
          '当前文件还没有可展示的 diff 内容。',
          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: lines.length,
      itemBuilder: (context, index) =>
          _SessionGitDiffLineTile(line: lines[index]),
    );
  }
}

class _SessionGitFileContentView extends StatelessWidget {
  const _SessionGitFileContentView({
    required this.content,
    required this.isBinary,
  });

  final String? content;
  final bool isBinary;

  @override
  Widget build(BuildContext context) {
    if (isBinary) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '当前文件是二进制内容，暂不支持直接预览源码。',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final source = content ?? '';
    if (source.isEmpty) {
      return const Center(
        child: Text(
          '当前没有可展示的文件内容。',
          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
        ),
      );
    }

    final fileLines = source.split('\n');
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: fileLines.length,
      itemBuilder: (context, index) => _SessionGitFileLineTile(
        lineNumber: index + 1,
        content: fileLines[index],
      ),
    );
  }
}
