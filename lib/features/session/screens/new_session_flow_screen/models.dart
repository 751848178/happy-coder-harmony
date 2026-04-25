part of 'new_session_flow_screen.dart';

class _MachineOption {
  const _MachineOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.host,
    required this.isOnline,
    this.homeDir,
  });

  final String id;
  final String title;
  final String subtitle;
  final String host;
  final bool isOnline;
  final String? homeDir;
}
