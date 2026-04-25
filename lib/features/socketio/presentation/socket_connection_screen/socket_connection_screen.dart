import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/extensions.dart';
import '../../domain/socket_service.dart';

part 'actions.dart';
part 'messages.dart';
part 'status.dart';

class SocketConnectionScreen extends ConsumerStatefulWidget {
  const SocketConnectionScreen({super.key});

  @override
  ConsumerState<SocketConnectionScreen> createState() =>
      _SocketConnectionScreenState();
}

class _SocketConnectionScreenState
    extends ConsumerState<SocketConnectionScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _sessionIdController = TextEditingController();
  final List<SocketMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  void _appendMessage(SocketMessage message) {
    setState(() => _messages.add(message));
  }

  void _clearMessages() {
    setState(_messages.clear);
  }

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
            onPressed: _clearMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConnectionStatusCard(socketState),
          Expanded(
            child: _messages.isEmpty ? _buildEmptyState() : _buildMessageList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }
}
