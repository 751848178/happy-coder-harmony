part of 'new_session_screen.dart';

extension _NewSessionScreenContent on _NewSessionScreenState {
  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(
            label: '会话标题',
            child: TextField(
              controller: _titleController,
              decoration: _inputDecoration('输入会话标题（可选）'),
            ),
          ),
          _buildTemplateSection(),
          _buildField(
            label: '工作路径（可选）',
            child: TextField(
              controller: _pathController,
              decoration: _inputDecoration(
                '输入项目工作路径',
                prefixIcon: const Icon(Icons.folder_outlined),
              ),
            ),
          ),
          _buildField(
            label: '会话描述（可选）',
            child: TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _inputDecoration('添加会话描述或初始提示'),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  Widget _buildTemplateSection() {
    return _buildField(
      label: '选择会话类型',
      child: Wrap(
        spacing: AppTheme.spacingSm,
        runSpacing: AppTheme.spacingSm,
        children: _templates
            .map(
              (template) => _TemplateCard(
                template: template,
                isSelected: _selectedTag == template.id,
                onTap: () => _selectTag(template.id),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        child,
        const SizedBox(height: AppTheme.spacingLg),
      ],
    );
  }

  InputDecoration _inputDecoration(String hintText, {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.neutral200)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isCreating ? null : _createSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
            ),
            child: _isCreating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('创建会话'),
          ),
        ),
      ),
    );
  }

  Future<void> _createSession() async {
    _setCreating(true);
    try {
      final path = _pathController.text.trim();
      final description = _descriptionController.text.trim();
      final sessionId =
          await ref.read(sessionStateProvider.notifier).createSession(
                title: _titleController.text.trim().isEmpty
                    ? null
                    : _titleController.text.trim(),
                tag: _selectedTag,
                path: path.isNotEmpty ? path : null,
                metadata: description.isNotEmpty
                    ? {'description': description}
                    : null,
              );
      if (sessionId != null && mounted) {
        unawaited(
          openSessionDetail(
            context: context,
            ref: ref,
            sessionId: sessionId,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建会话失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        _setCreating(false);
      }
    }
  }
}
