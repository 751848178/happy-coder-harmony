part of 'session_screen.dart';

extension _SessionScreenViewCommandPanels on _SessionScreenState {
  Widget _buildSlashCommandPanel(List<_SlashCommandItem> commands) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neutral200),
        boxShadow: AppTheme.shadowSm,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: commands.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: AppTheme.neutral200,
        ),
        itemBuilder: (context, index) {
          final item = commands[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.code_rounded, size: 18),
            title: Text(
              '/${item.command}',
              style: const TextStyle(
                fontFamily: AppTheme.fontFamilyMono,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: item.description == null
                ? null
                : Text(
                    item.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
            onTap: () {
              final value = '/${item.command} ';
              _messageController.value = TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInputTemplatePanel(List<_InputTemplateItem> templates) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neutral200),
        boxShadow: AppTheme.shadowSm,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: templates.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: AppTheme.neutral200,
        ),
        itemBuilder: (context, index) {
          final item = templates[index];
          return ListTile(
            dense: true,
            leading: Icon(item.icon, size: 18, color: AppTheme.brandColor),
            title: Text(
              item.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              item.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              _messageController.value = TextEditingValue(
                text: item.content,
                selection: TextSelection.collapsed(offset: item.content.length),
              );
            },
          );
        },
      ),
    );
  }


}
