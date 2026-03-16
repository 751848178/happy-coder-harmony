part of 'session_models.dart';

/// 机器模型
class Machine {
  final String id;
  final int? seq;
  final String name;
  final String? platform;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool active;
  final DateTime? activeAt;
  final Map<String, dynamic>? metadata;
  final int? metadataVersion;

  const Machine({
    required this.id,
    required this.name,
    this.platform,
    required this.createdAt,
    this.seq,
    this.updatedAt,
    this.active = true,
    this.activeAt,
    this.metadata,
    this.metadataVersion,
  });

  Machine copyWith({
    String? id,
    int? seq,
    String? name,
    String? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? active,
    DateTime? activeAt,
    Map<String, dynamic>? metadata,
    int? metadataVersion,
  }) {
    return Machine(
      id: id ?? this.id,
      seq: seq ?? this.seq,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      active: active ?? this.active,
      activeAt: activeAt ?? this.activeAt,
      metadata: metadata ?? this.metadata,
      metadataVersion: metadataVersion ?? this.metadataVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (seq != null) 'seq': seq,
      'name': name,
      if (platform != null) 'platform': platform,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'active': active,
      if (activeAt != null) 'activeAt': activeAt!.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
      if (metadataVersion != null) 'metadataVersion': metadataVersion,
    };
  }

  factory Machine.fromJson(Map<String, dynamic> json) {
    final metadata = _asStringMap(json['metadata']);
    final machineId = _firstNonEmptyString([
          json['id'],
          json['machineId'],
          json['machine_id'],
        ]) ??
        '';
    return Machine(
      id: machineId,
      seq: _parseInt(json['seq']),
      name: _firstNonEmptyString([
            json['name'],
            json['displayName'],
            json['display_name'],
          ]) ??
          metadata?['displayName']?.toString() ??
          metadata?['host']?.toString() ??
          machineId,
      platform: _firstNonEmptyString([
        json['platform'],
        json['os'],
        metadata?['platform'],
      ]),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']) ??
          DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      active: _parseBool(json['active']) ?? true,
      activeAt: _parseDateTime(json['activeAt'] ?? json['active_at']),
      metadata: metadata,
      metadataVersion:
          _parseInt(json['metadataVersion'] ?? json['metadata_version']),
    );
  }
}
