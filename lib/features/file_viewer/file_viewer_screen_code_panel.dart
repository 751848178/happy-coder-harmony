part of 'file_viewer_screen.dart';

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
    final lines =
        normalized.isEmpty ? const <String>[] : normalized.split('\n');
    final normalizedLanguage = normalizeFileViewerLanguage(language);
    final canHighlight = canHighlightFileViewerLanguage(normalizedLanguage);

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
          _FileViewerCodePanelHeader(language: normalizedLanguage),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 12, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FileViewerCodeLineNumbers(count: lines.length),
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
}

class _FileViewerCodePanelHeader extends StatelessWidget {
  const _FileViewerCodePanelHeader({
    required this.language,
  });

  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      child: Row(
        children: [
          for (final color in const [
            Color(0xFFFF5F56),
            Color(0xFFFFBD2E),
            Color(0xFF27C93F),
          ]) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (color != const Color(0xFF27C93F)) const SizedBox(width: 6),
          ],
          const Spacer(),
          Text(
            language == 'plaintext' ? '文本视图' : language.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FileViewerCodeLineNumbers extends StatelessWidget {
  const _FileViewerCodeLineNumbers({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < count; index++)
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
    );
  }
}
