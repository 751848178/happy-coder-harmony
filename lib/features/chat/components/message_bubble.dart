import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
import '../../session/domain/reducer.dart';

part 'message_bubble_content.dart';
part 'message_bubble_tooling.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.isOwnMessage = false,
    this.onTap,
    this.onLongPress,
  });

  final ReducerMessage message;
  final bool isOwnMessage;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final alignment =
        isOwnMessage ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isOwnMessage ? AppTheme.brandColor : AppTheme.surface;
    final textColor = isOwnMessage ? Colors.white : AppTheme.textPrimary;
    final borderRadius = BorderRadius.only(
      topLeft:
          isOwnMessage ? const Radius.circular(16) : const Radius.circular(4),
      topRight:
          isOwnMessage ? const Radius.circular(4) : const Radius.circular(16),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
    );

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.only(
            left: isOwnMessage ? 48 : 0,
            right: isOwnMessage ? 0 : 48,
            bottom: 8,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildMessageContent(context, textColor),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatTimestamp(message.createdAt),
                  style: TextStyle(fontSize: 11, color: AppTheme.neutral500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
