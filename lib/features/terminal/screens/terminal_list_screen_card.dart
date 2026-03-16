part of 'terminal_list_screen.dart';

class _TerminalSessionCard extends StatelessWidget {
  const _TerminalSessionCard({
    required this.session,
    required this.onTap,
    required this.onDisconnect,
    this.onDetails,
    required this.onDelete,
  });

  final TerminalSession session;
  final VoidCallback onTap;
  final VoidCallback? onDisconnect;
  final VoidCallback? onDetails;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusIcon, statusLabel) =
        _terminalStatusPresentation(session.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildTerminalSessionLeading(statusColor, statusIcon),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTerminalSessionInfo(
                  session,
                  statusColor: statusColor,
                  statusLabel: statusLabel,
                ),
              ),
              _buildTerminalSessionMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalSessionLeading(Color statusColor, IconData statusIcon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(statusIcon, color: statusColor, size: 24),
    );
  }

  Widget _buildTerminalSessionInfo(
    TerminalSession session, {
    required Color statusColor,
    required String statusLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                session.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildTerminalLocationRow(session),
        const SizedBox(height: 6),
        Text(
          '空闲 ${session._durationString}',
          style: const TextStyle(fontSize: 12, color: AppTheme.neutral500),
        ),
      ],
    );
  }

  Widget _buildTerminalLocationRow(TerminalSession session) {
    return Row(
      children: [
        const Icon(Icons.computer, size: 14, color: AppTheme.neutral500),
        const SizedBox(width: 4),
        Text(
          session.machine,
          style: const TextStyle(fontSize: 13, color: AppTheme.neutral600),
        ),
        if (session.path != null) ...[
          const SizedBox(width: 8),
          const Icon(Icons.folder, size: 14, color: AppTheme.neutral500),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              session.path!,
              style: const TextStyle(fontSize: 13, color: AppTheme.neutral600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTerminalSessionMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'details':
            onDetails?.call();
          case 'disconnect':
            onDisconnect?.call();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18),
              SizedBox(width: 12),
              Text('详情'),
            ],
          ),
        ),
        if (session.status == TerminalStatus.active)
          const PopupMenuItem(
            value: 'disconnect',
            child: Row(
              children: [
                Icon(Icons.link_off, size: 18),
                SizedBox(width: 12),
                Text('断开连接'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
              SizedBox(width: 12),
              Text('删除', style: TextStyle(color: AppTheme.errorColor)),
            ],
          ),
        ),
      ],
    );
  }
}
