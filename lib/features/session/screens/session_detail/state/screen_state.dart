part of '../session_detail.dart';

/// ============================================================================
/// 会话详情页状态类（核心）
/// ============================================================================
/// 
/// 这是会话详情页的核心状态类，管理页面的所有状态和逻辑
/// 
/// 【继承关系】
/// - ConsumerState: Riverpod 的状态类，可以访问 Provider
/// - SingleTickerProviderStateMixin: 提供动画控制器（用于刷新图标旋转）
/// - WidgetsBindingObserver: 监听应用生命周期（前台/后台切换）
/// 
/// 【状态管理策略】
/// 1. 全局状态 - 通过 Riverpod Provider 管理（会话列表、用户信息等）
/// 2. 页面状态 - 通过 State 类的字段管理（滚动位置、输入框内容等）
/// 3. 细粒度状态 - 通过 ValueNotifier 管理（避免全屏重建）
/// 
/// 【性能优化】
/// - ValueNotifier + ValueListenableBuilder: 只重建需要更新的小部件
/// - 消息列表使用虚拟滚动: 只渲染可见区域的消息
/// - 分页加载: 不一次性加载所有历史消息
/// - 防抖和节流: 避免频繁的网络请求和状态更新
/// 
/// 【学习要点】
/// - late 关键字: 延迟初始化，在使用前必须赋值
/// - final: 不可变引用（但对象内容可以变化）
/// - ValueNotifier: 轻量级的状态管理，适合简单的响应式更新
/// - TextEditingController: 管理文本输入框的内容
/// - FocusNode: 管理输入框的焦点状态
/// - ScrollController: 管理滚动位置
/// ============================================================================
class _SessionScreenState extends ConsumerState<SessionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  
  // ==========================================================================
  // 【1. 基础控制器】
  // 这些是 Flutter 框架提供的标准控制器
  // ==========================================================================
  
  /// 消息输入框控制器
  /// 用于获取和设置输入框的文本内容
  final TextEditingController _messageController = TextEditingController();
  
  /// 输入框焦点控制器
  /// 用于控制输入框的焦点状态（是否激活、是否显示键盘）
  final FocusNode _messageFocusNode = FocusNode();
  
  /// 滚动控制器（自定义）
  /// 管理消息列表的滚动位置和行为
  final _ChatScrollController _scrollController = _ChatScrollController();
  
  /// 刷新图标动画控制器
  /// 用于刷新按钮的旋转动画
  late final AnimationController _refreshIconController = AnimationController(
    vsync: this,  // vsync 用于同步动画帧率，避免不必要的重绘
    duration: const Duration(milliseconds: 900),
  );
  
  // ==========================================================================
  // 【2. 工具调用状态】
  // 管理 AI 工具调用的状态（如代码执行、文件操作）
  // ==========================================================================
  
  /// 正在执行的工具操作 ID 集合
  /// 用于防止重复提交和显示加载状态
  final Set<String> _toolActionsInFlight = <String>{};
  
  /// 工具操作的待处理状态通知器
  /// Key: 工具调用 ID, Value: 是否正在处理
  final Map<String, ValueNotifier<bool>> _toolActionPendingNotifiers =
      <String, ValueNotifier<bool>>{};
  
  /// 已展开的对话轮次 ID 集合
  /// 用于记住用户展开了哪些对话轮次（折叠/展开状态）
  final Set<String> _expandedTurnIds = <String>{};
  
  /// 自动批准的工具 ID 集合
  /// 用户可以设置某些工具自动批准，不需要每次都确认
  final Set<String> _autoApprovedToolIds = <String>{};
  
  /// 对话轮次的章节行 ID 映射
  /// 用于快速定位到特定的对话轮次
  final Map<String, String> _turnSectionRowIds = <String, String>{};
  
  /// 对话轮次的回复行 ID 映射
  final Map<String, String> _turnReplyRowIds = <String, String>{};
  
  // ==========================================================================
  // 【3. 服务实例】
  // 这些是单例服务，提供特定的功能
  // ==========================================================================
  
  /// 消息队列服务
  /// 管理待发送的消息队列（支持批量发送、重试等）
  final SessionComposerQueueService _composerQueueService =
      SessionComposerQueueService.instance;
  
  /// 输入模板服务
  /// 管理用户自定义的输入模板（快捷短语）
  final SessionInputTemplateService _inputTemplateService =
      SessionInputTemplateService.instance;
  
  /// UI 状态服务
  /// 持久化 UI 状态（如折叠状态、滚动位置等）
  final SessionUiStateService _uiStateService = SessionUiStateService.instance;
  
  /// Provider 容器（可选）
  /// 用于在特殊情况下访问 Provider
  ProviderContainer? _providerContainer;
  
  // ==========================================================================
  // 【4. 自定义控制器】
  // 这些是页面特定的控制器，协调复杂的功能
  // ==========================================================================
  
  /// 消息列表展示器
  /// 负责将原始消息数据转换为 UI 可以渲染的格式
  late final _SessionScreenBodyPresenter _bodyPresenter =
      _SessionScreenBodyPresenter(this);
  
  /// 加载协调器
  /// 协调会话数据、消息历史、UI 状态等的加载
  late final _SessionScreenLoadCoordinator _loadCoordinator =
      _SessionScreenLoadCoordinator(this);
  
  /// 命令控制器
  /// 管理命令面板（快捷命令、模板等）
  late final _SessionScreenCommandController _commandController =
      _SessionScreenCommandController(this);
  
  /// 视口控制器
  /// 管理消息列表的视口（可见区域）和滚动行为
  late final _SessionViewportController _viewportController =
      _SessionViewportController(this);
  
  // ==========================================================================
  // 【5. 细粒度状态（ValueNotifier）】
  // 这些状态只影响小部件，使用 ValueNotifier 避免全屏重建
  // ==========================================================================
  
  /// 是否正在发送消息
  /// 用于显示发送按钮的加载状态
  final ValueNotifier<bool> _isSendingN = ValueNotifier(false);
  
  /// 是否正在中止操作
  /// 用于显示中止按钮的加载状态
  final ValueNotifier<bool> _isAbortingN = ValueNotifier(false);
  
  /// 是否正在刷新会话状态
  /// 用于显示刷新按钮的加载状态
  final ValueNotifier<bool> _isRefreshingSessionStateN = ValueNotifier(false);
  
  /// 是否正在同步所有消息
  /// 用于显示全量同步的加载状态
  final ValueNotifier<bool> _isSyncingAllMessagesN = ValueNotifier(false);
  
  /// 是否正在加载更早的消息
  /// 用于显示向上滚动加载的指示器
  final ValueNotifier<bool> _isLoadingOlderMessagesN = ValueNotifier(false);
  
  /// 是否正在加载更新的消息
  /// 用于显示向下滚动加载的指示器
  final ValueNotifier<bool> _isLoadingNewerMessagesN = ValueNotifier(false);
  
  /// 是否正在加载归档历史
  /// 用于显示从本地数据库加载历史消息的状态
  final ValueNotifier<bool> _isHydratingArchiveHistoryN = ValueNotifier(false);
  
  /// 已归档的消息数量
  /// 显示本地数据库中缓存的消息总数
  final ValueNotifier<int> _archivedMessageCountN = ValueNotifier(0);
  
  /// 归档历史是否完整
  /// 表示是否已经加载了所有历史消息到本地
  final ValueNotifier<bool> _archivedMessageHistoryCompleteN =
      ValueNotifier(false);
  
  /// 会话概览是否折叠
  /// 控制顶部会话信息面板的展开/折叠状态
  final ValueNotifier<bool> _sessionOverviewCollapsedN = ValueNotifier(true);
  
  /// 自定义输入模板列表
  /// 用户保存的快捷短语列表
  final ValueNotifier<List<SessionInputTemplate>> _customInputTemplatesN =
      ValueNotifier(const <SessionInputTemplate>[]);
  
  /// 折叠的对话轮次摘要列表
  /// 用于显示折叠对话的简短摘要
  final ValueNotifier<List<_CollapsedTurnSummary>> _collapsedTurnSummariesN =
      ValueNotifier(const <_CollapsedTurnSummary>[]);
  
  /// 消息视口是否就绪
  /// 表示消息列表是否已经完成初始化和布局
  final ValueNotifier<bool> _messageViewportReadyN = ValueNotifier(false);
  
  /// 消息交互是否启用
  /// 控制是否可以点击、长按消息（加载完成后启用）
  final ValueNotifier<bool> _messageInteractionsEnabledN = ValueNotifier(false);
  
  /// 是否抑制内容闪烁
  /// 在加载历史消息时，临时隐藏消息列表，避免滚动位置跳动
  final ValueNotifier<bool> _suppressContentFlickerN = ValueNotifier(false);

  // ==========================================================================
  // 【6. 便捷 Getter】
  // 提供简洁的访问方式，不会触发 Widget 重建
  // ==========================================================================
  
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
  
  /// 是否拥有完整的归档历史
  /// 判断本地缓存的消息数量是否达到预期
  bool get _hasCompleteArchivedMessageHistory {
    final expectedMessageCount = _resolveExpectedArchivedHistoryMessageCount();
    return expectedMessageCount > 0 &&
        _isArchivedMessageHistoryComplete &&
        _archivedMessageCount >= expectedMessageCount;
  }

  /// 是否有本地可访问的更早归档消息
  /// 判断是否可以从本地数据库加载更早的消息
  bool get _hasLocallyAccessibleOlderArchivedMessages =>
      _archivedMessageCount > 0 &&
      _hasOlderMessages &&
      _messageWindowStartIndex > 0 &&
      _messageWindowStartIndex <= _archivedMessageCount;
  
  /// 是否有本地可访问的更新归档消息
  bool get _hasLocallyAccessibleNewerArchivedMessages =>
      _archivedMessageCount > 0 &&
      _hasNewerMessages &&
      (_messageWindowStartIndex + _messages.length) < _archivedMessageCount;
  
  /// 是否可以跳转到最早的归档边界
  bool get _canJumpToEarliestArchivedBoundary =>
      _archivedMessageCount > 0 &&
      _messageWindowStartIndex > 0 &&
      _messageWindowStartIndex < _archivedMessageCount;
  
  bool get _sessionOverviewCollapsed => _sessionOverviewCollapsedN.value;
  bool get _messageViewportReady => _messageViewportReadyN.value;
  List<_CollapsedTurnSummary> get _collapsedTurnSummaries =>
      _collapsedTurnSummariesN.value;

  // ==========================================================================
  // 【7. 普通状态字段】
  // 这些状态不需要细粒度更新，直接使用字段即可
  // ==========================================================================
  
  /// 是否正在等待中止操作的远程确认
  bool _awaitingAbortRemoteSettle = false;
  
  /// 是否正在自动发送队列中的消息
  bool _isAutoSendingQueuedMessage = false;
  
  /// 是否已调度队列协调
  bool _queueReconcileScheduled = false;
  
  /// 是否折叠所有对话轮次
  bool _collapseAllTurns = false;
  
  /// 是否已滚动到最新消息
  bool _hasScrolledToLatest = false;
  
  /// 初始加载是否完成
  /// 用于在加载阶段跳过非必要的计算
  bool _initialLoadComplete = false;
  
  /// 用户是否向上滚动过
  /// 用于判断是否需要自动滚动到最新消息
  bool _userHasScrolledUp = false;
  
  /// 当前活跃的响应本地 ID
  /// 用于标识正在生成的 AI 回复
  String? _activeResponseLocalId;
  
  /// 手动思考状态覆盖
  /// 用户可以手动控制是否显示"思考中"指示器
  bool? _manualThinkingOverride;

  // ==========================================================================
  // 【8. 滚动相关状态（ValueNotifier）】
  // 这些状态在滚动时高频变化，使用 ValueNotifier 优化性能
  // ==========================================================================
  
  /// 是否可以滚动到顶部
  final ValueNotifier<bool> _canScrollToTopN = ValueNotifier(false);
  
  /// 是否可以滚动到底部
  final ValueNotifier<bool> _canScrollToBottomN = ValueNotifier(false);
  
  /// 是否接近底部
  /// 用于判断是否自动滚动到最新消息
  final ValueNotifier<bool> _isNearBottomN = ValueNotifier(true);
  
  /// 是否应该粘附到最新消息
  /// 当用户在底部时，新消息到来会自动滚动
  final ValueNotifier<bool> _shouldStickToLatestN = ValueNotifier(true);
  
  /// 是否有未读消息
  /// 用于显示"有新消息"提示
  final ValueNotifier<bool> _hasUnreadMessagesN = ValueNotifier(false);
  
  /// 置顶的对话轮次 ID
  /// 用于在滚动时保持某个对话轮次可见
  final ValueNotifier<String?> _stickyTurnIdN = ValueNotifier(null);
  
  /// 滚动操作按钮是否折叠
  final ValueNotifier<bool> _scrollActionsCollapsedN = ValueNotifier(false);
  
  /// 滚动操作按钮的垂直偏移
  final ValueNotifier<double> _scrollActionVerticalOffsetN = ValueNotifier(0.0);
  
  /// 滚动操作按钮的水平拖动距离
  final ValueNotifier<double> _scrollActionDragDxN = ValueNotifier(0.0);

  // 便捷 Getter
  bool get _canScrollToTop => _canScrollToTopN.value;
  bool get _canScrollToBottom => _canScrollToBottomN.value;
  bool get _isNearBottom => _isNearBottomN.value;
  bool get _shouldStickToLatest => _shouldStickToLatestN.value;
  String? get _stickyTurnId => _stickyTurnIdN.value;
  bool get _scrollActionsCollapsed => _scrollActionsCollapsedN.value;
  double get _scrollActionVerticalOffset => _scrollActionVerticalOffsetN.value;
  double get _scrollActionDragDx => _scrollActionDragDxN.value;
  bool get _cachedHasStickyCandidates => _bodyPresenter.hasStickyCandidates;
  
  // ==========================================================================
  // 【9. 队列协调状态】
  // 用于批量处理消息队列的状态快照
  // ==========================================================================
  
  Session? _queuedReconcileSession;
  List<ReducerMessage>? _queuedReconcileMessages;
  int _queuedReconcileQueueSize = 0;
  String? _queuedReconcileActiveResponseLocalId;
  bool _queuedReconcileIsSending = false;
  bool _queuedReconcileIsAutoSending = false;
  bool? _queuedReconcileManualThinkingOverride;
  
  /// 队列中的消息列表
  final ValueNotifier<List<QueuedComposerMessage>> _queuedMessagesN =
      ValueNotifier(const <QueuedComposerMessage>[]);
  List<QueuedComposerMessage> get _queuedMessages => _queuedMessagesN.value;

  // ==========================================================================
  // 【10. 消息状态（核心）】
  // 管理当前会话的消息列表
  // ==========================================================================
  
  /// 消息视图状态
  /// 包含消息列表、加载状态、总数等信息
  /// 
  /// 【重要】这是页面级的消息状态，不依赖全局 Provider
  /// 每个会话详情页维护自己的消息列表，通过 messageChangesFor() 订阅更新
  final ValueNotifier<_SessionMessageViewState> _messageViewStateN =
      ValueNotifier(const _SessionMessageViewState.initial());
  
  /// 当前显示的消息列表
  List<ReducerMessage> get _messages => _messageViewStateN.value.messages;
  
  /// 是否已加载消息
  bool get _hasLoadedMessages => _messageViewStateN.value.hasLoadedMessages;
  
  /// 消息总数
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
