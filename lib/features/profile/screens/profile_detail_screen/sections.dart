part of 'profile_detail_screen.dart';

extension _ProfileDetailScreenSections on _ProfileDetailScreenState {
  Widget _buildBody(List<AIProfile> profiles) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        _buildBasicInfoSection(),
        const SizedBox(height: AppTheme.spacingLg),
        _buildProviderConfigSection(),
        const SizedBox(height: AppTheme.spacingLg),
        _buildEnvironmentVariablesSection(),
        const SizedBox(height: AppTheme.spacingXl),
        if (!_profile!.isBuiltIn) _buildDangerSection(),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    final providerType = _profile!.providerType;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('基本信息'),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? '请输入名称' : null,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (providerType != null) _buildProviderInfo(providerType),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderInfo(String providerType) {
    final (providerName, providerIcon) = switch (providerType) {
      'anthropic' => ('Anthropic (Claude)', Icons.psychology),
      'openai' => ('OpenAI (GPT)', Icons.smart_toy),
      'azure' => ('Azure OpenAI', Icons.cloud),
      'together' => ('Together AI', Icons.auto_awesome),
      _ => ('未知', Icons.settings),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(providerIcon, color: AppTheme.brandColor, size: 20),
          const SizedBox(width: 12),
          Text(
            providerName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          if (_profile!.isBuiltIn) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '内置',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.infoColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDangerSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('操作'),
            const SizedBox(height: AppTheme.spacingSm),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text('删除配置'),
              onPressed: _showDeleteConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutral700,
        ),
      ),
    );
  }
}
