import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/profile/domain/profile_models.dart';
import 'package:happy_coder_flutter/features/session/domain/session_creation_options.dart';
import 'package:happy_coder_flutter/features/session/domain/session_models.dart';

void main() {
  test('model options fallback to a single default option', () {
    final options = modelOptionsForAgent('codex');

    expect(options.map((option) => option.key), <String>['default']);
  });

  test('model options prefer PC metadata models when available', () {
    final options = modelOptionsForAgent(
      'codex',
      metadataOptions: const [
        {'code': 'gpt-5.4', 'value': 'GPT-5.4'},
        {'code': 'gpt-5.4-mini', 'value': 'GPT-5.4 Mini'},
      ],
    );

    expect(
      options.map((option) => option.key),
      <String>['gpt-5.4', 'gpt-5.4-mini'],
    );
  });

  test('remote mode resolution prefers metadata over local preference', () {
    final resolved = resolveRemoteModeValue(
      metadataValue: 'gpt-5-codex-high',
      explicitValue: 'gpt-5-medium',
      preferredValue: 'gpt-5-low',
    );

    expect(resolved, 'gpt-5-codex-high');
  });

  test('local mode resolution preserves local preference over metadata', () {
    final resolved = resolveLocalModeValue(
      preferredValue: 'gpt-5-codex-high',
      explicitValue: 'gpt-5-medium',
      metadataValue: 'gpt-5-low',
    );

    expect(resolved, 'gpt-5-codex-high');
  });

  test('current mode resolution prefers remote metadata over local mode', () {
    final options = modelOptionsForAgent('codex');

    final resolved = resolveCurrentModeOption(
      options,
      <String?>[
        'gpt-5-codex-high',
        'gpt-5-medium',
        defaultModelModeForAgent('codex'),
      ],
    );

    expect(resolved?.key, 'gpt-5-codex-high');
  });

  test('current mode resolution keeps unknown remote model code visible', () {
    final options = modelOptionsForAgent('gemini');

    final resolved = resolveCurrentModeOption(
      options,
      <String?>[
        'missing-model',
        defaultModelModeForAgent('gemini'),
      ],
    );

    expect(resolved?.key, 'missing-model');
    expect(resolved?.label, 'missing-model');
  });

  test(
      'listed mode resolution matches upstream app and leaves unknown key unselected',
      () {
    final options = modelOptionsForAgent(
      'codex',
      metadataOptions: const [
        {'code': 'gpt-5-medium', 'value': 'GPT-5 Medium'},
      ],
    );

    final matched = findPreferredListedModeOption(
      options,
      <String?>['missing-model', 'gpt-5-medium'],
    );
    final missing = findPreferredListedModeOption(
      options,
      <String?>['missing-model'],
    );

    expect(matched?.key, 'gpt-5-medium');
    expect(missing, isNull);
  });

  test('listed mode selection falls back when preferred key is unknown', () {
    final resolved = resolveListedModeSelection(
      preferred: 'pc-only-model',
      options: modelOptionsForAgent('codex'),
      fallback: defaultModelModeForAgent('codex'),
    );

    expect(resolved, 'default');
  });

  test('new session flow model options only keep default fallback', () {
    final options = newSessionModelOptionsForAgent('codex');

    expect(options.map((option) => option.key), <String>['default']);
  });

  test('mode metadata still resolves newest matching machine and agent session',
      () {
    final metadata = resolveModeMetadataForSessions(
      <Session>[
        _session(
          id: 'session-older-codex',
          updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
          metadata: <String, dynamic>{
            'machineId': 'machine-1',
            'flavor': 'codex',
            'models': const [
              {'code': 'gpt-5-codex-medium', 'value': 'GPT-5 Codex Medium'},
            ],
          },
        ),
        _session(
          id: 'session-newer-claude',
          updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962445908),
          metadata: <String, dynamic>{
            'machineId': 'machine-1',
            'flavor': 'claude',
            'models': const [
              {'code': 'opus', 'value': 'Opus'},
            ],
          },
        ),
        _session(
          id: 'session-newest-codex',
          updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962446908),
          metadata: <String, dynamic>{
            'machineId': 'machine-1',
            'flavor': 'codex',
            'models': const [
              {'code': 'gpt-5-codex-high', 'value': 'GPT-5 Codex High'},
            ],
          },
        ),
      ],
      machineId: 'machine-1',
      agent: 'codex',
    );

    expect((metadata?['models'] as List?)?.first['code'], 'gpt-5-codex-high');
  });

  test('mode metadata falls back to matching machine metadata when needed', () {
    final metadata = resolveModeMetadataForMachines(
      <Machine>[
        Machine(
          id: 'machine-1',
          name: 'Machine 1',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1772962446908),
          metadata: const <String, dynamic>{
            'agents': {
              'codex': {
                'models': [
                  {'code': 'gpt-5-codex-high', 'value': 'GPT-5 Codex High'},
                ],
              },
            },
          },
        ),
      ],
      machineId: 'machine-1',
      agent: 'codex',
    );

    expect((metadata?['models'] as List?)?.first['code'], 'gpt-5-codex-high');
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

Session _session({
  required String id,
  required DateTime updatedAt,
  required Map<String, dynamic> metadata,
}) {
  return Session(
    id: id,
    title: id,
    messages: const <dynamic>[],
    createdAt: updatedAt,
    updatedAt: updatedAt,
    active: true,
    metadata: metadata,
  );
}
