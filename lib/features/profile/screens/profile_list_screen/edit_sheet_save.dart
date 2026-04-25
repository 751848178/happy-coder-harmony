part of 'profile_list_screen.dart';

void _saveProfileEditSheet(_ProfileEditSheetState state) {
  if (!state._formKey.currentState!.validate()) {
    return;
  }

  final result = <String, dynamic>{
    'name': state._nameController.text.trim(),
    'description': state._descriptionController.text.trim(),
    'providerType': state._providerType,
    'permissionMode': state._permissionMode,
    'sessionType': state._sessionType,
  };

  switch (state._providerType) {
    case 'anthropic':
      result['baseUrl'] = state._baseUrlController.text.trim();
      result['authToken'] = state._authTokenController.text.trim();
      result['model'] = state._modelController.text.trim();
      break;
    case 'openai':
      result['baseUrl'] = state._baseUrlController.text.trim();
      result['apiKey'] = state._apiKeyController.text.trim();
      result['model'] = state._modelController.text.trim();
      break;
    case 'azure':
      result['apiKey'] = state._apiKeyController.text.trim();
      result['endpoint'] = state._endpointController.text.trim();
      result['apiVersion'] = state._apiVersionController.text.trim();
      result['deploymentName'] = state._deploymentNameController.text.trim();
      break;
    case 'together':
      result['apiKey'] = state._apiKeyController.text.trim();
      result['model'] = state._modelController.text.trim();
      break;
  }

  Navigator.pop(state.context, result);
}
