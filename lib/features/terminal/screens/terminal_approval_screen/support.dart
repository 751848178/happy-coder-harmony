part of 'terminal_approval_screen.dart';

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Icon(icon, size: 18, color: AppTheme.neutral500),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.neutral600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

class TerminalApprovalLinkParser {
  static TerminalApprovalRequest? parse(String url) {
    if (!url.startsWith('happy://terminal?')) {
      return null;
    }

    final uri = Uri.parse(url);
    final params = uri.queryParameters;
    final sessionId = params['sessionId'] ?? params['session'];

    if (sessionId == null) {
      return null;
    }

    return TerminalApprovalRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      machine: params['machine'] ?? params['host'] ?? 'localhost',
      path: params['path'] ?? params['dir'] ?? '/home/user',
      command: params['command'],
      requestingApp: params['app'] ?? params['from'] ?? 'Unknown App',
      requestedAt: DateTime.now(),
    );
  }
}
