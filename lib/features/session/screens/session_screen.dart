import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/platform/screen_awake_bridge.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/providers/app_providers.dart';
import '../../../shared/utils/extensions.dart';
import '../../../core/widgets/bottom_popup_sheet.dart';
import '../../../harmony/src/harmony_platform.dart';
import '../../../core/widgets/immediate_long_press_region.dart';
import '../data/session_composer_queue_service.dart';
import '../data/session_input_template_service.dart';
import '../domain/session_stats.dart';
import '../data/session_ui_state_service.dart';
import '../domain/session_list_preview.dart';
import '../presentation/session_input_template_catalog.dart';
import '../presentation/session_message_actions.dart';
import '../presentation/session_tool_visual_state.dart';
import '../presentation/session_turn_status.dart';
import '../domain/session_creation_options.dart';
import '../../socketio/domain/socket_service.dart';
import '../../storage/domain/storage_models.dart' as storage_models;

part 'session_screen_state_load.dart';
part 'session_screen_state_socket.dart';
part 'session_screen_state_scroll.dart';
part 'session_screen_state_queue.dart';
part 'session_screen_state_queue_management.dart';
part 'session_screen_state_refresh.dart';
part 'session_screen_state_turns.dart';
part 'session_screen_state_screen_awake.dart';
part 'session_screen_state_sticky_prompt.dart';
part 'session_screen_state_build.dart';
part 'session_screen_body_presenter.dart';
part 'session_screen_body_effects.dart';
part 'session_screen_load_coordinator.dart';
part 'session_screen_command_controller.dart';
part 'session_screen_message_view_state.dart';
part 'session_screen_viewport_controller.dart';
part 'session_screen_state_appbar.dart';
part 'session_screen_state_clone.dart';
part 'session_screen_view_overview.dart';
part 'session_screen_view_messages.dart';
part 'session_screen_view_indicators.dart';
part 'session_screen_view_indicators_thinking.dart';
part 'session_screen_view_indicators_sticky.dart';
part 'session_screen_view_controls.dart';
part 'session_screen_view_input.dart';
part 'session_screen_view_metadata.dart';
part 'session_screen_view_command_logic.dart';
part 'session_screen_view_command_panels.dart';
part 'session_screen_view_command_template_editor.dart';
part 'session_screen_view_queue_panel.dart';
part 'session_screen_state_actions.dart';
part 'session_screen_state_tool_actions.dart';
part 'session_screen_message_bubble.dart';
part 'session_screen_message_bubble_presenter.dart';
part 'session_screen_message_bubble_collapsed_text.dart';
part 'session_screen_message_bubble_collapsed_tool.dart';
part 'session_screen_message_bubble_content.dart';
part 'session_screen_message_bubble_status.dart';
part 'session_screen_message_bubble_tool_panel.dart';
part 'session_screen_message_bubble_tool_panel_support.dart';
part 'session_screen_message_bubble_tool_sections.dart';
part 'session_screen_message_bubble_tool_sections_2.dart';
part 'session_screen_message_bubble_tool_helpers.dart';
part 'session_screen_message_bubble_tool_helpers_2.dart';
part 'session_screen_message_bubble_tool_helpers_3.dart';
part 'session_screen_message_actions.dart';
part 'session_screen_message_forward.dart';
part 'session_screen_markdown_message.dart';
part 'session_screen_markdown_table.dart';
part 'session_screen_markdown_text.dart';
part 'session_screen_markdown_text_parser.dart';
part 'session_screen_markdown_inline_parser.dart';
part 'session_screen_inline_code_panel.dart';
part 'session_screen_inline_code_panel_helpers.dart';
part 'session_screen_inline_code_panel_render.dart';
part 'session_screen_inline_code_panel_helpers_2.dart';
part 'session_screen_tool_support.dart';
part 'session_screen_content_detection.dart';
part 'session_screen_markdown_block.dart';
part 'session_screen_turn_group.dart';
part 'session_screen_support_widgets.dart';
part 'session_screen_mode_option.dart';

const double _sessionMessageListTopPadding = 12.0;
const double _sessionMessageListBottomPadding = 24.0;
const double _sessionScrollActionButtonSize = 42.0;
const double _sessionScrollActionBottomInset = 20.0;
const double _sessionScrollActionGap = 10.0;
const double _sessionScrollActionHandleWidth = 22.0;
const double _sessionScrollActionHandleHeight = 86.0;
const double _sessionScrollActionHandlePeekWidth = 10.0;
const double _sessionScrollActionHideThreshold = 28.0;
const double _sessionScrollActionDragTravel = 42.0;
const double _sessionScrollActionTopClearance = 76.0;
const Duration _sessionMessageImmediateLongPressDelay = Duration(
  milliseconds: 480,
);
const double _sessionMessageLongPressMoveSlop = 36.0;
const Duration _sessionMessageInteractionIdleDelay = Duration(
  milliseconds: 160,
);
const double _sessionScrollActionRailHeight =
    _sessionScrollActionButtonSize * 3 + _sessionScrollActionGap * 2;
const double _sessionLongScrollJumpThresholdViewports = 4.0;
const double _sessionLongScrollAnimatedTailViewports = 0.9;
const bool _sessionVerbosePerfLogging = false;

class _SessionScreenSelection {
  const _SessionScreenSelection({
    required this.session,
    required this.hasLoadedSessions,
    required this.isReady,
  });

  const _SessionScreenSelection.initial()
      : this(
          session: null,
          hasLoadedSessions: false,
          isReady: false,
        );

  final Session? session;
  final bool hasLoadedSessions;
  final bool isReady;

  /// Compare sessions by fields the detail page actually uses.
  /// Excludes preview-only fields (previewText, lastMessageAt,
  /// listStatusKind, latestUsage) which change on every message
  /// update but are only consumed by the session list page.
  /// Without this, every streaming chunk triggers a full rebuild.
  static bool _sessionStableEqual(Session? a, Session? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.id == b.id &&
        a.title == b.title &&
        a.active == b.active &&
        a.thinking == b.thinking &&
        a.thinkingAt == b.thinkingAt &&
        a.draft == b.draft &&
        a.permissionMode == b.permissionMode &&
        a.modelMode == b.modelMode &&
        a.path == b.path &&
        a.presence == b.presence &&
        identical(a.metadata, b.metadata);
  }

  @override
  bool operator ==(Object other) {
    return other is _SessionScreenSelection &&
        _sessionStableEqual(session, other.session) &&
        hasLoadedSessions == other.hasLoadedSessions &&
        isReady == other.isReady;
  }

  @override
  int get hashCode => Object.hash(
        session?.id,
        session?.title,
        session?.active,
        session?.thinking,
        hasLoadedSessions,
        isReady,
      );
}

/// 会话详情屏幕
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen>
    with SingleTickerProviderStateMixin {
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
  final Map<String, String> _turnSectionMessageIds = <String, String>{};
  final Map<String, String> _turnReplyMessageIds = <String, String>{};
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
  StreamSubscription<SocketEvent>? _socketEventSubscription;
  Timer? _draftPersistDebounce;
  Timer? _messagePollingTimer;
  Timer? _socketRefreshDebounce;
  Timer? _messageInteractionIdleDebounce;
  bool _desiredScreenAwake = false;
  bool _appliedScreenAwake = false;
  bool _screenAwakeUpdateScheduled = false;

  void _scheduleActivateDetailRefreshGate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeSessionDetailIdProvider.notifier).state = widget.sessionId;
    });
  }

  void _scheduleDeactivateDetailRefreshGate() {
    final container = _providerContainer;
    if (container == null) {
      return;
    }
    final sessionId = widget.sessionId;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (container.read(activeSessionDetailIdProvider) != sessionId) {
        return;
      }
      container.read(activeSessionDetailIdProvider.notifier).state = null;
    });
  }

  @override
  void initState() {
    super.initState();
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
  void dispose() {
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
    super.dispose();
  }

  /// Subscribe to per-session message changes from the repository.
  void _subscribeToMessageChanges() {
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    _messageChangeSub =
        sessionNotifier.messageChangesFor(widget.sessionId).listen((_) {
      if (!mounted) return;
      _scheduleMessageSync();
    });
  }

  /// Schedule a coalesced message sync at the end of the current microtask.
  /// Multiple rapid state emissions (common during initial load) are collapsed
  /// into a single _syncMessagesFromRepository call, preventing 4-5 redundant
  /// full-rebuild cascades.
  void _scheduleMessageSync() {
    if (_messageSyncScheduled) return;
    _messageSyncScheduled = true;
    scheduleMicrotask(() {
      _messageSyncScheduled = false;
      if (!mounted) return;
      _syncMessagesFromRepository();
    });
  }

  /// Read current messages from the repository and update local ValueNotifiers.
  void _syncMessagesFromRepository() {
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final sessionMessages =
        sessionNotifier.getSessionMessages(widget.sessionId);
    final nextState = _SessionMessageViewState(
      messages: sessionMessages?.messages ?? const <ReducerMessage>[],
      hasLoadedMessages: sessionMessages?.isLoaded == true,
      totalMessageCount: sessionMessages?.totalMessageCount ?? 0,
      hasOlderMessages: sessionMessages?.hasOlderMessages == true,
      hasNewerMessages: sessionMessages?.hasNewerMessages == true,
      windowStartIndex: sessionMessages?.windowStartIndex ?? 0,
    );
    final previousState = _messageViewStateN.value;
    if (previousState == nextState) {
      return;
    }
    if (!nextState.hasLoadedMessages || nextState.messages.isEmpty) {
      _messageViewportReadyN.value = true;
    } else if (!previousState.hasLoadedMessages &&
        !nextState.hasNewerMessages &&
        !_hasScrolledToLatest &&
        !_userHasScrolledUp) {
      _messageViewportReadyN.value = false;
    }
    _messageViewStateN.value = nextState;
    _pruneMessageRenderCaches(nextState.messages);
    if (_collapseAllTurns &&
        nextState.hasLoadedMessages &&
        _collapsedTurnSummaries.isEmpty &&
        nextState.messages.isNotEmpty) {
      unawaited(
        _ensureCollapsedTurnSummariesLoaded(
          _resolveTurnGroups(nextState.messages),
        ),
      );
    }
    _logDuplicateMessageIds(nextState.messages, stage: 'message-sync');
    if (_sessionVerbosePerfLogging) {
      Logger.info(
        '[SessionPerf][message-sync] session=${widget.sessionId} '
        'loaded=${nextState.hasLoadedMessages} '
        'messages=${nextState.messages.length} '
        'total=${nextState.totalMessageCount} '
        'hasOlder=${nextState.hasOlderMessages} '
        'hasNewer=${nextState.hasNewerMessages} '
        'start=${nextState.windowStartIndex} '
        'prevLoaded=${previousState.hasLoadedMessages} '
        'prevMessages=${previousState.messages.length}',
      );
    }
    if (nextState.hasLoadedMessages &&
        nextState.totalMessageCount > nextState.messages.length &&
        _archivedMessageCount < nextState.totalMessageCount &&
        !_isHydratingArchiveHistory) {
      unawaited(_ensureArchivedMessageHistoryAccessible());
    }
    if (nextState.hasLoadedMessages && nextState.messages.isNotEmpty) {
      _scheduleMessageInteractionsIdleEnable();
    }
  }

  void _setMessageInteractionsEnabled(bool enabled) {
    if (_messageInteractionsEnabledN.value == enabled) {
      return;
    }
    _messageInteractionsEnabledN.value = enabled;
  }

  void _pauseMessageInteractions() {
    _messageInteractionIdleDebounce?.cancel();
    _messageInteractionIdleDebounce = null;
    _setMessageInteractionsEnabled(false);
  }

  void _scheduleMessageInteractionsIdleEnable() {
    _messageInteractionIdleDebounce?.cancel();
    _messageInteractionIdleDebounce = Timer(
      _sessionMessageInteractionIdleDelay,
      () {
        if (!mounted ||
            !_messageViewportReady ||
            !_hasLoadedMessages ||
            _messages.isEmpty ||
            !_scrollController.hasClients ||
            _viewportController.programmaticScrollActivity != 0 ||
            _isLoadingOlderMessages ||
            _isLoadingNewerMessages) {
          return;
        }
        final position = _scrollController.position;
        if (position.isScrollingNotifier.value) {
          _scheduleMessageInteractionsIdleEnable();
          return;
        }
        _setMessageInteractionsEnabled(true);
      },
    );
  }

  void _markMessageListScrollActivity() {
    _pauseMessageInteractions();
    _scheduleMessageInteractionsIdleEnable();
  }

  void _registerMessageRowContext(String messageId, BuildContext context) {
    final previousContext = _messageRowContexts[messageId];
    if (previousContext != null && !identical(previousContext, context)) {
      Logger.info(
        '[SessionAnchor] rebind session=${widget.sessionId} '
        'message=$messageId ${_debugMessageWindowSummary()}',
      );
    }
    _messageRowContexts[messageId] = context;
  }

  void _unregisterMessageRowContext(String messageId, BuildContext context) {
    final currentContext = _messageRowContexts[messageId];
    if (currentContext != null && !identical(currentContext, context)) {
      Logger.info(
        '[SessionAnchor] stale-detach session=${widget.sessionId} '
        'message=$messageId ${_debugMessageWindowSummary()}',
      );
    }
    if (identical(currentContext, context)) {
      _messageRowContexts.remove(messageId);
    }
  }

  BuildContext? _messageRowContext(String messageId) {
    return _messageRowContexts[messageId];
  }

  BuildContext? _turnSectionContext(String turnId) {
    final messageId = _turnSectionMessageIds[turnId];
    if (messageId == null) {
      return null;
    }
    return _messageRowContext(messageId);
  }

  BuildContext? _turnReplyContext(String turnId) {
    final messageId = _turnReplyMessageIds[turnId];
    if (messageId == null) {
      return null;
    }
    return _messageRowContext(messageId);
  }

  String? _resolveTurnReplyMessageId(_MessageTurnGroup group) {
    if (group.messages.isEmpty) {
      return null;
    }
    final promptId = group.userPrompt?.id;
    for (final message in group.messages) {
      if (message.id != promptId) {
        return message.id;
      }
    }
    return null;
  }

  void _pruneMessageRenderCaches(List<ReducerMessage> messages) {
    final activeMessageIds = messages.map((message) => message.id).toSet();
    final activeToolIds =
        messages.map((message) => message.tool?.id).whereType<String>().toSet();
    _messageRowContexts.removeWhere(
      (messageId, _) => !activeMessageIds.contains(messageId),
    );
    final staleToolIds = _toolActionPendingNotifiers.keys
        .where((toolId) => !activeToolIds.contains(toolId))
        .toList(growable: false);
    for (final toolId in staleToolIds) {
      _toolActionPendingNotifiers.remove(toolId)?.dispose();
      _toolActionsInFlight.remove(toolId);
    }
    final activeTurnGroups = _bodyPresenter.resolveTurnGroups(messages);
    _turnSectionMessageIds
      ..clear()
      ..addEntries(
        activeTurnGroups.where((group) => group.messages.isNotEmpty).map(
              (group) => MapEntry(group.id, group.messages.last.id),
            ),
      );
    _turnReplyMessageIds
      ..clear()
      ..addEntries(
        activeTurnGroups
            .map(
              (group) => MapEntry(group.id, _resolveTurnReplyMessageId(group)),
            )
            .where((entry) => entry.value != null)
            .map((entry) => MapEntry(entry.key, entry.value!)),
      );
  }

  String _debugMessageWindowSummary() {
    final firstMessage = _messages.isEmpty ? null : _messages.first;
    final lastMessage = _messages.isEmpty ? null : _messages.last;
    return 'window(start=$_messageWindowStartIndex loaded=${_messages.length} '
        'total=$_totalMessageCount older=$_hasOlderMessages newer=$_hasNewerMessages '
        'first=${firstMessage?.id ?? "none"} last=${lastMessage?.id ?? "none"})';
  }

  String _debugScrollSummary() {
    if (!_scrollController.hasClients) {
      return 'scroll(no-clients)';
    }
    final position = _scrollController.position;
    return 'scroll(offset=${position.pixels.toStringAsFixed(1)} '
        'min=${position.minScrollExtent.toStringAsFixed(1)} '
        'max=${position.maxScrollExtent.toStringAsFixed(1)} '
        'viewport=${position.viewportDimension.toStringAsFixed(1)})';
  }

  String _debugVisibleMessageSummary() {
    if (!_scrollController.hasClients || _messages.isEmpty) {
      return 'visible(first=none last=none count=0)';
    }
    final viewportBox = _messageListViewportRenderBox();
    if (viewportBox == null) {
      return 'visible(first=unknown last=unknown count=0)';
    }
    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + viewportBox.size.height;
    final turnGroups = _bodyPresenter.resolveTurnGroups(_messages);
    final flatItems = _bodyPresenter.resolveFlatItems(turnGroups);
    String? firstVisibleId;
    String? lastVisibleId;
    var visibleCount = 0;
    for (final item in flatItems) {
      final rowContext = _messageRowContext(item.message.id);
      final bounds = _renderBoxGlobalVerticalBounds(
        rowContext?.findRenderObject(),
      );
      if (bounds == null) {
        continue;
      }
      final top = bounds.$1;
      final bottom = bounds.$2;
      if (bottom <= viewportTop || top >= viewportBottom) {
        continue;
      }
      visibleCount += 1;
      firstVisibleId ??= item.message.id;
      lastVisibleId = item.message.id;
    }
    return 'visible(first=${firstVisibleId ?? "none"} '
        'last=${lastVisibleId ?? "none"} count=$visibleCount)';
  }

  (double, double)? _renderBoxGlobalVerticalBounds(RenderObject? renderObject) {
    if (renderObject is! RenderBox || !renderObject.attached) {
      return null;
    }
    if (!renderObject.hasSize) {
      return null;
    }
    final size = renderObject.size;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    final top = topLeft.dy;
    final bottom = top + size.height;
    if (!top.isFinite ||
        !bottom.isFinite ||
        !size.height.isFinite ||
        size.height < 0) {
      return null;
    }
    return (top, bottom);
  }

  String _debugArchiveAccessSummary() {
    return 'archive(localOlder=$_hasLocallyAccessibleOlderArchivedMessages '
        'localNewer=$_hasLocallyAccessibleNewerArchivedMessages '
        'canJumpEarliest=$_canJumpToEarliestArchivedBoundary '
        'archived=$_archivedMessageCount complete=$_hasCompleteArchivedMessageHistory '
        'loadingOlder=$_isLoadingOlderMessages loadingNewer=$_isLoadingNewerMessages '
        'hydrating=$_isHydratingArchiveHistory)';
  }

  String _debugAnchorStateSummary(String messageId) {
    final index = _messages.indexWhere((message) => message.id == messageId);
    final hasContext = _messageRowContexts.containsKey(messageId);
    final previousId = index > 0 && index < _messages.length
        ? _messages[index - 1].id
        : 'none';
    final nextId = index >= 0 && index < (_messages.length - 1)
        ? _messages[index + 1].id
        : 'none';
    return 'anchor(id=$messageId index=$index hasContext=$hasContext '
        'prev=$previousId next=$nextId rowContexts=${_messageRowContexts.length})';
  }

  ValueNotifier<bool> _toolActionPendingListenable(String toolId) {
    return _toolActionPendingNotifiers.putIfAbsent(
      toolId,
      () => ValueNotifier<bool>(_toolActionsInFlight.contains(toolId)),
    );
  }

  bool _isToolActionPending(String toolId) {
    return _toolActionPendingNotifiers[toolId]?.value == true ||
        _toolActionsInFlight.contains(toolId);
  }

  void _setToolActionPending(String toolId, bool pending) {
    final changed = pending
        ? _toolActionsInFlight.add(toolId)
        : _toolActionsInFlight.remove(toolId);
    final notifier = _toolActionPendingListenable(toolId);
    if (notifier.value != pending) {
      notifier.value = pending;
    }
    if (!changed && notifier.value == pending) {
      return;
    }
  }

  void _logDuplicateMessageIds(
    List<ReducerMessage> messages, {
    required String stage,
  }) {
    if (messages.length < 2) {
      return;
    }
    final seen = <String>{};
    final duplicates = <String>[];
    for (final message in messages) {
      if (!seen.add(message.id)) {
        duplicates.add(message.id);
      }
    }
    if (duplicates.isEmpty) {
      return;
    }
    Logger.error(
      '[SessionDuplicate] session=${widget.sessionId} stage=$stage '
      'duplicates=${duplicates.join(",")} ${_debugMessageWindowSummary()}',
    );
  }

  void _updateState(VoidCallback update) => setState(update);

  void _setSessionRefreshing(bool value) {
    if (_isRefreshingSessionState == value) {
      return;
    }

    if (value) {
      _refreshIconController.repeat();
    } else {
      _refreshIconController
        ..stop()
        ..reset();
    }

    _isRefreshingSessionStateN.value = value;
  }

  @override
  Widget build(BuildContext context) => _buildSessionScreen(context);
}
