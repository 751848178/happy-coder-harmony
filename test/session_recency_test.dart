import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/domain/session_models.dart';
import 'package:happy_coder_flutter/features/session/domain/session_recency.dart';

void main() {
  test('compareSessionsByRecency keeps equal updatedAt sessions deterministic',
      () {
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(1772962443908);
    final sessions = [
      Session(
        id: 'session-b',
        title: 'older created',
        messages: const [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
        updatedAt: updatedAt,
        active: true,
      ),
      Session(
        id: 'session-a',
        title: 'newer created',
        messages: const [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(1772962444908),
        updatedAt: updatedAt,
        active: true,
      ),
      Session(
        id: 'session-c',
        title: 'same created, later id',
        messages: const [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(1772962444908),
        updatedAt: updatedAt,
        active: true,
      ),
    ];

    sessions.sort(compareSessionsByRecency);

    expect(
      sessions.map((session) => session.id).toList(),
      ['session-a', 'session-c', 'session-b'],
    );
  });

  test(
      'resolveSessionUpdatedAtForRealtimeUpdate never moves updatedAt backward',
      () {
    final current = DateTime.fromMillisecondsSinceEpoch(1772962445908);
    final staleUpdate = DateTime.fromMillisecondsSinceEpoch(1772962443908);
    final freshEvent = DateTime.fromMillisecondsSinceEpoch(1772962447908);

    expect(
      resolveSessionUpdatedAtForRealtimeUpdate(
        currentUpdatedAt: current,
        sessionUpdatedAt: staleUpdate,
        eventCreatedAt: freshEvent,
      ),
      current,
    );

    expect(
      resolveSessionUpdatedAtForRealtimeUpdate(
        currentUpdatedAt: current,
        sessionUpdatedAt: null,
        eventCreatedAt: freshEvent,
      ),
      freshEvent,
    );
  });

  test('compareSessionsByStableListOrder prefers createdAt before updatedAt',
      () {
    final sessions = [
      Session(
        id: 'session-newer-created',
        title: 'newer created',
        messages: const [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(1772962446908),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
        active: true,
      ),
      Session(
        id: 'session-older-created',
        title: 'older created',
        messages: const [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(1772962444908),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962447908),
        active: true,
      ),
    ];

    sessions.sort(compareSessionsByStableListOrder);

    expect(
      sessions.map((session) => session.id).toList(),
      ['session-newer-created', 'session-older-created'],
    );
  });

  test('orderSessionsByStoredIds follows stored custom group order', () {
    final sessionA = Session(
      id: 'session-a',
      title: 'A',
      messages: const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
      active: true,
    );
    final sessionB = Session(
      id: 'session-b',
      title: 'B',
      messages: const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(1772962444908),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962447908),
      active: true,
    );

    final ordered = orderSessionsByStoredIds(
      ['session-b', 'session-a', 'missing', 'session-b'],
      <String, Session>{
        sessionA.id: sessionA,
        sessionB.id: sessionB,
      },
    );

    expect(
      ordered.map((session) => session.id).toList(),
      ['session-b', 'session-a'],
    );
  });
}
