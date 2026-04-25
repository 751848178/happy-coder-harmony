import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/encryption_repository.dart';
import '../../domain/encryption_service.dart';

part 'state_views.dart';
part 'has_keys.dart';
part 'feedback_views.dart';
part 'components.dart';

/// 加密设置屏幕
class EncryptionScreen extends ConsumerWidget {
  const EncryptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encryptionState = ref.watch(encryptionStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('加密设置'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _EncryptionStateView(state: encryptionState, ref: ref),
    );
  }
}
