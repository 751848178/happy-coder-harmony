import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/data/session_composer_queue_service.dart';

void main() {
  test('queued composer message json roundtrip keeps content and timestamps',
      () {
    final now = DateTime.parse('2026-03-14T10:11:12.000Z');
    final message = QueuedComposerMessage(
      id: 'queued-1',
      content: '继续补充这个需求的边界场景',
      createdAt: now,
      updatedAt: now.add(const Duration(minutes: 2)),
    );

    final restored = QueuedComposerMessage.fromJson(message.toJson());

    expect(restored.id, 'queued-1');
    expect(restored.content, '继续补充这个需求的边界场景');
    expect(restored.createdAt, now);
    expect(restored.updatedAt, now.add(const Duration(minutes: 2)));
  });

  test('queue service createDraft produces a queued message snapshot', () {
    final now = DateTime.parse('2026-03-14T10:11:12.000Z');
    final message = SessionComposerQueueService.instance.createDraft(
      '排队发送的第二条消息',
      now: now,
    );

    expect(message.id, 'queued_${now.microsecondsSinceEpoch}');
    expect(message.content, '排队发送的第二条消息');
    expect(message.createdAt, now);
    expect(message.updatedAt, now);
  });
}
