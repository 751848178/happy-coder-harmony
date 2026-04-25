part of 'login_test_screen.dart';

enum LogType { info, success, warning, error }

class TestLog {
  const TestLog({
    required this.level,
    required this.step,
    required this.message,
    this.details,
    required this.timestamp,
  });

  final LogType level;
  final String step;
  final String message;
  final String? details;
  final DateTime timestamp;
}
