part of 'message_input.dart';

Widget _buildMessageInputBody(_MessageInputState state) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: Column(
      children: [
        _buildMessageInputRow(state),
        if (!state._isExpanded) _buildMessageInputExpandButton(state),
        if (state._isExpanded) _buildMessageInputAuxiliaryActions(),
      ],
    ),
  );
}

Widget _buildMessageInputRow(_MessageInputState state) {
  return Container(
    decoration: BoxDecoration(
      color: AppTheme.neutral100,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: state._isExpanded ? AppTheme.brandColor : AppTheme.neutral300,
        width: state._isExpanded ? 2 : 1,
      ),
    ),
    child: Row(
      children: [
        if (state.widget.onAttachmentTap != null)
          IconButton(
            icon: Icon(Icons.attach_file, color: AppTheme.neutral600),
            onPressed:
                state.widget.enabled ? state.widget.onAttachmentTap : null,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
          ),
        Expanded(
          child: TextField(
            controller: state._controller,
            focusNode: state._focusNode,
            enabled: state.widget.enabled,
            maxLines: state._isExpanded ? state.widget.maxLines : 1,
            minLines: 1,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 15, height: 1.4),
            decoration: InputDecoration(
              hintText: state.widget.hintText,
              hintStyle: TextStyle(color: AppTheme.neutral500, fontSize: 15),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              isDense: true,
            ),
            onSubmitted: (_) => state._sendMessage(),
            onTap: () {
              if (!state._isExpanded) {
                state._toggleExpand();
              }
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: state.widget.enabled
                ? AppTheme.brandColor
                : AppTheme.neutral400,
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.send, color: Colors.white, size: 20),
            onPressed: state.widget.enabled ? state._sendMessage : null,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
          ),
        ),
      ],
    ),
  );
}

Widget _buildMessageInputExpandButton(_MessageInputState state) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: state.widget.enabled ? state._toggleExpand : null,
          icon: const Icon(Icons.expand_more,
              size: 16, color: AppTheme.brandColor),
          label: Text(
            '展开',
            style: TextStyle(color: AppTheme.brandColor, fontSize: 13),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        ),
      ],
    ),
  );
}

Widget _buildMessageInputAuxiliaryActions() {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        _AuxiliaryAction(icon: Icons.code, label: '代码'),
        _AuxiliaryAction(icon: Icons.mic, label: '语音'),
        _AuxiliaryAction(icon: Icons.insert_photo, label: '图片'),
        _AuxiliaryAction(icon: Icons.insert_drive_file, label: '文件'),
      ],
    ),
  );
}

class _AuxiliaryAction extends StatelessWidget {
  const _AuxiliaryAction({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.neutral100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.neutral300, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.neutral600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: AppTheme.neutral600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
