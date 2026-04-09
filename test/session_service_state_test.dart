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

    // Messages are no longer carried in the global state (sessionMessages
    // is always empty). Use the per-session accessor instead.
    final messages = notifier.getSessionMessages('session-1');

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

  test('windowed message snapshots preserve total count for large sessions', () {
    final repository = SessionRepository.instance;
    repository.clearAll();

    final session = Session(
      id: 'session-windowed-state',
      title: 'windowed',
      messages: const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
      active: true,
    );
    repository.applySessions([session]);

    final messages = List<ReducerMessage>.generate(
      6,
      (index) => ReducerMessage(
        id: 'message-$index',
        kind: 'text',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          1772962443908 + index,
        ),
        text: 'hello-$index',
      ),
      growable: false,
    );

    repository.replaceMessages(
      session.id,
      messages,
      preserveOptimisticMessages: false,
      totalMessageCount: messages.length,
      messageWindowSize: 3,
    );

    final stored = repository.getSessionMessages(session.id);
    final storedSession = repository.getSession(session.id);

    expect(stored, isNotNull);
    expect(stored!.messages, hasLength(3));
    expect(stored.messages.first.id, 'message-3');
    expect(stored.totalMessageCount, 6);
    expect(stored.windowStartIndex, 3);
    expect(stored.hasOlderMessages, isTrue);
    expect(stored.hasNewerMessages, isFalse);
    expect(storedSession?.latestUsage?.messageCount, 6);

    repository.clearAll();
  });

  test('archived middle window preserves latest preview fields', () {
    final repository = SessionRepository.instance;
    repository.clearAll();

    final baseTime = DateTime.fromMillisecondsSinceEpoch(1772962443908);
    final session = Session(
      id: 'session-archived-window',
      title: 'archived',
      messages: const [],
      createdAt: baseTime,
      updatedAt: baseTime,
      active: true,
      previewText: 'latest-preview',
      lastMessageAt: baseTime.add(const Duration(seconds: 10)),
      listStatusKind: 'running',
    );
    repository.applySessions([session]);

    final archivedWindowMessages = List<ReducerMessage>.generate(
      3,
      (index) => ReducerMessage(
        id: 'message-${index + 1}',
        kind: 'text',
        createdAt: baseTime.add(Duration(seconds: index + 1)),
        text: 'older-${index + 1}',
      ),
      growable: false,
    );

    repository.replaceMessageWindow(
      session.id,
      archivedWindowMessages,
      totalMessageCount: 6,
      windowStartIndex: 1,
    );

    final stored = repository.getSessionMessages(session.id);
    final storedSession = repository.getSession(session.id);

    expect(stored, isNotNull);
    expect(stored!.windowStartIndex, 1);
    expect(stored.hasOlderMessages, isTrue);
    expect(stored.hasNewerMessages, isTrue);
    expect(storedSession?.previewText, 'latest-preview');
    expect(storedSession?.lastMessageAt, session.lastMessageAt);
    expect(storedSession?.listStatusKind, 'running');

    repository.clearAll();
  });

  test('prependMessageWindow keeps older pages resident without loading all',
      () {
    final repository = SessionRepository.instance;
    repository.clearAll();

    final baseTime = DateTime.fromMillisecondsSinceEpoch(1772962443908);
    const sessionId = 'session-prepend-window';
    repository.applySessions([
      Session(
        id: sessionId,
        title: 'prepend-window',
        messages: const [],
        createdAt: baseTime,
        updatedAt: baseTime,
        active: true,
      ),
    ]);

    repository.replaceMessageWindow(
      sessionId,
      List<ReducerMessage>.generate(
        3,
        (index) => ReducerMessage(
          id: 'message-${index + 7}',
          kind: 'text',
          createdAt: baseTime.add(Duration(seconds: index + 7)),
          text: 'message-${index + 7}',
        ),
        growable: false,
      ),
      totalMessageCount: 12,
      windowStartIndex: 6,
    );

    repository.prependMessageWindow(
      sessionId,
      List<ReducerMessage>.generate(
        4,
        (index) => ReducerMessage(
          id: 'message-${index + 3}',
          kind: 'text',
          createdAt: baseTime.add(Duration(seconds: index + 3)),
          text: 'message-${index + 3}',
        ),
        growable: false,
      ),
      totalMessageCount: 12,
      maxWindowSize: 5,
    );

    final stored = repository.getSessionMessages(sessionId);
    expect(stored, isNotNull);
    expect(stored!.windowStartIndex, 2);
    expect(stored.messages.map((message) => message.id).toList(), [
      'message-3',
      'message-4',
      'message-5',
      'message-6',
      'message-7',
    ]);
    expect(stored.hasOlderMessages, isTrue);
    expect(stored.hasNewerMessages, isTrue);

    repository.clearAll();
  });

  test('appendMessageWindow keeps newer pages resident without loading all',
      () {
    final repository = SessionRepository.instance;
    repository.clearAll();

    final baseTime = DateTime.fromMillisecondsSinceEpoch(1772962443908);
    const sessionId = 'session-append-window';
    repository.applySessions([
      Session(
        id: sessionId,
        title: 'append-window',
        messages: const [],
        createdAt: baseTime,
        updatedAt: baseTime,
        active: true,
      ),
    ]);

    repository.replaceMessageWindow(
      sessionId,
      List<ReducerMessage>.generate(
        5,
        (index) => ReducerMessage(
          id: 'message-${index + 1}',
          kind: 'text',
          createdAt: baseTime.add(Duration(seconds: index + 1)),
          text: 'message-${index + 1}',
        ),
        growable: false,
      ),
      totalMessageCount: 12,
      windowStartIndex: 0,
    );

    repository.appendMessageWindow(
      sessionId,
      List<ReducerMessage>.generate(
        4,
        (index) => ReducerMessage(
          id: 'message-${index + 6}',
          kind: 'text',
          createdAt: baseTime.add(Duration(seconds: index + 6)),
          text: 'message-${index + 6}',
        ),
        growable: false,
      ),
      totalMessageCount: 12,
      maxWindowSize: 6,
    );

    final stored = repository.getSessionMessages(sessionId);
    expect(stored, isNotNull);
    expect(stored!.windowStartIndex, 3);
    expect(stored.messages.map((message) => message.id).toList(), [
      'message-4',
      'message-5',
      'message-6',
      'message-7',
      'message-8',
      'message-9',
    ]);
    expect(stored.hasOlderMessages, isTrue);
    expect(stored.hasNewerMessages, isTrue);

    repository.clearAll();
  });

  test('replaceMessageWindow canonicalizes duplicate message ids', () {
    final repository = SessionRepository.instance;
    repository.clearAll();

    final baseTime = DateTime.fromMillisecondsSinceEpoch(1772962443908);
    const sessionId = 'session-duplicate-window';
    repository.applySessions([
      Session(
        id: sessionId,
        title: 'duplicate-window',
        messages: const [],
        createdAt: baseTime,
        updatedAt: baseTime,
        active: true,
      ),
    ]);

    ReducerMessage toolMessage({
      required int archiveIndex,
      required ToolCallStatus status,
      String? result,
    }) {
      return ReducerMessage(
        id: 'tool:call-1',
        kind: 'tool-call',
        createdAt: baseTime.add(Duration(seconds: archiveIndex)),
        metadata: {'archiveIndex': archiveIndex},
        tool: ToolInfo(
          id: 'call-1',
          name: 'edit',
          arguments: const {'file': 'a.txt'},
          status: status,
          result: result,
        ),
      );
    }

    repository.replaceMessageWindow(
      sessionId,
      [
        toolMessage(archiveIndex: 4, status: ToolCallStatus.pending),
        toolMessage(
          archiveIndex: 5,
          status: ToolCallStatus.completed,
          result: 'done',
        ),
      ],
      totalMessageCount: 6,
      windowStartIndex: 4,
    );

    final stored = repository.getSessionMessages(sessionId);
    expect(stored, isNotNull);
    expect(stored!.messages, hasLength(1));
    expect(stored.messages.single.id, 'tool:call-1');
    expect(stored.messages.single.tool?.status, ToolCallStatus.completed);
    expect(stored.messages.single.tool?.result, 'done');
    expect(stored.windowStartIndex, 4);
    expect(stored.hasOlderMessages, isTrue);
    expect(stored.hasNewerMessages, isFalse);

    repository.clearAll();
  });

  test('appendMessageWindow canonicalizes overlapping duplicate tool ids', () {
    final repository = SessionRepository.instance;
    repository.clearAll();

    final baseTime = DateTime.fromMillisecondsSinceEpoch(1772962443908);
    const sessionId = 'session-append-duplicate-window';
    repository.applySessions([
      Session(
        id: sessionId,
        title: 'append-duplicate-window',
        messages: const [],
        createdAt: baseTime,
        updatedAt: baseTime,
        active: true,
      ),
    ]);

    repository.replaceMessageWindow(
      sessionId,
      [
        ReducerMessage(
          id: 'message-0',
          kind: 'text',
          createdAt: baseTime,
          text: 'before',
          metadata: const {'archiveIndex': 0},
        ),
        ReducerMessage(
          id: 'tool:call-2',
          kind: 'tool-call',
          createdAt: baseTime.add(const Duration(seconds: 1)),
          metadata: const {'archiveIndex': 1},
          tool: ToolInfo(
            id: 'call-2',
            name: 'edit',
            arguments: const {'file': 'b.txt'},
            status: ToolCallStatus.pending,
          ),
        ),
      ],
      totalMessageCount: 5,
      windowStartIndex: 0,
    );

    repository.appendMessageWindow(
      sessionId,
      [
        ReducerMessage(
          id: 'tool:call-2',
          kind: 'tool-call',
          createdAt: baseTime.add(const Duration(seconds: 2)),
          metadata: const {'archiveIndex': 2},
          tool: ToolInfo(
            id: 'call-2',
            name: 'edit',
            arguments: const {'file': 'b.txt'},
            status: ToolCallStatus.completed,
            result: 'ok',
          ),
        ),
        ReducerMessage(
          id: 'message-3',
          kind: 'text',
          createdAt: baseTime.add(const Duration(seconds: 3)),
          text: 'after',
          metadata: const {'archiveIndex': 3},
        ),
      ],
      totalMessageCount: 5,
      maxWindowSize: 5,
    );

    final stored = repository.getSessionMessages(sessionId);
    expect(stored, isNotNull);
    expect(stored!.messages.map((message) => message.id).toList(), [
      'message-0',
      'tool:call-2',
      'message-3',
    ]);
    expect(stored.messages[1].tool?.status, ToolCallStatus.completed);
    expect(stored.messages[1].tool?.result, 'ok');
    expect(stored.windowStartIndex, 0);
    expect(stored.hasOlderMessages, isFalse);
    expect(stored.hasNewerMessages, isTrue);

    repository.clearAll();
  });
}
