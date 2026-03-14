import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/data/session_grouping_service.dart';

void main() {
  test('default group collapse state survives json roundtrip', () {
    final state = SessionGroupingState(
      useCustomGroups: true,
      groups: const [
        SessionGroup(
          id: 'group-1',
          name: '进行中',
          sessionIds: ['session-1'],
          collapsed: true,
        ),
      ],
      ungroupedCollapsed: true,
      collapsedDefaultGroups: const {'今天', '本周'},
      expandedDefaultGroups: const {'过期会话'},
    );

    final decoded = SessionGroupingState.fromJson(state.toJson());

    expect(decoded.useCustomGroups, isTrue);
    expect(decoded.groups.single.id, 'group-1');
    expect(decoded.groups.single.collapsed, isTrue);
    expect(decoded.ungroupedCollapsed, isTrue);
    expect(decoded.collapsedDefaultGroups, {'今天', '本周'});
    expect(decoded.expandedDefaultGroups, {'过期会话'});
  });
}
