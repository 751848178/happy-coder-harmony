import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../data/session_project_repository_service.dart';
import '../domain/session_git_models.dart';

class SessionGitDiffScreen extends ConsumerStatefulWidget {
  const SessionGitDiffScreen({
    super.key,
    required this.sessionId,
    required this.file,
  });

  final String sessionId;
  final SessionGitFile file;

  @override
  ConsumerState<SessionGitDiffScreen> createState() =>
      _SessionGitDiffScreenState();
}

enum _GitFileDisplayMode {
  diff,
  file,
}

class _SessionGitDiffScreenState extends ConsumerState<SessionGitDiffScreen> {
  final SessionProjectRepositoryService _repositoryService =
      SessionProjectRepositoryService();

  bool _isLoading = true;
  String? _error;
  String? _diffContent;
  String? _fileContent;
  bool _isBinary = false;
  _GitFileDisplayMode _displayMode = _GitFileDisplayMode.diff;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifier = ref.read(sessionStateProvider.notifier);
      var session = notifier.getSession(widget.sessionId);
      if (session == null) {
        await notifier.loadSessions(force: true);
        session = notifier.getSession(widget.sessionId);
      }
      if (session == null) {
        throw Exception('未找到当前会话');
      }

      final diffFuture = _repositoryService.loadGitDiff(
        session: session,
        notifier: notifier,
        file: widget.file,
      );
      final contentFuture = _repositoryService.readFileContent(
        session: session,
        notifier: notifier,
        filePath: widget.file.path,
      );

      final diff = await diffFuture;
      final content = await contentFuture;
      if (!mounted) {
        return;
      }

      setState(() {
        _diffContent = diff;
        _fileContent = content?.content;
        _isBinary = content?.isBinary ?? false;
        _displayMode = (diff != null && diff.trim().isNotEmpty)
            ? _GitFileDisplayMode.diff
            : _GitFileDisplayMode.file;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '加载文件改动失败: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final diff = _diffContent ?? widget.file.diff ?? '';
    final lines = _parsePatch(diff);
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.file.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.file.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        actions: [
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
                  if (widget.file.fileId != null &&
                      widget.file.fileId!.isNotEmpty)
                    'fileId': widget.file.fileId!,
                  'path': widget.file.path,
                  'name': widget.file.fileName,
                },
              );
              context.push(uri.toString());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _DiffSummaryBar(file: widget.file),
          if ((_diffContent ?? '').trim().isNotEmpty || _fileContent != null)
            _buildDisplayModeBar(),
          Expanded(
            child: _buildBody(lines),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayModeBar() {
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
              selected: _displayMode == _GitFileDisplayMode.diff,
              onPressed: () {
                setState(() => _displayMode = _GitFileDisplayMode.diff);
              },
            ),
          if (hasDiff && hasFile) const SizedBox(width: 8),
          if (hasFile)
            _ModeButton(
              label: '当前文件',
              selected: _displayMode == _GitFileDisplayMode.file,
              onPressed: () {
                setState(() => _displayMode = _GitFileDisplayMode.file);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBody(List<_PatchLine> lines) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              height: 1.6,
            ),
          ),
        ),
      );
    }

    if (_displayMode == _GitFileDisplayMode.file) {
      if (_isBinary) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '当前文件是二进制内容，暂不支持直接预览源码。',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      final content = _fileContent ?? '';
      if (content.isEmpty) {
        return const Center(
          child: Text(
            '当前没有可展示的文件内容。',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
            ),
          ),
        );
      }
      final fileLines = content.split('\n');
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: fileLines.length,
        itemBuilder: (context, index) {
          final lineNumber = index + 1;
          return Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    '$lineNumber',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    fileLines[index],
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      fontFamily: 'monospace',
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    if (lines.isEmpty) {
      return const Center(
        child: Text(
          '当前文件还没有可展示的 diff 内容。',
          style: TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        return Container(
          color: _backgroundFor(line.type),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  line.leftNumber?.toString() ?? '',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 52,
                child: Text(
                  line.rightNumber?.toString() ?? '',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 14,
                child: Text(
                  line.symbol,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: _foregroundFor(line.type),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  line.content,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.55,
                    fontFamily: 'monospace',
                    color: _foregroundFor(line.type),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_PatchLine> _parsePatch(String patch) {
    if (patch.trim().isEmpty) {
      return const [];
    }
    final result = <_PatchLine>[];
    var left = 0;
    var right = 0;
    final hunkPattern = RegExp(r'^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@');

    for (final rawLine in patch.split('\n')) {
      if (rawLine.startsWith('diff --git') ||
          rawLine.startsWith('index ') ||
          rawLine.startsWith('--- ') ||
          rawLine.startsWith('+++ ')) {
        result.add(_PatchLine.meta(rawLine));
        continue;
      }

      final hunkMatch = hunkPattern.firstMatch(rawLine);
      if (hunkMatch != null) {
        left = int.tryParse(hunkMatch.group(1) ?? '') ?? 0;
        right = int.tryParse(hunkMatch.group(2) ?? '') ?? 0;
        result.add(_PatchLine.header(rawLine));
        continue;
      }

      if (rawLine.startsWith('+')) {
        result.add(
          _PatchLine.added(
            content: rawLine.substring(1),
            rightNumber: right,
          ),
        );
        right += 1;
        continue;
      }

      if (rawLine.startsWith('-')) {
        result.add(
          _PatchLine.removed(
            content: rawLine.substring(1),
            leftNumber: left,
          ),
        );
        left += 1;
        continue;
      }

      result.add(
        _PatchLine.context(
          content: rawLine.startsWith(' ') ? rawLine.substring(1) : rawLine,
          leftNumber: left == 0 ? null : left,
          rightNumber: right == 0 ? null : right,
        ),
      );
      if (!rawLine.startsWith('\\')) {
        left += 1;
        right += 1;
      }
    }

    return result;
  }

  Color _backgroundFor(_PatchLineType type) {
    switch (type) {
      case _PatchLineType.added:
        return const Color(0xFF052E16);
      case _PatchLineType.removed:
        return const Color(0xFF3F0D12);
      case _PatchLineType.header:
        return const Color(0xFF1E293B);
      case _PatchLineType.meta:
        return const Color(0xFF111827);
      case _PatchLineType.context:
        return const Color(0xFF0F172A);
    }
  }

  Color _foregroundFor(_PatchLineType type) {
    switch (type) {
      case _PatchLineType.added:
        return const Color(0xFF86EFAC);
      case _PatchLineType.removed:
        return const Color(0xFFFDA4AF);
      case _PatchLineType.header:
        return const Color(0xFFBFDBFE);
      case _PatchLineType.meta:
        return const Color(0xFF94A3B8);
      case _PatchLineType.context:
        return const Color(0xFFE5E7EB);
    }
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFCBD5E1),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DiffSummaryBar extends StatelessWidget {
  const _DiffSummaryBar({required this.file});

  final SessionGitFile file;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1F2937)),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SummaryTag(
            label: _statusLabel(file.status),
            background: _statusColor(file.status).withValues(alpha: 0.16),
            foreground: _statusColor(file.status),
          ),
          if (file.addedLines > 0)
            const _SummaryTag(
              label: '新增行',
              background: Color(0x22052E16),
              foreground: Color(0xFF86EFAC),
              valuePrefix: '+',
            ).withValue(file.addedLines),
          if (file.removedLines > 0)
            const _SummaryTag(
              label: '删除行',
              background: Color(0x223F0D12),
              foreground: Color(0xFFFDA4AF),
              valuePrefix: '-',
            ).withValue(file.removedLines),
          if (file.previousPath != null && file.previousPath!.isNotEmpty)
            _SummaryTag(
              label: '来自 ${file.previousPath}',
              background: const Color(0xFF1F2937),
              foreground: const Color(0xFFCBD5E1),
            ),
        ],
      ),
    );
  }

  static String _statusLabel(SessionGitFileStatus status) {
    switch (status) {
      case SessionGitFileStatus.added:
        return '新增';
      case SessionGitFileStatus.deleted:
        return '删除';
      case SessionGitFileStatus.renamed:
        return '重命名';
      case SessionGitFileStatus.untracked:
        return '未跟踪';
      case SessionGitFileStatus.modified:
        return '修改';
    }
  }

  static Color _statusColor(SessionGitFileStatus status) {
    switch (status) {
      case SessionGitFileStatus.added:
        return const Color(0xFF22C55E);
      case SessionGitFileStatus.deleted:
        return const Color(0xFFEF4444);
      case SessionGitFileStatus.renamed:
        return const Color(0xFF3B82F6);
      case SessionGitFileStatus.untracked:
        return const Color(0xFF94A3B8);
      case SessionGitFileStatus.modified:
        return const Color(0xFFF59E0B);
    }
  }
}

class _SummaryTag extends StatelessWidget {
  const _SummaryTag({
    required this.label,
    required this.background,
    required this.foreground,
    this.value,
    this.valuePrefix = '',
  });

  final String label;
  final Color background;
  final Color foreground;
  final int? value;
  final String valuePrefix;

  _SummaryTag withValue(int nextValue) {
    return _SummaryTag(
      label: label,
      background: background,
      foreground: foreground,
      value: nextValue,
      valuePrefix: valuePrefix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value == null ? label : '$label $valuePrefix$value',
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

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
    return _PatchLine(
      type: _PatchLineType.meta,
      symbol: '',
      content: content,
    );
  }

  factory _PatchLine.header(String content) {
    return _PatchLine(
      type: _PatchLineType.header,
      symbol: '@',
      content: content,
    );
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
