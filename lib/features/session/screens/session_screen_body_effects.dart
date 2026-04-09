part of 'session_screen.dart';

class _SessionScreenBodyEffects extends StatefulWidget {
  const _SessionScreenBodyEffects({
    required this.bodyState,
    required this.hasScrolledToLatest,
    required this.hasNewerMessages,
    required this.userHasScrolledUp,
    required this.initialLoadComplete,
    required this.autoApproveEnabled,
    required this.stickyTurnId,
    required this.onVisibleTurnGroupsChanged,
    required this.onScheduleScrollToLatest,
    required this.onMaybeAutoApprovePendingTools,
    required this.onUpdateScreenAwakePolicy,
    required this.onScheduleViewportStateRefresh,
    required this.onScheduleQueuedMessageReconciliation,
    required this.child,
  });

  final _SessionScreenBodyViewState bodyState;
  final bool hasScrolledToLatest;
  final bool hasNewerMessages;
  final bool userHasScrolledUp;
  final bool initialLoadComplete;
  final bool autoApproveEnabled;
  final String? stickyTurnId;
  final ValueChanged<List<_MessageTurnGroup>> onVisibleTurnGroupsChanged;
  final VoidCallback onScheduleScrollToLatest;
  final Future<void> Function() onMaybeAutoApprovePendingTools;
  final ValueChanged<bool> onUpdateScreenAwakePolicy;
  final VoidCallback onScheduleViewportStateRefresh;
  final VoidCallback onScheduleQueuedMessageReconciliation;
  final Widget child;

  @override
  State<_SessionScreenBodyEffects> createState() =>
      _SessionScreenBodyEffectsState();
}

class _SessionScreenBodyEffectsState extends State<_SessionScreenBodyEffects> {
  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleEffectSync();
  }

  @override
  void didUpdateWidget(covariant _SessionScreenBodyEffects oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleEffectSync();
  }

  void _scheduleEffectSync() {
    if (_syncScheduled) {
      return;
    }
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) {
        return;
      }
      final bodyState = widget.bodyState;
      widget.onVisibleTurnGroupsChanged(bodyState.turnGroups);
      if (bodyState.messages.isNotEmpty &&
          !widget.hasNewerMessages &&
          !widget.hasScrolledToLatest &&
          !widget.userHasScrolledUp) {
        Logger.info(
          '[SessionJumpDiag] effect-scroll-latest '
          'messages=${bodyState.messages.length} '
          'hasNewer=${widget.hasNewerMessages} '
          'hasScrolledToLatest=${widget.hasScrolledToLatest} '
          'userHasScrolledUp=${widget.userHasScrolledUp}',
        );
        widget.onScheduleScrollToLatest();
      }
      if (widget.autoApproveEnabled && bodyState.messages.isNotEmpty) {
        unawaited(widget.onMaybeAutoApprovePendingTools());
      }
      widget.onUpdateScreenAwakePolicy(bodyState.shouldKeepScreenAwake);
      if (bodyState.messages.isNotEmpty &&
          (bodyState.hasStickyCandidates || widget.stickyTurnId != null)) {
        widget.onScheduleViewportStateRefresh();
      }
      if (widget.initialLoadComplete) {
        widget.onScheduleQueuedMessageReconciliation();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
