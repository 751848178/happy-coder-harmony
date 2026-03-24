import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/domain/session_models.dart';

void main() {
  test('Session.fromJson tolerates summary payload fields from list endpoint',
      () {
    final session = Session.fromJson({
      'id': 'session-summary-1',
      'seq': '12',
      'messages': 42,
      'created_at': 1772973000000,
      'updated_at': 1772973060000,
      'active': 1,
      'active_at': 1772973090000,
      'metadata_version': '7',
      'agent_state_version': 3,
      'metadata': {
        'path': '/workspace/demo',
        'summary': {'messageCount': 42},
      },
      'latest_usage': {
        'message_count': '42',
        'token_count': '2048',
        'timestamp': 1772973090000,
      },
    });

    expect(session.id, 'session-summary-1');
    expect(session.seq, 12);
    expect(session.messages, isEmpty);
    expect(session.active, isTrue);
    expect(session.metadataVersion, 7);
    expect(session.agentStateVersion, 3);
    expect(session.path, '/workspace/demo');
    expect(session.latestUsage?.messageCount, 42);
    expect(session.latestUsage?.tokenCount, 2048);
  });

  test('Session.fromJson supports nested payload and stringified metadata', () {
    final session = Session.fromJson({
      'session_id': 'session-summary-2',
      'name': 'Remote Session',
      'metadata':
          '{"path":"/workspace/nested","currentModelCode":"gpt-5","currentOperatingModeCode":"workspace-write"}',
      'agent_state': '{"messageCount": 9}',
      'thinking': 'false',
      'latestUsage': {
        'outputTokens': 5,
        'inputTokens': 11,
        'timestamp': '1772973090000',
      },
    });

    expect(session.id, 'session-summary-2');
    expect(session.title, 'Remote Session');
    expect(session.path, '/workspace/nested');
    expect(session.thinking, isFalse);
    expect(session.latestUsage?.messageCount, 5);
    expect(session.latestUsage?.tokenCount, 11);
  });

  test('Session.copyWith can clear draft explicitly', () {
    final session = Session(
      id: 'session-draft-1',
      title: 'Draft Session',
      messages: const [],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      active: true,
      draft: 'pending input',
    );

    final cleared = session.copyWith(draft: null);

    expect(cleared.draft, isNull);
  });
}
