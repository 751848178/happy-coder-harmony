import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/profile/domain/profile_models.dart';
import 'package:happy_coder_flutter/features/session/domain/session_creation_options.dart';
import 'package:happy_coder_flutter/features/session/domain/session_models.dart';

void main() {
  test('model options return empty list when metadata is missing', () {
    final options = modelOptionsForAgent('codex');

    expect(options, isEmpty);
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

  test('model options return empty when agent has no metadata', () {
    expect(modelOptionsForAgent('claude'), isEmpty);
    expect(modelOptionsForAgent('codex'), isEmpty);
    expect(modelOptionsForAgent('gemini'), isEmpty);
    expect(modelOptionsForAgent(null), isEmpty);
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

  test('session permission mode keeps persisted local override on refresh', () {
    final resolved = resolveSessionPermissionMode(
      metadata: const <String, dynamic>{
        'flavor': 'claude',
        'currentOperatingModeCode': 'default',
      },
      localValue: 'acceptEdits',
      persistedValue: 'acceptEdits',
      explicitValue: 'default',
      metadataValue: 'default',
    );

    expect(resolved, 'acceptEdits');
  });

  test('session permission mode keeps explicit local default reset', () {
    final resolved = resolveSessionPermissionMode(
      metadata: const <String, dynamic>{
        'flavor': 'claude',
        'currentOperatingModeCode': 'bypassPermissions',
      },
      persistedValue: 'default',
      explicitValue: null,
      metadataValue: 'bypassPermissions',
    );

    expect(resolved, 'default');
  });

  test('session permission mode falls back to remote metadata when unset', () {
    final resolved = resolveSessionPermissionMode(
      metadata: const <String, dynamic>{
        'flavor': 'claude',
        'currentOperatingModeCode': 'plan',
      },
      explicitValue: null,
      metadataValue: 'plan',
    );

    expect(resolved, 'plan');
  });

  test('session permission mode defaults to bypass when sandbox is enabled',
      () {
    final resolved = resolveSessionPermissionMode(
      metadata: const <String, dynamic>{
        'flavor': 'claude',
        'sandbox': {'enabled': true},
      },
      explicitValue: null,
      metadataValue: null,
    );

    expect(resolved, 'bypassPermissions');
  });

  test('session model mode keeps persisted local override on refresh', () {
    final resolved = resolveSessionModelMode(
      metadata: const <String, dynamic>{
        'flavor': 'claude',
        'currentModelCode': 'default',
      },
      localValue: 'opus',
      persistedValue: 'opus',
      explicitValue: 'default',
      metadataValue: 'default',
    );

    expect(resolved, 'opus');
  });

  test('session model mode keeps in-memory local override on refresh', () {
    final resolved = resolveSessionModelMode(
      metadata: const <String, dynamic>{
        'flavor': 'codex',
        'currentModelCode': 'gpt-5-codex-high',
      },
      localValue: 'gpt-5-medium',
      explicitValue: null,
      metadataValue: 'gpt-5-codex-high',
    );

    expect(resolved, 'gpt-5-medium');
  });

  test(
      'session model mode resolves to remote metadata when persisted is default',
      () {
    final resolved = resolveSessionModelMode(
      metadata: const <String, dynamic>{
        'flavor': 'claude',
        'currentModelCode': 'opus',
      },
      persistedValue: 'default',
      explicitValue: null,
      metadataValue: 'opus',
    );

    expect(resolved, 'opus');
  });

  test('session model mode falls back to remote metadata when unset', () {
    final resolved = resolveSessionModelMode(
      metadata: const <String, dynamic>{
        'flavor': 'codex',
        'currentModelCode': 'gpt-5-codex-medium',
      },
      explicitValue: null,
      metadataValue: 'gpt-5-codex-medium',
    );

    expect(resolved, 'gpt-5-codex-medium');
  });

  test(
      'session model mode keeps default semantic when no explicit model exists',
      () {
    final resolved = resolveSessionModelMode(
      metadata: const <String, dynamic>{
        'flavor': 'codex',
      },
      explicitValue: null,
      metadataValue: null,
    );

    expect(resolved, 'default');
  });

  test('current mode resolution prefers remote metadata over local mode', () {
    final options = modelOptionsForAgent(
      'codex',
      metadataOptions: const [
        {'code': 'gpt-5-codex-high', 'value': 'GPT-5 Codex High'},
        {'code': 'gpt-5-medium', 'value': 'GPT-5 Medium'},
      ],
    );

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

  test('current mode resolution returns null when no model key matches', () {
    final options = modelOptionsForAgent(
      'gemini',
      metadataOptions: const [
        {'code': 'gemini-2.5-pro', 'value': 'Gemini 2.5 Pro'},
      ],
    );

    final resolved = resolveCurrentModeOption(
      options,
      <String?>['missing-model'],
    );

    expect(resolved, isNull);
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

  test(
      'listed mode selection falls back to default when key is unknown and options empty',
      () {
    final resolved = resolveListedModeSelection(
      preferred: 'pc-only-model',
      options: modelOptionsForAgent('codex'),
      fallback: defaultModelModeForAgent('codex'),
    );

    expect(resolved, 'default');
  });

  test('new session flow model options return empty when no metadata', () {
    final options = newSessionModelOptionsForAgent('codex');

    expect(options, isEmpty);
  });

  test('codex permission options stay hardcoded even with metadata modes', () {
    final options = permissionOptionsForAgent(
      'codex',
      metadataOptions: const [
        {'code': 'metadata-only', 'value': 'Metadata Mode'},
      ],
    );

    expect(
      options.map((option) => option.key),
      <String>['default', 'read-only', 'safe-yolo', 'yolo'],
    );
  });

  test('default model mode keeps CLI default routing semantics', () {
    expect(defaultModelModeForAgent('claude'), 'default');
    expect(defaultModelModeForAgent('codex'), 'default');
    expect(defaultModelModeForAgent('gemini'), 'default');
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

  test('available mode metadata prefers current session metadata first', () {
    final metadata = resolveAvailableModeMetadata(
      preferredMetadata: const <String, dynamic>{
        'models': [
          {'code': 'gpt-5.4', 'value': 'GPT-5.4'},
        ],
      },
      sessions: <Session>[
        _session(
          id: 'other-session',
          updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962447908),
          metadata: <String, dynamic>{
            'machineId': 'machine-1',
            'flavor': 'codex',
            'models': const [
              {'code': 'gpt-5-codex-high', 'value': 'GPT-5 Codex High'},
            ],
          },
        ),
      ],
      machines: const <Machine>[],
      machineId: 'machine-1',
      agent: 'codex',
    );

    expect((metadata?['models'] as List?)?.first['code'], 'gpt-5.4');
  });

  test('available mode metadata falls back to recent matching sessions', () {
    final metadata = resolveAvailableModeMetadata(
      preferredMetadata: const <String, dynamic>{
        'machineId': 'machine-1',
        'flavor': 'codex',
      },
      sessions: <Session>[
        _session(
          id: 'session-newest-codex',
          updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962447908),
          metadata: <String, dynamic>{
            'machineId': 'machine-1',
            'flavor': 'codex',
            'models': const [
              {'code': 'gpt-5-codex-high', 'value': 'GPT-5 Codex High'},
            ],
          },
        ),
      ],
      machines: const <Machine>[],
      machineId: 'machine-1',
      agent: 'codex',
    );

    expect((metadata?['models'] as List?)?.first['code'], 'gpt-5-codex-high');
  });

  test('available mode metadata resolves nested machine metadata buckets', () {
    final metadata = resolveAvailableModeMetadata(
      preferredMetadata: null,
      sessions: const <Session>[],
      machines: <Machine>[
        Machine(
          id: 'machine-1',
          name: 'Machine 1',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1772962446908),
          metadata: const <String, dynamic>{
            'providers': {
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
