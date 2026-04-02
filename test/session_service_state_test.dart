import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/data/session_repository.dart';
import 'package:happy_coder_flutter/features/session/domain/reducer.dart';
import 'package:happy_coder_flutter/features/session/domain/session_models.dart';
import 'package:happy_coder_flutter/features/session/domain/session_service.dart';

void main() {
  test('whenOrNull returns null for non-ready states instead of throwing', () {
    expect(
      SessionServiceState.initial.whenOrNull(
        ready: (sessions, sessionMessages, machines) => sessions.length,
      ),
      isNull,
    );
    expect(
      SessionServiceState.loading.whenOrNull(
        ready: (sessions, sessionMessages, machines) => sessions.length,
      ),
      isNull,
    );
    expect(
      SessionServiceState.error('boom').whenOrNull(
        ready: (sessions, sessionMessages, machines) => sessions.length,
      ),
      isNull,
    );
  });

  test('message updates promote notifier from initial to ready', () async {
    final repository = SessionRepository.instance;
    repository.clearAll();

    final notifier = SessionServiceNotifier(repository);
    repository.applyMessages('session-1', [
      ReducerMessage(
        id: 'message-1',
        kind: 'text',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
        text: 'hello',
      ),
    ]);

    await Future<void>.delayed(const Duration(milliseconds: 10));

    final messages = notifier.state.whenOrNull(
      ready: (_, sessionMessages, __) => sessionMessages['session-1'],
    );

    expect(messages, isNotNull);
    expect(messages!.messages, hasLength(1));
    expect(messages.messages.first.text, 'hello');

    notifier.dispose();
    repository.clearAll();
  });

  test('session deletion emits updated ready state', () async {
    final repository = SessionRepository.instance;
    repository.clearAll();

    final notifier = SessionServiceNotifier(repository);
    final session = Session(
      id: 'session-delete-1',
      title: 'demo',
      messages: const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
      active: true,
    );

    repository.applySessions([session]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    repository.deleteSession(session.id);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final sessions = notifier.state.when(
      initial: () => fail(
        'Expected sessions state to be ready after deleting a session.',
      ),
      loading: () => fail(
        'Expected sessions state to be ready after deleting a session.',
      ),
      ready: (sessions, _, __) => sessions,
      error: (_) => fail(
        'Expected sessions state to be ready after deleting a session.',
      ),
    );
    expect(sessions.containsKey(session.id), isFalse);

    notifier.dispose();
    repository.clearAll();
  });
}
