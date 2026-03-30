import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// A widget that detects long press using the gesture arena.
///
/// Unlike [Listener]-based approaches, this widget participates in Flutter's
/// gesture arena so it properly competes with [SelectableText] and scroll
/// recognizers. When it wins the arena at [longPressDelay], competing
/// recognizers (including [SelectableText]'s internal long press handler) are
/// naturally rejected, preventing duplicate menus or platform-level zoom on
/// HarmonyOS / iOS.
///
/// The [moveSlop] controls how far the pointer may drift from the initial
/// touch position before the long press is cancelled. In scrollable contexts
/// a larger value (e.g. 36 px) helps avoid accidental triggers during slow
/// scrolling.
class ImmediateLongPressRegion extends StatelessWidget {
  const ImmediateLongPressRegion({
    super.key,
    required this.child,
    required this.onLongPress,
    this.longPressDelay = kLongPressTimeout,
    this.moveSlop = kTouchSlop,
  });

  final Widget child;
  final FutureOr<void> Function() onLongPress;
  final Duration longPressDelay;
  final double moveSlop;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        _ArenaLongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            _ArenaLongPressGestureRecognizer>(
          () => _ArenaLongPressGestureRecognizer(
            duration: longPressDelay,
            movementThreshold: moveSlop,
          ),
          (recognizer) {
            recognizer.onLongPress = () {
              onLongPress();
            };
          },
        ),
      },
      child: child,
    );
  }
}

/// A [LongPressGestureRecognizer] subclass that overrides
/// [preAcceptSlopTolerance] with a custom [movementThreshold].
///
/// By extending [LongPressGestureRecognizer] directly we inherit all the
/// arena lifecycle management (accept / reject, timer, velocity tracking)
/// and simply customise the movement tolerance before the deadline fires.
class _ArenaLongPressGestureRecognizer extends LongPressGestureRecognizer {
  _ArenaLongPressGestureRecognizer({
    required Duration duration,
    required this.movementThreshold,
  }) : super(duration: duration);

  final double movementThreshold;

  @override
  double? get preAcceptSlopTolerance => movementThreshold;
}
