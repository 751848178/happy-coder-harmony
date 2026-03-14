import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../app/providers/app_providers.dart';
import '../../../shared/utils/extensions.dart';

import '../components/sidebar.dart';
import '../components/message_bubble.dart';
import '../components/message_input.dart';
import '../components/session_list.dart';

/// 聊天屏幕
///
/// 主聊天界面，包含侧边栏、消息列表和输入框
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    this.sessionId,
  });

  final String? sessionId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showSessionList = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _toggleSessionList() {
    setState(() {
      _showSessionList = !_showSessionList;
    });
  }

  void _handleSendMessage(String message) {
    if (widget.sessionId != null) {
      final sessionNotifier = ref.read(sessionStateProvider.notifier);
      sessionNotifier.sendMessage(
        sessionId: widget.sessionId!,
        content: message,
      );
      _scrollToBottom();
    }
  }

  void _handleSessionTap(String sessionId) {
    // 更新当前会话
    ref.read(currentSessionProvider.notifier).state =
        ref.read(sessionStateProvider).whenOrNull(
              ready: (sessions, _, __) => sessions[sessionId],
            );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: Row(
        children: [
          // 侧边栏
          if (!_showSessionList)
            Sidebar(
              onSessionTap: _handleSessionTap,
              onSettingsTap: () {},
            ),

          // 会话列表覆盖层
          if (_showSessionList) _buildSessionListOverlay(context),

          // 主聊天区域
          Expanded(
            child: _buildChatArea(context),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  /// 构建会话列表覆盖层
  Widget _buildSessionListOverlay(BuildContext context) {
    return Container(
      width: 320,
      color: AppTheme.surface,
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.neutral300,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _toggleSessionList,
                ),
                const SizedBox(width: 8),
                Text(
                  '会话列表',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('新建'),
                ),
              ],
            ),
          ),
          // 会话列表
          Expanded(
            child: SessionsList(
              onSessionTap: _handleSessionTap,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建聊天区域
  Widget _buildChatArea(BuildContext context) {
    if (widget.sessionId == null) {
      return _buildWelcomeView(context);
    }

    return Column(
      children: [
        // 顶部标题栏
        _buildAppBar(context),

        // 消息列表
        Expanded(
          child: _buildMessageList(context),
        ),

        // 输入框
        _buildInputArea(context),
      ],
    );
  }

  /// 构建欢迎视图
  Widget _buildWelcomeView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppTheme.neutral300,
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to ${AppConfig.appName}',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '选择一个会话开始对话',
            style: TextStyle(
              color: AppTheme.neutral600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _toggleSessionList,
            icon: const Icon(Icons.list),
            label: const Text('查看会话列表'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建顶部标题栏
  Widget _buildAppBar(BuildContext context) {
    final sessionState = ref.watch(sessionStateProvider);
    final session = sessionState.whenOrNull(
      ready: (sessions, sessionMessages, machines) =>
          sessions[widget.sessionId],
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.neutral300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 会话切换按钮
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _toggleSessionList,
          ),
          const SizedBox(width: 12),
          // 会话标题
          Expanded(
            child: Text(
              session?.title ?? 'New Chat',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 更多操作按钮
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onSelected: (value) {
              _handleMenuSelection(context, value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 12),
                    Text('重命名'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.push_pin_outlined, size: 18),
                    SizedBox(width: 12),
                    Text('置顶'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 3,
                child: Row(
                  children: [
                    Icon(Icons.archive_outlined, size: 18),
                    SizedBox(width: 12),
                    Text('归档'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 4,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 12),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 处理菜单选择
  void _handleMenuSelection(BuildContext context, int value) {
    switch (value) {
      case 1: // 重命名
        Logger.info('Rename session');
        break;
      case 2: // 置顶
        Logger.info('Pin session');
        break;
      case 3: // 归档
        Logger.info('Archive session');
        break;
      case 4: // 删除
        _showDeleteDialog(context);
        break;
    }
  }

  /// 显示删除对话框
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: const Text('确认删除此会话吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Logger.info('Session deleted');
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 构建消息列表
  Widget _buildMessageList(BuildContext context) {
    // 从 sessionStateProvider 获取消息
    final sessionState = ref.watch(sessionStateProvider);

    List<ReducerMessage> messages = [];

    sessionState.whenOrNull(
      ready: (sessions, sessionMessages, machines) {
        final currentMessages = sessionMessages[widget.sessionId];
        if (currentMessages != null) {
          messages = currentMessages.messages;
        }
      },
    );

    // 如果没有消息，显示欢迎提示
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_outlined,
              size: 64,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              '发送第一条消息开始对话',
              style: TextStyle(
                color: AppTheme.neutral600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_outlined,
              size: 64,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              '发送第一条消息开始对话',
              style: TextStyle(
                color: AppTheme.neutral600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MessageBubble(
            message: message,
            isOwnMessage: index % 2 == 1,
          ),
        );
      },
    );
  }

  /// 构建输入区域
  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(
            color: AppTheme.neutral300,
            width: 1,
          ),
        ),
      ),
      child: MessageInput(
        sessionId: widget.sessionId!,
        hintText: '输入消息...',
        maxLines: 5,
        onSendMessage: _handleSendMessage,
      ),
    );
  }

  /// 构建浮动操作按钮
  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: _toggleSessionList,
      backgroundColor: AppTheme.brandColor,
      child: const Icon(Icons.list),
    );
  }
}
