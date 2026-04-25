import '../domain/reducer.dart';

class SessionToolVisualState {
  const SessionToolVisualState({
    required this.status,
    required this.showsManualActions,
    required this.showsAutoResolvingFooter,
  });

  final ToolCallStatus status;
  final bool showsManualActions;
  final bool showsAutoResolvingFooter;
}

SessionToolVisualState resolveSessionToolVisualState({
  required ToolCallStatus status,
  required bool autoApproveEnabled,
  required bool isToolActionPending,
}) {
  if (autoApproveEnabled) {
    if (status == ToolCallStatus.pending || isToolActionPending) {
      return const SessionToolVisualState(
        status: ToolCallStatus.executing,
        showsManualActions: false,
        showsAutoResolvingFooter: true,
      );
    }
    // approved / executing / completed / failed → silent
    return SessionToolVisualState(
      status: status,
      showsManualActions: false,
      showsAutoResolvingFooter: false,
    );
  }

  if (status == ToolCallStatus.pending || isToolActionPending) {
    return const SessionToolVisualState(
      status: ToolCallStatus.pending,
      showsManualActions: true,
      showsAutoResolvingFooter: false,
    );
  }

  return SessionToolVisualState(
    status: status,
    showsManualActions: false,
    showsAutoResolvingFooter: false,
  );
}
