part of 'profile_list_screen.dart';

Widget _buildProfileEditSheet(_ProfileEditSheetState state) {
  return DraggableScrollableSheet(
    initialChildSize: 0.8,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    builder: (context, scrollController) => Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      child: Column(
        children: [
          _buildProfileEditHandle(),
          _buildProfileEditHeader(state),
          Expanded(
            child: Form(
              key: state._formKey,
              child: ListView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                children: [
                  _buildProfileSectionHeader('基本信息'),
                  _buildProfileNameField(state),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildProfileDescriptionField(state),
                  const SizedBox(height: AppTheme.spacingLg),
                  if (state.widget.profile == null) ...[
                    _buildProfileProviderSelector(state),
                    const SizedBox(height: AppTheme.spacingLg),
                  ],
                  _buildProfileProviderConfig(state),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildProfileSectionHeader('默认设置'),
                  _buildProfilePermissionField(state),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildProfileSessionTypeField(state),
                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ),
          _buildProfileSaveButton(state),
        ],
      ),
    ),
  );
}

Widget _buildProfileEditHandle() {
  return Container(
    margin: const EdgeInsets.only(top: 12),
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: AppTheme.neutral300,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

Widget _buildProfileEditHeader(_ProfileEditSheetState state) {
  return Padding(
    padding: const EdgeInsets.all(AppTheme.spacingLg),
    child: Row(
      children: [
        Text(
          state.widget.profile == null ? '创建配置' : '编辑配置',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(state.context),
        ),
      ],
    ),
  );
}

Widget _buildProfileSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.neutral600,
      ),
    ),
  );
}

Widget _buildProfileNameField(_ProfileEditSheetState state) {
  return TextFormField(
    controller: state._nameController,
    decoration: const InputDecoration(
      labelText: '名称',
      border: OutlineInputBorder(),
    ),
    validator: (value) => value == null || value.isEmpty ? '请输入名称' : null,
  );
}

Widget _buildProfileDescriptionField(_ProfileEditSheetState state) {
  return TextFormField(
    controller: state._descriptionController,
    decoration: const InputDecoration(
      labelText: '描述（可选）',
      border: OutlineInputBorder(),
    ),
    maxLines: 2,
  );
}

Widget _buildProfileSaveButton(_ProfileEditSheetState state) {
  return Container(
    padding: const EdgeInsets.all(AppTheme.spacingLg),
    child: SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _saveProfileEditSheet(state),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            state.widget.profile == null ? '创建' : '保存',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ),
  );
}
