part of 'profile_list_screen.dart';

Widget _buildProfileProviderSelector(_ProfileEditSheetState state) {
  return Column(
    children: [
      _buildProfileSectionHeader('AI 提供商'),
      _buildProfileDropdownField<String>(
        label: '选择提供商',
        value: state._providerType,
        items: const [
          DropdownMenuItem(
              value: 'anthropic', child: Text('Anthropic (Claude)')),
          DropdownMenuItem(value: 'openai', child: Text('OpenAI (GPT)')),
          DropdownMenuItem(value: 'azure', child: Text('Azure OpenAI')),
          DropdownMenuItem(value: 'together', child: Text('Together AI')),
        ],
        onChanged: (value) {
          state._updateView(() {
            state._providerType = value!;
            final options =
                ModelOption.getOptionsForProvider(state._providerType);
            state._selectedModel = options.isNotEmpty ? options.first : null;
          });
        },
      ),
    ],
  );
}

Widget _buildProfileProviderConfig(_ProfileEditSheetState state) {
  switch (state._providerType) {
    case 'anthropic':
      return _buildProfileProviderForm(
        state,
        title: 'Anthropic 配置',
        providerKey: 'anthropic',
        fields: [
          _profileField(
            state._authTokenController,
            'API Token',
            hintText: 'sk-ant-...',
            obscureText: true,
          ),
          _profileField(
            state._baseUrlController,
            'Base URL（可选）',
            hintText: 'https://api.anthropic.com',
          ),
        ],
      );
    case 'openai':
      return _buildProfileProviderForm(
        state,
        title: 'OpenAI 配置',
        providerKey: 'openai',
        fields: [
          _profileField(
            state._apiKeyController,
            'API Key',
            hintText: 'sk-...',
            obscureText: true,
          ),
          _profileField(
            state._baseUrlController,
            'Base URL（可选）',
            hintText: 'https://api.openai.com/v1',
          ),
        ],
      );
    case 'azure':
      return _buildProfileProviderForm(
        state,
        title: 'Azure OpenAI 配置',
        providerKey: 'azure',
        fields: [
          _profileField(state._apiKeyController, 'API Key', obscureText: true),
          _profileField(
            state._endpointController,
            'Endpoint',
            hintText: 'https://your-resource.openai.azure.com',
          ),
          _profileField(
            state._apiVersionController,
            'API Version',
            hintText: '2024-02-15-preview',
          ),
          _profileField(state._deploymentNameController, 'Deployment Name'),
        ],
      );
    case 'together':
      return _buildProfileProviderForm(
        state,
        title: 'Together AI 配置',
        providerKey: 'together',
        fields: [
          _profileField(state._apiKeyController, 'API Key', obscureText: true),
        ],
      );
    default:
      return const SizedBox.shrink();
  }
}

Widget _buildProfileProviderForm(
  _ProfileEditSheetState state, {
  required String title,
  required String providerKey,
  required List<Widget> fields,
}) {
  final options = ModelOption.getOptionsForProvider(providerKey);
  return Column(
    children: [
      _buildProfileSectionHeader(title),
      for (var index = 0; index < fields.length; index++) ...[
        fields[index],
        if (index != fields.length - 1)
          const SizedBox(height: AppTheme.spacingMd),
      ],
      if (fields.isNotEmpty) const SizedBox(height: AppTheme.spacingMd),
      _buildProfileSectionHeader('模型选择'),
      ModelSelector(
        options: options,
        selectedOption: state._selectedModel,
        onChanged: (option) {
          state._updateView(() {
            state._selectedModel = option;
            state._modelController.text = option.model ?? '';
          });
        },
      ),
      if (state._selectedModel?.maxTokens != null) ...[
        const SizedBox(height: AppTheme.spacingMd),
        Center(
          child: ContextSizeDisplay(
            maxTokens: state._selectedModel!.maxTokens!,
            contextWindow: state._selectedModel!.contextWindow ?? '',
          ),
        ),
      ],
    ],
  );
}

Widget _profileField(
  TextEditingController controller,
  String label, {
  String? hintText,
  bool obscureText = false,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      hintText: hintText,
      border: const OutlineInputBorder(),
    ),
    obscureText: obscureText,
  );
}
