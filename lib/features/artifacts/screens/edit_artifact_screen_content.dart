part of 'edit_artifact_screen.dart';

extension _EditArtifactScreenContent on _EditArtifactScreenState {
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandColor),
      );
    }

    if (_error != null || _artifact == null) {
      return Center(
        child: Text(
          _error ?? '工件不存在',
          style: const TextStyle(color: AppTheme.neutral600),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InputSection(
          label: '标题',
          child: TextField(
            controller: _titleController,
            decoration: _inputDecoration('例如：重构后的路由梳理'),
            onChanged: (_) => _markDirty(),
          ),
        ),
        const SizedBox(height: 20),
        _InputSection(
          label: '正文',
          child: TextField(
            controller: _bodyController,
            minLines: 12,
            maxLines: 20,
            decoration: _inputDecoration('在这里编辑工件内容'),
            onChanged: (_) => _markDirty(),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: AppTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _InputSection extends StatelessWidget {
  const _InputSection({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
