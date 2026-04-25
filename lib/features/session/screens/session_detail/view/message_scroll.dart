part of '../session_detail.dart';

class _ChatScrollController extends ScrollController {
  double? _standbyPixels;
  double? _standbyMaxScrollExtent;
  double? _standbyLastObservedMaxScrollExtent;
  bool _standbyAlignToBottom = false;

  /// Safe access to the current scroll position.
  ///
  /// Unlike [position], this does not assert that only one position is
  /// attached.  During a widget rebuild that swaps one `ListView` for another
  /// (e.g. when `_collapseAllTurns` toggles), the framework may briefly have
  /// two positions attached to this controller — the old one detaching and
  /// the new one attaching within the same frame.  Using [position] in that
  /// window triggers an assertion error.  This getter returns the most
  /// recently attached position instead.
  ScrollPosition get effectivePosition {
    assert(positions.isNotEmpty);
    return positions.last;
  }

  ScrollPosition? get effectivePositionOrNull =>
      positions.isEmpty ? null : positions.last;

  bool isEffectivePosition(ScrollPosition position) {
    return identical(effectivePositionOrNull, position);
  }

  @override
  void jumpTo(double value) {
    if (!hasClients) {
      return;
    }
    effectivePosition.jumpTo(value);
  }

  @override
  Future<void> animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) {
    if (!hasClients) {
      return Future<void>.value();
    }
    return effectivePosition.animateTo(
      offset,
      duration: duration,
      curve: curve,
    );
  }

  /// Record scroll state before prepending older messages above viewport.
  void standbyForPrepend() {
    if (!hasClients) return;
    _standbyPixels = effectivePosition.pixels;
    _standbyMaxScrollExtent = effectivePosition.maxScrollExtent;
    _standbyLastObservedMaxScrollExtent = null;
    _standbyAlignToBottom = false;
  }

  /// Record scroll state before appending newer messages below viewport.
  void standbyForAppend() {
    if (!hasClients) return;
    _standbyPixels = effectivePosition.pixels;
    _standbyMaxScrollExtent = effectivePosition.maxScrollExtent;
    _standbyLastObservedMaxScrollExtent = null;
    _standbyAlignToBottom = true;
  }

  /// Record scroll state for a jump-to-bottom operation.
  /// Sets standby pixels equal to maxScrollExtent so that the synchronous
  /// correction in [_ChatScrollPosition] pins the viewport to the bottom
  /// of the new content during layout, eliminating the one-frame white flash.
  void standbyForBottomJump() {
    if (!hasClients) return;
    _standbyPixels = effectivePosition.maxScrollExtent;
    _standbyMaxScrollExtent = effectivePosition.maxScrollExtent;
    _standbyLastObservedMaxScrollExtent = null;
    _standbyAlignToBottom = true;
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _ChatScrollPosition(
      controller: this,
      physics: physics,
      context: context,
      initialPixels: oldPosition?.pixels ?? initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

/// ScrollPosition that corrects scroll offset synchronously during layout
/// when a standby is active on the owning [_ChatScrollController].
///
/// This eliminates the one-frame jitter caused by post-frame-callback-based
/// anchor restoration. Correction happens in [applyContentDimensions], which
/// is called during layout (before paint), so the user never sees the wrong
/// position.
class _ChatScrollPosition extends ScrollPositionWithSingleContext {
  _ChatScrollPosition({
    required _ChatScrollController controller,
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  }) : _controller = controller;

  final _ChatScrollController _controller;

  @override
  bool applyContentDimensions(double min, double max) {
    final standbyPixels = _controller._standbyPixels;
    final standbyMax = _controller._standbyMaxScrollExtent;
    if (standbyPixels != null &&
        standbyMax != null &&
        _controller.isEffectivePosition(this)) {
      final previousObservedMax =
          _controller._standbyLastObservedMaxScrollExtent;
      final maxStable = previousObservedMax != null &&
          (max - previousObservedMax).abs() < 0.5;
      _controller._standbyLastObservedMaxScrollExtent = max;
      final alignToBottom = _controller._standbyAlignToBottom;
      final delta = max - standbyMax;
      // Flutter may refine content dimensions multiple times in one layout.
      // Only consume standby after maxScrollExtent stabilizes; otherwise an
      // early coarse max can over-correct the viewport and trigger window
      // jumps or opposite-edge autoload.
      if (max >= standbyMax && maxStable) {
        if (delta.abs() > 0.5) {
          final double corrected;
          if (alignToBottom) {
            // Append mode: keep distance from bottom constant.
            corrected = (max - (standbyMax - standbyPixels)).clamp(min, max);
          } else {
            // Prepend mode: shift down by the height of new content above.
            corrected = (standbyPixels + delta).clamp(min, max);
          }
          forcePixels(corrected);
        }
        // Consume standby once maxScrollExtent stabilizes, even if no
        // correction is ultimately needed.
        _controller._standbyPixels = null;
        _controller._standbyMaxScrollExtent = null;
        _controller._standbyLastObservedMaxScrollExtent = null;
        _controller._standbyAlignToBottom = false;
      }
    }
    return super.applyContentDimensions(min, max);
  }
}
