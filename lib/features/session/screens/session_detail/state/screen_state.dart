part of '../session_detail.dart';

class _SessionScreenState extends ConsumerState<SessionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final _ChatScrollController _scrollController = _ChatScrollController();
  late final AnimationController _refreshIconController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  final Set<String> _toolActionsInFlight = <String>{};
  final Map<String, ValueNotifier<bool>> _toolActionPendingNotifiers =
      <String, ValueNotifier<bool>>{};
  final Set<String> _expandedTurnIds = <String>{};
  final Set<String> _autoApprovedToolIds = <String>{};
  final Map<String, String> _turnSectionRowIds = <String, String>{};
  final Map<String, String> _turnReplyRowIds = <String, String>{};
  final SessionComposerQueueService _composerQueueService =
      SessionComposerQueueService.instance;
  final SessionInputTemplateService _inputTemplateService =
      SessionInputTemplateService.instance;
  final SessionUiStateService _uiStateService = SessionUiStateService.instance;
  ProviderContainer? _providerContainer;
  late final _SessionScreenBodyPresenter _bodyPresenter =
      _SessionScreenBodyPresenter(this);
  late final _SessionScreenLoadCoordinator _loadCoordinator =
      _SessionScreenLoadCoordinator(this);
  late final _SessionScreenCommandController _commandController =
      _SessionScreenCommandController(this);
  late final _SessionViewportController _viewportController =
      _SessionViewportController(this);
  // --- Atomic state: ValueNotifiers for leaf-only UI state ---
  // These only affect small widgets (icons, buttons) — wrapping them in
  // ValueNotifier + ValueListenableBuilder avoids full-screen rebuilds.
  final ValueNotifier<bool> _isSendingN = ValueNotifier(false);
  final ValueNotifier<bool> _isAbortingN = ValueNotifier(false);
  final ValueNotifier<bool> _isRefreshingSessionStateN = ValueNotifier(false);
  final ValueNotifier<bool> _isSyncingAllMessagesN = ValueNotifier(false);
  final ValueNotifier<bool> _isLoadingOlderMessagesN = ValueNotifier(false);
  final ValueNotifier<bool> _isLoadingNewerMessagesN = ValueNotifier(false);
  final ValueNotifier<bool> _isHydratingArchiveHistoryN = ValueNotifier(false);
  final ValueNotifier<int> _archivedMessageCountN = ValueNotifier(0);
  final ValueNotifier<bool> _archivedMessageHistoryCompleteN =
      ValueNotifier(false);
  final ValueNotifier<bool> _sessionOverviewCollapsedN = ValueNotifier(true);
  final ValueNotifier<List<SessionInputTemplate>> _customInputTemplatesN =
      ValueNotifier(const <SessionInputTemplate>[]);
  final ValueNotifier<List<_CollapsedTurnSummary>> _collapsedTurnSummariesN =
      ValueNotifier(const <_CollapsedTurnSummary>[]);
  final ValueNotifier<bool> _messageViewportReadyN = ValueNotifier(false);
  final ValueNotifier<bool> _messageInteractionsEnabledN = ValueNotifier(false);
  // When true the message list paints with opacity 0 to hide the single-frame
  // scroll-position jitter that occurs when older messages are prepended.
  // When true the message list is replaced by a loading indicator to hide
  // the single-frame scroll-position jitter that occurs when older messages
  // are prepended during edge loading.
  final ValueNotifier<bool> _suppressContentFlickerN = ValueNotifier(false);

  // Convenience getters for logic reads (no rebuild triggered).
  bool get _isSending => _isSendingN.value;
  bool get _isAborting => _isAbortingN.value;
  bool get _isRefreshingSessionState => _isRefreshingSessionStateN.value;
  bool get _isSyncingAllMessages => _isSyncingAllMessagesN.value;
  bool get _isLoadingOlderMessages => _isLoadingOlderMessagesN.value;
  bool get _isLoadingNewerMessages => _isLoadingNewerMessagesN.value;
  bool get _isHydratingArchiveHistory => _isHydratingArchiveHistoryN.value;
  int get _archivedMessageCount => _archivedMessageCountN.value;
  bool get _isArchivedMessageHistoryComplete =>
      _archivedMessageHistoryCompleteN.value;
  bool get _hasCompleteArchivedMessageHistory {
    final expectedMessageCount = _resolveExpectedArchivedHistoryMessageCount();
    return expectedMessageCount > 0 &&
        _isArchivedMessageHistoryComplete &&
        _archivedMessageCount >= expectedMessageCount;
  }

  bool get _hasLocallyAccessibleOlderArchivedMessages =>
      _archivedMessageCount > 0 &&
      _hasOlderMessages &&
      _messageWindowStartIndex > 0 &&
      _messageWindowStartIndex <= _archivedMessageCount;
  bool get _hasLocallyAccessibleNewerArchivedMessages =>
      _archivedMessageCount > 0 &&
      _hasNewerMessages &&
      (_messageWindowStartIndex + _messages.length) < _archivedMessageCount;
  bool get _canJumpToEarliestArchivedBoundary =>
      _archivedMessageCount > 0 &&
      _messageWindowStartIndex > 0 &&
      _messageWindowStartIndex < _archivedMessageCount;
  bool get _sessionOverviewCollapsed => _sessionOverviewCollapsedN.value;
  bool get _messageViewportReady => _messageViewportReadyN.value;
  List<_CollapsedTurnSummary> get _collapsedTurnSummaries =>
      _collapsedTurnSummariesN.value;

  bool _awaitingAbortRemoteSettle = false;
  bool _isAutoSendingQueuedMessage = false;
  bool _queueReconcileScheduled = false;
  bool _collapseAllTurns = false;
  bool _hasScrolledToLatest = false;
  // Track whether the initial session data load is done so that build()
  // can skip non-essential computation during the loading phase.
  bool _initialLoadComplete = false;
  bool _userHasScrolledUp = false;
  String? _activeResponseLocalId;
  bool? _manualThinkingOverride;

  // --- Scroll / overlay state backed by ValueNotifiers ---
  // These change at high frequency during scrolling and drag gestures.
  // Using ValueNotifiers ensures only the specific overlay widgets rebuild,
  // not the entire screen (message list, input area, AppBar, etc.).
  final ValueNotifier<bool> _canScrollToTopN = ValueNotifier(false);
  final ValueNotifier<bool> _canScrollToBottomN = ValueNotifier(false);
  final ValueNotifier<bool> _isNearBottomN = ValueNotifier(true);
  final ValueNotifier<bool> _shouldStickToLatestN = ValueNotifier(true);
  final ValueNotifier<bool> _hasUnreadMessagesN = ValueNotifier(false);
  final ValueNotifier<String?> _stickyTurnIdN = ValueNotifier(null);
  final ValueNotifier<bool> _scrollActionsCollapsedN = ValueNotifier(false);
  final ValueNotifier<double> _scrollActionVerticalOffsetN = ValueNotifier(0.0);
  final ValueNotifier<double> _scrollActionDragDxN = ValueNotifier(0.0);

  bool get _canScrollToTop => _canScrollToTopN.value;
  bool get _canScrollToBottom => _canScrollToBottomN.value;
  bool get _isNearBottom => _isNearBottomN.value;
  bool get _shouldStickToLatest => _shouldStickToLatestN.value;
  String? get _stickyTurnId => _stickyTurnIdN.value;
  bool get _scrollActionsCollapsed => _scrollActionsCollapsedN.value;
  double get _scrollActionVerticalOffset => _scrollActionVerticalOffsetN.value;
  double get _scrollActionDragDx => _scrollActionDragDxN.value;
  bool get _cachedHasStickyCandidates => _bodyPresenter.hasStickyCandidates;
  Session? _queuedReconcileSession;
  List<ReducerMessage>? _queuedReconcileMessages;
  int _queuedReconcileQueueSize = 0;
  String? _queuedReconcileActiveResponseLocalId;
  bool _queuedReconcileIsSending = false;
  bool _queuedReconcileIsAutoSending = false;
  bool? _queuedReconcileManualThinkingOverride;
  final ValueNotifier<List<QueuedComposerMessage>> _queuedMessagesN =
      ValueNotifier(const <QueuedComposerMessage>[]);
  List<QueuedComposerMessage> get _queuedMessages => _queuedMessagesN.value;

  // --- Per-session message state (local, not from global Riverpod state) ---
  // Messages are managed per-session. A ValueNotifier +
  // messageChangesFor() subscription provides reactive updates scoped
  // to this session, without loading all sessions' messages globally.
  final ValueNotifier<_SessionMessageViewState> _messageViewStateN =
      ValueNotifier(const _SessionMessageViewState.initial());
  List<ReducerMessage> get _messages => _messageViewStateN.value.messages;
  bool get _hasLoadedMessages => _messageViewStateN.value.hasLoadedMessages;
  int get _totalMessageCount => _messageViewStateN.value.totalMessageCount;
  bool get _hasOlderMessages => _messageViewStateN.value.hasOlderMessages;
  bool get _hasNewerMessages => _messageViewStateN.value.hasNewerMessages;
  int get _messageWindowStartIndex => _messageViewStateN.value.windowStartIndex;
  StreamSubscription<void>? _messageChangeSub;
  // Guards against redundant _syncMessagesFromRepository calls.
  // During initial load, multiple state emissions arrive in rapid succession
  // (replaceMessages → applyMessages → preview update).  Each triggers a
  // _syncMessagesFromRepository → _messagesN update → full build cascade.
  // Debouncing coalesces these into a single sync per microtask.
  bool _messageSyncScheduled = false;
  final Map<String, BuildContext> _messageRowContexts =
      <String, BuildContext>{};
  List<SessionInputTemplate> get _customInputTemplates =>
      _customInputTemplatesN.value;
  List<_MessageTurnGroup> _visibleTurnGroups = const <_MessageTurnGroup>[];
  List<_MessageTurnGroup>? _cachedPruneTurnGroups;
  // Cached file-path tap handler — avoids creating a new closure on every
  // _buildMessageBubble() call for every visible message on every build.
  String? _cachedFilePathTapHandlerSessionId;
  void Function(String)? _cachedFilePathTapHandler;
  StreamSubscription<SocketEvent>? _socketEventSubscription;
  Timer? _draftPersistDebounce;
  Timer? _messagePollingTimer;
  Timer? _socketRefreshDebounce;
  Timer? _messageInteractionIdleDebounce;
  bool _desiredScreenAwake = false;
  bool _appliedScreenAwake = false;
  bool _screenAwakeUpdateScheduled = false;
  int _screenAwakePolicyEpoch = 0;

  void _scheduleActivateDetailRefreshGate() {
    final sessionId = widget.sessionId;
    scheduleMicrotask(() {
      if (!mounted) {
        return;
      }
      ref.read(activeSessionDetailIdProvider.notifier).state = sessionId;
    });
  }

  void _scheduleDeactivateDetailRefreshGate() {
    final container = _providerContainer;
    if (container == null) {
      return;
    }
    final sessionId = widget.sessionId;
    scheduleMicrotask(() {
      if (container.read(activeSessionDetailIdProvider) != sessionId) {
        return;
      }
      container.read(activeSessionDetailIdProvider.notifier).state = null;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleActivateDetailRefreshGate();
    _scrollController.addListener(_handleScrollMetricsChanged);
    _messageController.addListener(_handleComposerChanged);
    _loadQueuedComposerMessages();
    _loadNonCriticalUiData();
    _loadSessionData();
    _subscribeToSocketEvents();
    _subscribeToMessageChanges();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerContainer ??= ProviderScope.containerOf(context, listen: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _messagePollingTimer?.cancel();
      _messagePollingTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      if (_messageChangeSub != null) {
        _startMessagePolling();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scheduleDeactivateDetailRefreshGate();
    unawaited(_releaseScreenAwakePolicy());
    _messageController.removeListener(_handleComposerChanged);
    _messageFocusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _draftPersistDebounce?.cancel();
    _socketEventSubscription?.cancel();
    _messagePollingTimer?.cancel();
    _socketRefreshDebounce?.cancel();
    _messageInteractionIdleDebounce?.cancel();
    _refreshIconController.dispose();
    _messageChangeSub?.cancel();
    _messageViewStateN.dispose();
    _isSendingN.dispose();
    _isAbortingN.dispose();
    _isRefreshingSessionStateN.dispose();
    _isSyncingAllMessagesN.dispose();
    _isLoadingOlderMessagesN.dispose();
    _isLoadingNewerMessagesN.dispose();
    _isHydratingArchiveHistoryN.dispose();
    _archivedMessageCountN.dispose();
    _archivedMessageHistoryCompleteN.dispose();
    _sessionOverviewCollapsedN.dispose();
    _customInputTemplatesN.dispose();
    _collapsedTurnSummariesN.dispose();
    _messageViewportReadyN.dispose();
    _messageInteractionsEnabledN.dispose();
    _canScrollToTopN.dispose();
    _canScrollToBottomN.dispose();
    _isNearBottomN.dispose();
    _shouldStickToLatestN.dispose();
    _hasUnreadMessagesN.dispose();
    _stickyTurnIdN.dispose();
    _scrollActionsCollapsedN.dispose();
    _scrollActionVerticalOffsetN.dispose();
    _scrollActionDragDxN.dispose();
    _suppressContentFlickerN.dispose();
    _queuedMessagesN.dispose();
    for (final notifier in _toolActionPendingNotifiers.values) {
      notifier.dispose();
    }
    clearContentDetectionCaches();
    MarkdownBlock.parseCache.clear();
    MarkdownTextSection.parseCache.clear();
    MarkdownInlineParser.parseCache.clear();
    super.dispose();
  }

  void _updateState(VoidCallback update) => setState(update);

  @override
  Widget build(BuildContext context) => _buildSessionScreen(context);
}
