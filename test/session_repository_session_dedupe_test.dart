import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/data/session_repository.dart';
import 'package:happy_coder_flutter/features/session/domain/session_models.dart';

void main() {
  test('identical session updates are ignored', () async {
    final repository = SessionRepository.instance;
    repository.clearAll();

    final changes = <SessionStateChange>[];
    final subscription = repository.stateChanges.listen(changes.add);

    final session = Session(
      id: 'session-1',
      seq: 1,
      title: 'demo',
      messages: const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(1772973000000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1772973000000),
      active: true,
      path: '/tmp/demo',
      metadata: const {
        'path': '/tmp/demo',
        'flavor': 'claude',
      },
    );

    repository.applySessions([session]);
    repository.applySessions([session]);

    await Future<void>.delayed(const Duration(milliseconds: 10));

    final sessionUpdates = changes
        .where((change) => change.type == SessionChangeType.sessionsUpdated)
        .length;
    expect(sessionUpdates, 1);

    await subscription.cancel();
    repository.clearAll();
  });
}
