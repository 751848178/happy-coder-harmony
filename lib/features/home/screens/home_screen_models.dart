part of 'home_screen.dart';

enum HomeTab {
  sessions,
  inbox,
  settings;

  static HomeTab fromRouteValue(String? value) {
    switch (value) {
      case 'inbox':
        return HomeTab.inbox;
      case 'settings':
        return HomeTab.settings;
      case 'sessions':
      default:
        return HomeTab.sessions;
    }
  }
}

class _ConnectionStatus {
  const _ConnectionStatus({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;
}

class _HomeMachineFilterOption {
  const _HomeMachineFilterOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.sessionCount,
    this.isOnline = false,
    this.isUnknown = false,
  });

  final String id;
  final String label;
  final String subtitle;
  final int sessionCount;
  final bool isOnline;
  final bool isUnknown;
}
