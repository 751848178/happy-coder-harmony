part of 'session_screen.dart';

extension _SessionScreenStateScroll on _SessionScreenState {
  void _scrollToBottom() => _viewportController.scrollToBottom();

  void _scheduleScrollToLatest({
    bool animate = false,
    bool force = false,
  }) => _viewportController.scheduleScrollToLatest(
        animate: animate,
        force: force,
      );

  void _scrollToTop() => _viewportController.scrollToTop();
}
