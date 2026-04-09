import 'package:flutter_test/flutter_test.dart';
import 'package:happy_coder_flutter/features/session/domain/reducer.dart';
import 'package:happy_coder_flutter/features/session/presentation/session_tool_visual_state.dart';

void main() {
  test('auto approval pending tools render as stable executing state', () {
    final state = resolveSessionToolVisualState(
      status: ToolCallStatus.pending,
      autoApproveEnabled: true,
      isToolActionPending: false,
    );

    expect(state.status, ToolCallStatus.executing);
    expect(state.showsAutoResolvingFooter, isTrue);
    expect(state.showsManualActions, isFalse);
  });

  test('manual pending tools keep manual action footer', () {
    final state = resolveSessionToolVisualState(
      status: ToolCallStatus.pending,
      autoApproveEnabled: false,
      isToolActionPending: false,
    );

    expect(state.status, ToolCallStatus.pending);
    expect(state.showsAutoResolvingFooter, isFalse);
    expect(state.showsManualActions, isTrue);
  });

  test('completed tools do not keep transient footer', () {
    final state = resolveSessionToolVisualState(
      status: ToolCallStatus.completed,
      autoApproveEnabled: true,
      isToolActionPending: false,
    );

    expect(state.status, ToolCallStatus.completed);
    expect(state.showsAutoResolvingFooter, isFalse);
    expect(state.showsManualActions, isFalse);
  });
}
