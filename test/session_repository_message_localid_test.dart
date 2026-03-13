import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/data/session_repository.dart';
import 'package:happy_coder_flutter/features/session/domain/reducer.dart';

void main() {
  test('server message replaces optimistic local message with same localId',
      () {
    final repository = SessionRepository.instance;
    repository.clearAll();

    const sessionId = 'session-local-id';
    final now = DateTime.fromMillisecondsSinceEpoch(1773222000000);

    repository.applyMessages(sessionId, [
      ReducerMessage(
        id: 'msg_local_1',
        kind: 'text',
        createdAt: now,
        text: 'hello',
        metadata: const {
          'role': 'user',
          'localId': 'msg_local_1',
          'optimistic': true,
        },
      ),
    ]);

    repository.applyMessages(sessionId, [
      ReducerMessage(
        id: 'srv_1',
        kind: 'text',
        createdAt: now,
        text: 'hello',
        metadata: const {
          'role': 'user',
          'localId': 'msg_local_1',
        },
      ),
    ]);

    final sessionMessages = repository.getSessionMessages(sessionId);
    expect(sessionMessages, isNotNull);
    expect(sessionMessages!.messages, hasLength(1));
    expect(sessionMessages.messages.single.id, 'srv_1');
    expect(sessionMessages.messages.single.metadata?['localId'], 'msg_local_1');

    repository.clearAll();
  });
}
