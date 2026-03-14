import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/domain/session_activity_state.dart';
import 'package:happy_coder_flutter/features/session/domain/session_models.dart';

void main() {
  test('ephemeral activity clears stale thinking when session becomes inactive',
      () {
    final session = _session(
      active: true,
      activeAt: _createdAt,
      thinking: true,
      thinkingAt: _createdAt,
    );

    final updated = applyEphemeralSessionActivity(
      session: session,
      active: false,
      activeAt: _createdAt.add(const Duration(seconds: 5)),
      thinkingProvided: false,
      thinking: null,
    );

    expect(updated.active, isFalse);
    expect(updated.thinking, isFalse);
    expect(updated.thinkingAt, isNull);
  });

  test('heartbeat without thinking field keeps active reply state intact', () {
    final session = _session(
      active: true,
      activeAt: _createdAt,
      thinking: true,
      thinkingAt: _createdAt,
    );

    final updated = applyEphemeralSessionActivity(
      session: session,
      active: true,
      activeAt: _createdAt.add(const Duration(seconds: 5)),
      thinkingProvided: false,
      thinking: null,
    );

    expect(updated.active, isTrue);
    expect(updated.thinking, isTrue);
    expect(updated.thinkingAt, _createdAt.add(const Duration(seconds: 5)));
  });

  test('session copyWith can clear thinking timestamp explicitly', () {
    final session = _session(
      active: true,
      activeAt: _createdAt,
      thinking: false,
      thinkingAt: _createdAt,
    );

    final updated = session.copyWith(thinkingAt: null);

    expect(updated.thinkingAt, isNull);
  });
}

DateTime get _createdAt => DateTime.fromMillisecondsSinceEpoch(1772970000000);

Session _session({
  required bool active,
  DateTime? activeAt,
  bool? thinking,
  DateTime? thinkingAt,
}) {
  return Session(
    id: 'session-1',
    title: 'Session',
    messages: const <dynamic>[],
    createdAt: _createdAt,
    updatedAt: _createdAt,
    active: active,
    activeAt: activeAt,
    thinking: thinking,
    thinkingAt: thinkingAt,
  );
}
