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

import '../../socketio/domain/socket_service.dart';
import '../domain/session_creation_options.dart';

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
  bool _activeResponseObservedThinking = false;
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

  Future<void> _loadSessionUiState() async {
    final state = await _uiStateService.get(widget.sessionId);
    if (!mounted) {
      return;
    }
    setState(() {
      _sessionOverviewCollapsed = state.overviewCollapsed;
      _collapseAllTurns = state.collapseAllTurns;
      _expandedTurnIds
        ..clear()
        ..addAll(state.expandedTurnIds);
    });
  }

  Future<void> _persistSessionUiState() {
    return _uiStateService.update(
      widget.sessionId,
      overviewCollapsed: _sessionOverviewCollapsed,
      collapseAllTurns: _collapseAllTurns,
      expandedTurnIds: Set<String>.from(_expandedTurnIds),
    );
  }

  Future<void> _loadQueuedComposerMessages() async {
    final queuedMessages = await _composerQueueService.get(widget.sessionId);
    if (!mounted) {
      return;
    }
    setState(() {
      _queuedMessages = queuedMessages;
    });
  }

  Future<void> _storeQueuedComposerMessages(
    List<QueuedComposerMessage> queuedMessages,
  ) async {
    if (mounted) {
      setState(() {
        _queuedMessages = List<QueuedComposerMessage>.from(queuedMessages);
      });
    }
    try {
      await _composerQueueService.replace(widget.sessionId, queuedMessages);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新待发送消息失败: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _loadSessionData() async {
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final currentSession = sessionNotifier.getSession(widget.sessionId);
    if (currentSession == null || currentSession.metadata == null) {
      await sessionNotifier.loadSessions();
    }
    if (sessionNotifier.getSession(widget.sessionId) == null) {
      return;
    }
    await sessionNotifier.loadSessionMessages(widget.sessionId);
    await _maybeAutoApprovePendingTools();
    _scheduleScrollToLatest(force: true);

    // 订阅 Socket 消息
    ref.read(socketStateProvider.notifier).subscribeToSession(widget.sessionId);
    _startMessagePolling();
  }

  void _startMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) {
        _scheduleMessageRefresh(autoScroll: _shouldStickToLatest);
      },
    );
  }

  void _subscribeToSocketEvents() {
    final socketNotifier = ref.read(socketStateProvider.notifier);
    _socketEventSubscription = socketNotifier.eventStream.listen((event) {
      event.when(
        connecting: () {},
        connected: (_) {
          _scheduleMessageRefresh(autoScroll: _shouldStickToLatest);
          unawaited(_maybeAutoApprovePendingTools());
        },
        disconnected: (_) {},
        error: (_) {},
        messageReceived: (message) {
          if (message.sessionId == widget.sessionId) {
            final shouldAutoScroll = _shouldStickToLatest;
            _scheduleMessageRefresh(autoScroll: shouldAutoScroll);
            if (!shouldAutoScroll && mounted) {
              setState(() {
                _hasUnreadMessages = true;
              });
            }
          }
        },
        reconnecting: (_) {},
      );
    });
  }

  void _scheduleMessageRefresh({bool autoScroll = false}) {
    _socketRefreshDebounce?.cancel();
    _socketRefreshDebounce = Timer(
      const Duration(milliseconds: 150),
      () async {
        await ref.read(sessionStateProvider.notifier).loadSessionMessages(
              widget.sessionId,
            );
        await _maybeAutoApprovePendingTools();
        if (autoScroll) {
          _scheduleScrollToLatest(animate: true, force: true);
          if (mounted) {
            setState(() {
              _hasUnreadMessages = false;
            });
          }
        } else {
          _scheduleViewportStateRefresh();
        }
      },
    );
  }

  void _handleComposerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _handleScrollMetricsChanged() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    final nextCanScrollToTop = position.pixels > 32;
    final nextCanScrollToBottom = distanceToBottom > 32;
    final nextIsNearBottom = distanceToBottom < 72;
    final nextShouldStickToLatest = distanceToBottom <= 8;
    final shouldUpdate = nextCanScrollToTop != _canScrollToTop ||
        nextCanScrollToBottom != _canScrollToBottom ||
        nextIsNearBottom != _isNearBottom ||
        nextShouldStickToLatest != _shouldStickToLatest;
    _scheduleViewportStateRefresh();
    if (!shouldUpdate) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _canScrollToTop = nextCanScrollToTop;
      _canScrollToBottom = nextCanScrollToBottom;
      _isNearBottom = nextIsNearBottom;
      _shouldStickToLatest = nextShouldStickToLatest;
      if (nextIsNearBottom) {
        _hasUnreadMessages = false;
      }
    });
  }

  void _scrollToBottom() {
    _scheduleScrollToLatest(animate: true, force: true);
  }

  void _scheduleScrollToLatest({
    bool animate = false,
    bool force = false,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      if (_hasScrolledToLatest && !force) {
        return;
      }
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
      _hasScrolledToLatest = true;
      _shouldStickToLatest = true;
      _hasUnreadMessages = false;
      _handleScrollMetricsChanged();
    });
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _scheduleQueuedMessageReconciliation() {
    if (_queueReconcileScheduled) {
      return;
    }
    _queueReconcileScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queueReconcileScheduled = false;
      if (!mounted) {
        return;
      }
      unawaited(_reconcileQueuedMessageState());
    });
  }

  Future<void> _reconcileQueuedMessageState() async {
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final session = sessionNotifier.getSession(widget.sessionId);
    final messages =
        sessionNotifier.getSessionMessages(widget.sessionId)?.messages ??
            const <ReducerMessage>[];
    final turnGroups = _MessageTurnGroup.build(messages);

    final activeLocalId = _activeResponseLocalId;
    if (activeLocalId != null) {
      final activeGroup = _findTurnGroupByLocalId(turnGroups, activeLocalId) ??
          (turnGroups.isNotEmpty ? turnGroups.last : null);
      final sawThinkingNow = _activeResponseObservedThinking ||
          session?.thinking == true ||
          _groupHasThinkingMessage(activeGroup);
      if (sawThinkingNow != _activeResponseObservedThinking && mounted) {
        setState(() {
          _activeResponseObservedThinking = sawThinkingNow;
        });
      }
      if (_hasActiveResponseCompleted(
        session: session,
        activeGroup: activeGroup,
        sawThinking: sawThinkingNow,
      )) {
        if (mounted) {
          setState(() {
            _activeResponseLocalId = null;
            _activeResponseObservedThinking = false;
          });
        }
      }
    }

    await _maybeSendNextQueuedMessage(session, turnGroups);
  }

  _MessageTurnGroup? _findTurnGroupByLocalId(
    List<_MessageTurnGroup> turnGroups,
    String localId,
  ) {
    for (final group in turnGroups) {
      final promptLocalId = group.userPrompt?.metadata?['localId']?.toString();
      if (promptLocalId == localId) {
        return group;
      }
    }
    return null;
  }

  bool _groupHasThinkingMessage(_MessageTurnGroup? group) {
    if (group == null) {
      return false;
    }
    return group.messages.any(
      (message) => message.metadata?['outputType']?.toString() == 'thinking',
    );
  }

  bool _groupHasTurnClose(_MessageTurnGroup? group) {
    if (group == null) {
      return false;
    }
    return group.messages.any((message) => message.isTurnClose);
  }

  bool _groupHasCompletionSignal(_MessageTurnGroup? group) {
    if (group == null) {
      return false;
    }
    if (_groupHasTurnClose(group)) {
      return true;
    }
    return group.messages.any((message) {
      if (!message.isAgentEvent) {
        return false;
      }
      final eventType = message.metadata?['eventType']?.toString();
      return eventType == 'stop' ||
          eventType == 'task_complete' ||
          eventType == 'turn_aborted';
    });
  }

  bool _groupHasPendingToolWork(_MessageTurnGroup? group) {
    if (group == null) {
      return false;
    }
    return group.messages.any((message) {
      final status = message.tool?.status;
      return status == ToolCallStatus.pending ||
          status == ToolCallStatus.approved ||
          status == ToolCallStatus.executing;
    });
  }

  bool _groupHasRenderableAgentOutput(_MessageTurnGroup? group) {
    if (group == null) {
      return false;
    }
    return group.messages.any((message) {
      if (message.isToolCall) {
        return true;
      }
      if (!message.isText) {
        return false;
      }
      final role = message.metadata?['role']?.toString();
      final outputType = message.metadata?['outputType']?.toString();
      return role != 'user' &&
          outputType != 'thinking' &&
          (message.text?.trim().isNotEmpty ?? false);
    });
  }

  bool _isThinkingStillBlocking({
    required Session? session,
    required _MessageTurnGroup? group,
  }) {
    if (_groupHasThinkingMessage(group)) {
      return true;
    }
    if (session?.thinking != true) {
      return false;
    }
    return !_groupHasCompletionSignal(group);
  }

  bool _hasActiveResponseCompleted({
    required Session? session,
    required _MessageTurnGroup? activeGroup,
    required bool sawThinking,
  }) {
    if (_isSending) {
      return false;
    }
    final promptMetadata = activeGroup?.userPrompt?.metadata;
    final promptStillOptimistic = promptMetadata?['optimistic'] == true;
    if (promptStillOptimistic) {
      return false;
    }

    final hasPendingToolWork = _groupHasPendingToolWork(activeGroup);
    if (_groupHasCompletionSignal(activeGroup)) {
      return !hasPendingToolWork;
    }
    if (_isThinkingStillBlocking(session: session, group: activeGroup)) {
      return false;
    }
    if (hasPendingToolWork) {
      return false;
    }
    if (!sawThinking) {
      return false;
    }
    // Some backends finish a turn by clearing thinking without emitting an
    // explicit turn-close event, so we fall back to the rendered agent output.
    if (_groupHasRenderableAgentOutput(activeGroup)) {
      return true;
    }
    return false;
  }

  bool _isConversationBusy(
    Session? session,
    List<_MessageTurnGroup> turnGroups,
  ) {
    final latestGroup = turnGroups.isNotEmpty ? turnGroups.last : null;
    if (_isSending || _isAutoSendingQueuedMessage) {
      return true;
    }
    if (_activeResponseLocalId != null) {
      return true;
    }
    if (_isThinkingStillBlocking(session: session, group: latestGroup)) {
      return true;
    }
    if (_groupHasPendingToolWork(latestGroup)) {
      return true;
    }
    final latestPrompt = latestGroup?.userPrompt;
    if (latestPrompt?.metadata?['optimistic'] == true) {
      return true;
    }
    return false;
  }

  Future<void> _maybeSendNextQueuedMessage(
    Session? session,
    List<_MessageTurnGroup> turnGroups,
  ) async {
    if (session == null) {
      return;
    }
    if (_queuedMessages.isEmpty || _isConversationBusy(session, turnGroups)) {
      return;
    }
    if (_isAutoSendingQueuedMessage) {
      return;
    }

    final nextMessage = _queuedMessages.first;
    final remaining = List<QueuedComposerMessage>.from(_queuedMessages)
      ..removeAt(0);

    setState(() {
      _isAutoSendingQueuedMessage = true;
      _queuedMessages = remaining;
    });

    try {
      try {
        await _composerQueueService.replace(widget.sessionId, remaining);
      } catch (error) {
        if (mounted) {
          final restoredQueue = <QueuedComposerMessage>[
            nextMessage,
            ..._queuedMessages,
          ];
          setState(() {
            _queuedMessages = restoredQueue;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('更新待发送消息失败: $error'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }
      final sent = await _dispatchMessage(
        nextMessage.content,
        restoreComposerOnError: false,
      );
      if (!sent && mounted) {
        final restoredQueue = <QueuedComposerMessage>[
          nextMessage,
          ..._queuedMessages,
        ];
        setState(() {
          _queuedMessages = restoredQueue;
        });
        await _composerQueueService.replace(widget.sessionId, restoredQueue);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAutoSendingQueuedMessage = false;
        });
      }
    }
  }

  Future<void> _enqueueComposerMessage(String content, {int? insertAt}) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final nextMessage = _composerQueueService.createDraft(trimmed);
    final nextQueue = List<QueuedComposerMessage>.from(_queuedMessages);
    final targetIndex = insertAt == null
        ? nextQueue.length
        : insertAt.clamp(0, nextQueue.length);
    nextQueue.insert(targetIndex, nextMessage);
    await _storeQueuedComposerMessages(nextQueue);
  }

  Future<void> _removeQueuedComposerMessage(String messageId) async {
    final nextQueue = _queuedMessages
        .where((message) => message.id != messageId)
        .toList(growable: false);
    await _storeQueuedComposerMessages(nextQueue);
  }

  Future<void> _editQueuedComposerMessage(QueuedComposerMessage message) async {
    final index = _queuedMessages.indexWhere((item) => item.id == message.id);
    if (index < 0) {
      return;
    }
    final currentDraft = _messageController.text.trim();
    final nextQueue = List<QueuedComposerMessage>.from(_queuedMessages)
      ..removeAt(index);
    if (currentDraft.isNotEmpty && currentDraft != message.content.trim()) {
      final preservedDraft = _composerQueueService.createDraft(currentDraft);
      nextQueue.insert(index, preservedDraft);
    }
    await _storeQueuedComposerMessages(nextQueue);
    _setComposerText(message.content);
    _messageFocusNode.requestFocus();
  }

  void _setComposerText(String text) {
    _messageController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _refreshSessionState() async {
    if (_isRefreshingSessionState) {
      return;
    }

    final authState = ref.read(authStateProvider);
    final credentials = authState.credentials;
    if (credentials == null) {
      return;
    }

    setState(() {
      _isRefreshingSessionState = true;
    });

    try {
      await Future.wait([
        ref.read(sessionStateProvider.notifier).loadSessions(force: true),
        ref.read(socketStateProvider.notifier).initialize(
              machineId: credentials.machineId,
              token: credentials.token,
            ),
      ]);
      await ref
          .read(sessionStateProvider.notifier)
          .loadSessionMessages(widget.sessionId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新连接状态失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingSessionState = false;
        });
      }
    }
  }

  String _createLocalMessageId() {
    return 'msg_${DateTime.now().microsecondsSinceEpoch}';
  }

  void _toggleAllTurns(List<_MessageTurnGroup> groups) {
    if (groups.isEmpty) {
      return;
    }
    setState(() {
      _collapseAllTurns = !_collapseAllTurns;
      _expandedTurnIds.clear();
      if (!_collapseAllTurns) {
        _expandedTurnIds.addAll(groups.map((group) => group.id));
      }
    });
    unawaited(_persistSessionUiState());
    _scheduleScrollToLatest(force: true);
  }

  void _toggleTurnGroup(_MessageTurnGroup group) {
    setState(() {
      if (_expandedTurnIds.contains(group.id)) {
        _expandedTurnIds.remove(group.id);
      } else {
        _expandedTurnIds.add(group.id);
      }
    });
    unawaited(_persistSessionUiState());
  }

  GlobalKey _turnSectionKey(String turnId) {
    return _turnSectionKeys.putIfAbsent(
      turnId,
      () => GlobalKey(debugLabel: 'turn-section-$turnId'),
    );
  }

  GlobalKey _turnReplyAnchorKey(String turnId) {
    return _turnReplyAnchorKeys.putIfAbsent(
      turnId,
      () => GlobalKey(debugLabel: 'turn-reply-$turnId'),
    );
  }

  void _scheduleViewportStateRefresh() {
    if (_viewportUpdateScheduled) {
      return;
    }
    _viewportUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewportUpdateScheduled = false;
      _refreshStickyTurnPrompt();
    });
  }

  void _refreshStickyTurnPrompt() {
    if (!mounted || _collapseAllTurns || _visibleTurnGroups.isEmpty) {
      if (_stickyTurnId != null && mounted) {
        setState(() {
          _stickyTurnId = null;
        });
      }
      return;
    }

    final viewportContext = _messageListViewportKey.currentContext;
    final viewportRender = viewportContext?.findRenderObject();
    if (viewportRender is! RenderBox) {
      return;
    }

    final viewportTop = viewportRender.localToGlobal(Offset.zero).dy + 8;
    const stickyHeight = 44.0;
    String? nextStickyTurnId;

    for (final group in _visibleTurnGroups) {
      final prompt = group.userPrompt;
      if (prompt == null || group.messages.length <= 1) {
        continue;
      }

      final replyRender =
          _turnReplyAnchorKey(group.id).currentContext?.findRenderObject();
      final sectionRender =
          _turnSectionKey(group.id).currentContext?.findRenderObject();
      if (replyRender is! RenderBox || sectionRender is! RenderBox) {
        continue;
      }

      final replyTop = replyRender.localToGlobal(Offset.zero).dy;
      final sectionBottom =
          sectionRender.localToGlobal(Offset(0, sectionRender.size.height)).dy;
      if (replyTop <= viewportTop &&
          sectionBottom > viewportTop + stickyHeight) {
        nextStickyTurnId = group.id;
        break;
      }
    }

    if (nextStickyTurnId == _stickyTurnId) {
      return;
    }

    setState(() {
      _stickyTurnId = nextStickyTurnId;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionStateProvider);
    final settings = ref.watch(settingsStateProvider);
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final session = sessionNotifier.getSession(widget.sessionId);
    final sessionMessages =
        sessionNotifier.getSessionMessages(widget.sessionId);
    final messages = sessionMessages?.messages ?? [];
    final turnGroups = _MessageTurnGroup.build(messages);
    final sessionStats = session == null
        ? null
        : SessionStatsCalculator.fromSession(
            session: session,
            messages: messages,
          );
    if (messages.isNotEmpty && !_hasScrolledToLatest) {
      _scheduleScrollToLatest();
    }
    if (session != null &&
        _shouldAutoApprove(session) &&
        messages.any(
          (message) =>
              message.tool?.status == ToolCallStatus.pending &&
              !_autoApprovedToolIds.contains(message.tool!.id),
        )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_maybeAutoApprovePendingTools());
      });
    }
    final slashCommands = _resolveSlashCommands(session);
    final visibleSlashCommands = _visibleSlashCommands(
      session,
      settings.commandPaletteEnabled,
    );
    final visibleInputTemplates = _visibleInputTemplates();
    final conversationBusy = _isConversationBusy(session, turnGroups);
    final hasLoadedSessions = sessionNotifier.sessions.isNotEmpty;
    _visibleTurnGroups = turnGroups;
    if (messages.isNotEmpty) {
      _scheduleViewportStateRefresh();
    }
    _scheduleQueuedMessageReconciliation();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: AppTheme.neutral50,
        appBar: _buildAppBar(
          context,
          session,
          turnGroups: turnGroups,
          showOverviewToggle: sessionStats != null,
        ),
        body: session == null && !hasLoadedSessions
            ? const Center(child: CircularProgressIndicator())
            : session == null && hasLoadedSessions
                ? _buildDeletedState()
                : Column(
                    children: [
                      if (session != null &&
                          sessionStats != null &&
                          !_sessionOverviewCollapsed)
                        _buildSessionOverview(session, sessionStats),
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: messages.isEmpty
                                  ? _buildEmptyState()
                                  : _buildMessageList(
                                      messages: messages,
                                      turnGroups: turnGroups,
                                      autoApproveEnabled: session != null
                                          ? _shouldAutoApprove(session)
                                          : false,
                                    ),
                            ),
                            if (messages.isNotEmpty &&
                                _stickyTurnId != null &&
                                !_collapseAllTurns)
                              Positioned(
                                left: AppTheme.spacingMd,
                                top: 8,
                                right: session?.thinking == true ? 132 : 16,
                                child: _buildStickyTurnPrompt(),
                              ),
                            if (messages.isNotEmpty &&
                                session?.thinking == true)
                              Positioned(
                                top: 8,
                                right: AppTheme.spacingMd,
                                child: _buildFloatingThinkingBadge(session!),
                              ),
                            if (messages.isNotEmpty && _hasUnreadMessages)
                              Positioned(
                                left: AppTheme.spacingMd,
                                right: AppTheme.spacingMd,
                                bottom: 76,
                                child: Center(
                                  child: _buildNewMessageIndicator(),
                                ),
                              ),
                            if (messages.isNotEmpty)
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppTheme.spacingMd,
                                    bottom: 12,
                                  ),
                                  child: _buildScrollActions(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildInputArea(
                        session,
                        turnGroups,
                        conversationBusy: conversationBusy,
                        settings: settings,
                        slashCommands: slashCommands,
                        visibleSlashCommands: visibleSlashCommands,
                        visibleInputTemplates: visibleInputTemplates,
                      ),
                    ],
                  ),
      ),
    );
  }

  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('${AppRoutes.home}?tab=sessions');
  }

  /// 应用栏
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    Session? session, {
    required List<_MessageTurnGroup> turnGroups,
    required bool showOverviewToggle,
  }) {
    final metadata = session?.metadata ?? const <String, dynamic>{};
    final subtitle = _formatPathForDisplay(
      metadata['path']?.toString() ?? session?.path ?? '',
      metadata['homeDir']?.toString(),
    );
    final title = _resolveHeaderTitle(session);

    return AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      toolbarHeight: 70,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _handleBackNavigation,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle.isNotEmpty || session?.active == true)
            Row(
              children: [
                if (session?.active == true) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.successColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    subtitle.isNotEmpty
                        ? subtitle
                        : (session?.active == true ? '活跃中' : ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: session?.active == true
                          ? AppTheme.successColor
                          : AppTheme.neutral600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded),
          onPressed: () =>
              context.push(AppRoutes.sessionInfoDetail(widget.sessionId)),
          tooltip: '会话信息',
        ),
        if (showOverviewToggle)
          IconButton(
            icon: Icon(
              _sessionOverviewCollapsed
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
            ),
            onPressed: () {
              setState(() {
                _sessionOverviewCollapsed = !_sessionOverviewCollapsed;
              });
              unawaited(_persistSessionUiState());
            },
            tooltip: _sessionOverviewCollapsed ? '展开会话信息' : '收起会话信息',
          ),
        if (turnGroups.isNotEmpty)
          IconButton(
            icon: Icon(
              _collapseAllTurns
                  ? Icons.unfold_more_rounded
                  : Icons.unfold_less_rounded,
            ),
            onPressed: () => _toggleAllTurns(turnGroups),
            tooltip: _collapseAllTurns ? '展开全部轮次' : '按轮次折叠',
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'rename':
                _showRenameDialog(session);
                break;
              case 'clone':
                _openCloneSession(session);
                break;
              case 'git':
                context.push(AppRoutes.sessionGitDetail(widget.sessionId));
                break;
              case 'info':
                context.push(AppRoutes.sessionInfoDetail(widget.sessionId));
                break;
              case 'clear':
                _showClearDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.drive_file_rename_outline, size: 18),
                  SizedBox(width: 12),
                  Text('修改名称'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clone',
              child: Row(
                children: [
                  Icon(Icons.control_point_duplicate_outlined, size: 18),
                  SizedBox(width: 12),
                  Text('克隆会话'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'git',
              child: Row(
                children: [
                  Icon(Icons.account_tree_outlined, size: 18),
                  SizedBox(width: 12),
                  Text('Git 仓库'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18),
                  SizedBox(width: 12),
                  Text('会话详情'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.clear_all, size: 18),
                  SizedBox(width: 12),
                  Text('清空消息'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openCloneSession(Session? session) {
    if (session == null) {
      return;
    }
    final metadata = session.metadata ?? const <String, dynamic>{};
    final uri = AppRoutes.newClonedSession(
      machineId: metadata['machineId']?.toString(),
      path: session.path ?? metadata['path']?.toString(),
      agent: metadata['flavor']?.toString(),
      permissionMode: session.permissionMode ??
          metadata['currentOperatingModeCode']?.toString(),
      modelMode: session.modelMode ?? metadata['currentModelCode']?.toString(),
    );
    context.push(uri);
  }

  Widget _buildSessionOverview(Session session, SessionStats sessionStats) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    final host = metadata['host']?.toString();
    final flavor = _resolveFlavorLabel(metadata['flavor']?.toString());
    final version = metadata['version']?.toString();
    final workingDirectory = _formatPathForDisplay(
      metadata['path']?.toString() ?? session.path ?? '',
      metadata['homeDir']?.toString(),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        AppTheme.spacingSm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (workingDirectory.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.folder_open_rounded,
                  size: 16,
                  color: AppTheme.neutral600,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    workingDirectory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutral700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _InfoChip(
                  icon: Icons.memory_rounded,
                  label: flavor,
                  color: AppTheme.brandColor,
                ),
                if (host != null && host.isNotEmpty) ...[
                  const SizedBox(width: AppTheme.spacingSm),
                  _InfoChip(
                    icon: Icons.computer_rounded,
                    label: host,
                    color: AppTheme.infoColor,
                  ),
                ],
                if (version != null && version.isNotEmpty) ...[
                  const SizedBox(width: AppTheme.spacingSm),
                  _InfoChip(
                    icon: Icons.code_rounded,
                    label: version,
                    color: AppTheme.successColor,
                  ),
                ],
                if (sessionStats.hasChanges) ...[
                  const SizedBox(width: AppTheme.spacingSm),
                  _InfoChip(
                    icon: Icons.edit_note_rounded,
                    label: '${sessionStats.changedLineCount} 行改动',
                    color: AppTheme.warningColor,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 52,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 16),
            const Text(
              '这个会话已经不存在了',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '它可能已经被删除，或者还没有同步完成。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _handleBackNavigation,
              child: const Text('返回会话列表'),
            ),
          ],
        ),
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            '开始新的对话',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.neutral700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '发送消息开始与 AI 助手对话',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  /// 消息列表
  Widget _buildMessageList({
    required List<ReducerMessage> messages,
    required List<_MessageTurnGroup> turnGroups,
    required bool autoApproveEnabled,
  }) {
    if (_collapseAllTurns && turnGroups.isNotEmpty) {
      return ListView.builder(
        key: _messageListViewportKey,
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMd,
          12,
          AppTheme.spacingMd,
          12,
        ),
        itemCount: turnGroups.length,
        itemBuilder: (context, index) {
          final group = turnGroups[index];
          return _buildTurnGroupCard(
            group,
            expanded: _expandedTurnIds.contains(group.id),
            autoApproveEnabled: autoApproveEnabled,
          );
        },
      );
    }

    return ListView(
      key: _messageListViewportKey,
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        12,
        AppTheme.spacingMd,
        12,
      ),
      children: [
        for (final group in turnGroups)
          _buildExpandedTurnSection(
            group,
            autoApproveEnabled: autoApproveEnabled,
          ),
      ],
    );
  }

  Widget _buildExpandedTurnSection(
    _MessageTurnGroup group, {
    required bool autoApproveEnabled,
  }) {
    final prompt = group.userPrompt;
    final remainingMessages = prompt == null
        ? group.messages
        : group.messages
            .where((message) => message.id != prompt.id)
            .toList(growable: false);

    return KeyedSubtree(
      key: _turnSectionKey(group.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (prompt != null)
              _buildMessageBubble(
                prompt,
                autoApproveEnabled: autoApproveEnabled,
              ),
            if (remainingMessages.isNotEmpty)
              SizedBox(
                key: _turnReplyAnchorKey(group.id),
                height: 0,
              ),
            for (final message in remainingMessages)
              _buildMessageBubble(
                message,
                autoApproveEnabled: autoApproveEnabled,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ReducerMessage message, {
    required bool autoApproveEnabled,
  }) {
    return _MessageBubble(
      key: ValueKey(message.id),
      message: message,
      autoApproveEnabled: autoApproveEnabled,
      isToolActionPending: message.tool != null &&
          _toolActionsInFlight.contains(message.tool!.id),
      onApproveTool: _approveToolCall,
      onRejectTool: _rejectToolCall,
    );
  }

  Widget _buildTurnGroupCard(
    _MessageTurnGroup group, {
    required bool expanded,
    required bool autoApproveEnabled,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: expanded ? 8 : 2),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleTurnGroup(group),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppTheme.neutral500,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.neutral200),
              ),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Column(
                children: [
                  for (final message in group.messages)
                    _buildMessageBubble(
                      message,
                      autoApproveEnabled: autoApproveEnabled,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNewMessageIndicator() {
    return FilledButton.icon(
      onPressed: _scrollToBottom,
      icon: const Icon(Icons.arrow_downward_rounded, size: 16),
      label: const Text('有新消息'),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.brandColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        elevation: 3,
      ),
    );
  }

  Widget _buildFloatingThinkingBadge(Session session) {
    final label = session.thinkingAt == null
        ? 'AI 思考中'
        : _formatThinkingLabel(session.thinkingAt!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.brandColor.withValues(alpha: 0.16)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.brandColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyTurnPrompt() {
    final stickyGroup =
        _visibleTurnGroups.cast<_MessageTurnGroup?>().firstWhere(
              (group) => group?.id == _stickyTurnId,
              orElse: () => null,
            );
    final prompt = stickyGroup?.userPrompt;
    if (prompt == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neutral200),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.brandColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 12,
              color: AppTheme.brandColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              prompt.text?.replaceAll(RegExp(r'\s+'), ' ').trim().isNotEmpty ==
                      true
                  ? prompt.text!.replaceAll(RegExp(r'\s+'), ' ').trim()
                  : stickyGroup!.preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatThinkingLabel(DateTime since) {
    final duration = DateTime.now().difference(since);
    if (duration.inSeconds < 1) {
      return 'AI 思考中';
    }
    if (duration.inSeconds < 60) {
      return 'AI 思考 ${duration.inSeconds}s';
    }
    if (duration.inMinutes < 60) {
      return 'AI 思考 ${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return 'AI 思考 ${duration.inHours}h ${duration.inMinutes % 60}m';
  }

  Widget _buildScrollActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ScrollActionButton(
          icon: Icons.vertical_align_top_rounded,
          tooltip: '回到顶部',
          enabled: _canScrollToTop,
          onTap: _scrollToTop,
        ),
        const SizedBox(height: 10),
        _ScrollActionButton(
          icon: Icons.vertical_align_bottom_rounded,
          tooltip: '回到最新消息',
          enabled: _canScrollToBottom,
          onTap: _scrollToBottom,
        ),
      ],
    );
  }

  /// 输入区域
  Widget _buildSessionControls(
    Session session,
    List<_MessageTurnGroup> turnGroups,
  ) {
    final permissionOption = _resolveCurrentPermissionOption(session);
    final modelOption = _resolveCurrentModelOption(session);
    final isActive = session.active || session.presence?.isOnline == true;
    final statusText = isActive ? '已连接' : '离线';

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.successColor
                          : AppTheme.neutral500,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isActive
                          ? AppTheme.successColor
                          : AppTheme.neutral600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IgnorePointer(
              ignoring: _isRefreshingSessionState,
              child: Opacity(
                opacity: _isRefreshingSessionState ? 0.72 : 1,
                child: _ControlChip(
                  icon: _isRefreshingSessionState
                      ? Icons.sync_rounded
                      : Icons.refresh_rounded,
                  label: _isRefreshingSessionState ? '刷新中' : '刷新',
                  onTap: _refreshSessionState,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ControlChip(
              icon: Icons.security_rounded,
              label: '权限 ${permissionOption.label}',
              onTap: _showPermissionDialog,
            ),
            const SizedBox(width: 8),
            _ControlChip(
              icon: Icons.tune_rounded,
              label: '模型 ${modelOption.label}',
              onTap: () => _showModelDialog(session),
            ),
            if (turnGroups.isNotEmpty) ...[
              const SizedBox(width: 8),
              _ControlChip(
                icon: _collapseAllTurns
                    ? Icons.unfold_more_rounded
                    : Icons.unfold_less_rounded,
                label: _collapseAllTurns ? '展开轮次' : '折叠轮次',
                onTap: () => _toggleAllTurns(turnGroups),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(
    Session? session,
    List<_MessageTurnGroup> turnGroups, {
    required bool conversationBusy,
    required SettingsState settings,
    required List<_SlashCommandItem> slashCommands,
    required List<_SlashCommandItem> visibleSlashCommands,
    required List<_InputTemplateItem> visibleInputTemplates,
  }) {
    final flavor =
        _resolveFlavorLabel(session?.metadata?['flavor']?.toString());
    final hasComposerText = _messageController.text.trim().isNotEmpty;
    final sendTooltip = conversationBusy ? '加入待发送队列' : '发送消息';
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.neutral200),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_queuedMessages.isNotEmpty) ...[
              _buildQueuedComposerPanel(
                busy: conversationBusy,
              ),
              const SizedBox(height: 10),
            ],
            if (session != null) ...[
              _buildSessionControls(session, turnGroups),
              const SizedBox(height: 8),
            ],
            if (settings.commandPaletteEnabled &&
                _shouldShowSlashCommands(visibleSlashCommands))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSlashCommandPanel(visibleSlashCommands),
              ),
            if (_shouldShowInputTemplates(visibleInputTemplates))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildInputTemplatePanel(visibleInputTemplates),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    maxLines: 5,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: conversationBusy
                          ? 'AI 正在回复，继续发送会加入队列...'
                          : '向$flavor发送消息...',
                      filled: true,
                      fillColor: AppTheme.neutral100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingSm,
                      ),
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: settings.agentInputEnterToSend
                        ? TextInputAction.send
                        : TextInputAction.newline,
                    onSubmitted: settings.agentInputEnterToSend
                        ? (_) => _handleSendAction(session, turnGroups)
                        : null,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                IconButton(
                  tooltip: sendTooltip,
                  onPressed: hasComposerText
                      ? () => _handleSendAction(session, turnGroups)
                      : null,
                  icon: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          conversationBusy
                              ? Icons.playlist_add_rounded
                              : Icons.send_rounded,
                        ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
            if ((settings.commandPaletteEnabled && slashCommands.isNotEmpty) ||
                _defaultInputTemplates.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    [
                      if (settings.commandPaletteEnabled &&
                          slashCommands.isNotEmpty)
                        '输入 `/` 查看 ${slashCommands.length} 个可用指令',
                      if (_defaultInputTemplates.isNotEmpty) '输入 `^` 快速插入模板',
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.neutral600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _resolveHeaderTitle(Session? session) {
    if (session == null) {
      return '未命名会话';
    }
    final path = session.metadata?['path']?.toString() ?? session.path;
    if (path != null && path.isNotEmpty) {
      final parts = path.split('/').where((item) => item.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        return parts.last;
      }
    }
    if (session.title.isNotEmpty) {
      return session.title;
    }
    return '未命名会话';
  }

  String _formatPathForDisplay(String path, String? homeDir) {
    if (path.isEmpty) {
      return '';
    }
    if (homeDir == null || homeDir.isEmpty) {
      return path;
    }
    if (path == homeDir) {
      return '~';
    }
    if (path.startsWith('$homeDir/')) {
      return '~${path.substring(homeDir.length)}';
    }
    return path;
  }

  String _resolveFlavorLabel(String? flavor) {
    switch (flavor) {
      case 'claude':
        return 'Claude Code';
      case 'codex':
        return 'Codex';
      case 'gemini':
        return 'Gemini';
      case null:
      case '':
        return AppConfig.assistantName;
      default:
        return flavor;
    }
  }

  List<_ModeOption> _permissionOptionsFor(Session session) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    return permissionOptionsForAgent(
      metadata['flavor']?.toString(),
      metadataOptions: metadata['operatingModes'],
    ).map(_ModeOption.fromSessionModeOption).toList();
  }

  List<_ModeOption> _modelOptionsFor(Session session) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    return modelOptionsForAgent(
      metadata['flavor']?.toString(),
      metadataOptions: metadata['models'],
    ).map(_ModeOption.fromSessionModeOption).toList();
  }

  _ModeOption _resolveCurrentPermissionOption(Session session) {
    final options = _permissionOptionsFor(session);
    final currentKey = session.permissionMode ??
        session.metadata?['currentOperatingModeCode']?.toString() ??
        'default';
    return options.firstWhere(
      (option) => option.key == currentKey,
      orElse: () => options.first,
    );
  }

  _ModeOption _resolveCurrentModelOption(Session session) {
    final options = _modelOptionsFor(session);
    final metadata = session.metadata ?? const <String, dynamic>{};
    final currentKey = session.modelMode ??
        metadata['currentModelCode']?.toString() ??
        options.first.key;
    return options.firstWhere(
      (option) => option.key == currentKey,
      orElse: () => options.first,
    );
  }

  void _showModelDialog(Session session) {
    final options = _modelOptionsFor(session);
    final current = _resolveCurrentModelOption(session);
    _showModeSheet(
      title: '模型设置',
      options: options,
      current: current,
      onSelected: (option) {
        ref.read(sessionStateProvider.notifier).updateModelMode(
              widget.sessionId,
              option.key,
            );
        Navigator.pop(context);
      },
    );
  }

  void _showModeSheet({
    required String title,
    required List<_ModeOption> options,
    required _ModeOption current,
    required ValueChanged<_ModeOption> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final mediaHeight = MediaQuery.sizeOf(context).height;
        final sheetHeight = (options.length * 76.0 + 140.0)
            .clamp(240.0, mediaHeight * 0.72)
            .toDouble();
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: sheetHeight,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Expanded(
                      child: ListView.builder(
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppTheme.spacingMd),
                            child: _ModeOptionTile(
                              option: option,
                              selected: option.key == current.key,
                              onTap: () => onSelected(option),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<_SlashCommandItem> _resolveSlashCommands(Session? session) {
    final metadataCommands = session?.metadata?['slashCommands'];
    final items = <_SlashCommandItem>[
      const _SlashCommandItem(
        command: 'compact',
        description: '压缩当前对话上下文',
      ),
      const _SlashCommandItem(
        command: 'clear',
        description: '清空当前会话消息',
      ),
    ];
    final seen = items.map((item) => item.command).toSet();
    if (metadataCommands is List) {
      for (final command in metadataCommands) {
        final value = command.toString().trim();
        if (value.isEmpty ||
            seen.contains(value) ||
            _ignoredSlashCommands.contains(value)) {
          continue;
        }
        items.add(
          _SlashCommandItem(
            command: value,
            description: _slashCommandDescriptions[value],
          ),
        );
        seen.add(value);
      }
    }
    return items;
  }

  List<_SlashCommandItem> _visibleSlashCommands(
    Session? session,
    bool enabled,
  ) {
    if (!enabled) {
      return const <_SlashCommandItem>[];
    }
    final text = _messageController.text.trimLeft();
    if (!text.startsWith('/')) {
      return const <_SlashCommandItem>[];
    }
    final rawQuery = text.substring(1);
    if (rawQuery.contains(' ')) {
      return const <_SlashCommandItem>[];
    }
    final query = rawQuery.trim().toLowerCase();
    final commands = _resolveSlashCommands(session);
    if (query.isEmpty) {
      return commands;
    }
    return commands
        .where(
          (item) =>
              item.command.toLowerCase().contains(query) ||
              (item.description?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  bool _shouldShowSlashCommands(List<_SlashCommandItem> commands) {
    return _messageController.text.trimLeft().startsWith('/') &&
        commands.isNotEmpty;
  }

  List<_InputTemplateItem> _visibleInputTemplates() {
    final text = _messageController.text.trimLeft();
    if (!text.startsWith('^')) {
      return const <_InputTemplateItem>[];
    }
    final rawQuery = text.substring(1);
    if (rawQuery.contains(' ')) {
      return const <_InputTemplateItem>[];
    }
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _defaultInputTemplates;
    }
    return _defaultInputTemplates
        .where(
          (item) =>
              item.label.toLowerCase().contains(query) ||
              item.content.toLowerCase().contains(query),
        )
        .toList();
  }

  bool _shouldShowInputTemplates(List<_InputTemplateItem> templates) {
    return _messageController.text.trimLeft().startsWith('^') &&
        templates.isNotEmpty;
  }

  Widget _buildSlashCommandPanel(List<_SlashCommandItem> commands) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neutral200),
        boxShadow: AppTheme.shadowSm,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: commands.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: AppTheme.neutral200,
        ),
        itemBuilder: (context, index) {
          final item = commands[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.code_rounded, size: 18),
            title: Text(
              '/${item.command}',
              style: const TextStyle(
                fontFamily: AppTheme.fontFamilyMono,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: item.description == null
                ? null
                : Text(
                    item.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
            onTap: () {
              final value = '/${item.command} ';
              _messageController.value = TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInputTemplatePanel(List<_InputTemplateItem> templates) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neutral200),
        boxShadow: AppTheme.shadowSm,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: templates.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: AppTheme.neutral200,
        ),
        itemBuilder: (context, index) {
          final item = templates[index];
          return ListTile(
            dense: true,
            leading: Icon(item.icon, size: 18, color: AppTheme.brandColor),
            title: Text(
              item.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              item.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              _messageController.value = TextEditingValue(
                text: item.content,
                selection: TextSelection.collapsed(offset: item.content.length),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQueuedComposerPanel({required bool busy}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: SizedBox(
        key: ValueKey<String>('queued-panel-${_queuedMessages.length}-$busy'),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.playlist_add_check_rounded,
                    size: 14,
                    color: AppTheme.brandColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '待发送消息 ${_queuedMessages.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (busy)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.brandColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'AI 回复中',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.brandColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 112),
              child: ListView.separated(
                shrinkWrap: true,
                physics: _queuedMessages.length > 2
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: _queuedMessages.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppTheme.neutral200,
                ),
                itemBuilder: (context, index) {
                  final item = _queuedMessages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text(
                            '${index + 1}.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.neutral700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _editQueuedComposerMessage(item),
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              item.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _editQueuedComposerMessage(item),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            '修改',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _removeQueuedComposerMessage(item.id),
                          tooltip: '删除待发送消息',
                          visualDensity: VisualDensity.compact,
                          splashRadius: 18,
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldAutoApprove(Session session) {
    final normalized = (session.permissionMode ??
            session.metadata?['currentOperatingModeCode']?.toString() ??
            '')
        .replaceAll(RegExp(r'[\s_\-]'), '')
        .toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    return normalized.contains('bypass') ||
        normalized.contains('skip') ||
        normalized.contains('yolo') ||
        normalized.contains('acceptedit') ||
        normalized.contains('auto');
  }

  Future<void> _maybeAutoApprovePendingTools() async {
    if (!ref.read(socketStateProvider).isConnected) {
      return;
    }
    final session =
        ref.read(sessionStateProvider.notifier).getSession(widget.sessionId);
    if (session == null || !_shouldAutoApprove(session)) {
      return;
    }
    final messages = ref
            .read(sessionStateProvider.notifier)
            .getSessionMessages(widget.sessionId)
            ?.messages ??
        const <ReducerMessage>[];
    final pendingToolIds = messages
        .where(
          (message) =>
              message.tool?.status == ToolCallStatus.pending &&
              !_toolActionsInFlight.contains(message.tool!.id) &&
              !_autoApprovedToolIds.contains(message.tool!.id),
        )
        .map((message) => message.tool!.id)
        .toList();
    for (final toolId in pendingToolIds) {
      _autoApprovedToolIds.add(toolId);
      await _approveToolCall(toolId, showError: false);
    }
  }

  void _showRenameDialog(Session? session) {
    if (session == null) {
      return;
    }
    final controller = TextEditingController(text: session.title);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改会话名称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入新的会话名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _renameSession(controller.text);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameSession(String alias) async {
    try {
      await ref.read(sessionStateProvider.notifier).renameSession(
            sessionId: widget.sessionId,
            alias: alias,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('会话名称已更新'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新会话名称失败: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _handleSendAction(
    Session? session,
    List<_MessageTurnGroup> turnGroups,
  ) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    if (_isConversationBusy(session, turnGroups)) {
      _messageController.clear();
      _messageFocusNode.requestFocus();
      await _enqueueComposerMessage(text);
      return;
    }

    _messageController.clear();
    _messageFocusNode.requestFocus();
    await _dispatchMessage(text);
  }

  Future<bool> _dispatchMessage(
    String text, {
    bool restoreComposerOnError = true,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final localId = _createLocalMessageId();
    setState(() {
      _isSending = true;
      _activeResponseLocalId = localId;
      _activeResponseObservedThinking = false;
    });

    try {
      final sendFuture = ref.read(sessionStateProvider.notifier).sendMessage(
            sessionId: widget.sessionId,
            content: trimmed,
            localId: localId,
          );
      _scheduleScrollToLatest(animate: true, force: true);
      await sendFuture;
      _scrollToBottom();
      return true;
    } catch (e) {
      if (_activeResponseLocalId == localId && mounted) {
        setState(() {
          _activeResponseLocalId = null;
          _activeResponseObservedThinking = false;
        });
      }
      if (restoreComposerOnError) {
        _setComposerText(trimmed);
        _messageFocusNode.requestFocus();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _approveToolCall(String toolId, {bool showError = true}) async {
    if (_toolActionsInFlight.contains(toolId)) {
      return;
    }

    setState(() => _toolActionsInFlight.add(toolId));

    try {
      await ref.read(sessionStateProvider.notifier).submitToolApproval(
            sessionId: widget.sessionId,
            toolId: toolId,
          );
    } catch (e) {
      _autoApprovedToolIds.remove(toolId);
      await ref
          .read(sessionStateProvider.notifier)
          .loadSessionMessages(widget.sessionId);
      if (mounted && showError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('批准失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _toolActionsInFlight.remove(toolId));
      }
    }
  }

  Future<void> _rejectToolCall(String toolId, String? reason) async {
    if (_toolActionsInFlight.contains(toolId)) {
      return;
    }

    setState(() => _toolActionsInFlight.add(toolId));

    try {
      await ref.read(sessionStateProvider.notifier).submitToolRejection(
            sessionId: widget.sessionId,
            toolId: toolId,
            reason: reason,
          );
    } catch (e) {
      await ref
          .read(sessionStateProvider.notifier)
          .loadSessionMessages(widget.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('拒绝失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _toolActionsInFlight.remove(toolId));
      }
    }
  }

  /// 显示清空消息对话框
  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空消息'),
        content: const Text('确认要清空此会话的所有消息吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearMessages();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  /// 清空消息
  void _clearMessages() {
    try {
      ref
          .read(sessionStateProvider.notifier)
          .clearSessionMessages(widget.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('消息已清空'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清空失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// 显示权限设置对话框
  void _showPermissionDialog() {
    final session =
        ref.read(sessionStateProvider.notifier).getSession(widget.sessionId);
    if (session == null) {
      return;
    }

    final options = _permissionOptionsFor(session);
    final current = _resolveCurrentPermissionOption(session);
    _showModeSheet(
      title: '权限设置',
      options: options,
      current: current,
      onSelected: (option) {
        ref.read(sessionStateProvider.notifier).updatePermissionMode(
              widget.sessionId,
              option.key,
            );
        Navigator.pop(context);
        unawaited(_maybeAutoApprovePendingTools());
      },
    );
  }
}

/// 消息气泡
class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.autoApproveEnabled,
    required this.isToolActionPending,
    required this.onApproveTool,
    required this.onRejectTool,
  });

  final ReducerMessage message;
  final bool autoApproveEnabled;
  final bool isToolActionPending;
  final Future<void> Function(String) onApproveTool;
  final Future<void> Function(String, String?) onRejectTool;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with AutomaticKeepAliveClientMixin<_MessageBubble> {
  bool _collapsed = true;

  ReducerMessage get message => widget.message;
  bool get autoApproveEnabled => widget.autoApproveEnabled;
  bool get isToolActionPending => widget.isToolActionPending;
  Future<void> Function(String) get onApproveTool => widget.onApproveTool;
  Future<void> Function(String, String?) get onRejectTool =>
      widget.onRejectTool;

  @override
  void initState() {
    super.initState();
    _collapsed = _shouldStartCollapsed(message);
    updateKeepAlive();
  }

  @override
  void didUpdateWidget(covariant _MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id) {
      _collapsed = _shouldStartCollapsed(message);
      updateKeepAlive();
    }
  }

  @override
  bool get wantKeepAlive => !_collapsed;

  bool _shouldStartCollapsed(ReducerMessage value) {
    if (value.isToolCall && value.tool != null) {
      return _shouldCollapseToolMessage(value.tool!);
    }
    if (value.isText) {
      return _shouldCollapseTextMessage(value.text ?? '');
    }
    if (value.isError) {
      return _shouldCollapseTextMessage(value.text ?? '');
    }
    return false;
  }

  bool _shouldCollapseTextMessage(String text) {
    final normalized = text.trimRight();
    if (normalized.isEmpty) {
      return false;
    }
    final lineCount = '\n'.allMatches(normalized).length + 1;
    return normalized.length > 320 || lineCount > 9;
  }

  bool _shouldCollapseToolMessage(ToolInfo tool) {
    final command = _extractCommand(tool.arguments);
    final diff = _extractDiff(tool);
    final argumentsPreview = _formatToolArguments(tool.arguments);
    final result = _formatToolResult(tool.result);
    return _looksLarge(command) ||
        _looksLarge(diff) ||
        _looksLarge(argumentsPreview) ||
        _looksLarge(result);
  }

  bool _looksLarge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }
    final normalized = value.trimRight();
    final lineCount = '\n'.allMatches(normalized).length + 1;
    return normalized.length > 240 || lineCount > 6;
  }

  void _toggleCollapsed() {
    setState(() => _collapsed = !_collapsed);
    updateKeepAlive();
  }

  Widget _buildCollapseButton({
    required Color color,
    required String collapsedLabel,
    required String expandedLabel,
  }) {
    return InkWell(
      onTap: _toggleCollapsed,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          _collapsed ? collapsedLabel : expandedLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedTextPreview({
    required String content,
    required Color textColor,
    required bool isUser,
  }) {
    final blocks = _MarkdownBlock.parse(content);
    final firstTextBlock = blocks.cast<_MarkdownBlock?>().firstWhere(
          (block) =>
              block != null &&
              block.type == _MarkdownBlockType.text &&
              block.text.trim().isNotEmpty,
          orElse: () => null,
        );
    final firstCodeBlock = blocks.cast<_MarkdownBlock?>().firstWhere(
          (block) =>
              block != null &&
              block.type == _MarkdownBlockType.code &&
              block.text.trim().isNotEmpty,
          orElse: () => null,
        );
    final firstTableBlock = blocks.cast<_MarkdownBlock?>().firstWhere(
          (block) =>
              block != null &&
              block.type == _MarkdownBlockType.table &&
              block.headers.isNotEmpty,
          orElse: () => null,
        );

    if (firstCodeBlock != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (firstTextBlock != null) ...[
            Text(
              _plainTextPreview(firstTextBlock.text),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
          ],
          IgnorePointer(
            child: _InlineCodePanel(
              code: firstCodeBlock.text,
              language: firstCodeBlock.language,
              isUser: isUser,
              collapsedLines: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUser ? '展开查看完整用户消息' : '展开查看完整消息',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: isUser ? 0.82 : 0.72),
            ),
          ),
        ],
      );
    }

    if (firstTableBlock != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 148,
            child: ClipRect(
              child: IgnorePointer(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: _MarkdownTableBlock(
                    headers: firstTableBlock.headers,
                    rows: firstTableBlock.rows,
                    isUser: isUser,
                    textColor: textColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUser ? '展开查看完整用户消息' : '展开查看完整消息',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: isUser ? 0.82 : 0.72),
            ),
          ),
        ],
      );
    }

    if (_looksLikeMarkdownContent(content)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 148,
            child: ClipRect(
              child: IgnorePointer(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: _MarkdownMessageContent(
                    content: content,
                    isUser: isUser,
                    textColor: textColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUser ? '展开查看完整用户消息' : '展开查看完整消息',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: isUser ? 0.82 : 0.72),
            ),
          ),
        ],
      );
    }
    final preview = _plainTextPreview(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          preview,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isUser ? '展开查看完整用户消息' : '展开查看完整消息',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor.withValues(alpha: isUser ? 0.82 : 0.72),
          ),
        ),
      ],
    );
  }

  bool _looksLikeMarkdownContent(String content) {
    return _looksLikeMarkdownContentValue(content);
  }

  Widget _buildCollapsedToolPreview({
    required String? command,
    required String? diffPreview,
    required String? resultPreview,
  }) {
    final summaryItems = <String>[
      if (command != null && command.isNotEmpty)
        '命令: ${_plainTextPreview(command)}',
      if (diffPreview != null && diffPreview.isNotEmpty)
        '改动: ${diffPreview.split('\n').length} 行',
      if (resultPreview != null && resultPreview.isNotEmpty)
        '输出: ${_plainTextPreview(resultPreview)}',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < summaryItems.take(3).length; index++) ...[
            Text(
              summaryItems[index],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppTheme.neutral700,
              ),
            ),
            if (index != summaryItems.take(3).length - 1)
              const SizedBox(height: 6),
          ],
          if (summaryItems.isEmpty)
            const Text(
              '展开查看完整调用详情',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.neutral700,
              ),
            ),
        ],
      ),
    );
  }

  String _plainTextPreview(String text) {
    final normalized = text
        .replaceAll(RegExp(r'```[\s\S]*?```'), '[代码片段]')
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.length <= 160) {
      return normalized;
    }
    return '${normalized.substring(0, 160)}...';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // 根据消息类型渲染不同的气泡
    if (message.isText) {
      return _buildTextMessage(context);
    } else if (message.isAgentEvent) {
      return _buildAgentEventMessage();
    } else if (message.isPermissionRequest) {
      return _buildPermissionRequestMessage();
    } else if (message.isTurnClose) {
      return _buildTurnCloseMessage();
    } else if (message.isError) {
      return _buildErrorMessage();
    } else if (message.isToolCall && message.tool != null) {
      return _buildToolCallMessage(message.tool!);
    } else {
      return _buildDefaultMessage();
    }
  }

  Widget _buildTextMessage(BuildContext context) {
    final role = message.metadata?['role']?.toString();
    final isUser = role == 'user';
    final isThinking = message.metadata?['outputType'] == 'thinking';
    final isOptimistic = message.metadata?['optimistic'] == true;
    final canCollapse = _shouldCollapseTextMessage(message.text ?? '');
    final bubbleColor = isUser ? AppTheme.brandColor : AppTheme.surface;
    final textColor = isUser ? Colors.white : AppTheme.textPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppTheme.radiusLg),
              topRight: const Radius.circular(AppTheme.radiusLg),
              bottomLeft: Radius.circular(isUser ? AppTheme.radiusLg : 4),
              bottomRight: Radius.circular(isUser ? 4 : AppTheme.radiusLg),
            ),
            border: Border.all(
              color: isUser ? AppTheme.brandColor : AppTheme.neutral200,
            ),
            boxShadow: isUser ? null : AppTheme.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canCollapse)
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildCollapseButton(
                    color: isUser
                        ? Colors.white.withValues(alpha: 0.92)
                        : AppTheme.brandColor,
                    collapsedLabel: '展开',
                    expandedLabel: '收起',
                  ),
                ),
              if (canCollapse) const SizedBox(height: 6),
              Opacity(
                opacity: isThinking ? 0.84 : 1,
                child: _collapsed && canCollapse
                    ? _buildCollapsedTextPreview(
                        content: message.text ?? '',
                        textColor: textColor,
                        isUser: isUser,
                      )
                    : _MarkdownMessageContent(
                        content: message.text ?? '',
                        isUser: isUser,
                        textColor: textColor,
                      ),
              ),
              if (isUser && isOptimistic) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '发送中',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRequestMessage() {
    final permission = message.permission;
    if (permission == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.warningColor, size: 20),
              const SizedBox(width: AppTheme.spacingSm),
              const Text(
                '权限请求',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text('工具: ${permission.tool}'),
          if (permission.reason != null) ...[
            const SizedBox(height: 4),
            Text(
              permission.reason!,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutral700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAgentEventMessage() {
    final text = message.text?.trim();
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.neutral100,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral700,
          ),
        ),
      ),
    );
  }

  Widget _buildTurnCloseMessage() {
    final turnClose = message.turnClose;
    if (turnClose == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            turnClose.abandoned ? Icons.cancel : Icons.check_circle_outline,
            size: 16,
            color:
                turnClose.abandoned ? AppTheme.errorColor : AppTheme.neutral600,
          ),
          const SizedBox(width: 8),
          Text(
            turnClose.abandoned ? '回合已终止' : '回合已结束',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              message.text ?? '发生错误',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCallMessage(ToolInfo tool) {
    final status = tool.status ?? ToolCallStatus.pending;
    final isPending = status == ToolCallStatus.pending;
    final category = _toolCategory(tool.name);
    final presentation = _toolPresentationKind(tool.name);
    final command = _extractCommand(tool.arguments);
    final primaryPath = _extractPrimaryPath(tool.arguments);
    final diffPreview = _extractDiff(tool);
    final canCollapse = _shouldCollapseToolMessage(tool);
    final argumentsPreview = _shouldShowRawArguments(
              tool.arguments,
              command: command,
              diff: diffPreview,
            ) &&
            _shouldDisplayArguments(tool.name)
        ? _formatToolArguments(tool.arguments)
        : null;
    final resultPreview = _formatToolResult(tool.result);
    final resultLanguage = _guessLanguageForResult(
      resultPreview,
      toolName: tool.name,
    );
    final summaryText = _toolSummaryText(tool, resultPreview: resultPreview);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPending
            ? AppTheme.warningColor.withValues(alpha: 0.08)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isPending ? AppTheme.warningColor : AppTheme.neutral300,
          width: 1,
        ),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _toolIcon(tool.name),
                color: isPending ? AppTheme.warningColor : AppTheme.neutral600,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  _toolTitle(tool.name),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildToolStatusBadge(status),
              if (canCollapse) ...[
                const SizedBox(width: 8),
                _buildCollapseButton(
                  color: AppTheme.brandColor,
                  collapsedLabel: '展开',
                  expandedLabel: '收起',
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TurnMetaChip(label: category),
              if (primaryPath != null && primaryPath.isNotEmpty)
                _TurnMetaChip(label: primaryPath),
            ],
          ),
          if (tool.description != null &&
              tool.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              tool.description!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppTheme.neutral600,
              ),
            ),
          ],
          if (_collapsed && canCollapse) ...[
            const SizedBox(height: 10),
            _buildCollapsedToolPreview(
              command: command,
              diffPreview: diffPreview,
              resultPreview: resultPreview,
            ),
          ] else ...[
            ..._buildToolDetailSections(
              tool: tool,
              presentation: presentation,
              command: command,
              diffPreview: diffPreview,
              argumentsPreview: argumentsPreview,
              resultPreview: resultPreview,
              resultLanguage: resultLanguage,
              summaryText: summaryText,
            ),
            if (tool.error != null) ...[
              const SizedBox(height: 10),
              _ToolSection(
                title: '错误信息',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    tool.error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.errorColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ],
          if (isPending) ...[
            const SizedBox(height: 10),
            if (autoApproveEnabled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    if (isToolActionPending)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.successColor,
                        ),
                      )
                    else
                      const Icon(
                        Icons.auto_mode_rounded,
                        size: 16,
                        color: AppTheme.successColor,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isToolActionPending ? '正在自动批准这次调用…' : '当前权限模式会自动处理这次调用',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isToolActionPending)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.brandColor,
                        ),
                      ),
                    ),
                  OutlinedButton(
                    onPressed: isToolActionPending
                        ? null
                        : () => onRejectTool(tool.id, null),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('拒绝'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: isToolActionPending
                        ? null
                        : () => onApproveTool(tool.id),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(isToolActionPending ? '提交中' : '批准'),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildToolDetailSections({
    required ToolInfo tool,
    required String presentation,
    required String? command,
    required String? diffPreview,
    required String? argumentsPreview,
    required String? resultPreview,
    required String resultLanguage,
    required String? summaryText,
  }) {
    final sections = <Widget>[];

    switch (presentation) {
      case 'bash':
        if (command != null && command.isNotEmpty) {
          sections.addAll([
            const SizedBox(height: 10),
            _ToolSection(
              title: '命令',
              child: _InlineCodePanel(
                code: command,
                language: 'shell',
                isUser: false,
                collapsedLines: 6,
              ),
            ),
          ]);
        }
        if (resultPreview != null && resultPreview.isNotEmpty) {
          sections.addAll([
            const SizedBox(height: 10),
            _ToolSection(
              title: '终端输出',
              child: _ToolResultView(
                content: resultPreview,
                language: resultLanguage.isEmpty ? 'shell' : resultLanguage,
                preferCode: true,
              ),
            ),
          ]);
        }
        break;
      case 'read':
      case 'search':
        if (summaryText != null && summaryText.isNotEmpty) {
          sections.addAll([
            const SizedBox(height: 10),
            _ToolSection(
              title: presentation == 'read' ? '读取摘要' : '结果摘要',
              child: _ToolSummaryCard(text: summaryText),
            ),
          ]);
        }
        if (resultPreview != null && resultPreview.isNotEmpty) {
          sections.addAll([
            const SizedBox(height: 10),
            _ToolSection(
              title: _resultSectionTitle(tool.name),
              child: _ToolResultView(
                content: resultPreview,
                language: resultLanguage,
              ),
            ),
          ]);
        }
        break;
      case 'edit':
        if (diffPreview != null && diffPreview.isNotEmpty) {
          sections.addAll([
            const SizedBox(height: 10),
            _ToolSection(
              title: '改动预览',
              child: _InlineCodePanel(
                code: diffPreview,
                language: 'diff',
                isUser: false,
                collapsedLines: 8,
              ),
            ),
          ]);
        }
        if (resultPreview != null &&
            resultPreview.isNotEmpty &&
            resultPreview != diffPreview) {
          sections.addAll([
            const SizedBox(height: 10),
            _ToolSection(
              title: '结果',
              child: _ToolResultView(
                content: resultPreview,
                language: resultLanguage,
                preferCode: true,
              ),
            ),
          ]);
        }
        break;
      case 'question':
        final prompt = _firstNonEmpty([
          tool.arguments['question']?.toString(),
          tool.arguments['prompt']?.toString(),
          tool.description,
        ]);
        if (prompt != null) {
          sections.addAll([
            const SizedBox(height: 10),
            _ToolSection(
              title: '确认内容',
              child: _ToolSummaryCard(text: prompt),
            ),
          ]);
        }
        final options = tool.arguments['options'];
        if (options is List && options.isNotEmpty) {
          sections.addAll([
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options
                  .map(
                    (entry) => _TurnMetaChip(label: entry.toString()),
                  )
                  .toList(),
            ),
          ]);
        }
        break;
      case 'todo':
        final todos = tool.arguments['todos'];
        if (todos is List && todos.isNotEmpty) {
          sections.addAll([
            const SizedBox(height: 10),
            _ToolSection(
              title: '待办状态',
              child: _ToolTodoList(items: todos),
            ),
          ]);
        }
        break;
      default:
        if (command != null && command.isNotEmpty) {
          sections.addAll([
            const SizedBox(height: 10),
            _ToolSection(
              title: '命令',
              child: _InlineCodePanel(
                code: command,
                language: 'shell',
                isUser: false,
                collapsedLines: 6,
              ),
            ),
          ]);
        }
        if (diffPreview != null && diffPreview.isNotEmpty) {
          sections.addAll([
            const SizedBox(height: 10),
            _ToolSection(
              title: '改动预览',
              child: _InlineCodePanel(
                code: diffPreview,
                language: 'diff',
                isUser: false,
                collapsedLines: 8,
              ),
            ),
          ]);
        }
        if (argumentsPreview != null) {
          sections.addAll([
            const SizedBox(height: 10),
            _ToolSection(
              title: '输入参数',
              child: _InlineCodePanel(
                code: argumentsPreview,
                language: 'json',
                isUser: false,
                collapsedLines: 4,
              ),
            ),
          ]);
        }
        if (resultPreview != null && resultPreview.isNotEmpty) {
          sections.addAll([
            const SizedBox(height: 10),
            _ToolSection(
              title: _resultSectionTitle(tool.name),
              child: _ToolResultView(
                content: resultPreview,
                language: resultLanguage,
                preferCode: _prefersCodeView(tool.name),
              ),
            ),
          ]);
        }
        break;
    }

    if (sections.isEmpty && summaryText != null && summaryText.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 10),
        _ToolSection(
          title: '摘要',
          child: _ToolSummaryCard(text: summaryText),
        ),
      ]);
    }

    return sections;
  }

  String _toolPresentationKind(String toolName) {
    final lower = toolName.toLowerCase();
    if (lower.contains('bash') ||
        lower.contains('shell') ||
        lower.contains('execute')) {
      return 'bash';
    }
    if (lower.contains('read') || lower == 'file') {
      return 'read';
    }
    if (lower.contains('grep') ||
        lower.contains('glob') ||
        lower.contains('search') ||
        lower == 'ls') {
      return 'search';
    }
    if (lower.contains('edit') ||
        lower.contains('write') ||
        lower.contains('patch') ||
        lower.contains('diff')) {
      return 'edit';
    }
    if (lower.contains('askuserquestion')) {
      return 'question';
    }
    if (lower.contains('todo')) {
      return 'todo';
    }
    if (lower.contains('task')) {
      return 'task';
    }
    return 'generic';
  }

  bool _shouldDisplayArguments(String toolName) {
    const compactKinds = {
      'read',
      'write',
      'edit',
      'multiedit',
      'notebookedit',
      'bash',
      'codexbash',
      'geminibash',
      'glob',
      'grep',
      'ls',
      'search',
      'toolsearch',
      'askuserquestion',
      'todowrite',
      'task',
      'codexpatch',
      'geminipatch',
      'codexdiff',
      'geminidiff',
      'file',
    };
    return !compactKinds.contains(toolName.toLowerCase());
  }

  bool _prefersCodeView(String toolName) {
    final lower = toolName.toLowerCase();
    return lower.contains('read') ||
        lower.contains('bash') ||
        lower.contains('edit') ||
        lower.contains('write') ||
        lower.contains('patch') ||
        lower.contains('diff') ||
        lower.contains('grep') ||
        lower.contains('search') ||
        lower == 'file';
  }

  String? _toolSummaryText(
    ToolInfo tool, {
    required String? resultPreview,
  }) {
    final presentation = _toolPresentationKind(tool.name);
    switch (presentation) {
      case 'read':
        return _firstNonEmpty([
          tool.arguments['path']?.toString(),
          tool.arguments['file_path']?.toString(),
          tool.description,
        ]);
      case 'search':
        return _firstNonEmpty([
          tool.arguments['pattern']?.toString(),
          tool.arguments['query']?.toString(),
          tool.arguments['path']?.toString(),
          resultPreview == null ? null : _plainTextPreview(resultPreview),
        ]);
      case 'task':
        return _firstNonEmpty([
          tool.arguments['prompt']?.toString(),
          tool.arguments['description']?.toString(),
          resultPreview == null ? null : _plainTextPreview(resultPreview),
        ]);
      default:
        return null;
    }
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String _toolCategory(String toolName) {
    final lower = toolName.toLowerCase();
    if (lower.contains('bash') ||
        lower.contains('shell') ||
        lower.contains('execute')) {
      return '命令执行';
    }
    if (lower.contains('read') ||
        lower.contains('ls') ||
        lower.contains('glob') ||
        lower.contains('grep') ||
        lower.contains('search')) {
      return '读取与搜索';
    }
    if (lower.contains('edit') ||
        lower.contains('write') ||
        lower.contains('patch') ||
        lower.contains('diff')) {
      return '文件改动';
    }
    if (lower.contains('reason') ||
        lower.contains('task') ||
        lower.contains('todo') ||
        lower.contains('plan') ||
        lower.contains('think')) {
      return '规划与推理';
    }
    if (lower.contains('web')) {
      return '网页访问';
    }
    return '工具调用';
  }

  IconData _toolIcon(String toolName) {
    final lower = toolName.toLowerCase();
    if (lower.contains('bash') ||
        lower.contains('shell') ||
        lower.contains('execute')) {
      return Icons.terminal_rounded;
    }
    if (lower.contains('read') || lower.contains('ls')) {
      return Icons.description_outlined;
    }
    if (lower.contains('glob') ||
        lower.contains('grep') ||
        lower.contains('search')) {
      return Icons.search_rounded;
    }
    if (lower.contains('edit') ||
        lower.contains('write') ||
        lower.contains('patch') ||
        lower.contains('diff')) {
      return Icons.edit_note_rounded;
    }
    if (lower.contains('web')) {
      return Icons.public_rounded;
    }
    if (lower.contains('todo') ||
        lower.contains('task') ||
        lower.contains('plan')) {
      return Icons.checklist_rounded;
    }
    return Icons.handyman_outlined;
  }

  String _toolTitle(String toolName) {
    switch (toolName) {
      case 'Bash':
      case 'CodexBash':
      case 'GeminiBash':
      case 'shell':
      case 'execute':
        return '命令执行';
      case 'Read':
      case 'read':
      case 'NotebookRead':
        return '读取文件';
      case 'Edit':
      case 'edit':
      case 'MultiEdit':
      case 'Write':
      case 'NotebookEdit':
        return '修改文件';
      case 'CodexDiff':
      case 'GeminiDiff':
      case 'CodexPatch':
      case 'GeminiPatch':
        return '代码改动';
      case 'Glob':
      case 'Grep':
      case 'LS':
      case 'search':
      case 'ToolSearch':
        return '搜索内容';
      case 'WebFetch':
      case 'WebSearch':
        return '网页检索';
      case 'Task':
        return '子任务';
      case 'TodoWrite':
        return '待办更新';
      case 'AskUserQuestion':
        return '用户确认';
      default:
        return '工具调用 · $toolName';
    }
  }

  String? _extractPrimaryPath(Map<String, dynamic> arguments) {
    const keys = [
      'file_path',
      'path',
      'cwd',
      'root',
      'uri',
      'target_file',
    ];
    for (final key in keys) {
      final value = arguments[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    final locations = arguments['locations'];
    if (locations is List && locations.isNotEmpty) {
      final first = locations.first;
      if (first is Map && first['path'] is String) {
        return first['path'] as String;
      }
    }
    return null;
  }

  String? _extractCommand(Map<String, dynamic> arguments) {
    final value = arguments['command'] ?? arguments['cmd'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  String? _extractDiff(ToolInfo tool) {
    final arguments = tool.arguments;
    final directPatch = arguments['patch'] ?? arguments['diff'];
    if (directPatch is String && directPatch.trim().isNotEmpty) {
      return directPatch.trimRight();
    }

    final oldString = arguments['old_string'] ?? arguments['oldText'];
    final newString = arguments['new_string'] ?? arguments['newText'];
    if (oldString is String && newString is String) {
      return [
        '--- 旧内容',
        oldString,
        '+++ 新内容',
        newString,
      ].join('\n');
    }

    final edits = arguments['edits'];
    if (edits is List && edits.isNotEmpty) {
      final buffer = StringBuffer();
      for (final edit in edits.whereType<Map>()) {
        final oldValue = edit['old_string']?.toString() ?? '';
        final newValue = edit['new_string']?.toString() ?? '';
        if (oldValue.isEmpty && newValue.isEmpty) {
          continue;
        }
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.writeln('--- 旧内容');
        buffer.writeln(oldValue);
        buffer.writeln('+++ 新内容');
        buffer.writeln(newValue);
      }
      if (buffer.isNotEmpty) {
        return buffer.toString().trimRight();
      }
    }

    final result = tool.result;
    if (result != null &&
        (result.contains('@@') ||
            result.contains('diff --git') ||
            result.contains('*** Begin Patch'))) {
      return result.trimRight();
    }
    return null;
  }

  bool _shouldShowRawArguments(
    Map<String, dynamic> arguments, {
    required String? command,
    required String? diff,
  }) {
    if (arguments.isEmpty) {
      return false;
    }
    if (command == null && diff == null) {
      return true;
    }
    final remaining = Map<String, dynamic>.from(arguments)
      ..remove('command')
      ..remove('cmd')
      ..remove('patch')
      ..remove('diff')
      ..remove('old_string')
      ..remove('new_string')
      ..remove('oldText')
      ..remove('newText')
      ..remove('edits');
    return remaining.isNotEmpty;
  }

  String? _formatToolResult(String? result) {
    if (result == null || result.trim().isEmpty) {
      return null;
    }
    final trimmed = result.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return trimmed;
      }
    }
    return trimmed;
  }

  String _guessLanguageForResult(
    String? content, {
    required String toolName,
  }) {
    if (content == null || content.isEmpty) {
      return '';
    }
    final lowerTool = toolName.toLowerCase();
    if (content.startsWith('{') || content.startsWith('[')) {
      return 'json';
    }
    if (content.contains('diff --git') || content.contains('@@')) {
      return 'diff';
    }
    final detected = _detectStructuredLanguage(content);
    if (detected.isNotEmpty) {
      return detected;
    }
    if (lowerTool.contains('bash') ||
        lowerTool.contains('shell') ||
        lowerTool.contains('execute')) {
      return 'shell';
    }
    if (lowerTool.contains('read') ||
        lowerTool.contains('write') ||
        lowerTool.contains('edit')) {
      return 'text';
    }
    return '';
  }

  String _resultSectionTitle(String toolName) {
    final lower = toolName.toLowerCase();
    if (lower.contains('bash') ||
        lower.contains('shell') ||
        lower.contains('execute')) {
      return '命令输出';
    }
    if (lower.contains('read')) {
      return '文件内容';
    }
    if (lower.contains('search') ||
        lower.contains('grep') ||
        lower.contains('glob') ||
        lower.contains('ls')) {
      return '搜索结果';
    }
    return '输出结果';
  }

  Widget _buildToolStatusBadge(ToolCallStatus status) {
    Color color;
    String text;

    switch (status) {
      case ToolCallStatus.pending:
        color = AppTheme.warningColor;
        text = '待确认';
        break;
      case ToolCallStatus.approved:
        color = AppTheme.infoColor;
        text = '已处理';
        break;
      case ToolCallStatus.rejected:
        color = AppTheme.errorColor;
        text = '已拒绝';
        break;
      case ToolCallStatus.executing:
        color = AppTheme.infoColor;
        text = '执行中';
        break;
      case ToolCallStatus.completed:
        color = AppTheme.infoColor;
        text = '已完成';
        break;
      case ToolCallStatus.failed:
        color = AppTheme.errorColor;
        text = '失败';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String? _formatToolArguments(Map<String, dynamic> arguments) {
    if (arguments.isEmpty) {
      return null;
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(arguments);
    } catch (_) {
      return arguments.toString();
    }
  }

  String _messageKindLabel(String kind) {
    switch (kind) {
      case 'text':
        return '文本消息';
      case 'tool-call':
        return '工具调用';
      case 'permission-request':
        return '权限请求';
      case 'turn-close':
        return '回合结束';
      case 'agent-event':
        return '状态事件';
      case 'error':
        return '错误消息';
      default:
        return kind;
    }
  }

  Widget _buildDefaultMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Text(
        _messageKindLabel(message.kind),
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.neutral600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _MarkdownMessageContent extends StatelessWidget {
  const _MarkdownMessageContent({
    required this.content,
    required this.isUser,
    required this.textColor,
  });

  final String content;
  final bool isUser;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final blocks = _MarkdownBlock.parse(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          if (blocks[index].type == _MarkdownBlockType.code)
            _InlineCodePanel(
              code: blocks[index].text,
              language: blocks[index].language,
              isUser: isUser,
            )
          else if (blocks[index].type == _MarkdownBlockType.table)
            _MarkdownTableBlock(
              headers: blocks[index].headers,
              rows: blocks[index].rows,
              isUser: isUser,
              textColor: textColor,
            )
          else
            _MarkdownTextBlock(
              content: blocks[index].text,
              isUser: isUser,
              textColor: textColor,
            ),
          if (index != blocks.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MarkdownTableBlock extends StatelessWidget {
  const _MarkdownTableBlock({
    required this.headers,
    required this.rows,
    required this.isUser,
    required this.textColor,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final bool isUser;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isUser ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0);
    final panelColor =
        isUser ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFFCFDFF);
    final headerColor =
        isUser ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFF1F5F9);
    final headerTextColor = isUser ? Colors.white : const Color(0xFF334155);
    final normalizedRows = rows
        .map(
          (row) => List<String>.generate(
            headers.length,
            (index) => index < row.length ? row[index] : '',
          ),
        )
        .toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: {
            for (var index = 0; index < headers.length; index++)
              index: const IntrinsicColumnWidth(flex: 1),
          },
          border: TableBorder(
            horizontalInside: BorderSide(color: borderColor),
            verticalInside:
                BorderSide(color: borderColor.withValues(alpha: 0.55)),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerColor),
              children: [
                for (final header in headers)
                  _MarkdownTableCell(
                    text: header,
                    textColor: headerTextColor,
                    isHeader: true,
                  ),
              ],
            ),
            for (var rowIndex = 0; rowIndex < normalizedRows.length; rowIndex++)
              TableRow(
                decoration: BoxDecoration(
                  color: rowIndex.isEven
                      ? panelColor
                      : panelColor.withValues(alpha: isUser ? 0.07 : 0.72),
                ),
                children: [
                  for (final cell in normalizedRows[rowIndex])
                    _MarkdownTableCell(
                      text: cell,
                      textColor: textColor,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MarkdownTableCell extends StatelessWidget {
  const _MarkdownTableCell({
    required this.text,
    required this.textColor,
    this.isHeader = false,
  });

  final String text;
  final Color textColor;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SelectableText(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: isHeader ? 12.5 : 13,
          height: 1.45,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

enum _MarkdownTextSectionType {
  paragraph,
  heading1,
  heading2,
  heading3,
  bulletList,
  numberedList,
  quote,
}

class _MarkdownTextBlock extends StatelessWidget {
  const _MarkdownTextBlock({
    required this.content,
    required this.isUser,
    required this.textColor,
  });

  final String content;
  final bool isUser;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final sections = _MarkdownTextSection.parse(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          _buildSection(sections[index]),
          if (index != sections.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildSection(_MarkdownTextSection section) {
    switch (section.type) {
      case _MarkdownTextSectionType.heading1:
        return _buildRichText(
          section.text,
          baseStyle: TextStyle(
            color: textColor,
            fontSize: 20,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        );
      case _MarkdownTextSectionType.heading2:
        return _buildRichText(
          section.text,
          baseStyle: TextStyle(
            color: textColor,
            fontSize: 18,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        );
      case _MarkdownTextSectionType.heading3:
        return _buildRichText(
          section.text,
          baseStyle: TextStyle(
            color: textColor,
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        );
      case _MarkdownTextSectionType.bulletList:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in section.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        '•',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRichText(
                        item,
                        baseStyle: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      case _MarkdownTextSectionType.numberedList:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < section.items.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}.',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRichText(
                        section.items[index],
                        baseStyle: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      case _MarkdownTextSectionType.quote:
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            color: isUser
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.neutral50,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: isUser
                    ? Colors.white.withValues(alpha: 0.42)
                    : AppTheme.brandColor.withValues(alpha: 0.45),
                width: 3,
              ),
            ),
          ),
          child: _buildRichText(
            section.text,
            baseStyle: TextStyle(
              color: textColor.withValues(alpha: 0.92),
              fontSize: 13,
              height: 1.55,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      case _MarkdownTextSectionType.paragraph:
        return _buildRichText(
          section.text,
          baseStyle: TextStyle(
            color: textColor,
            fontSize: 14,
            height: 1.5,
          ),
        );
    }
  }

  Widget _buildRichText(
    String raw, {
    required TextStyle baseStyle,
  }) {
    return SelectableText.rich(
      TextSpan(
        children: _MarkdownInlineParser.buildSpans(
          raw,
          baseStyle: baseStyle,
          linkColor: isUser ? Colors.white : AppTheme.brandColor,
          inlineCodeColor: textColor,
          inlineCodeBackground: isUser
              ? Colors.white.withValues(alpha: 0.16)
              : AppTheme.neutral100,
        ),
      ),
    );
  }
}

class _MarkdownTextSection {
  const _MarkdownTextSection._({
    required this.type,
    this.text = '',
    this.items = const [],
  });

  final _MarkdownTextSectionType type;
  final String text;
  final List<String> items;

  static List<_MarkdownTextSection> parse(String input) {
    final normalized = input.trim();
    if (normalized.isEmpty) {
      return const [];
    }

    final chunks = normalized
        .split(RegExp(r'\n\s*\n'))
        .map((chunk) => chunk.trim())
        .where((chunk) => chunk.isNotEmpty);
    final sections = <_MarkdownTextSection>[];

    for (final chunk in chunks) {
      final lines = chunk.split('\n').map((line) => line.trimRight()).toList();
      final heading = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(lines.first);
      if (heading != null && lines.length == 1) {
        final level = heading.group(1)!.length;
        final text = heading.group(2)!.trim();
        sections.add(
          _MarkdownTextSection._(
            type: switch (level) {
              1 => _MarkdownTextSectionType.heading1,
              2 => _MarkdownTextSectionType.heading2,
              _ => _MarkdownTextSectionType.heading3,
            },
            text: text,
          ),
        );
        continue;
      }

      if (lines.every((line) => RegExp(r'^\s*[-*+]\s+').hasMatch(line))) {
        sections.add(
          _MarkdownTextSection._(
            type: _MarkdownTextSectionType.bulletList,
            items: lines
                .map((line) => line.replaceFirst(RegExp(r'^\s*[-*+]\s+'), ''))
                .toList(),
          ),
        );
        continue;
      }

      if (lines.every((line) => RegExp(r'^\s*\d+\.\s+').hasMatch(line))) {
        sections.add(
          _MarkdownTextSection._(
            type: _MarkdownTextSectionType.numberedList,
            items: lines
                .map((line) => line.replaceFirst(RegExp(r'^\s*\d+\.\s+'), ''))
                .toList(),
          ),
        );
        continue;
      }

      if (lines.every((line) => line.trimLeft().startsWith('>'))) {
        sections.add(
          _MarkdownTextSection._(
            type: _MarkdownTextSectionType.quote,
            text: lines
                .map((line) => line.replaceFirst(RegExp(r'^\s*>\s?'), ''))
                .join('\n')
                .trim(),
          ),
        );
        continue;
      }

      sections.add(
        _MarkdownTextSection._(
          type: _MarkdownTextSectionType.paragraph,
          text: chunk,
        ),
      );
    }

    return sections;
  }
}

class _MarkdownInlineParser {
  static final RegExp _pattern = RegExp(
    r'(\[([^\]]+)\]\(([^)]+)\)|`([^`]+)`|\*\*([^*]+)\*\*|__([^_]+)__|\*([^*]+)\*|_([^_]+)_)',
  );

  static List<InlineSpan> buildSpans(
    String input, {
    required TextStyle baseStyle,
    required Color linkColor,
    required Color inlineCodeColor,
    required Color inlineCodeBackground,
  }) {
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _pattern.allMatches(input)) {
      if (match.start > cursor) {
        spans.add(TextSpan(
          text: input.substring(cursor, match.start),
          style: baseStyle,
        ));
      }

      if (match.group(2) != null && match.group(3) != null) {
        final label = match.group(2)!;
        final url = match.group(3)!;
        spans.add(
          TextSpan(
            text: label,
            style: baseStyle.copyWith(
              color: linkColor,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrlString(url);
              },
          ),
        );
      } else if (match.group(4) != null) {
        spans.add(
          TextSpan(
            text: match.group(4),
            style: baseStyle.copyWith(
              fontFamily: AppTheme.fontFamilyMono,
              fontSize: (baseStyle.fontSize ?? 14) - 1,
              backgroundColor: inlineCodeBackground,
              color: inlineCodeColor,
            ),
          ),
        );
      } else if (match.group(5) != null || match.group(6) != null) {
        spans.add(
          TextSpan(
            text: match.group(5) ?? match.group(6)!,
            style: baseStyle.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (match.group(7) != null || match.group(8) != null) {
        spans.add(
          TextSpan(
            text: match.group(7) ?? match.group(8)!,
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      }

      cursor = match.end;
    }

    if (cursor < input.length) {
      spans.add(TextSpan(
        text: input.substring(cursor),
        style: baseStyle,
      ));
    }

    return spans;
  }
}

class _InlineCodePanel extends StatefulWidget {
  const _InlineCodePanel({
    required this.code,
    required this.language,
    required this.isUser,
    this.collapsedLines = 8,
  });

  final String code;
  final String language;
  final bool isUser;
  final int collapsedLines;

  @override
  State<_InlineCodePanel> createState() => _InlineCodePanelState();
}

class _InlineCodePanelState extends State<_InlineCodePanel>
    with AutomaticKeepAliveClientMixin<_InlineCodePanel> {
  bool _expanded = false;

  @override
  bool get wantKeepAlive => _expanded;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final normalizedCode = widget.code.trimRight();
    final lines = normalizedCode.split('\n');
    final shouldCollapse =
        lines.length > widget.collapsedLines || widget.code.length > 320;
    final visibleCode = !_expanded && shouldCollapse
        ? lines.take(widget.collapsedLines).join('\n')
        : normalizedCode;
    final visibleLines = visibleCode.split('\n');
    final isDiff = _isDiffLanguage(widget.language);
    final isTerminal = _isTerminalLanguage(widget.language);
    final backgroundColor = widget.isUser
        ? const Color(0xFF1F2937)
        : isTerminal
            ? const Color(0xFF0D1117)
            : const Color(0xFF1E1E1E);
    final foregroundColor = Colors.white;
    final borderColor = widget.isUser
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFF30363D);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTerminal ? Icons.terminal_rounded : Icons.code_rounded,
                size: 14,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                _languageLabel(widget.language),
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamilyMono,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${lines.length} 行',
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamilyMono,
                  fontSize: 11,
                  color: Colors.white38,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: normalizedCode),
                  );
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('代码已复制'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    '复制',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
              if (shouldCollapse) const SizedBox(width: 8),
              if (shouldCollapse)
                InkWell(
                  onTap: () {
                    setState(() => _expanded = !_expanded);
                    updateKeepAlive();
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Text(
                      _expanded ? '收起' : '展开',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF58A6FF),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: isDiff
                  ? _buildDiffBlock(visibleLines)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isTerminal) ...[
                          _buildLineNumbers(visibleLines.length),
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: visibleLines.length * 21,
                            color: Colors.white10,
                          ),
                          const SizedBox(width: 12),
                        ],
                        _buildCodeBody(
                          visibleCode,
                          foregroundColor: foregroundColor,
                          isTerminal: isTerminal,
                        ),
                      ],
                    ),
            ),
          ),
          if (shouldCollapse && !_expanded) ...[
            const SizedBox(height: 6),
            Text(
              '还有 ${lines.length - widget.collapsedLines} 行',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white60,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isTerminalLanguage(String language) {
    const terminalLanguages = {
      'shell',
      'bash',
      'sh',
      'zsh',
      'console',
      'terminal',
    };
    return terminalLanguages.contains(language.toLowerCase());
  }

  bool _isDiffLanguage(String language) => language.toLowerCase() == 'diff';

  String _languageLabel(String language) {
    if (language.isEmpty) {
      return '代码';
    }
    switch (language.toLowerCase()) {
      case 'shell':
      case 'bash':
      case 'zsh':
      case 'sh':
        return '终端';
      case 'diff':
        return '差异';
      case 'yaml':
        return 'YAML';
      case 'json':
        return 'JSON';
      case 'dockerfile':
        return 'Dockerfile';
      case 'nginx':
        return 'Nginx';
      case 'ini':
        return 'INI';
      default:
        return language;
    }
  }

  Widget _buildLineNumbers(int count) {
    return Text(
      List<String>.generate(count, (index) => '${index + 1}').join('\n'),
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontFamily: AppTheme.fontFamilyMono,
        fontSize: 12.5,
        height: 1.6,
        color: Colors.white38,
      ),
    );
  }

  Widget _buildCodeBody(
    String code, {
    required Color foregroundColor,
    required bool isTerminal,
  }) {
    final normalizedLanguage = _normalizeLanguage(widget.language);
    if (isTerminal ||
        widget.language.isEmpty ||
        widget.language == 'text' ||
        !_canHighlightLanguage(normalizedLanguage)) {
      return SelectableText(
        code,
        style: TextStyle(
          fontFamily: AppTheme.fontFamilyMono,
          fontSize: 12.5,
          height: 1.6,
          color: isTerminal ? const Color(0xFFC9D1D9) : foregroundColor,
        ),
      );
    }

    return HighlightView(
      code,
      language: normalizedLanguage,
      theme: vs2015Theme,
      padding: EdgeInsets.zero,
      textStyle: const TextStyle(
        fontFamily: AppTheme.fontFamilyMono,
        fontSize: 12.5,
        height: 1.6,
      ),
    );
  }

  Widget _buildDiffBlock(List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < lines.length; index++)
          Container(
            color: _diffBackground(lines[index]),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamilyMono,
                      fontSize: 12.5,
                      height: 1.6,
                      color: Colors.white38,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SelectableText(
                  lines[index],
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamilyMono,
                    fontSize: 12.5,
                    height: 1.6,
                    color: _diffForeground(lines[index]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _diffBackground(String line) {
    if (line.startsWith('+') && !line.startsWith('+++')) {
      return const Color(0x33238B4B);
    }
    if (line.startsWith('-') && !line.startsWith('---')) {
      return const Color(0x33DA3633);
    }
    if (line.startsWith('@@')) {
      return const Color(0x334A4A7A);
    }
    return Colors.transparent;
  }

  Color _diffForeground(String line) {
    if (line.startsWith('+') && !line.startsWith('+++')) {
      return const Color(0xFF7EE787);
    }
    if (line.startsWith('-') && !line.startsWith('---')) {
      return const Color(0xFFFF7B72);
    }
    if (line.startsWith('@@')) {
      return const Color(0xFF79C0FF);
    }
    return Colors.white;
  }

  String _normalizeLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'ts':
        return 'typescript';
      case 'js':
        return 'javascript';
      case 'yml':
        return 'yaml';
      case 'dockerfile':
      case 'nginx':
      case 'ini':
        return 'plaintext';
      case 'shell':
      case 'bash':
      case 'zsh':
      case 'sh':
        return 'bash';
      default:
        return language;
    }
  }

  bool _canHighlightLanguage(String language) {
    const supported = {
      'bash',
      'c',
      'cpp',
      'css',
      'dart',
      'diff',
      'go',
      'html',
      'java',
      'javascript',
      'json',
      'kotlin',
      'markdown',
      'objc',
      'php',
      'plaintext',
      'python',
      'ruby',
      'rust',
      'sql',
      'swift',
      'typescript',
      'xml',
      'yaml',
    };
    return supported.contains(language);
  }
}

class _ToolSection extends StatelessWidget {
  const _ToolSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.neutral700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ToolSummaryCard extends StatelessWidget {
  const _ToolSummaryCard({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: AppTheme.neutral800,
        ),
      ),
    );
  }
}

class _ToolTodoList extends StatelessWidget {
  const _ToolTodoList({
    required this.items,
  });

  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _ToolTodoRow(item: items[index]),
            if (index != items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ToolTodoRow extends StatelessWidget {
  const _ToolTodoRow({
    required this.item,
  });

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final map = item is Map ? item : const <String, dynamic>{};
    final content = map['content']?.toString() ?? item.toString();
    final status = map['status']?.toString() ?? 'pending';
    final color = switch (status) {
      'completed' => AppTheme.successColor,
      'in_progress' => AppTheme.infoColor,
      _ => AppTheme.neutral500,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            status == 'completed'
                ? Icons.check_circle_rounded
                : status == 'in_progress'
                    ? Icons.timelapse_rounded
                    : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppTheme.neutral800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolResultView extends StatelessWidget {
  const _ToolResultView({
    required this.content,
    required this.language,
    this.preferCode = false,
  });

  final String content;
  final String language;
  final bool preferCode;

  @override
  Widget build(BuildContext context) {
    final resolvedLanguage =
        language.isNotEmpty ? language : _detectStructuredLanguage(content);
    final looksLikeMarkdown = !preferCode &&
        resolvedLanguage.isEmpty &&
        _looksLikeMarkdownContentValue(content);

    if (looksLikeMarkdown) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.neutral50,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: _MarkdownMessageContent(
          content: content,
          isUser: false,
          textColor: AppTheme.textPrimary,
        ),
      );
    }

    if (!preferCode && resolvedLanguage.isEmpty) {
      return _ToolSummaryCard(text: content);
    }

    return _InlineCodePanel(
      code: content,
      language: resolvedLanguage,
      isUser: false,
      collapsedLines: 8,
    );
  }
}

bool _looksLikeMarkdownContentValue(String content) {
  final normalized = content.trim();
  if (normalized.isEmpty) {
    return false;
  }
  return normalized.contains('```') ||
      RegExp(r'(^|\n)\s{0,3}#{1,6}\s').hasMatch(normalized) ||
      RegExp(r'(^|\n)\s*[-*+]\s+').hasMatch(normalized) ||
      RegExp(r'(^|\n)\s*\d+\.\s+').hasMatch(normalized) ||
      RegExp(r'(^|\n)\s*\|.+\|').hasMatch(normalized) ||
      RegExp(r'\[[^\]]+\]\([^)]+\)').hasMatch(normalized) ||
      RegExp(r'(^|\n)>\s+').hasMatch(normalized);
}

String _detectStructuredLanguage(String content) {
  final normalized = content.trim();
  if (normalized.isEmpty) {
    return '';
  }

  if ((normalized.startsWith('{') || normalized.startsWith('[')) &&
      _canDecodeJson(normalized)) {
    return 'json';
  }
  if (_looksLikeDiff(normalized)) {
    return 'diff';
  }
  if (_looksLikeDockerfile(normalized)) {
    return 'dockerfile';
  }
  if (_looksLikeYaml(normalized)) {
    return 'yaml';
  }
  if (_looksLikeEnvFile(normalized)) {
    return 'bash';
  }
  if (_looksLikeNginx(normalized)) {
    return 'nginx';
  }
  if (_looksLikeShell(normalized)) {
    return 'bash';
  }
  if (_looksLikeSql(normalized)) {
    return 'sql';
  }
  if (_looksLikeXml(normalized)) {
    return 'xml';
  }
  if (_looksLikeIni(normalized)) {
    return 'ini';
  }
  if (_looksLikeCodeLikeBlock(normalized)) {
    return 'text';
  }
  return '';
}

bool _canDecodeJson(String value) {
  try {
    jsonDecode(value);
    return true;
  } catch (_) {
    return false;
  }
}

bool _looksLikeDiff(String value) =>
    value.contains('diff --git') ||
    value.contains('*** Begin Patch') ||
    value.contains('\n@@') ||
    RegExp(r'(^|\n)[+-]{3}\s').hasMatch(value);

bool _looksLikeDockerfile(String value) => RegExp(
      r'(^|\n)\s*(FROM|RUN|COPY|ADD|WORKDIR|ENV|CMD|ENTRYPOINT|EXPOSE|ARG)\b',
      caseSensitive: false,
    ).hasMatch(value);

bool _looksLikeYaml(String value) {
  final lines =
      value.split('\n').where((line) => line.trim().isNotEmpty).toList();
  if (lines.length < 2) {
    return false;
  }
  final keyedLines = lines.where(
    (line) => RegExp("^\\s*[\\w\\-./\"']+\\s*:\\s*.*\$").hasMatch(line),
  );
  return keyedLines.length >= 2;
}

bool _looksLikeEnvFile(String value) {
  final lines =
      value.split('\n').where((line) => line.trim().isNotEmpty).toList();
  if (lines.isEmpty) {
    return false;
  }
  final matched = lines.where(
    (line) => RegExp(r'^[A-Za-z_][A-Za-z0-9_]*=').hasMatch(line.trim()),
  );
  return matched.length >= 2;
}

bool _looksLikeNginx(String value) => RegExp(
      r'(^|\n)\s*(server|location|upstream)\s*\{|(^|\n)\s*listen\s+\d+',
      caseSensitive: false,
    ).hasMatch(value);

bool _looksLikeShell(String value) => RegExp(
      r'(^|\n)\s*(npm|pnpm|yarn|git|docker|cd|ls|cat|echo|export|curl|chmod|./)',
      caseSensitive: false,
    ).hasMatch(value);

bool _looksLikeSql(String value) => RegExp(
      r'(^|\n)\s*(select|insert|update|delete|create|alter|drop)\b',
      caseSensitive: false,
    ).hasMatch(value);

bool _looksLikeXml(String value) =>
    value.startsWith('<') && RegExp(r'<[A-Za-z][^>]*>').hasMatch(value);

bool _looksLikeIni(String value) =>
    RegExp(r'(^|\n)\s*\[[^\]]+\]\s*$').hasMatch(value);

bool _looksLikeCodeLikeBlock(String value) {
  final lines = value
      .split('\n')
      .map((line) => line.trimRight())
      .where((line) => line.trim().isNotEmpty)
      .toList();
  if (lines.length < 3) {
    return false;
  }

  var scored = 0;
  for (final line in lines) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('#') ||
        trimmed.startsWith('- ') ||
        trimmed.startsWith('* ')) {
      scored++;
    }
    if (trimmed.contains('=') ||
        trimmed.contains(':') ||
        trimmed.contains('{') ||
        trimmed.contains('}') ||
        trimmed.contains('[') ||
        trimmed.contains(']') ||
        trimmed.contains(';')) {
      scored++;
    }
    if (RegExp(r'^\s{2,}\S').hasMatch(line)) {
      scored++;
    }
  }

  return scored >= lines.length;
}

enum _MarkdownBlockType { text, code, table }

class _MarkdownBlock {
  const _MarkdownBlock._({
    required this.type,
    this.text = '',
    this.language = '',
    this.headers = const [],
    this.rows = const [],
  });

  final _MarkdownBlockType type;
  final String text;
  final String language;
  final List<String> headers;
  final List<List<String>> rows;

  static List<_MarkdownBlock> parse(String input) {
    final normalized = input.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    final blocks = <_MarkdownBlock>[];
    final textBuffer = StringBuffer();

    void flushText() {
      final value = textBuffer.toString().trim();
      if (value.isNotEmpty) {
        final segments = value
            .split(RegExp(r'\n\s*\n'))
            .map((segment) => segment.trim())
            .where((segment) => segment.isNotEmpty);
        for (final segment in segments) {
          final detectedLanguage = _looksLikeMarkdownContentValue(segment)
              ? ''
              : _detectStructuredLanguage(segment);
          if (detectedLanguage.isNotEmpty && segment.split('\n').length >= 2) {
            blocks.add(_MarkdownBlock._(
              type: _MarkdownBlockType.code,
              text: segment,
              language: detectedLanguage,
            ));
            continue;
          }
          blocks.add(_MarkdownBlock._(
            type: _MarkdownBlockType.text,
            text: segment,
          ));
        }
      }
      textBuffer.clear();
    }

    var index = 0;
    while (index < lines.length) {
      final line = lines[index];
      final fence = RegExp(r'^\s*```([^\n`]*)\s*$').firstMatch(line);
      if (fence != null) {
        flushText();
        final language = (fence.group(1) ?? '').trim();
        index += 1;
        final codeLines = <String>[];
        while (index < lines.length &&
            !RegExp(r'^\s*```\s*$').hasMatch(lines[index])) {
          codeLines.add(lines[index]);
          index += 1;
        }
        if (index < lines.length) {
          index += 1;
        }
        final code = codeLines.join('\n').trimRight();
        if (code.isNotEmpty) {
          blocks.add(_MarkdownBlock._(
            type: _MarkdownBlockType.code,
            text: code,
            language: language,
          ));
        }
        continue;
      }

      if (_isMarkdownTableStart(lines, index)) {
        flushText();
        final headers = _splitMarkdownTableRow(lines[index]);
        index += 2;
        final rows = <List<String>>[];
        while (
            index < lines.length && _looksLikeMarkdownTableRow(lines[index])) {
          rows.add(_splitMarkdownTableRow(lines[index]));
          index += 1;
        }
        if (headers.isNotEmpty) {
          blocks.add(_MarkdownBlock._(
            type: _MarkdownBlockType.table,
            headers: headers,
            rows: rows,
          ));
        }
        continue;
      }

      textBuffer.writeln(line);
      index += 1;
    }

    flushText();
    return blocks.isEmpty
        ? [
            _MarkdownBlock._(
              type: _MarkdownBlockType.text,
              text: normalized,
            ),
          ]
        : blocks;
  }

  static bool _isMarkdownTableStart(List<String> lines, int index) {
    if (index + 1 >= lines.length) {
      return false;
    }
    final headerLine = lines[index];
    final separatorLine = lines[index + 1];
    return _looksLikeMarkdownTableRow(headerLine) &&
        RegExp(r'^\s*\|?(\s*:?-{3,}:?\s*\|)+\s*:?-{3,}:?\s*\|?\s*$')
            .hasMatch(separatorLine);
  }

  static bool _looksLikeMarkdownTableRow(String line) {
    final trimmed = line.trim();
    return trimmed.contains('|') &&
        !trimmed.startsWith('```') &&
        trimmed.replaceAll('|', '').trim().isNotEmpty;
  }

  static List<String> _splitMarkdownTableRow(String line) {
    final trimmed = line.trim().replaceFirst(RegExp(r'^\|'), '').replaceFirst(
          RegExp(r'\|$'),
          '',
        );
    return trimmed.split('|').map((cell) => cell.trim()).toList();
  }
}

class _MessageTurnGroup {
  const _MessageTurnGroup({
    required this.id,
    required this.messages,
    required this.preview,
    required this.createdAt,
    this.userPrompt,
  });

  final String id;
  final List<ReducerMessage> messages;
  final String preview;
  final DateTime createdAt;
  final ReducerMessage? userPrompt;

  static List<_MessageTurnGroup> build(List<ReducerMessage> messages) {
    if (messages.isEmpty) {
      return const [];
    }

    final groups = <_MessageTurnGroup>[];
    final currentMessages = <ReducerMessage>[];
    ReducerMessage? currentPrompt;

    void flushCurrent() {
      if (currentMessages.isEmpty) {
        return;
      }
      groups.add(
        _MessageTurnGroup(
          id: currentPrompt?.id ?? currentMessages.first.id,
          messages: List<ReducerMessage>.from(currentMessages),
          preview: _previewFor(
            currentPrompt,
            fallback: currentMessages.first,
          ),
          createdAt: currentMessages.first.createdAt,
          userPrompt: currentPrompt,
        ),
      );
      currentMessages.clear();
      currentPrompt = null;
    }

    for (final message in messages) {
      final isUserText =
          message.isText && message.metadata?['role']?.toString() == 'user';
      if (isUserText) {
        flushCurrent();
        currentPrompt = message;
      }
      currentMessages.add(message);
    }
    flushCurrent();

    return groups;
  }

  static String _previewFor(
    ReducerMessage? prompt, {
    required ReducerMessage fallback,
  }) {
    final source = (prompt?.text ?? fallback.text ?? fallback.kind).trim();
    if (source.isEmpty) {
      return '空消息';
    }
    final normalized = source.replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 56) {
      return normalized;
    }
    return '${normalized.substring(0, 56)}...';
  }
}

class _TurnMetaChip extends StatelessWidget {
  const _TurnMetaChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutral700,
        ),
      ),
    );
  }
}

class _ScrollActionButton extends StatelessWidget {
  const _ScrollActionButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.45,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                icon,
                size: 20,
                color: enabled ? AppTheme.textPrimary : AppTheme.neutral400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlChip extends StatelessWidget {
  const _ControlChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.neutral300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppTheme.neutral700),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeOption {
  const _ModeOption({
    required this.key,
    required this.label,
    this.description,
  });

  factory _ModeOption.fromSessionModeOption(SessionModeOption value) {
    return _ModeOption(
      key: value.key,
      label: value.label,
      description: value.description,
    );
  }

  final String key;
  final String label;
  final String? description;
}

class _ModeOptionTile extends StatelessWidget {
  const _ModeOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ModeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.brandColor.withValues(alpha: 0.08)
              : AppTheme.surface,
          border: Border.all(
            color: selected ? AppTheme.brandColor : AppTheme.neutral200,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.brandColor : AppTheme.neutral500,
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (option.description != null &&
                      option.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      option.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const Set<String> _ignoredSlashCommands = {
  'add-dir',
  'agents',
  'config',
  'statusline',
  'bashes',
  'settings',
  'cost',
  'doctor',
  'exit',
  'help',
  'ide',
  'init',
  'install-github-app',
  'mcp',
  'memory',
  'migrate-installer',
  'model',
  'pr-comments',
  'release-notes',
  'resume',
  'status',
  'bug',
  'review',
  'security-review',
  'terminal-setup',
  'upgrade',
  'vim',
  'permissions',
  'hooks',
  'export',
  'logout',
  'login',
};

const Map<String, String> _slashCommandDescriptions = {
  'compact': '压缩当前对话上下文',
  'clear': '清空当前会话消息',
  'reset': '重置当前会话',
  'debug': '查看调试信息',
  'status': '查看当前连接状态',
  'stop': '停止当前任务',
  'abort': '中止当前任务',
  'cancel': '取消当前任务',
};

const List<_InputTemplateItem> _defaultInputTemplates = [
  _InputTemplateItem(
    label: '解释这段代码',
    content: '请解释这段代码的功能和实现方式。',
    icon: Icons.lightbulb_outline_rounded,
  ),
  _InputTemplateItem(
    label: '添加注释',
    content: '请为这段代码添加清晰、简洁的注释。',
    icon: Icons.comment_outlined,
  ),
  _InputTemplateItem(
    label: '查找 Bug',
    content: '请帮我排查这段代码中可能存在的问题，并给出修复建议。',
    icon: Icons.bug_report_outlined,
  ),
  _InputTemplateItem(
    label: '性能优化',
    content: '请分析这段代码的性能瓶颈，并给出可落地的优化方案。',
    icon: Icons.speed_rounded,
  ),
  _InputTemplateItem(
    label: 'Code Review',
    content: '请帮我做一次代码审查，重点关注潜在 Bug、性能问题和可维护性。',
    icon: Icons.rate_review_outlined,
  ),
  _InputTemplateItem(
    label: '编写测试',
    content: '请为这段代码编写测试，覆盖主要场景和边界情况。',
    icon: Icons.science_outlined,
  ),
];

class _SlashCommandItem {
  const _SlashCommandItem({
    required this.command,
    this.description,
  });

  final String command;
  final String? description;
}

class _InputTemplateItem {
  const _InputTemplateItem({
    required this.label,
    required this.content,
    required this.icon,
  });

  final String label;
  final String content;
  final IconData icon;
}
