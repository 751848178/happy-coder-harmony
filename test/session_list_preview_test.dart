import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/domain/reducer.dart';
import 'package:happy_coder_flutter/features/session/domain/session_list_preview.dart';
import 'package:happy_coder_flutter/features/session/domain/session_models.dart';

void main() {
  Session buildSession({
    String title = 'Session Title',
    Map<String, dynamic>? metadata,
    String? path,
    String? previewText,
    DateTime? lastMessageAt,
    String? listStatusKind,
  }) {
    return Session(
      id: 'session-preview-test',
      title: title,
      messages: const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
      active: true,
      metadata: metadata,
      path: path,
      previewText: previewText,
      lastMessageAt: lastMessageAt,
      listStatusKind: listStatusKind,
    );
  }

  test('prefers latest user message preview when messages are loaded', () {
    final preview = resolveSessionListPreview(
      session: buildSession(metadata: {
        'description': 'should not be used',
      }),
      messages: [
        ReducerMessage(
          id: 'message-1',
          kind: 'text',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
          metadata: const {'role': 'assistant'},
          text: 'assistant answer',
        ),
        ReducerMessage(
          id: 'message-2',
          kind: 'text',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1772962444908),
          metadata: const {'role': 'user'},
          text: 'latest user prompt',
        ),
      ],
      hasLoadedMessages: true,
    );

    expect(preview, 'latest user prompt');
  });

  test('returns syncing placeholder until message snapshot is loaded', () {
    final snapshot = resolveSessionListActivitySnapshot(
      session: buildSession(
        metadata: const {
          'description': 'Workspace sync failure needs follow-up',
        },
      ),
    );

    expect(snapshot.previewText, '最近消息待同步');
    expect(snapshot.isSyncing, isTrue);
    expect(snapshot.lastMessageAt, isNull);
  });

  test('returns waiting placeholder after an empty snapshot is loaded', () {
    final snapshot = resolveSessionListActivitySnapshot(
      session: buildSession(path: '/Users/demo/projects/happy-coder-flutter'),
      messages: const [],
      hasLoadedMessages: true,
    );

    expect(snapshot.previewText, '等待第一条消息');
    expect(snapshot.isSyncing, isFalse);
    expect(snapshot.lastMessageAt, isNull);
  });

  test('uses precomputed preview fields before message snapshot is loaded', () {
    final lastMessageAt = DateTime.fromMillisecondsSinceEpoch(1772962446908);
    final snapshot = resolveSessionListActivitySnapshot(
      session: buildSession(
        previewText: 'cached preview text',
        lastMessageAt: lastMessageAt,
      ),
    );

    expect(snapshot.previewText, 'cached preview text');
    expect(snapshot.isSyncing, isFalse);
    expect(snapshot.lastMessageAt, lastMessageAt);
  });

  test('prefers explicit renamed title over working directory', () {
    final title = resolveSessionListTitle(
      buildSession(
        title: '临时标题',
        path: '/Users/demo/projects/happy-coder-flutter',
        metadata: const {'name': '已重命名会话'},
      ),
    );

    expect(title, '已重命名会话');
  });

  test(
      'falls back to working directory title when summary became session title',
      () {
    final title = resolveSessionListTitle(
      buildSession(
        title: '修复滚动白屏问题',
        path: '/Users/demo/projects/happy-coder-flutter',
      ),
    );

    expect(title, 'happy-coder-flutter');
  });

  test('resolves last activity from latest loaded message', () {
    final session = buildSession();
    final latestAt = DateTime.fromMillisecondsSinceEpoch(1772962445908);

    final activityAt = resolveSessionListLastActivityAt(
      session: session,
      messages: [
        ReducerMessage(
          id: 'message-1',
          kind: 'text',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
          text: 'older',
        ),
        ReducerMessage(
          id: 'message-2',
          kind: 'text',
          createdAt: latestAt,
          text: 'latest',
        ),
      ],
      hasLoadedMessages: true,
    );

    expect(activityAt, latestAt);
  });

  test('does not use updatedAt before real last message time is loaded', () {
    final session = buildSession();

    final activityAt = resolveSessionListLastActivityAt(
      session: session,
    );

    expect(activityAt, isNull);
  });

  test('resolves codex agent from flavor metadata', () {
    final agent = resolveSessionListAgent(
      buildSession(
        metadata: const {'flavor': 'codex'},
      ),
    );

    expect(agent, 'codex');
  });

  test('prefers waiting permission status over thinking when tool is pending',
      () {
    final status = resolveSessionListStatusSnapshot(
      messages: [
        ReducerMessage(
          id: 'tool-1',
          kind: 'tool-call',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1772962444908),
          tool: ToolInfo(
            id: 'tool-1',
            name: 'read_file',
            arguments: const <String, dynamic>{},
            status: ToolCallStatus.pending,
          ),
        ),
      ],
      isThinking: true,
      isActive: true,
    );

    expect(status?.kind, SessionListStatusKind.waitingPermission);
    expect(status?.label, '等待权限');
  });

  test('returns thinking status when no permission request is pending', () {
    final status = resolveSessionListStatusSnapshot(
      messages: const [],
      isThinking: true,
      isActive: true,
    );

    expect(status?.kind, SessionListStatusKind.thinking);
    expect(status?.label, '思考中');
  });

  test('returns running status for approved tool execution', () {
    final status = resolveSessionListStatusSnapshot(
      messages: [
        ReducerMessage(
          id: 'tool-approved',
          kind: 'tool-call',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1772962444908),
          tool: ToolInfo(
            id: 'tool-1',
            name: 'exec_command',
            arguments: const <String, dynamic>{},
            status: ToolCallStatus.executing,
          ),
        ),
      ],
      isThinking: false,
      isActive: true,
    );

    expect(status?.kind, SessionListStatusKind.running);
    expect(status?.label, '执行中');
  });

  test('returns failed status for rejected tool call', () {
    final status = resolveSessionListStatusSnapshot(
      messages: [
        ReducerMessage(
          id: 'tool-rejected',
          kind: 'tool-call',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1772962444908),
          tool: ToolInfo(
            id: 'tool-1',
            name: 'read_file',
            arguments: const <String, dynamic>{},
            status: ToolCallStatus.rejected,
          ),
        ),
      ],
      isThinking: false,
      isActive: true,
    );

    expect(status?.kind, SessionListStatusKind.failed);
    expect(status?.label, '失败');
  });

  test('returns interrupted status for turn_aborted event', () {
    final status = resolveSessionListStatusSnapshot(
      messages: [
        ReducerMessage(
          id: 'event-turn-aborted',
          kind: 'agent-event',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1772962444908),
          metadata: const <String, dynamic>{
            'eventType': 'turn_aborted',
          },
        ),
      ],
      isThinking: false,
      isActive: true,
    );

    expect(status?.kind, SessionListStatusKind.interrupted);
    expect(status?.label, '已中止');
  });

  test('returns inactive status when session is closed and no live state', () {
    final status = resolveSessionListStatusSnapshot(
      messages: const [],
      isThinking: false,
      isActive: false,
    );

    expect(status?.kind, SessionListStatusKind.inactive);
    expect(status?.label, '已关闭');
  });

  test('user prompt boundary clears historical terminal status', () {
    final status = resolveSessionListStatusSnapshot(
      messages: [
        ReducerMessage(
          id: 'historical-failure',
          kind: 'tool-call',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
          tool: ToolInfo(
            id: 'tool-1',
            name: 'exec_command',
            arguments: const <String, dynamic>{},
            status: ToolCallStatus.failed,
          ),
        ),
        ReducerMessage(
          id: 'latest-user',
          kind: 'text',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1772962445908),
          metadata: const <String, dynamic>{'role': 'user'},
          text: '继续处理',
        ),
      ],
      isThinking: false,
      isActive: true,
    );

    expect(status, isNull);
  });
}
