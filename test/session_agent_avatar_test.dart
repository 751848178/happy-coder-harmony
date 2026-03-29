import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/core/theme/app_theme.dart';
import 'package:happy_coder_flutter/features/session/presentation/session_agent_avatar.dart';
import 'package:happy_coder_flutter/features/session/domain/session_models.dart';

void main() {
  Session buildSession({
    required String flavor,
  }) {
    final now = DateTime.fromMillisecondsSinceEpoch(1772962443908);
    return Session(
      id: 'session-avatar-test-$flavor',
      title: 'Avatar Test',
      messages: const [],
      createdAt: now,
      updatedAt: now,
      active: true,
      metadata: <String, dynamic>{'flavor': flavor},
    );
  }

  test('codex visual spec keeps upstream asset and tint semantics', () {
    final spec = sessionAgentVisualSpec(buildSession(flavor: 'codex'));

    expect(spec.assetPath, 'assets/images/icon-gpt.png');
    expect(spec.tintColor, AppTheme.neutral900);
    expect(spec.iconScale, lessThan(0.56));
  });

  test('claude visual spec keeps original asset colors', () {
    final spec = sessionAgentVisualSpec(buildSession(flavor: 'claude'));

    expect(spec.assetPath, 'assets/images/icon-claude.png');
    expect(spec.tintColor, isNull);
  });
}
