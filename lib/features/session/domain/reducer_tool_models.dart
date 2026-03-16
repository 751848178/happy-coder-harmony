part of 'reducer.dart';

enum ToolCallStatus {
  pending,
  approved,
  rejected,
  executing,
  completed,
  failed,
}

class ToolInfo {
  ToolInfo({
    required this.id,
    required this.name,
    required this.arguments,
    this.status,
    this.result,
    this.error,
    this.description,
  });

  final String id;
  final String name;
  final Map<String, dynamic> arguments;
  final ToolCallStatus? status;
  final String? result;
  final String? error;
  final String? description;

  factory ToolInfo.fromJson(Map<String, dynamic> json) {
    return ToolInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      arguments: _asStringMap(json['arguments']) ?? const <String, dynamic>{},
      status: json['status'] != null
          ? ToolCallStatus.values.firstWhere(
              (candidate) => candidate.name == json['status'] as String,
              orElse: () => ToolCallStatus.pending,
            )
          : null,
      result: json['result'] as String?,
      error: json['error'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'arguments': arguments,
      if (status != null) 'status': status!.name,
      if (result != null) 'result': result,
      if (error != null) 'error': error,
      if (description != null) 'description': description,
    };
  }

  ToolInfo copyWith({
    String? id,
    String? name,
    Map<String, dynamic>? arguments,
    ToolCallStatus? status,
    String? result,
    String? error,
    String? description,
  }) {
    return ToolInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      arguments: arguments ?? this.arguments,
      status: status ?? this.status,
      result: result ?? this.result,
      error: error ?? this.error,
      description: description ?? this.description,
    );
  }
}

class PermissionRequest {
  PermissionRequest({
    required this.tool,
    required this.arguments,
    this.reason,
  });

  final String tool;
  final Map<String, dynamic> arguments;
  final String? reason;

  factory PermissionRequest.fromJson(Map<String, dynamic> json) {
    return PermissionRequest(
      tool: json['tool'] as String? ?? '',
      arguments: _asStringMap(json['arguments']) ?? const <String, dynamic>{},
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tool': tool,
      'arguments': arguments,
      if (reason != null) 'reason': reason,
    };
  }
}

class TurnClose {
  TurnClose({
    this.abandoned = false,
    this.reason,
  });

  final bool abandoned;
  final String? reason;

  factory TurnClose.fromJson(Map<String, dynamic> json) {
    return TurnClose(
      abandoned: json['abandoned'] as bool? ?? false,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'abandoned': abandoned,
      if (reason != null) 'reason': reason,
    };
  }
}
