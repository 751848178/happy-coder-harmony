class SessionBashRequest {
  const SessionBashRequest({
    required this.command,
    this.cwd,
    this.timeout,
  });

  final String command;
  final String? cwd;
  final int? timeout;

  Map<String, dynamic> toJson() {
    return {
      'command': command,
      if (cwd != null && cwd!.isNotEmpty) 'cwd': cwd,
      if (timeout != null) 'timeout': timeout,
    };
  }
}

class SessionBashResponse {
  const SessionBashResponse({
    required this.success,
    this.stdout = '',
    this.stderr = '',
    this.exitCode = -1,
    this.error,
  });

  final bool success;
  final String stdout;
  final String stderr;
  final int exitCode;
  final String? error;

  factory SessionBashResponse.fromJson(Map<String, dynamic> json) {
    return SessionBashResponse(
      success: json['success'] == true,
      stdout: json['stdout']?.toString() ?? '',
      stderr: json['stderr']?.toString() ?? '',
      exitCode: _toInt(json['exitCode']) ?? -1,
      error: json['error']?.toString(),
    );
  }
}

class SessionReadFileResponse {
  const SessionReadFileResponse({
    required this.success,
    this.content,
    this.error,
  });

  final bool success;
  final String? content;
  final String? error;

  factory SessionReadFileResponse.fromJson(Map<String, dynamic> json) {
    return SessionReadFileResponse(
      success: json['success'] == true,
      content: json['content']?.toString(),
      error: json['error']?.toString(),
    );
  }
}

class SessionRipgrepRequest {
  const SessionRipgrepRequest({
    required this.args,
    this.cwd,
  });

  final List<String> args;
  final String? cwd;

  Map<String, dynamic> toJson() {
    return {
      'args': args,
      if (cwd != null && cwd!.isNotEmpty) 'cwd': cwd,
    };
  }
}

class SessionRipgrepResponse {
  const SessionRipgrepResponse({
    required this.success,
    this.stdout = '',
    this.stderr = '',
    this.exitCode = -1,
    this.error,
  });

  final bool success;
  final String stdout;
  final String stderr;
  final int exitCode;
  final String? error;

  factory SessionRipgrepResponse.fromJson(Map<String, dynamic> json) {
    return SessionRipgrepResponse(
      success: json['success'] == true,
      stdout: json['stdout']?.toString() ?? '',
      stderr: json['stderr']?.toString() ?? '',
      exitCode: _toInt(json['exitCode']) ?? -1,
      error: json['error']?.toString(),
    );
  }
}

int? _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}
