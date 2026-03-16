import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
import '../data/auth_repository.dart';
import '../data/token_storage_service.dart';

part 'login_test_screen_actions.dart';
part 'login_test_screen_models.dart';
part 'login_test_screen_support.dart';
part 'login_test_screen_views.dart';

class LoginTestScreen extends ConsumerStatefulWidget {
  const LoginTestScreen({super.key});

  @override
  ConsumerState<LoginTestScreen> createState() => _LoginTestScreenState();
}

class _LoginTestScreenState extends ConsumerState<LoginTestScreen> {
  final TextEditingController _linkController = TextEditingController();
  final List<TestLog> _logs = [];
  bool _isRunning = false;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  void _setRunning(bool value) => _updateView(() => _isRunning = value);

  void _clearLogs() => _updateView(_logs.clear);

  void _addLog(LogType level, String step, String message, String? details) {
    _updateView(() {
      _logs.add(
        TestLog(
          level: level,
          step: step,
          message: message,
          details: details,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _runFullTest() => _runLoginFullTest(this);

  void _testParseLink() => _testLoginLinkParsing(this);

  Future<void> _testStorage() => _testLoginStorage(this);

  Future<void> _clearCredentials() => _clearLoginCredentials(this);

  @override
  Widget build(BuildContext context) => _buildLoginTestScaffold(this);
}
