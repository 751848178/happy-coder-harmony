part of '../session_detail.dart';

/// ============================================================================
/// 会话详情页 - 数据加载扩展
/// ============================================================================
/// 
/// 这个扩展包含了会话详情页的数据加载相关方法
/// 
/// 【加载内容】
/// 1. 非关键 UI 数据 - 输入模板、UI 状态等
/// 2. 消息队列 - 待发送的消息
/// 3. 会话数据 - 会话信息和消息历史
/// 4. 草稿恢复 - 恢复用户未发送的输入内容
/// 
/// 【学习要点】
/// - extension 是 Dart 的扩展方法，可以为现有类添加新方法
/// - Future.wait 可以并行执行多个异步操作，提高加载速度
/// - mounted 检查 Widget 是否还在树中，避免在已销毁的 Widget 上操作
/// ============================================================================
extension _SessionScreenStateLoad on _SessionScreenState {
  
  /// 加载非关键 UI 数据
  /// 
  /// 【加载内容】
  /// 1. 输入模板 - 用户保存的快捷短语
  /// 2. UI 状态 - 折叠状态、展开的对话轮次等
  /// 
  /// 【并行加载】
  /// 使用 Future.wait 同时加载多个数据，提高效率
  /// 
  /// 【mounted 检查】
  /// 异步操作完成后，必须检查 Widget 是否还在树中
  /// 如果用户已经离开页面，就不应该再更新状态
  Future<void> _loadNonCriticalUiData() async {
    // 并行加载输入模板和 UI 状态
    final results = await Future.wait([
      _inputTemplateService.loadTemplates(),  // 加载输入模板
      _uiStateService.get(widget.sessionId),  // 加载 UI 状态
    ]);
    
    // 检查 Widget 是否还在树中
    if (!mounted) {
      return;
    }
    
    // 解析加载结果
    final templates = results[0] as List<SessionInputTemplate>;
    final uiState = results[1] as SessionUiState;
    
    // 更新输入模板
    _customInputTemplatesN.value =
        List<SessionInputTemplate>.unmodifiable(templates);
    
    // 更新会话概览折叠状态
    _sessionOverviewCollapsedN.value = uiState.overviewCollapsed;
    
    // 更新对话轮次的折叠状态
    _updateState(() {
      _collapseAllTurns = uiState.collapseAllTurns;
      _expandedTurnIds
        ..clear()
        ..addAll(uiState.expandedTurnIds);
    });
  }

  /// 恢复消息输入框的草稿内容
  /// 
  /// 【功能】
  /// 当用户重新打开会话时，恢复之前未发送的输入内容
  /// 
  /// 【参数】
  /// - session: 会话对象，包含草稿内容
  /// - force: 是否强制恢复（即使输入框已有内容）
  /// 
  /// 【逻辑】
  /// 1. 如果输入框已有内容且不强制恢复，则跳过
  /// 2. 如果草稿内容与当前内容相同，则跳过
  /// 3. 否则，将草稿内容设置到输入框
  void _restoreComposerDraft(
    Session? session, {
    bool force = false,
  }) {
    final draft = session?.draft ?? '';
    
    // 如果输入框已有内容且不强制恢复，则跳过
    if (!force && _messageController.text.isNotEmpty) {
      return;
    }
    
    // 如果草稿内容与当前内容相同，则跳过
    if (_messageController.text == draft) {
      return;
    }
    
    // 设置草稿内容到输入框
    _setComposerText(draft);
  }

  /// 持久化会话 UI 状态
  /// 
  /// 【保存内容】
  /// - 会话概览是否折叠
  /// - 是否折叠所有对话轮次
  /// - 已展开的对话轮次 ID 列表
  /// 
  /// 【用途】
  /// 当用户下次打开会话时，可以恢复之前的 UI 状态
  Future<void> _persistSessionUiState() {
    return _uiStateService.update(
      widget.sessionId,
      overviewCollapsed: _sessionOverviewCollapsed,
      collapseAllTurns: _collapseAllTurns,
      expandedTurnIds: Set<String>.from(_expandedTurnIds),
    );
  }

  /// 加载队列中的待发送消息
  /// 
  /// 【功能】
  /// 从本地存储加载用户排队等待发送的消息
  /// 
  /// 【使用场景】
  /// - 用户添加了多条消息到队列，但还没有发送
  /// - 应用重启后，需要恢复队列中的消息
  Future<void> _loadQueuedComposerMessages() async {
    final queuedMessages = await _composerQueueService.get(widget.sessionId);
    
    // 检查 Widget 是否还在树中
    if (!mounted) {
      return;
    }
    
    // 更新队列消息列表
    _queuedMessagesN.value = queuedMessages;
  }

  /// 存储队列中的待发送消息
  /// 
  /// 【功能】
  /// 将待发送的消息保存到本地存储
  /// 
  /// 【参数】
  /// - queuedMessages: 待发送的消息列表
  /// 
  /// 【错误处理】
  /// 如果保存失败，显示错误提示
  Future<void> _storeQueuedComposerMessages(
    List<QueuedComposerMessage> queuedMessages,
  ) async {
    // 如果 Widget 还在树中，立即更新 UI
    if (mounted) {
      _queuedMessagesN.value = List<QueuedComposerMessage>.from(queuedMessages);
    }
    
    // 保存到本地存储
    try {
      await _composerQueueService.replace(widget.sessionId, queuedMessages);
    } catch (error) {
      // 如果 Widget 已销毁，不显示错误提示
      if (!mounted) {
        return;
      }
      
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新待发送消息失败: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  /// 加载会话数据（核心方法）
  /// 
  /// 【功能】
  /// 这是页面初始化时调用的核心方法，负责加载所有必要的数据
  /// 
  /// 【委托】
  /// 实际的加载逻辑由 _loadCoordinator（加载协调器）处理
  /// 协调器会按照正确的顺序加载：
  /// 1. 会话基本信息
  /// 2. 消息历史（分页加载）
  /// 3. UI 状态
  /// 4. 队列消息
  /// 
  /// 【为什么使用协调器？】
  /// 加载逻辑复杂，涉及多个步骤和依赖关系
  /// 使用协调器可以：
  /// - 集中管理加载逻辑
  /// - 处理加载失败和重试
  /// - 优化加载顺序和并发
  Future<void> _loadSessionData() => _loadCoordinator.loadSessionData();
}
