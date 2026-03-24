import '../../profile/domain/profile_models.dart' as profile_models;

part 'session_creation_options_agents.dart';
part 'session_creation_options_modes.dart';

class SessionModeOption {
  const SessionModeOption({
    required this.key,
    required this.label,
    this.description,
  });

  final String key;
  final String label;
  final String? description;

  factory SessionModeOption.fromMap(Map<dynamic, dynamic> map) {
    return SessionModeOption(
      key: map['code']?.toString() ?? map['key']?.toString() ?? 'default',
      label: map['value']?.toString() ?? map['name']?.toString() ?? '默认',
      description: map['description']?.toString(),
    );
  }
}
