part of 'enhanced_new_session_screen.dart';

class Machine {
  const Machine({
    required this.id,
    required this.name,
    required this.platform,
    required this.status,
  });

  final String id;
  final String name;
  final String platform;
  final MachineStatus status;
}

enum MachineStatus { online, offline, busy }

class ProfileSummary {
  const ProfileSummary({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final bool isDefault;
}
