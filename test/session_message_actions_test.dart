import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/domain/reducer.dart';
import 'package:happy_coder_flutter/features/session/presentation/session_message_actions.dart';

void main() {
  test('text messages keep original content for long-press actions', () {
    final message = ReducerMessage(
      id: 'message-text',
      kind: 'text',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1772970000000),
      text: '  第一行\n第二行  ',
      metadata: const <String, dynamic>{'role': 'agent'},
    );

    expect(
      resolveSessionMessageActionText(message),
      '  第一行\n第二行  ',
    );
  });

  test('tool call messages do not expose long-press text actions', () {
    final message = ReducerMessage(
      id: 'message-tool',
      kind: 'tool-call',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1772970000000),
      text: 'tool output',
      tool: ToolInfo(
        id: 'tool-1',
        name: 'exec_command',
        arguments: const <String, dynamic>{'cmd': 'pwd'},
      ),
    );

    expect(
      resolveSessionMessageActionText(message),
      contains('工具调用: exec_command'),
    );
    expect(
      resolveSessionMessageActionText(message),
      contains('"cmd":"pwd"'),
    );
  });

  test('selection context menu adds direct message action entries', () {
    var forwarded = false;
    var savedTemplate = false;
    var inserted = false;

    final items = buildSessionMessageContextMenuButtonItems(
      baseItems: const <ContextMenuButtonItem>[
        ContextMenuButtonItem(
          onPressed: null,
          type: ContextMenuButtonType.copy,
        ),
        ContextMenuButtonItem(
          onPressed: null,
          type: ContextMenuButtonType.selectAll,
        ),
      ],
      onForward: () => forwarded = true,
      onSaveTemplate: () => savedTemplate = true,
      onInsertIntoComposer: () => inserted = true,
    );

    expect(items[0].type, ContextMenuButtonType.copy);
    expect(items[1].label, sessionMessageContextMenuForwardLabel);
    expect(items[2].label, sessionMessageContextMenuSaveTemplateLabel);
    expect(items[3].label, sessionMessageContextMenuInsertLabel);
    expect(items[4].type, ContextMenuButtonType.selectAll);

    items[1].onPressed!.call();
    items[2].onPressed!.call();
    items[3].onPressed!.call();

    expect(forwarded, isTrue);
    expect(savedTemplate, isTrue);
    expect(inserted, isTrue);
  });

  test('permission request messages expose summary text for actions', () {
    final message = ReducerMessage(
      id: 'message-permission',
      kind: 'permission-request',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1772970000000),
      permission: PermissionRequest(
        tool: 'read_file',
        arguments: const <String, dynamic>{'path': '/tmp/config.json'},
        reason: '需要读取配置文件',
      ),
    );

    expect(
      resolveSessionMessageActionText(message),
      '权限请求\n工具: read_file\n需要读取配置文件',
    );
  });

  test('turn-close messages expose visible label for actions', () {
    final message = ReducerMessage(
      id: 'message-turn-close',
      kind: 'turn-close',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1772970000000),
      turnClose: TurnClose(abandoned: true),
    );

    expect(resolveSessionMessageActionText(message), '回合已终止');
  });

  test('forwarded content appends to existing draft with spacing', () {
    final merged = mergeForwardedMessageIntoDraft(
      existingDraft: '已有草稿',
      forwardedText: '转发内容',
    );

    expect(merged, '已有草稿\n\n转发内容');
  });

  test('insert text respects current cursor position', () {
    final nextValue = insertComposerTextAtSelection(
      currentValue: const TextEditingValue(
        text: 'HelloWorld',
        selection: TextSelection.collapsed(offset: 5),
      ),
      insertion: ' ',
    );

    expect(nextValue.text, 'Hello World');
    expect(nextValue.selection.baseOffset, 6);
    expect(nextValue.selection.extentOffset, 6);
  });

  test('insert text replaces the selected range', () {
    final nextValue = insertComposerTextAtSelection(
      currentValue: const TextEditingValue(
        text: 'Hello World',
        selection: TextSelection(baseOffset: 6, extentOffset: 11),
      ),
      insertion: 'Codex',
    );

    expect(nextValue.text, 'Hello Codex');
    expect(nextValue.selection.baseOffset, 11);
    expect(nextValue.selection.extentOffset, 11);
  });
}
