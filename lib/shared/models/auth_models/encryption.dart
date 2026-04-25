part of 'auth_models.dart';

enum EncryptionType {
  legacy,
  sodium,
  rsa,
}

extension EncryptionTypeExtension on EncryptionType {
  String toValue() => name;
}

extension EncryptionTypeString on String {
  EncryptionType toEncryptionType() {
    return EncryptionType.values.firstWhere(
      (candidate) => candidate.name == this,
      orElse: () => EncryptionType.legacy,
    );
  }
}

class Credentials {
  const Credentials({
    required this.token,
    required this.machineId,
    required this.encryptionKey,
    required this.encryptionType,
    this.publicKey,
    this.machineKey,
    this.secret,
  });

  final String token;
  final String machineId;
  final String encryptionKey;
  final EncryptionType encryptionType;
  final String? publicKey;
  final String? machineKey;
  final String? secret;

  factory Credentials.fromJson(Map<String, dynamic> json) {
    return Credentials(
      token: json['token'] as String? ?? '',
      machineId: json['machineId'] as String? ?? '',
      encryptionKey: json['encryptionKey'] as String? ?? '',
      encryptionType: (json['encryptionType'] as String?)?.toEncryptionType() ??
          EncryptionType.legacy,
      publicKey: json['publicKey'] as String?,
      machineKey: json['machineKey'] as String?,
      secret: json['secret'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'machineId': machineId,
      'encryptionKey': encryptionKey,
      'encryptionType': encryptionType.toValue(),
      if (publicKey != null) 'publicKey': publicKey,
      if (machineKey != null) 'machineKey': machineKey,
      if (secret != null) 'secret': secret,
    };
  }
}

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.githubUsername,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final String? githubUsername;
  final DateTime? createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      githubUsername: json['githubUsername'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  String toJson() {
    return '';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (bio != null) 'bio': bio,
      if (githubUsername != null) 'githubUsername': githubUsername,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  String toJsonString() {
    return toMap().toString();
  }
}
