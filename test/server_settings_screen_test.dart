import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/settings/screens/server_settings_screen.dart';

void main() {
  testWidgets('server selection is opened from modify entry sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ServerSettingsScreen(),
      ),
    );

    expect(find.text('选择 Happy Server'), findsNothing);
    expect(find.text('修改服务器地址'), findsOneWidget);

    await tester.tap(find.text('修改服务器地址'));
    await tester.pumpAndSettle();

    expect(
      find.text('选择默认服务器、开发者提供的国内服务器或自定义 Happy Server 地址。'),
      findsOneWidget,
    );
    expect(find.text('开发者提供的国内服务器'), findsWidgets);
  });
}
