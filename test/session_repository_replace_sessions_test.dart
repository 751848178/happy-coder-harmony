import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/data/session_repository.dart';
import 'package:happy_coder_flutter/features/session/domain/session_models.dart';

void main() {
  test('applySessions with replace removes stale cached sessions', () {
    final repository = SessionRepository.instance;
    repository.clearAll();

    final oldSession = Session(
      id: 'session-old',
      title: 'old',
      messages: const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(1772973000000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1772973000000),
      active: true,
    );
    final freshSession = Session(
      id: 'session-fresh',
      title: 'fresh',
      messages: const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(1772973000000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1772973060000),
      active: true,
    );

    repository.applySessions([oldSession]);
    repository.applySessions([freshSession], replace: true);

    final sessions = repository.getAllSessions();
    expect(sessions, hasLength(1));
    expect(sessions.single.id, 'session-fresh');

    repository.clearAll();
  });
}
