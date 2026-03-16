import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
import '../components/message_bubble.dart';
import '../components/message_input.dart';
import '../components/session_list.dart';
import '../components/sidebar.dart';

part 'chat_screen_layout.dart';
part 'chat_screen_messages.dart';

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
    if (!_scrollController.hasClients) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _toggleSessionList() {
    setState(() => _showSessionList = !_showSessionList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: Row(
        children: [
          if (!_showSessionList)
            Sidebar(
              onSessionTap: _handleSessionTap,
              onSettingsTap: () {},
            ),
          if (_showSessionList) _buildSessionListOverlay(),
          Expanded(child: _buildChatArea()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
}
