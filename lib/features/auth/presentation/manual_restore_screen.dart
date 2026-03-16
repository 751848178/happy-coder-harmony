import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
import '../data/auth_repository.dart';

part 'manual_restore_screen_actions.dart';
part 'manual_restore_screen_body.dart';
part 'manual_restore_screen_link_parsing.dart';
part 'manual_restore_screen_secret_processing.dart';

class ManualRestoreScreen extends ConsumerStatefulWidget {
  const ManualRestoreScreen({super.key, this.authUrl});

  final String? authUrl;

  @override
  ConsumerState<ManualRestoreScreen> createState() =>
      _ManualRestoreScreenState();
}

class _ManualRestoreScreenState extends ConsumerState<ManualRestoreScreen> {
  final TextEditingController _secretKeyController = TextEditingController();
  bool _isRestoring = false;
  String? _errorMessage;
  bool _showSecret = false;

  @override
  void initState() {
    super.initState();
    final authUrl = widget.authUrl?.trim();
    if (authUrl != null && authUrl.isNotEmpty) {
      _secretKeyController.text = authUrl;
    }
    _secretKeyController.addListener(_handleSecretChanged);
    if (authUrl != null && authUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoRestore());
    }
  }

  @override
  void dispose() {
    _secretKeyController.removeListener(_handleSecretChanged);
    _secretKeyController.dispose();
    super.dispose();
  }

  void _handleSecretChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  void _tryAutoRestore() {
    if (!mounted) {
      return;
    }
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      _restoreAccount();
    }
  }

  void _clearSecret() => _secretKeyController.clear();

  void _toggleSecretVisibility() =>
      _updateView(() => _showSecret = !_showSecret);

  Future<void> _restoreAccount() => _restoreManualAccount(this);

  @override
  Widget build(BuildContext context) => _buildManualRestoreScaffold(this);
}
