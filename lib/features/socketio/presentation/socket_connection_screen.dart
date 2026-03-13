import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/socket_service.dart';
import '../../../app/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';

/// Socket.IO 连接屏幕
///
/// 用于测试和监控 Socket.IO 连接状态
class SocketConnectionScreen extends ConsumerStatefulWidget {
  const SocketConnectionScreen({super.key});

  @override
  ConsumerState<SocketConnectionScreen> createState() => _SocketConnectionScreenState();
}

class _SocketConnectionScreenState extends ConsumerState<SocketConnectionScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _sessionIdController = TextEditingController();
  final List<SocketMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _subscribeToEvents();
    _sessionIdController.text = 'test-session-001';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _sessionIdController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _subscribeToEvents() {
    final socketNotifier = ref.read(socketStateProvider.notifier);

    socketNotifier.messageStream.listen((message) {
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    });
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

  Future<void> _connect() async {
    final authState = ref.read(authStateProvider);

    final credentials = authState.credentials;

    if (credentials == null) {
      Logger.error('Not authenticated');
      return;
    }

    await ref.read(socketStateProvider.notifier).initialize(
          machineId: credentials.machineId,
          token: credentials.token,
        );
  }

  Future<void> _disconnect() async {
    await ref.read(socketStateProvider.notifier).disconnect();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    final sessionId = _sessionIdController.text.trim();

    if (content.isEmpty || sessionId.isEmpty) {
      return;
    }

    await ref.read(socketStateProvider.notifier).sendMessage(
          sessionId: sessionId,
          content: content,
        );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final socketState = ref.watch(socketStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Socket.IO 连接'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 连接状态卡片
          _buildConnectionStatusCard(socketState),

          // 消息列表
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessageList(),
          ),

          // 消息输入区域
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(SocketState state) {
    late Color statusColor;
    late String statusText;
    late IconData statusIcon;
    bool isConnected = false;

    state.when(
      initial: () {
        statusColor = Colors.grey;
        statusText = '未连接';
        statusIcon = Icons.wifi_off;
      },
      connecting: () {
        statusColor = Colors.orange;
        statusText = '连接中...';
        statusIcon = Icons.sync;
      },
      connected: (socketId) {
        statusColor = Colors.green;
        statusText = '已连接: $socketId';
        statusIcon = Icons.wifi;
        isConnected = true;
      },
      reconnecting: (attempt) {
        statusColor = Colors.orange;
        statusText = '重连中... (第 $attempt 次)';
        statusIcon = Icons.sync_problem;
      },
      error: (message) {
        statusColor = Colors.red;
        statusText = '错误: $message';
        statusIcon = Icons.error;
      },
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.neutral300),
        ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '连接状态',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutral600,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (!isConnected)
            ElevatedButton.icon(
              onPressed: _connect,
              icon: const Icon(Icons.link, size: 18),
              label: const Text('连接'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.link_off, size: 18),
              label: const Text('断开'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 64, color: AppTheme.neutral400),
          const SizedBox(height: 16),
          Text(
            '暂无消息',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(SocketMessage message) {
    final isUser = message.type == SocketMessageType.user;
    final isSystem = message.type == SocketMessageType.system;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.brandColor
              : isSystem
                  ? Colors.grey.shade200
                  : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: !isUser && !isSystem
              ? Border.all(color: AppTheme.neutral300)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Row(
                children: [
                  Icon(
                    message.type == SocketMessageType.server
                        ? Icons.computer
                        : message.type == SocketMessageType.tool
                            ? Icons.build
                            : Icons.info,
                    size: 14,
                    color: AppTheme.neutral600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    message.type.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.neutral600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    message.timestamp?.toIso8601String().substring(11, 19) ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.neutral600,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            if (message.metadata != null && message.metadata!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Metadata: ${message.metadata}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isUser ? Colors.white70 : AppTheme.neutral600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.neutral300),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Session ID 输入
            TextField(
              controller: _sessionIdController,
              decoration: InputDecoration(
                labelText: '会话 ID',
                hintText: '输入会话 ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 消息输入
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
