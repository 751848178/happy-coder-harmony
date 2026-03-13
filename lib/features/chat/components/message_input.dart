import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

/// 消息输入组件
///
/// 提供消息输入框和发送功能
class MessageInput extends ConsumerStatefulWidget {
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
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _controller.text.trim();

    if (message.isEmpty || !widget.enabled) {
      return;
    }

    widget.onSendMessage?.call(message);
    _controller.clear();

    // 如果已展开，收起输入框
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
      });
    }

    // 重新聚焦
    _focusNode.requestFocus();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // 输入框区域
          Container(
            decoration: BoxDecoration(
              color: AppTheme.neutral100,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isExpanded ? AppTheme.brandColor : AppTheme.neutral300,
                width: _isExpanded ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // 附件按钮
                if (widget.onAttachmentTap != null)
                  IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: AppTheme.neutral600,
                    ),
                    onPressed: widget.enabled
                        ? widget.onAttachmentTap
                        : null,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      minWidth: 40,
                    ),
                  ),
                // 文本输入框
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    maxLines: _isExpanded ? widget.maxLines : 1,
                    minLines: 1,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: AppTheme.neutral500,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    onTap: () {
                      if (!_isExpanded) {
                        _toggleExpand();
                      }
                    },
                  ),
                ),
                // 发送按钮
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? AppTheme.brandColor
                        : AppTheme.neutral400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: widget.enabled ? _sendMessage : null,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      minWidth: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 展开按钮（未展开时显示）
          if (!_isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: widget.enabled ? _toggleExpand : null,
                    icon: const Icon(
                      Icons.expand_more,
                      size: 16,
                      color: AppTheme.brandColor,
                    ),
                    label: Text(
                      '展开',
                      style: TextStyle(
                        color: AppTheme.brandColor,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 辅助功能按钮
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildAuxiliaryButton(
                    icon: Icons.code,
                    label: '代码',
                    onTap: () {},
                  ),
                  _buildAuxiliaryButton(
                    icon: Icons.mic,
                    label: '语音',
                    onTap: () {},
                  ),
                  _buildAuxiliaryButton(
                    icon: Icons.insert_photo,
                    label: '图片',
                    onTap: () {},
                  ),
                  _buildAuxiliaryButton(
                    icon: Icons.insert_drive_file,
                    label: '文件',
                    onTap: () {},
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 构建辅助按钮
  Widget _buildAuxiliaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppTheme.neutral100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.neutral300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: AppTheme.neutral600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.neutral600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
