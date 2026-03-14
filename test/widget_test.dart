import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/main.dart';

void main() {
  testWidgets('app boots inside ProviderScope', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HappyCoderApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(HappyCoderApp), findsOneWidget);
    expect(find.byType(ProviderScope), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
