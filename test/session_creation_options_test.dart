import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/profile/domain/profile_models.dart';
import 'package:happy_coder_flutter/features/session/domain/session_creation_options.dart';

void main() {
  test('codex exposes full upstream model list', () {
    final options = modelOptionsForAgent('codex');

    expect(
      options.map((option) => option.key),
      containsAll(<String>[
        'gpt-5-codex-high',
        'gpt-5-codex-medium',
        'gpt-5-codex-low',
        'gpt-5-minimal',
        'gpt-5-low',
        'gpt-5-medium',
        'gpt-5-high',
      ]),
    );
  });

  test('profile preferred agent follows compatibility and provider', () {
    final claudeProfile = AIProfile(
      id: 'claude-only',
      name: 'Claude Only',
      anthropicConfig: const AnthropicConfig(model: 'claude-3-5-sonnet'),
      compatibility: const ProfileCompatibility(
        claude: true,
        codex: false,
        gemini: false,
      ),
    );
    final codexProfile = AIProfile(
      id: 'codex-only',
      name: 'Codex Only',
      openaiConfig: const OpenAIConfig(model: 'gpt-4o'),
      compatibility: const ProfileCompatibility(
        claude: false,
        codex: true,
        gemini: false,
      ),
    );

    expect(resolvePreferredAgentForProfile(claudeProfile, fallback: 'codex'),
        'claude');
    expect(resolvePreferredAgentForProfile(codexProfile, fallback: 'claude'),
        'codex');
  });
}
