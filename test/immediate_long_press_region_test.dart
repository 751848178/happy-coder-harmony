import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/core/widgets/immediate_long_press_region.dart';

void main() {
  testWidgets('fires long press before finger lift and suppresses child long press',
      (tester) async {
    var didLongPress = false;
    var didChildLongPress = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ImmediateLongPressRegion(
              longPressDelay: const Duration(milliseconds: 80),
              onLongPress: () async {
                didLongPress = true;
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () {
                  didChildLongPress = true;
                },
                child: const SizedBox(width: 120, height: 120),
              ),
            ),
          ),
        ),
      ),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
    await tester.pump(const Duration(milliseconds: 90));

    expect(didLongPress, isTrue);
    expect(didChildLongPress, isFalse);

    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pump();

    expect(didChildLongPress, isFalse);
  });

  testWidgets('does not fire when pointer moves beyond slop', (tester) async {
    var didLongPress = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ImmediateLongPressRegion(
              longPressDelay: const Duration(milliseconds: 80),
              onLongPress: () async {
                didLongPress = true;
              },
              child: const SizedBox(width: 120, height: 120),
            ),
          ),
        ),
      ),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump(const Duration(milliseconds: 90));

    expect(didLongPress, isFalse);
    await gesture.up();
  });

  testWidgets('does not fire when pointer is released before deadline',
      (tester) async {
    var didLongPress = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ImmediateLongPressRegion(
              longPressDelay: const Duration(milliseconds: 300),
              onLongPress: () async {
                didLongPress = true;
              },
              child: const SizedBox(width: 120, height: 120),
            ),
          ),
        ),
      ),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));

    expect(didLongPress, isFalse);
  });

  testWidgets('does not fire when pointer drifts slightly within slop',
      (tester) async {
    var didLongPress = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ImmediateLongPressRegion(
              longPressDelay: const Duration(milliseconds: 80),
              moveSlop: 20.0,
              onLongPress: () async {
                didLongPress = true;
              },
              child: const SizedBox(width: 120, height: 120),
            ),
          ),
        ),
      ),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
    // Move 10px, within the 20px slop
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump(const Duration(milliseconds: 90));

    expect(didLongPress, isTrue);
    await gesture.up();
  });
}
