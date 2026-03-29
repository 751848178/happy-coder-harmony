import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/data/session_repository.dart';
import 'package:happy_coder_flutter/features/session/domain/reducer.dart'
    hide LatestUsage;
import 'package:happy_coder_flutter/features/session/domain/session_models.dart'
    show LatestUsage, Session;

void main() {
  test(
      'replaceMessages removes stale server entries and preserves unsynced local drafts',
      () {
    final repository = SessionRepository.instance..clearAll();

    const sessionId = 'session-snapshot-1';
    final now = DateTime.fromMillisecondsSinceEpoch(1773222000000);

    repository
      ..applyMessages(sessionId, [
        ReducerMessage(
          id: 'srv_1',
          kind: 'text',
          createdAt: now,
          text: '旧的服务端消息',
          metadata: const {'role': 'agent'},
        ),
        ReducerMessage(
          id: 'srv_2',
          kind: 'text',
          createdAt: now.add(const Duration(seconds: 1)),
          text: '已经被服务端删除的消息',
          metadata: const {'role': 'agent'},
        ),
        ReducerMessage(
          id: 'msg_local_1',
          kind: 'text',
          createdAt: now.add(const Duration(seconds: 2)),
          text: '尚未同步的本地消息',
          metadata: const {
            'role': 'user',
            'localId': 'msg_local_1',
            'optimistic': true,
          },
        ),
      ])
      ..replaceMessages(sessionId, [
        ReducerMessage(
          id: 'srv_1',
          kind: 'text',
          createdAt: now,
          text: '旧的服务端消息',
          metadata: const {'role': 'agent'},
        ),
      ]);

    final sessionMessages = repository.getSessionMessages(sessionId);
    expect(sessionMessages, isNotNull);
    expect(
      sessionMessages!.messages.map((message) => message.id).toList(),
      ['srv_1', 'msg_local_1'],
    );

    repository.clearAll();
  });

  test('replaceMessages swaps optimistic message for matching server localId',
      () {
    final repository = SessionRepository.instance..clearAll();

    const sessionId = 'session-snapshot-2';
    final now = DateTime.fromMillisecondsSinceEpoch(1773222000000);

    repository
      ..applyMessages(sessionId, [
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
      ])
      ..replaceMessages(sessionId, [
        ReducerMessage(
          id: 'srv_100',
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
    expect(sessionMessages.messages.single.id, 'srv_100');

    repository.clearAll();
  });

  test(
      'replaceMessages preserves stronger local tool state over stale snapshot',
      () {
    final repository = SessionRepository.instance..clearAll();

    const sessionId = 'session-snapshot-3';
    final now = DateTime.fromMillisecondsSinceEpoch(1773222000000);

    repository
      ..applyMessages(sessionId, [
        ReducerMessage(
          id: 'tool_message',
          kind: 'tool-call',
          createdAt: now,
          tool: ToolInfo(
            id: 'tool-1',
            name: 'edit_file',
            arguments: const {'path': '/tmp/demo.dart'},
            status: ToolCallStatus.pending,
          ),
        ),
      ])
      ..approveToolCall(sessionId, 'tool-1')
      ..replaceMessages(sessionId, [
        ReducerMessage(
          id: 'tool_message',
          kind: 'tool-call',
          createdAt: now,
          tool: ToolInfo(
            id: 'tool-1',
            name: 'edit_file',
            arguments: const {'path': '/tmp/demo.dart'},
            status: ToolCallStatus.pending,
          ),
        ),
      ]);

    final sessionMessages = repository.getSessionMessages(sessionId);
    expect(sessionMessages, isNotNull);
    expect(
      sessionMessages!.messages.single.tool!.status,
      ToolCallStatus.approved,
    );

    repository.clearAll();
  });

  test('replaceMessages can fully replace local snapshot during manual resync',
      () {
    final repository = SessionRepository.instance..clearAll();

    const sessionId = 'session-snapshot-5';
    final now = DateTime.fromMillisecondsSinceEpoch(1773222000000);

    repository
      ..applyMessages(sessionId, [
        ReducerMessage(
          id: 'srv_1',
          kind: 'text',
          createdAt: now,
          text: '服务端消息',
        ),
        ReducerMessage(
          id: 'msg_local_1',
          kind: 'text',
          createdAt: now.add(const Duration(seconds: 1)),
          text: '残留本地消息',
          metadata: const {
            'role': 'user',
            'localId': 'msg_local_1',
            'optimistic': true,
          },
        ),
      ])
      ..replaceMessages(
        sessionId,
        [
          ReducerMessage(
            id: 'srv_1',
            kind: 'text',
            createdAt: now,
            text: '服务端消息',
          ),
        ],
        preserveOptimisticMessages: false,
      );

    final sessionMessages = repository.getSessionMessages(sessionId);
    expect(sessionMessages, isNotNull);
    expect(sessionMessages!.messages.map((message) => message.id).toList(), [
      'srv_1',
    ]);

    repository.clearAll();
  });

  test('message mutations keep session latestUsage message count in sync', () {
    final repository = SessionRepository.instance..clearAll();

    const sessionId = 'session-snapshot-4';
    final now = DateTime.fromMillisecondsSinceEpoch(1773222000000);

    repository
      ..applySessions([
        Session(
          id: sessionId,
          title: '消息计数同步',
          messages: const [],
          createdAt: now,
          updatedAt: now,
          active: true,
          latestUsage: LatestUsage(
            messageCount: 9,
            tokenCount: 128,
            timestamp: now,
          ),
        ),
      ])
      ..applyMessages(sessionId, [
        ReducerMessage(
          id: 'srv_1',
          kind: 'text',
          createdAt: now,
          text: '第一条',
        ),
        ReducerMessage(
          id: 'srv_2',
          kind: 'text',
          createdAt: now.add(const Duration(seconds: 1)),
          text: '第二条',
        ),
      ]);
    expect(repository.getSession(sessionId)?.latestUsage?.messageCount, 2);

    repository.replaceMessages(sessionId, [
      ReducerMessage(
        id: 'srv_1',
        kind: 'text',
        createdAt: now,
        text: '第一条',
      ),
    ]);
    expect(repository.getSession(sessionId)?.latestUsage?.messageCount, 1);

    repository.clearSessionMessages(sessionId);
    expect(repository.getSession(sessionId)?.latestUsage?.messageCount, 0);

    repository.clearAll();
  });
}
