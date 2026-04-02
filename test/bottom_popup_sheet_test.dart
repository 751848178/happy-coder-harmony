import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/core/widgets/bottom_popup_sheet.dart';

void main() {
  testWidgets('shows custom bottom popup without BottomSheet widget',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: FilledButton(
                  onPressed: () {
                    showBottomPopupSheet<void>(
                      context: context,
                      builder: (context) {
                        return Container(
                          key: const Key('popup-panel'),
                          height: 120,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.byKey(const Key('popup-panel')), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });
}
