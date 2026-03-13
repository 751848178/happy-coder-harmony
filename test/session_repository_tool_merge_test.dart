import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/data/session_repository.dart';
import 'package:happy_coder_flutter/features/session/domain/reducer.dart';

void main() {
  test('tool result merges into existing tool card without losing context', () {
    final repository = SessionRepository.instance;
    repository.clearAll();

    const sessionId = 'session-tool-merge';
    const toolMessageId = 'tool:call_1';
    const toolId = 'call_1';
    final startedAt = DateTime.fromMillisecondsSinceEpoch(1773300000000);
    final completedAt = startedAt.add(const Duration(seconds: 3));

    repository.applyMessages(sessionId, [
      ReducerMessage(
        id: toolMessageId,
        kind: 'tool-call',
        createdAt: startedAt,
        tool: ToolInfo(
          id: toolId,
          name: 'Read',
          arguments: {'file_path': '/tmp/demo.yaml'},
          status: ToolCallStatus.pending,
          description: '读取配置文件',
        ),
        metadata: const {'role': 'agent'},
      ),
    ]);

    repository.applyMessages(sessionId, [
      ReducerMessage(
        id: toolMessageId,
        kind: 'tool-call',
        createdAt: completedAt,
        tool: ToolInfo(
          id: toolId,
          name: 'unknown',
          arguments: const {},
          status: ToolCallStatus.completed,
          result: 'services:\n  redis:\n    image: redis:7.2-alpine',
        ),
        metadata: const {'role': 'agent'},
      ),
    ]);

    final sessionMessages = repository.getSessionMessages(sessionId);
    expect(sessionMessages, isNotNull);
    expect(sessionMessages!.messages, hasLength(1));

    final merged = sessionMessages.messages.single;
    expect(merged.createdAt, startedAt);
    expect(merged.tool, isNotNull);
    expect(merged.tool!.name, 'Read');
    expect(merged.tool!.arguments['file_path'], '/tmp/demo.yaml');
    expect(merged.tool!.status, ToolCallStatus.completed);
    expect(merged.tool!.result, contains('redis:7.2-alpine'));
    expect(merged.tool!.description, '读取配置文件');

    repository.clearAll();
  });
}
