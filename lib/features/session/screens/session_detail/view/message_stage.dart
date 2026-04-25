part of '../session_detail.dart';

extension _SessionScreenMessageStage on _SessionScreenState {
  Widget _buildMessageListStage({
    required Widget list,
    required bool shouldRevealList,
    required bool suppressFlicker,
  }) {
    final listVisible = shouldRevealList && !suppressFlicker;
    final stageIndex = !shouldRevealList
        ? 1
        : listVisible
            ? 0
            : 2;

    // Keep the ListView mounted for anchor restoration, but guarantee the
    // stage paints through a single visible branch. This avoids compositor
    // artifacts on OHOS where hidden scroll layers can be retained and appear
    // as a second half-screen message list during send/rebuild churn.
    return ColoredBox(
      color: AppTheme.neutral50,
      child: ClipRect(
        child: SizedBox.expand(
          child: IndexedStack(
            index: stageIndex,
            children: [
              IgnorePointer(
                ignoring: !listVisible,
                child: RepaintBoundary(
                  key: const ValueKey('session-message-list-stage'),
                  child: list,
                ),
              ),
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox.expand(),
            ],
          ),
        ),
      ),
    );
  }
}
