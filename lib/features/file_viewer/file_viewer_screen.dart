import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../app/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../session/data/derived_session_files_service.dart';
import '../session/data/session_project_repository_service.dart';
import '../session/data/session_files_provider.dart';
import '../session/data/session_files_repository.dart';
import '../session/domain/session_files_models.dart';

enum _FilePresentation {
  text,
  markdown,
  json,
  binary,
}

/// Session file viewer using real repository data instead of sample placeholders.
class FileViewerScreen extends ConsumerStatefulWidget {
  const FileViewerScreen({
    super.key,
    this.sessionId,
    this.fileId,
    required this.fileName,
    this.mimeType,
    this.filePath,
  });

  final String? sessionId;
  final String? fileId;
  final String fileName;
  final String? mimeType;
  final String? filePath;

  @override
  ConsumerState<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends ConsumerState<FileViewerScreen> {
  final DerivedSessionFilesService _derivedFilesService =
      const DerivedSessionFilesService();
  final SessionProjectRepositoryService _projectRepositoryService =
      SessionProjectRepositoryService();
  bool _isLoading = true;
  bool _usingDerivedContent = false;
  String? _error;
  String? _content;
  SessionFile? _resolvedFile;

  @override
  void initState() {
    super.initState();
    _loadFileContent();
  }

  _FilePresentation get _presentation {
    final name = (_resolvedFile?.fileName ?? widget.fileName).toLowerCase();
    final mime =
        (widget.mimeType ?? _resolvedFile?.mimeType ?? '').toLowerCase();

    final isBinaryMime = mime.startsWith('image/') ||
        mime == 'application/pdf' ||
        mime.startsWith('audio/') ||
        mime.startsWith('video/');
    if (isBinaryMime) {
      return _FilePresentation.binary;
    }

    if (name.endsWith('.md')) {
      return _FilePresentation.markdown;
    }
    if (name.endsWith('.json') || mime == 'application/json') {
      return _FilePresentation.json;
    }

    final binaryExtensions = <String>[
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.pdf',
      '.zip',
      '.mp3',
      '.mp4',
      '.mov',
    ];
    if (binaryExtensions.any(name.endsWith)) {
      return _FilePresentation.binary;
    }
    return _FilePresentation.text;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _resolvedFile?.fileName.isNotEmpty == true
        ? _resolvedFile!.fileName
        : widget.fileName;
    final displayPath =
        _resolvedFile?.filePath ?? _normalizePath(widget.filePath);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName.isEmpty ? '文件' : displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (displayPath != null && displayPath.isNotEmpty)
              Text(
                displayPath,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutral600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadFileContent,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
          if (_content != null && _content!.isNotEmpty)
            IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _content!));
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('文件内容已复制')),
                );
              },
              icon: const Icon(Icons.copy_outlined),
              tooltip: '复制',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
            style: const TextStyle(color: AppTheme.neutral700),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_presentation == _FilePresentation.binary) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '当前版本暂不支持直接预览该二进制文件，但文件浏览流程已与上游一致，点击文件将进入详情页。',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final content = _formattedContent();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_usingDerivedContent)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.infoColor.withValues(alpha: 0.22),
              ),
            ),
            child: const Text(
              '当前后端没有开放文件内容接口，下面展示的是根据会话消息和工具结果还原出的最近一次相关内容，可能不是完整文件。',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppTheme.neutral700,
              ),
            ),
          ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: _buildContentView(content),
          ),
        ),
      ],
    );
  }

  Widget _buildContentView(String content) {
    switch (_presentation) {
      case _FilePresentation.markdown:
        return SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.neutral200),
            ),
            child: MarkdownBody(
              data: content,
              selectable: true,
              softLineBreak: true,
              onTapLink: (text, href, title) {
                if (href != null && href.isNotEmpty) {
                  launchUrlString(href);
                }
              },
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppTheme.textPrimary,
                ),
                h1: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                h2: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                h3: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                code: const TextStyle(
                  fontFamily: AppTheme.fontFamilyMono,
                  fontSize: 12.5,
                  color: AppTheme.textPrimary,
                  backgroundColor: AppTheme.neutral100,
                ),
                a: const TextStyle(
                  color: AppTheme.brandColor,
                  decoration: TextDecoration.underline,
                ),
                blockquote: TextStyle(
                  color: AppTheme.neutral700.withValues(alpha: 0.9),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        );
      case _FilePresentation.json:
      case _FilePresentation.text:
        return SingleChildScrollView(
          child: _StandaloneCodePanel(
            code: content,
            language: _resolveLanguage(),
          ),
        );
      case _FilePresentation.binary:
        return const SizedBox.shrink();
    }
  }

  String _formattedContent() {
    final content = _content ?? '';
    if (_presentation == _FilePresentation.json) {
      try {
        final decoded = jsonDecode(content);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return content;
      }
    }
    return content;
  }

  String _resolveLanguage() {
    final mime = (widget.mimeType ?? _resolvedFile?.mimeType ?? '').toLowerCase();
    final name = (_resolvedFile?.fileName ?? widget.fileName).toLowerCase();

    if (name.endsWith('.dart')) return 'dart';
    if (name.endsWith('.ts')) return 'typescript';
    if (name.endsWith('.tsx')) return 'typescript';
    if (name.endsWith('.js') || name.endsWith('.jsx')) return 'javascript';
    if (name.endsWith('.json') || mime == 'application/json') return 'json';
    if (name.endsWith('.md')) return 'markdown';
    if (name.endsWith('.yaml') || name.endsWith('.yml')) return 'yaml';
    if (name.endsWith('.sh') || name.endsWith('.bash') || mime.contains('shell')) {
      return 'bash';
    }
    if (name.endsWith('.py')) return 'python';
    if (name.endsWith('.go')) return 'go';
    if (name.endsWith('.java')) return 'java';
    if (name.endsWith('.kt')) return 'kotlin';
    if (name.endsWith('.swift')) return 'swift';
    if (name.endsWith('.rs')) return 'rust';
    if (name.endsWith('.html')) return 'html';
    if (name.endsWith('.css')) return 'css';
    if (name.endsWith('.sql')) return 'sql';
    if (mime.contains('xml') || name.endsWith('.xml')) return 'xml';
    return 'plaintext';
  }

  Future<void> _loadFileContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _usingDerivedContent = false;
    });

    final normalizedPath = _normalizePath(widget.filePath);
    try {
      if (widget.sessionId != null &&
          widget.sessionId!.isNotEmpty &&
          normalizedPath != null &&
          normalizedPath.isNotEmpty) {
        final notifier = ref.read(sessionStateProvider.notifier);
        var session = notifier.getSession(widget.sessionId!);
        if (session == null) {
          await notifier.loadSessions(force: true);
          session = notifier.getSession(widget.sessionId!);
        }
        if (session != null) {
          final rpcContent = await _projectRepositoryService.readFileContent(
            session: session,
            notifier: notifier,
            filePath: normalizedPath,
          );
          if (rpcContent != null) {
            if (!mounted) {
              return;
            }
            setState(() {
              _content = rpcContent.content;
              _isLoading = false;
              _usingDerivedContent = false;
            });
            return;
          }
        }
      }

      final repository = ref.read(sessionFilesRepositoryProvider);
      var resolvedFileId = widget.fileId;
      SessionFile? resolvedFile;

      if (widget.sessionId != null &&
          widget.sessionId!.isNotEmpty &&
          widget.filePath != null &&
          widget.filePath!.trim().isNotEmpty) {
        resolvedFile = await repository.findFileByPath(
          widget.sessionId!,
          normalizedPath!,
        );
        resolvedFileId ??= resolvedFile?.id;
      }

      if (resolvedFileId != null && resolvedFileId.startsWith('derived:')) {
        throw const SessionFilesApiException(
          message: '当前文件来自会话回退数据',
          statusCode: 404,
        );
      }

      if (resolvedFileId == null || resolvedFileId.isEmpty) {
        throw Exception('缺少可读取的文件标识');
      }

      final content = await repository.readFileContent(resolvedFileId);
      if (!mounted) {
        return;
      }

      setState(() {
        _resolvedFile = resolvedFile;
        _content = content;
        _isLoading = false;
        _usingDerivedContent = false;
      });
    } catch (error) {
      final derived = await _loadDerivedFileContent(
        normalizedPath: normalizedPath,
      );
      if (derived != null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _resolvedFile = derived.$1;
          _content = derived.$2;
          _isLoading = false;
          _usingDerivedContent = true;
          _error = null;
        });
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '读取文件失败: $error';
        _isLoading = false;
      });
    }
  }

  Future<(SessionFile?, String?)?> _loadDerivedFileContent({
    required String? normalizedPath,
  }) async {
    if (widget.sessionId == null ||
        widget.sessionId!.isEmpty ||
        normalizedPath == null ||
        normalizedPath.isEmpty) {
      return null;
    }

    final notifier = ref.read(sessionStateProvider.notifier);
    var session = notifier.getSession(widget.sessionId!);
    if (session == null) {
      await notifier.loadSessions(force: true);
      session = notifier.getSession(widget.sessionId!);
    }
    await notifier.loadSessionMessages(widget.sessionId!);
    final messages =
        notifier.getSessionMessages(widget.sessionId!)?.messages ?? const [];

    final derivedFile = _derivedFilesService.findDerivedFileByPath(
      sessionId: widget.sessionId!,
      filePath: normalizedPath,
      session: session,
      messages: messages,
    );
    final content = _derivedFilesService.deriveFileContent(
      filePath: normalizedPath,
      session: session,
      messages: messages,
    );
    if (derivedFile == null && (content == null || content.isEmpty)) {
      return null;
    }
    return (derivedFile, content);
  }

  String? _normalizePath(String? rawPath) {
    if (rawPath == null || rawPath.trim().isEmpty) {
      return rawPath;
    }

    final trimmed = Uri.decodeComponent(rawPath.trim());
    try {
      var padded = trimmed.replaceAll('-', '+').replaceAll('_', '/');
      while (padded.length % 4 != 0) {
        padded += '=';
      }
      final decoded = utf8.decode(base64Decode(padded));
      if (decoded.contains('/') || decoded.contains('\\')) {
        return decoded;
      }
    } catch (_) {
      // Fall back to the raw path when it is not base64-encoded.
    }

    return trimmed;
  }
}

class _StandaloneCodePanel extends StatelessWidget {
  const _StandaloneCodePanel({
    required this.code,
    required this.language,
  });

  final String code;
  final String language;

  @override
  Widget build(BuildContext context) {
    final normalized = code.trimRight();
    final lines = normalized.isEmpty ? const <String>[] : normalized.split('\n');
    final normalizedLanguage = _normalizeLanguage(language);
    final canHighlight = _canHighlightLanguage(normalizedLanguage);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: const Color(0xFF2D3748)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5F56),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFBD2E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF27C93F),
                    shape: BoxShape.circle,
                  ),
                ),
                const Spacer(),
                Text(
                  normalizedLanguage == 'plaintext'
                      ? '文本视图'
                      : normalizedLanguage.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 12, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var index = 0; index < lines.length; index++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1.8),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontFamily: AppTheme.fontFamilyMono,
                                height: 1.55,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.only(right: 14),
                    color: const Color(0xFF2D3748),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.sizeOf(context).width - 92,
                    ),
                    child: canHighlight
                        ? HighlightView(
                            normalized,
                            language: normalizedLanguage,
                            theme: vs2015Theme,
                            padding: EdgeInsets.zero,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              height: 1.55,
                              fontFamily: AppTheme.fontFamilyMono,
                            ),
                          )
                        : SelectableText(
                            normalized,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.55,
                              color: Color(0xFFE5E7EB),
                              fontFamily: AppTheme.fontFamilyMono,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _normalizeLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'ts':
      case 'tsx':
        return 'typescript';
      case 'js':
      case 'jsx':
        return 'javascript';
      case 'yml':
        return 'yaml';
      case 'shell':
      case 'sh':
      case 'zsh':
        return 'bash';
      default:
        return language.toLowerCase();
    }
  }

  static bool _canHighlightLanguage(String language) {
    const supported = <String>{
      'bash',
      'css',
      'dart',
      'go',
      'html',
      'java',
      'javascript',
      'json',
      'kotlin',
      'markdown',
      'plaintext',
      'python',
      'rust',
      'sql',
      'swift',
      'typescript',
      'xml',
      'yaml',
    };
    return supported.contains(language);
  }
}
