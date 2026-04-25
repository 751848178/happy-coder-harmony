part of 'session_list.dart';

class _SessionsListContent extends StatelessWidget {
  const _SessionsListContent({
    required this.sessions,
    required this.onSessionTap,
    required this.onNewSessionTap,
  });

  final List<Session> sessions;
  final void Function(String sessionId)? onSessionTap;
  final VoidCallback? onNewSessionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onNewSessionTap != null)
          _SessionsNewButton(onPressed: onNewSessionTap!),
        Expanded(
          child: ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return SessionListItem(
                session: session,
                onTap: () => onSessionTap?.call(session.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SessionsNewButton extends StatelessWidget {
  const _SessionsNewButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add),
          label: const Text('新建会话'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
