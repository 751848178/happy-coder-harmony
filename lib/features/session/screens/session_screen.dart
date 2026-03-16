import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/providers/app_providers.dart';
import '../../../app/services/settings_service.dart' show SettingsState;
import '../data/session_composer_queue_service.dart';
import '../domain/session_stats.dart';
import '../data/session_ui_state_service.dart';
import '../presentation/session_turn_status.dart';
import '../domain/session_creation_options.dart';
import '../../socketio/domain/socket_service.dart';

part 'session_screen_state_load.dart';
part 'session_screen_state_socket.dart';
part 'session_screen_state_scroll.dart';
part 'session_screen_state_queue.dart';
part 'session_screen_state_refresh.dart';
part 'session_screen_state_turns.dart';
part 'session_screen_state_sticky_prompt.dart';
part 'session_screen_state_build.dart';
part 'session_screen_state_appbar.dart';
part 'session_screen_state_clone.dart';
part 'session_screen_view_overview.dart';
part 'session_screen_view_messages.dart';
part 'session_screen_view_indicators.dart';
part 'session_screen_view_controls.dart';
part 'session_screen_view_input.dart';
part 'session_screen_view_metadata.dart';
part 'session_screen_view_command_logic.dart';
part 'session_screen_view_command_panels.dart';
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

class _SessionScreenState extends ConsumerState<SessionScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _messageListViewportKey = GlobalKey();
  final Set<String> _toolActionsInFlight = <String>{};
  final Set<String> _expandedTurnIds = <String>{};
  final Set<String> _autoApprovedToolIds = <String>{};
  final Map<String, GlobalKey> _turnSectionKeys = <String, GlobalKey>{};
  final Map<String, GlobalKey> _turnReplyAnchorKeys = <String, GlobalKey>{};
  final SessionComposerQueueService _composerQueueService =
      SessionComposerQueueService.instance;
  final SessionUiStateService _uiStateService = SessionUiStateService.instance;
  bool _isSending = false;
  bool _isAutoSendingQueuedMessage = false;
  bool _isRefreshingSessionState = false;
  bool _queueReconcileScheduled = false;
  bool _collapseAllTurns = false;
  bool _sessionOverviewCollapsed = true;
  bool _hasScrolledToLatest = false;
  bool _canScrollToTop = false;
  bool _canScrollToBottom = false;
  bool _isNearBottom = true;
  bool _shouldStickToLatest = true;
  bool _hasUnreadMessages = false;
  bool _viewportUpdateScheduled = false;
  String? _activeResponseLocalId;
  String? _stickyTurnId;
  List<QueuedComposerMessage> _queuedMessages = const <QueuedComposerMessage>[];
  List<_MessageTurnGroup> _visibleTurnGroups = const <_MessageTurnGroup>[];
  StreamSubscription<SocketEvent>? _socketEventSubscription;
  Timer? _messagePollingTimer;
  Timer? _socketRefreshDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollMetricsChanged);
    _messageController.addListener(_handleComposerChanged);
    _loadQueuedComposerMessages();
    _loadSessionUiState();
    _loadSessionData();
    _subscribeToSocketEvents();
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleComposerChanged);
    _messageFocusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _socketEventSubscription?.cancel();
    _messagePollingTimer?.cancel();
    _socketRefreshDebounce?.cancel();
    super.dispose();
  }

  void _updateState(VoidCallback update) => setState(update);

  @override
  Widget build(BuildContext context) => _buildSessionScreen(context);
}
