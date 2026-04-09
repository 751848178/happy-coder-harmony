import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../app/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../session/data/derived_session_files_service.dart';
import '../session/data/session_files_provider.dart';
import '../session/data/session_files_repository.dart';
import '../session/data/session_project_repository_service.dart';
import '../session/domain/session_files_models.dart';

part 'file_viewer_screen_body.dart';
part 'file_viewer_screen_chrome.dart';
part 'file_viewer_screen_code_panel.dart';
part 'file_viewer_screen_code_panel_helpers.dart';
part 'file_viewer_screen_helpers.dart';
part 'file_viewer_screen_load.dart';

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

  // Editing state
  bool _isEditing = false;
  bool _isSaving = false;
  TextEditingController? _editController;

  @override
  void initState() {
    super.initState();
    _loadFileContent();
  }

  @override
  void dispose() {
    _editController?.dispose();
    super.dispose();
  }

  bool get _canEdit =>
      !_usingDerivedContent &&
      widget.sessionId != null &&
      widget.sessionId!.isNotEmpty &&
      widget.filePath != null &&
      widget.filePath!.isNotEmpty &&
      (_presentation == _FilePresentation.text ||
          _presentation == _FilePresentation.json);

  void _enterEditMode() {
    if (_content == null) return;
    _editController?.dispose();
    _editController = TextEditingController(text: _content);
    setState(() {
      _isEditing = true;
    });
  }

  void _exitEditMode() {
    setState(() {
      _isEditing = false;
      _isSaving = false;
    });
    _editController?.dispose();
    _editController = null;
  }

  void _setSaving(bool value) {
    setState(() => _isSaving = value);
  }

  void _showSaveError(String message) {
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSaveSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('文件已保存')),
    );
  }

  void _beginLoadingFileContent() {
    setState(() {
      _isLoading = true;
      _error = null;
      _usingDerivedContent = false;
    });
  }

  void _showLoadedRepositoryContent({
    required String content,
  }) {
    setState(() {
      _content = content;
      _isLoading = false;
      _usingDerivedContent = false;
    });
  }

  void _showLoadedSessionContent({
    required SessionFile? resolvedFile,
    required String content,
  }) {
    setState(() {
      _resolvedFile = resolvedFile;
      _content = content;
      _isLoading = false;
      _usingDerivedContent = false;
    });
  }

  void _showDerivedContent({
    required SessionFile? resolvedFile,
    required String? content,
  }) {
    setState(() {
      _resolvedFile = resolvedFile;
      _content = content;
      _isLoading = false;
      _usingDerivedContent = true;
      _error = null;
    });
  }

  void _showLoadError(Object error) {
    setState(() {
      _error = '读取文件失败: $error';
      _isLoading = false;
    });
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
    const binaryExtensions = <String>[
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
        title: _FileViewerAppBarTitle(
            displayName: displayName, displayPath: displayPath),
        actions: _buildAppBarActions(),
      ),
      body: _buildBody(),
    );
  }
}
