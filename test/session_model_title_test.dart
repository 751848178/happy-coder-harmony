import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/domain/session_models.dart';

void main() {
  test('session title falls back to workspace basename', () {
    final session = Session.fromJson({
      'id': 'cmmhjy7ls9trvxe14aujd7tu3',
      'metadata': {
        'path': '/Users/zhaoxingbo/Workspace/ai-driven/deyi',
      },
      'createdAt': 1772962443908,
      'updatedAt': 1772962443908,
    });

    expect(session.title, 'deyi');
  });
}
