part of 'session_creation_options.dart';

Map<String, String> buildProfileEnvironmentVariables(
  profile_models.AIProfile profile,
) {
  final envVars = <String, String>{};
  for (final item in profile.environmentVariables) {
    envVars[item.name] = item.value;
  }
  _applyAnthropicEnv(envVars, profile);
  _applyOpenAiEnv(envVars, profile);
  _applyAzureEnv(envVars, profile);
  _applyTogetherEnv(envVars, profile);
  _applyTmuxEnv(envVars, profile);
  return envVars;
}

void _applyAnthropicEnv(
    Map<String, String> envVars, profile_models.AIProfile profile) {
  final anthropic = profile.anthropicConfig;
  if (anthropic == null) {
    return;
  }
  if ((anthropic.baseUrl ?? '').isNotEmpty) {
    envVars['ANTHROPIC_BASE_URL'] = anthropic.baseUrl!;
  }
  if ((anthropic.authToken ?? '').isNotEmpty) {
    envVars['ANTHROPIC_AUTH_TOKEN'] = anthropic.authToken!;
  }
  if ((anthropic.model ?? '').isNotEmpty) {
    envVars['ANTHROPIC_MODEL'] = anthropic.model!;
  }
}

void _applyOpenAiEnv(
    Map<String, String> envVars, profile_models.AIProfile profile) {
  final openai = profile.openaiConfig;
  if (openai == null) {
    return;
  }
  if ((openai.apiKey ?? '').isNotEmpty) {
    envVars['OPENAI_API_KEY'] = openai.apiKey!;
  }
  if ((openai.baseUrl ?? '').isNotEmpty) {
    envVars['OPENAI_BASE_URL'] = openai.baseUrl!;
  }
  if ((openai.model ?? '').isNotEmpty) {
    envVars['OPENAI_MODEL'] = openai.model!;
  }
}

void _applyAzureEnv(
    Map<String, String> envVars, profile_models.AIProfile profile) {
  final azure = profile.azureOpenAIConfig;
  if (azure == null) {
    return;
  }
  if ((azure.apiKey ?? '').isNotEmpty) {
    envVars['AZURE_OPENAI_API_KEY'] = azure.apiKey!;
  }
  if ((azure.endpoint ?? '').isNotEmpty) {
    envVars['AZURE_OPENAI_ENDPOINT'] = azure.endpoint!;
  }
  if ((azure.apiVersion ?? '').isNotEmpty) {
    envVars['AZURE_OPENAI_API_VERSION'] = azure.apiVersion!;
  }
  if ((azure.deploymentName ?? '').isNotEmpty) {
    envVars['AZURE_OPENAI_DEPLOYMENT_NAME'] = azure.deploymentName!;
  }
}

void _applyTogetherEnv(
    Map<String, String> envVars, profile_models.AIProfile profile) {
  final together = profile.togetherAIConfig;
  if (together == null) {
    return;
  }
  if ((together.apiKey ?? '').isNotEmpty) {
    envVars['TOGETHER_API_KEY'] = together.apiKey!;
  }
  if ((together.model ?? '').isNotEmpty) {
    envVars['TOGETHER_MODEL'] = together.model!;
  }
}

void _applyTmuxEnv(
    Map<String, String> envVars, profile_models.AIProfile profile) {
  final tmux = profile.tmuxConfig;
  if (tmux == null) {
    return;
  }
  if (tmux.sessionName != null) {
    envVars['TMUX_SESSION_NAME'] = tmux.sessionName!;
  }
  if (tmux.tmpDir != null) {
    envVars['TMUX_TMPDIR'] = tmux.tmpDir!;
  }
  if (tmux.updateEnvironment != null) {
    envVars['TMUX_UPDATE_ENVIRONMENT'] = tmux.updateEnvironment!.toString();
  }
}
