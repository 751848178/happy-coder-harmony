part of 'profile_detail_screen.dart';

extension _ProfileDetailScreenProviderConfig on _ProfileDetailScreenState {
  Widget _buildProviderConfigSection() {
    final providerType = _profile!.providerType;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('${_profile!.providerDisplayName ?? 'AI'} 配置'),
            const SizedBox(height: AppTheme.spacingSm),
            if (providerType != null)
              _buildProviderSpecificConfig(providerType),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSpecificConfig(String providerType) {
    return switch (providerType) {
      'anthropic' => _buildAnthropicConfig(),
      'openai' => _buildOpenAIConfig(),
      'azure' => _buildAzureConfig(),
      'together' => _buildTogetherConfig(),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildAnthropicConfig() => _buildProviderFields(
        apiLabel: 'API Token',
        apiValue: _profile!.anthropicConfig?.authToken ?? '',
        baseLabel: 'Base URL（可选）',
        baseValue: _profile!.anthropicConfig?.baseUrl ?? '',
        footer: '当前模型: ${_profile!.anthropicConfig?.model ?? '默认'}',
      );

  Widget _buildOpenAIConfig() => _buildProviderFields(
        apiLabel: 'API Key',
        apiValue: _profile!.openaiConfig?.apiKey ?? '',
        baseLabel: 'Base URL（可选）',
        baseValue: _profile!.openaiConfig?.baseUrl ?? '',
        footer: '当前模型: ${_profile!.openaiConfig?.model ?? '默认'}',
      );

  Widget _buildAzureConfig() => _buildProviderFields(
        apiLabel: 'API Key',
        apiValue: _profile!.azureOpenAIConfig?.apiKey ?? '',
        baseLabel: 'Endpoint',
        baseValue: _profile!.azureOpenAIConfig?.endpoint ?? '',
      );

  Widget _buildTogetherConfig() => _buildProviderFields(
        apiLabel: 'API Key',
        apiValue: _profile!.togetherAIConfig?.apiKey ?? '',
        footer: '当前模型: ${_profile!.togetherAIConfig?.model ?? '默认'}',
      );

  Widget _buildProviderFields({
    required String apiLabel,
    required String apiValue,
    String? baseLabel,
    String? baseValue,
    String? footer,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: apiLabel,
            border: const OutlineInputBorder(),
          ),
          enabled: !_profile!.isBuiltIn,
          obscureText: true,
          controller: TextEditingController(text: apiValue),
        ),
        if (baseLabel != null) ...[
          const SizedBox(height: AppTheme.spacingMd),
          TextFormField(
            decoration: InputDecoration(
              labelText: baseLabel,
              border: const OutlineInputBorder(),
            ),
            enabled: !_profile!.isBuiltIn,
            controller: TextEditingController(text: baseValue ?? ''),
          ),
        ],
        if (footer != null) ...[
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            footer,
            style: const TextStyle(fontSize: 13, color: AppTheme.neutral600),
          ),
        ],
      ],
    );
  }
}
