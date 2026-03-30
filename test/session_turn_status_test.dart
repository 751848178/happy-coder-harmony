import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/domain/reducer.dart';
import 'package:happy_coder_flutter/features/session/domain/session_models.dart';
import 'package:happy_coder_flutter/features/session/presentation/session_turn_status.dart';

void main() {
  test('rendered reply without thinking or turn-close still completes reply',
      () {
    final prompt = _userPrompt(localId: 'local-1');
    final messages = <ReducerMessage>[
      prompt,
      _agentText('已经拿到结果了'),
    ];

    expect(
      sessionActiveResponseHasCompleted(
        session: _session(thinking: false),
        messages: messages,
        userPrompt: prompt,
        isSending: false,
      ),
      isTrue,
    );
  });

  test('historical thinking followed by final answer is no longer blocking',
      () {
    final prompt = _userPrompt(localId: 'local-2');
    final messages = <ReducerMessage>[
      prompt,
      _agentText('先分析一下', outputType: 'thinking'),
      _agentText('这是最终回复'),
    ];

    expect(
      sessionTurnIsThinkingStillBlocking(
        session: _session(thinking: false),
        messages: messages,
      ),
      isFalse,
    );
    expect(
      sessionConversationIsBusy(
        session: _session(thinking: false),
        latestTurnMessages: messages,
        latestUserPrompt: prompt,
        isSending: false,
        isAutoSendingQueuedMessage: false,
        activeResponseLocalId: null,
      ),
      isFalse,
    );
  });

  test('thinking-only reply remains busy until there is final output', () {
    final prompt = _userPrompt(localId: 'local-3');
    final messages = <ReducerMessage>[
      prompt,
      _agentText('我还在思考', outputType: 'thinking'),
    ];

    expect(
      sessionTurnIsThinkingStillBlocking(
        session: _session(thinking: false),
        messages: messages,
      ),
      isTrue,
    );
    expect(
      sessionActiveResponseHasCompleted(
        session: _session(thinking: false),
        messages: messages,
        userPrompt: prompt,
        isSending: false,
      ),
      isFalse,
    );
  });

  test('ready event clears blocking state even without visible turn-close', () {
    final prompt = _userPrompt(localId: 'local-ready');
    final messages = <ReducerMessage>[
      prompt,
      _agentText('我先想一下', outputType: 'thinking'),
      _agentEvent('ready'),
    ];

    expect(
      sessionTurnIsThinkingStillBlocking(
        session: _session(thinking: false),
        messages: messages,
      ),
      isFalse,
    );
    expect(
      sessionConversationIsBusy(
        session: _session(thinking: false),
        latestTurnMessages: messages,
        latestUserPrompt: prompt,
        isSending: false,
        isAutoSendingQueuedMessage: false,
        activeResponseLocalId: null,
      ),
      isFalse,
    );
  });

  test('turn_aborted clears stale pending tool blockers', () {
    final prompt = _userPrompt(localId: 'local-abort-tool');
    final messages = <ReducerMessage>[
      prompt,
      _toolCall(ToolCallStatus.pending),
      _agentEvent('turn_aborted'),
    ];

    expect(
      sessionActiveResponseHasCompleted(
        session: _session(thinking: true),
        messages: messages,
        userPrompt: prompt,
        isSending: false,
      ),
      isTrue,
    );
    expect(
      sessionConversationIsBusy(
        session: _session(thinking: true),
        latestTurnMessages: messages,
        latestUserPrompt: prompt,
        isSending: false,
        isAutoSendingQueuedMessage: false,
        activeResponseLocalId: null,
      ),
      isFalse,
    );
  });

  test('manual thinking override can unblock stuck conversation', () {
    final prompt = _userPrompt(localId: 'local-manual');
    final messages = <ReducerMessage>[
      prompt,
      _agentText('我还在思考', outputType: 'thinking'),
    ];

    expect(
      sessionTurnIsThinkingStillBlocking(
        session: _session(thinking: true),
        messages: messages,
        manualThinkingOverride: false,
      ),
      isFalse,
    );
    expect(
      sessionConversationIsBusy(
        session: _session(thinking: true),
        latestTurnMessages: messages,
        latestUserPrompt: prompt,
        isSending: false,
        isAutoSendingQueuedMessage: false,
        activeResponseLocalId: null,
        manualThinkingOverride: false,
      ),
      isFalse,
    );
  });

  test('completion signal overrides manual thinking=true', () {
    final prompt = _userPrompt(localId: 'local-manual-complete');
    final messages = <ReducerMessage>[
      prompt,
      _agentText('我还在思考', outputType: 'thinking'),
      _agentEvent('turn_aborted'),
    ];

    expect(
      sessionTurnIsThinkingStillBlocking(
        session: _session(thinking: true),
        messages: messages,
        manualThinkingOverride: true,
      ),
      isFalse,
    );
  });

  test('pending tool work still blocks queued auto-send', () {
    final prompt = _userPrompt(localId: 'local-4');
    final messages = <ReducerMessage>[
      prompt,
      _toolCall(ToolCallStatus.executing),
      _agentText('命令正在执行'),
    ];

    expect(
      sessionActiveResponseHasCompleted(
        session: _session(thinking: false),
        messages: messages,
        userPrompt: prompt,
        isSending: false,
      ),
      isFalse,
    );
    expect(
      sessionConversationIsBusy(
        session: _session(thinking: false),
        latestTurnMessages: messages,
        latestUserPrompt: prompt,
        isSending: false,
        isAutoSendingQueuedMessage: false,
        activeResponseLocalId: null,
      ),
      isTrue,
    );
  });

  test('abort settles once remote session stops even without final output', () {
    final prompt = _userPrompt(localId: 'local-abort-idle');
    final messages = <ReducerMessage>[
      prompt,
      _agentText('我还在思考', outputType: 'thinking'),
    ];

    expect(
      sessionActiveResponseHasCompleted(
        session: _session(thinking: false),
        messages: messages,
        userPrompt: prompt,
        isSending: false,
      ),
      isFalse,
    );
    expect(
      sessionAbortHasSettledRemotely(
        session: _session(thinking: false),
        messages: messages,
        userPrompt: prompt,
        isSending: false,
      ),
      isTrue,
    );
  });

  test('abort does not settle while remote session still reports thinking', () {
    final prompt = _userPrompt(localId: 'local-abort-still-thinking');
    final messages = <ReducerMessage>[
      prompt,
      _agentText('我还在思考', outputType: 'thinking'),
    ];

    expect(
      sessionAbortHasSettledRemotely(
        session: _session(thinking: true),
        messages: messages,
        userPrompt: prompt,
        isSending: false,
      ),
      isFalse,
    );
  });

  test('manual finished override bypasses stale pending tool blockers', () {
    final prompt = _userPrompt(localId: 'local-pending-override');
    final messages = <ReducerMessage>[
      prompt,
      _toolCall(ToolCallStatus.pending),
    ];

    expect(
      sessionConversationIsBusy(
        session: _session(thinking: true),
        latestTurnMessages: messages,
        latestUserPrompt: prompt,
        isSending: false,
        isAutoSendingQueuedMessage: false,
        activeResponseLocalId: null,
        manualThinkingOverride: false,
      ),
      isFalse,
    );
  });

  test('manual finished override bypasses stale optimistic prompt blockers',
      () {
    final prompt = _userPrompt(
      localId: 'local-optimistic-override',
      optimistic: true,
    );

    expect(
      sessionConversationIsBusy(
        session: _session(thinking: false),
        latestTurnMessages: [prompt],
        latestUserPrompt: prompt,
        isSending: false,
        isAutoSendingQueuedMessage: false,
        activeResponseLocalId: 'msg_local_100',
        manualThinkingOverride: false,
      ),
      isFalse,
    );
  });

  test('sourceRole=user is still treated as user-authored content', () {
    final echoedUserMessage = ReducerMessage(
      id: 'server-user-1',
      kind: 'text',
      createdAt: _createdAt,
      text: '继续执行',
      metadata: const <String, dynamic>{
        'role': 'agent',
        'sourceRole': 'user',
      },
    );

    expect(sessionMessageIsUserAuthored(echoedUserMessage), isTrue);
    expect(
      sessionTurnHasRenderableAgentOutput([echoedUserMessage]),
      isFalse,
    );
    expect(
      sessionTurnIsThinkingStillBlocking(
        session: _session(thinking: false),
        messages: [echoedUserMessage],
      ),
      isFalse,
    );
  });
}

DateTime get _createdAt => DateTime.fromMillisecondsSinceEpoch(1772970000000);

Session _session({required bool thinking}) {
  return Session(
    id: 'session-1',
    title: 'Session',
    messages: const <dynamic>[],
    createdAt: _createdAt,
    updatedAt: _createdAt,
    active: true,
    thinking: thinking,
  );
}

ReducerMessage _userPrompt({
  required String localId,
  bool optimistic = false,
}) {
  return ReducerMessage(
    id: 'prompt-$localId',
    kind: 'text',
    createdAt: _createdAt,
    text: '继续执行',
    metadata: <String, dynamic>{
      'role': 'user',
      'localId': localId,
      if (optimistic) 'optimistic': true,
    },
  );
}

ReducerMessage _agentText(String text, {String? outputType}) {
  return ReducerMessage(
    id: 'agent-${text.hashCode}',
    kind: 'text',
    createdAt: _createdAt,
    text: text,
    metadata: <String, dynamic>{
      'role': 'agent',
      if (outputType != null) 'outputType': outputType,
    },
  );
}

ReducerMessage _toolCall(ToolCallStatus status) {
  return ReducerMessage(
    id: 'tool-${status.name}',
    kind: 'tool-call',
    createdAt: _createdAt,
    tool: ToolInfo(
      id: 'tool-1',
      name: 'exec',
      arguments: const <String, dynamic>{'cmd': 'echo 1'},
      status: status,
    ),
  );
}

ReducerMessage _agentEvent(String eventType, {String? text}) {
  return ReducerMessage(
    id: 'event-$eventType',
    kind: 'agent-event',
    createdAt: _createdAt,
    text: text,
    metadata: <String, dynamic>{
      'role': 'agent',
      'eventType': eventType,
    },
  );
}
