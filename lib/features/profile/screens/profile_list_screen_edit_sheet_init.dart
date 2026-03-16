part of 'profile_list_screen.dart';

void _initializeProfileEditSheet(
  _ProfileEditSheetState state,
  AIProfile? profile,
) {
  if (profile == null) {
    state._nameController = TextEditingController(text: '');
    state._descriptionController = TextEditingController(text: '');
    state._permissionMode = PermissionMode.defaultMode;
    state._sessionType = SessionType.simple;
    final options = ModelOption.getOptionsForProvider(state._providerType);
    state._selectedModel = options.isNotEmpty ? options.first : null;
    return;
  }

  state._nameController = TextEditingController(text: profile.name);
  state._descriptionController =
      TextEditingController(text: profile.description ?? '');

  String? modelValue;
  if (profile.anthropicConfig != null) {
    state._providerType = 'anthropic';
    state._baseUrlController.text = profile.anthropicConfig!.baseUrl ?? '';
    state._authTokenController.text = profile.anthropicConfig!.authToken ?? '';
    modelValue = profile.anthropicConfig!.model;
    state._modelController.text = modelValue ?? '';
  } else if (profile.openaiConfig != null) {
    state._providerType = 'openai';
    state._apiKeyController.text = profile.openaiConfig!.apiKey ?? '';
    state._baseUrlController.text = profile.openaiConfig!.baseUrl ?? '';
    modelValue = profile.openaiConfig!.model;
    state._modelController.text = modelValue ?? '';
  } else if (profile.azureOpenAIConfig != null) {
    state._providerType = 'azure';
    state._apiKeyController.text = profile.azureOpenAIConfig!.apiKey ?? '';
    state._endpointController.text = profile.azureOpenAIConfig!.endpoint ?? '';
    state._apiVersionController.text =
        profile.azureOpenAIConfig!.apiVersion ?? '';
    state._deploymentNameController.text =
        profile.azureOpenAIConfig!.deploymentName ?? '';
    modelValue = profile.azureOpenAIConfig!.deploymentName;
  } else if (profile.togetherAIConfig != null) {
    state._providerType = 'together';
    state._apiKeyController.text = profile.togetherAIConfig!.apiKey ?? '';
    modelValue = profile.togetherAIConfig!.model;
    state._modelController.text = modelValue ?? '';
  }

  if (modelValue != null) {
    final options = ModelOption.getOptionsForProvider(state._providerType);
    state._selectedModel = options.cast<ModelOption?>().firstWhere(
          (option) => option?.model == modelValue,
          orElse: () => null,
        );
  }

  state._permissionMode = profile.defaultPermissionMode;
  state._sessionType = profile.defaultSessionType;
}

void _disposeProfileEditSheet(_ProfileEditSheetState state) {
  state._nameController.dispose();
  state._descriptionController.dispose();
  state._baseUrlController.dispose();
  state._authTokenController.dispose();
  state._modelController.dispose();
  state._apiKeyController.dispose();
  state._endpointController.dispose();
  state._apiVersionController.dispose();
  state._deploymentNameController.dispose();
}
