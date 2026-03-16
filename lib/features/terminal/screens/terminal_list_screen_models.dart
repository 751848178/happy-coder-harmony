part of 'terminal_list_screen.dart';

/// Terminal status
enum TerminalStatus {
  active,
  idle,
  disconnected,
  error,
}

/// Terminal session model
class TerminalSession {
  const TerminalSession({
    required this.id,
    required this.name,
    required this.machine,
    this.path,
    this.status = TerminalStatus.idle,
    required this.createdAt,
    this.lastActivity,
    this.pid,
    this.exitCode,
  });

  final String id;
  final String name;
  final String machine;
  final String? path;
  final TerminalStatus status;
  final DateTime createdAt;
  final DateTime? lastActivity;
  final String? pid;
  final int? exitCode;

  Duration get age => DateTime.now().difference(createdAt);

  Duration get idle {
    if (lastActivity == null) {
      return age;
    }
    return DateTime.now().difference(lastActivity!);
  }

  String get _durationString {
    final duration = idle;
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    }
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    }
    if (duration.inHours < 24) {
      return '${duration.inHours}h';
    }
    return '${duration.inDays}d';
  }

  TerminalSession copyWith({
    String? id,
    String? name,
    String? machine,
    String? path,
    TerminalStatus? status,
    DateTime? createdAt,
    DateTime? lastActivity,
    String? pid,
    int? exitCode,
  }) {
    return TerminalSession(
      id: id ?? this.id,
      name: name ?? this.name,
      machine: machine ?? this.machine,
      path: path ?? this.path,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      pid: pid ?? this.pid,
      exitCode: exitCode ?? this.exitCode,
    );
  }
}
