import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/domain/reducer.dart'
    show ReducerMessage, ToolInfo, ToolCallStatus;
import 'package:happy_coder_flutter/features/session/domain/session_local_snapshot.dart';
import 'package:happy_coder_flutter/features/session/domain/session_models.dart';

void main() {
  test(
      'buildLocalSessionSnapshot keeps the loaded message count across restart',
      () {
    final session = Session(
      id: 'session-local-snapshot',
      title: 'Snapshot',
      messages: const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962445908),
      active: true,
      latestUsage: LatestUsage(
        messageCount: 2,
        tokenCount: 1024,
        timestamp: DateTime.fromMillisecondsSinceEpoch(1772962444908),
      ),
    );

    final snapshot = buildLocalSessionSnapshot(
      session: session,
      loadedMessageCount: 5,
    );

    expect(snapshot[localSessionSnapshotMessageCountKey], 5);
    final restored = restoreLatestUsageFromLocalSnapshot(
      snapshot,
      fallbackTimestamp: session.updatedAt,
    );
    expect(restored, isNotNull);
    expect(restored!.messageCount, 5);
    expect(restored.tokenCount, 1024);
  });

  test(
      'restoreLatestUsageFromLocalSnapshot falls back to explicit message count',
      () {
    final restored = restoreLatestUsageFromLocalSnapshot(
      <String, dynamic>{localSessionSnapshotMessageCountKey: 3},
      fallbackTimestamp: DateTime.fromMillisecondsSinceEpoch(1772962445908),
    );

    expect(restored, isNotNull);
    expect(restored!.messageCount, 3);
    expect(restored.tokenCount, 0);
  });

  test('display message count trusts loaded messages once available', () {
    final session = Session(
      id: 'session-display-count',
      title: 'Display Count',
      messages: const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962445908),
      active: true,
      latestUsage: LatestUsage(
        messageCount: 6,
        tokenCount: 256,
        timestamp: DateTime.fromMillisecondsSinceEpoch(1772962444908),
      ),
    );

    expect(
      resolveDisplaySessionMessageCount(
        session: session,
        loadedMessageCount: 3,
      ),
      3,
    );
    expect(
      resolveDisplaySessionMessageCount(
        session: session,
        loadedMessageCount: 8,
      ),
      8,
    );
  });

  test('local snapshot can roundtrip loaded reducer messages and last seq', () {
    final session = Session(
      id: 'session-message-restore',
      title: 'Message Restore',
      messages: const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962445908),
      active: true,
    );
    final messages = <ReducerMessage>[
      ReducerMessage(
        id: 'msg-1',
        kind: 'text',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
        text: '第一条消息',
        metadata: const {'role': 'user'},
      ),
      ReducerMessage(
        id: 'msg-2',
        kind: 'tool-call',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1772962444908),
        tool: ToolInfo(
          id: 'tool-1',
          name: 'edit_file',
          arguments: const {'path': '/tmp/demo.dart'},
          status: ToolCallStatus.approved,
        ),
      ),
    ];

    final snapshot = buildLocalSessionSnapshot(
      session: session,
      loadedMessageCount: messages.length,
      loadedMessages: messages,
      messagesLoaded: true,
      lastSeq: 42,
    );

    expect(localSnapshotHasLoadedMessages(snapshot), isTrue);
    expect(restoreSessionLastSeqFromLocalSnapshot(snapshot), 42);

    final restored = restoreMessagesFromLocalSnapshot(snapshot);
    expect(restored, isNotNull);
    expect(restored, hasLength(2));
    expect(restored![0].id, 'msg-1');
    expect(restored[1].tool?.status, ToolCallStatus.approved);
  });
}
