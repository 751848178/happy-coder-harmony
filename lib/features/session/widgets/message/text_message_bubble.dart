import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/reducer.dart';
import 'session_message_action_types.dart';
import 'session_message_bubble_presenter.dart';
import 'markdown/markdown_message_content.dart';
import 'collapsed_text_preview.dart';

class TextMessageBubble extends StatefulWidget {
  const TextMessageBubble({
    required this.message,
    required this.isUser,
    required this.canCollapse,
    required this.startCollapsed,
    this.onMessageAction,
    this.onFilePathTap,
    required this.presenter,
  });
  final ReducerMessage message;
  final bool isUser;
  final bool canCollapse;
  final bool startCollapsed;
  final SessionMessageActionHandler? onMessageAction;
  final void Function(String)? onFilePathTap;
  final SessionMessageBubblePresenter presenter;

  @override
  State<TextMessageBubble> createState() => _TextMessageBubbleState();
}

class _TextMessageBubbleState extends State<TextMessageBubble> {
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.startCollapsed;
  }

  @override
  void didUpdateWidget(covariant TextMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _collapsed = widget.startCollapsed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.message.text;
    if (text == null || text.trim().isEmpty) return const SizedBox.shrink();

    final isThinking = widget.message.metadata?['outputType'] == 'thinking';
    final isOptimistic = widget.message.metadata?['optimistic'] == true;
    final bubbleColor = widget.isUser ? AppTheme.brandColor : AppTheme.surface;
    final textColor = widget.isUser ? Colors.white : AppTheme.textPrimary;

    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppTheme.radiusLg),
              topRight: const Radius.circular(AppTheme.radiusLg),
              bottomLeft:
                  Radius.circular(widget.isUser ? AppTheme.radiusLg : 4),
              bottomRight:
                  Radius.circular(widget.isUser ? 4 : AppTheme.radiusLg),
            ),
            border: Border.all(
                color:
                    widget.isUser ? AppTheme.brandColor : AppTheme.neutral200),
            boxShadow: widget.isUser ? null : AppTheme.shadowSm,
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (widget.canCollapse)
              Align(
                  alignment: Alignment.centerRight,
                  child: _collapseButton(textColor)),
            if (widget.canCollapse) const SizedBox(height: 6),
            Opacity(
                opacity: isThinking ? 0.84 : 1,
                child: _collapsed && widget.canCollapse
                    ? CollapsedTextPreview(
                        content: text,
                        textColor: textColor,
                        isUser: widget.isUser,
                        presenter: widget.presenter)
                    : MarkdownMessageContent(
                        content: text,
                        isUser: widget.isUser,
                        textColor: textColor,
                        onMessageAction: widget.onMessageAction,
                        onFilePathTap: widget.onFilePathTap)),
            if (widget.isUser && isOptimistic) ...[
              const SizedBox(height: 8),
              Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.9)))),
                const SizedBox(width: 6),
                Text('发送中',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9))),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _collapseButton(Color textColor) {
    final color = widget.isUser
        ? Colors.white.withValues(alpha: 0.92)
        : AppTheme.brandColor;
    return InkWell(
      onTap: () => setState(() => _collapsed = !_collapsed),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(_collapsed ? '展开' : '收起',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color))),
    );
  }
}
