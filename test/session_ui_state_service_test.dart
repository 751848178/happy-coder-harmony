import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/data/session_ui_state_service.dart';

void main() {
  test('session ui state json roundtrip keeps collapsed preferences', () {
    const state = SessionUiState(
      overviewCollapsed: false,
      collapseAllTurns: true,
      expandedTurnIds: {'turn-1', 'turn-2'},
    );

    final restored = SessionUiState.fromJson(state.toJson());

    expect(restored.overviewCollapsed, isFalse);
    expect(restored.collapseAllTurns, isTrue);
    expect(restored.expandedTurnIds, {'turn-1', 'turn-2'});
    expect(restored.isDefault, isFalse);
  });

  test('default ui state is treated as removable snapshot', () {
    const state = SessionUiState();

    expect(state.overviewCollapsed, isTrue);
    expect(state.collapseAllTurns, isFalse);
    expect(state.expandedTurnIds, isEmpty);
    expect(state.isDefault, isTrue);
  });
}
