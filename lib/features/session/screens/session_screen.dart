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
import '../presentation/session_turn_status.dart';
import '../domain/session_creation_options.dart';
import '../../socketio/domain/socket_service.dart';

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
const double _sessionScrollActionRailHeight =
    _sessionScrollActionButtonSize * 3 + _sessionScrollActionGap * 2;

class _SessionScreenSelection {
  const _SessionScreenSelection({
    required this.session,
    required this.messages,
    required this.hasLoadedSessions,
    required this.hasLoadedMessages,
    required this.isReady,
  });

  const _SessionScreenSelection.initial()
      : this(
          session: null,
          messages: null,
          hasLoadedSessions: false,
          hasLoadedMessages: false,
          isReady: false,
        );

  final Session? session;
  final List<ReducerMessage>? messages;
  final bool hasLoadedSessions;
  final bool hasLoadedMessages;
  final bool isReady;

  @override
  bool operator ==(Object other) {
    return other is _SessionScreenSelection &&
        identical(session, other.session) &&
        identical(messages, other.messages) &&
        hasLoadedSessions == other.hasLoadedSessions &&
        hasLoadedMessages == other.hasLoadedMessages &&
        isReady == other.isReady;
  }

  @override
  int get hashCode => Object.hash(
        session,
        messages,
        hasLoadedSessions,
        hasLoadedMessages,
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
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _refreshIconController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  final Set<String> _toolActionsInFlight = <String>{};
  final Set<String> _expandedTurnIds = <String>{};
  final Set<String> _autoApprovedToolIds = <String>{};
  final Map<String, GlobalKey> _turnSectionKeys = <String, GlobalKey>{};
  final Map<String, GlobalKey> _turnReplyAnchorKeys = <String, GlobalKey>{};
  final SessionComposerQueueService _composerQueueService =
      SessionComposerQueueService.instance;
  final SessionInputTemplateService _inputTemplateService =
      SessionInputTemplateService.instance;
  final SessionUiStateService _uiStateService = SessionUiStateService.instance;
  bool _isSending = false;
  bool _isAborting = false;
  bool _awaitingAbortRemoteSettle = false;
  bool _isAutoSendingQueuedMessage = false;
  bool _isRefreshingSessionState = false;
  bool _queueReconcileScheduled = false;
  bool _collapseAllTurns = false;
  bool _sessionOverviewCollapsed = true;
  bool _hasScrolledToLatest = false;
  // Track whether the initial session data load is done so that build()
  // can skip non-essential computation during the loading phase.
  bool _initialLoadComplete = false;
  bool _userHasScrolledUp = false;
  bool _viewportUpdateScheduled = false;
  bool _hasStickyTurnCandidates = false;
  bool _scrollToLatestScheduled = false;
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
  Session? _cachedStatsSession;
  List<ReducerMessage>? _cachedStatsMessages;
  SessionStats? _cachedSessionStats;
  List<ReducerMessage>? _cachedTurnGroupMessages;
  List<_MessageTurnGroup> _cachedTurnGroups = const <_MessageTurnGroup>[];
  Session? _queuedReconcileSession;
  List<ReducerMessage>? _queuedReconcileMessages;
  int _queuedReconcileQueueSize = 0;
  String? _queuedReconcileActiveResponseLocalId;
  bool _queuedReconcileIsSending = false;
  bool _queuedReconcileIsAutoSending = false;
  bool? _queuedReconcileManualThinkingOverride;
  int _scrollToLatestRequestId = 0;
  final ValueNotifier<List<QueuedComposerMessage>> _queuedMessagesN =
      ValueNotifier(const <QueuedComposerMessage>[]);
  List<QueuedComposerMessage> get _queuedMessages => _queuedMessagesN.value;
  List<SessionInputTemplate> _customInputTemplates =
      const <SessionInputTemplate>[];
  List<_MessageTurnGroup> _visibleTurnGroups = const <_MessageTurnGroup>[];
  StreamSubscription<SocketEvent>? _socketEventSubscription;
  Timer? _draftPersistDebounce;
  Timer? _messagePollingTimer;
  Timer? _socketRefreshDebounce;
  bool _desiredScreenAwake = false;
  bool _appliedScreenAwake = false;
  bool _screenAwakeUpdateScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollMetricsChanged);
    _messageController.addListener(_handleComposerChanged);
    _loadQueuedComposerMessages();
    _loadNonCriticalUiData();
    _loadSessionData();
    _subscribeToSocketEvents();
  }

  @override
  void dispose() {
    unawaited(_releaseScreenAwakePolicy());
    _messageController.removeListener(_handleComposerChanged);
    _messageFocusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _draftPersistDebounce?.cancel();
    _socketEventSubscription?.cancel();
    _messagePollingTimer?.cancel();
    _socketRefreshDebounce?.cancel();
    _refreshIconController.dispose();
    _canScrollToTopN.dispose();
    _canScrollToBottomN.dispose();
    _isNearBottomN.dispose();
    _shouldStickToLatestN.dispose();
    _hasUnreadMessagesN.dispose();
    _stickyTurnIdN.dispose();
    _scrollActionsCollapsedN.dispose();
    _scrollActionVerticalOffsetN.dispose();
    _scrollActionDragDxN.dispose();
    _queuedMessagesN.dispose();
    super.dispose();
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

    if (!mounted) {
      _isRefreshingSessionState = value;
      return;
    }
    _updateState(() {
      _isRefreshingSessionState = value;
    });
  }

  @override
  Widget build(BuildContext context) => _buildSessionScreen(context);
}
