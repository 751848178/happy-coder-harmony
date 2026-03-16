import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

part 'message_input_actions.dart';
part 'message_input_body.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    required this.sessionId,
    this.hintText = '输入消息...',
    this.maxLines = 5,
    this.enabled = true,
    this.onSendMessage,
    this.onAttachmentTap,
  });

  final String sessionId;
  final String hintText;
  final int maxLines;
  final bool enabled;
  final void Function(String message)? onSendMessage;
  final VoidCallback? onAttachmentTap;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  void _sendMessage() => _submitMessage(this);

  void _toggleExpand() => _toggleMessageInputExpand(this);

  @override
  Widget build(BuildContext context) => _buildMessageInputBody(this);
}
