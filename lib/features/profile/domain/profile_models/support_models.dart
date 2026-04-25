part of 'profile_models.dart';

/// Environment variable with name and value
class EnvironmentVariable {
  final String name;
  final String value;

  const EnvironmentVariable({
    required this.name,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
      };

  factory EnvironmentVariable.fromJson(Map<String, dynamic> json) {
    return EnvironmentVariable(
      name: json['name'] as String,
      value: json['value'] as String,
    );
  }

  EnvironmentVariable copyWith({
    String? name,
    String? value,
  }) {
    return EnvironmentVariable(
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }
}

/// Profile compatibility settings for different agents
class ProfileCompatibility {
  final bool claude;
  final bool codex;
  final bool gemini;

  const ProfileCompatibility({
    this.claude = true,
    this.codex = true,
    this.gemini = true,
  });

  Map<String, dynamic> toJson() => {
        'claude': claude,
        'codex': codex,
        'gemini': gemini,
      };

  factory ProfileCompatibility.fromJson(Map<String, dynamic> json) {
    return ProfileCompatibility(
      claude: json['claude'] as bool? ?? true,
      codex: json['codex'] as bool? ?? true,
      gemini: json['gemini'] as bool? ?? true,
    );
  }

  ProfileCompatibility copyWith({
    bool? claude,
    bool? codex,
    bool? gemini,
  }) {
    return ProfileCompatibility(
      claude: claude ?? this.claude,
      codex: codex ?? this.codex,
      gemini: gemini ?? this.gemini,
    );
  }
}
