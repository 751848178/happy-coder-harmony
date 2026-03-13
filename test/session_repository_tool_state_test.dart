import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/data/session_repository.dart';
import 'package:happy_coder_flutter/features/session/domain/reducer.dart';

void main() {
  test('approved tool state survives stale pending refresh', () {
    final repository = SessionRepository.instance;
    repository.clearAll();

    final createdAt = DateTime.fromMillisecondsSinceEpoch(1772970000000);
    const sessionId = 'session-1';
    const messageId = 'message-1';
    const toolId = 'tool-1';

    repository.applyMessages(sessionId, [
      ReducerMessage(
        id: messageId,
        kind: 'tool-call',
        createdAt: createdAt,
        tool: ToolInfo(
          id: toolId,
          name: 'edit_file',
          arguments: {'path': '/tmp/demo.dart'},
          status: ToolCallStatus.pending,
        ),
      ),
    ]);

    repository.approveToolCall(sessionId, toolId);

    repository.applyMessages(sessionId, [
      ReducerMessage(
        id: messageId,
        kind: 'tool-call',
        createdAt: createdAt,
        tool: ToolInfo(
          id: toolId,
          name: 'edit_file',
          arguments: {'path': '/tmp/demo.dart'},
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
}
