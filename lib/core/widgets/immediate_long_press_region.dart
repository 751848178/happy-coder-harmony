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
///
/// Additionally, velocity-based rejection prevents the long press from firing
/// when the user is actively scrolling: if consecutive pointer move events
/// exceed a scroll-like velocity, the gesture is rejected before the timer
/// fires.
class ImmediateLongPressRegion extends StatelessWidget {
  const ImmediateLongPressRegion({
    super.key,
    required this.child,
    required this.onLongPress,
    this.enabled = true,
    this.longPressDelay = kLongPressTimeout,
    this.moveSlop = kTouchSlop,
  });

  final Widget child;
  final FutureOr<void> Function() onLongPress;
  final bool enabled;
  final Duration longPressDelay;
  final double moveSlop;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: enabled
          ? {
              _ArenaLongPressGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
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
            }
          : const <Type, GestureRecognizerFactory>{},
      child: child,
    );
  }
}

/// A [LongPressGestureRecognizer] subclass that overrides
/// [preAcceptSlopTolerance] with a custom [movementThreshold] and adds
/// velocity-based rejection to prevent long press from firing during active
/// scrolling.
///
/// By extending [LongPressGestureRecognizer] directly we inherit all the
/// arena lifecycle management (accept / reject, timer) and add a velocity
/// check on top. When consecutive [PointerMoveEvent]s exceed
/// [_scrollVelocityThreshold], the recognizer rejects itself so the scroll
/// recognizer can take over.
class _ArenaLongPressGestureRecognizer extends LongPressGestureRecognizer {
  _ArenaLongPressGestureRecognizer({
    required Duration duration,
    required this.movementThreshold,
  }) : super(duration: duration);

  final double movementThreshold;

  int? _trackedPointer;
  Offset? _previousPosition;
  Duration? _previousTimestamp;
  int _scrollLikeMoveCount = 0;

  /// Pointer velocity above this threshold (px/s) suggests scrolling.
  static const double _scrollVelocityThreshold = 120.0;

  /// Number of consecutive scroll-like move events needed to reject.
  static const int _scrollMoveConfirmation = 2;

  @override
  double? get preAcceptSlopTolerance => movementThreshold;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _trackedPointer = event.pointer;
    _previousPosition = event.position;
    _previousTimestamp = event.timeStamp;
    _scrollLikeMoveCount = 0;
    super.addAllowedPointer(event);
  }

  @override
  void didExceedDeadline() {
    final pointer = _trackedPointer;
    super.didExceedDeadline();
    if (pointer != null) {
      GestureBinding.instance.cancelPointer(pointer);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent &&
        _previousPosition != null &&
        _previousTimestamp != null) {
      final dtMicros = (event.timeStamp - _previousTimestamp!).inMicroseconds;
      if (dtMicros > 0) {
        final distance = (event.position - _previousPosition!).distance;
        final velocity = distance * 1000000 / dtMicros;
        if (velocity > _scrollVelocityThreshold) {
          _scrollLikeMoveCount++;
          if (_scrollLikeMoveCount >= _scrollMoveConfirmation) {
            resolve(GestureDisposition.rejected);
            return;
          }
        } else {
          _scrollLikeMoveCount = 0;
        }
      }
      _previousPosition = event.position;
      _previousTimestamp = event.timeStamp;
    }
    super.handleEvent(event);
  }

  @override
  void acceptGesture(int pointer) {
    _reset();
    super.acceptGesture(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    _reset();
    super.rejectGesture(pointer);
  }

  void _reset() {
    _trackedPointer = null;
    _previousPosition = null;
    _previousTimestamp = null;
    _scrollLikeMoveCount = 0;
  }
}
