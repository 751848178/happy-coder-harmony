part of 'file_viewer_screen.dart';

extension on _FileViewerScreenState {
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
        if (_usingDerivedContent) const _DerivedFileContentBanner(),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child:
                _isEditing ? _buildEditModeView() : _buildContentView(content),
          ),
        ),
      ],
    );
  }

  Widget _buildContentView(String content) {
    switch (_presentation) {
      case _FilePresentation.markdown:
        return SingleChildScrollView(
          child: _FileViewerMarkdownCard(content: content),
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

  Widget _buildEditModeView() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: const Color(0xFF2D3748)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FileViewerCodePanelHeader(language: _resolveLanguage()),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: TextField(
                controller: _editController,
                maxLines: null,
                expands: true,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  fontFamily: AppTheme.fontFamilyMono,
                  color: Color(0xFFE5E7EB),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DerivedFileContentBanner extends StatelessWidget {
  const _DerivedFileContentBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.22)),
      ),
      child: const Text(
        '当前后端没有开放文件内容接口，下面展示的是根据会话消息和工具结果还原出的最近一次相关内容，可能不是完整文件。',
        style: TextStyle(
          fontSize: 12,
          height: 1.5,
          color: AppTheme.neutral700,
        ),
      ),
    );
  }
}

class _FileViewerMarkdownCard extends StatelessWidget {
  const _FileViewerMarkdownCard({
    required this.content,
  });

  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        styleSheet: fileViewerMarkdownStyleSheet(),
      ),
    );
  }
}
