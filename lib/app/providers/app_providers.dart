import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/auth_models.dart';
import '../../shared/models/auth_state.dart';

import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/token_storage_service.dart';

import '../../features/encryption/domain/encryption_service.dart';
import '../../features/encryption/data/encryption_repository.dart';
import '../../features/socketio/domain/socket_service.dart';
import '../../features/socketio/data/socket_repository.dart';
import '../../features/session/domain/session_service.dart';
import '../../features/session/data/session_repository.dart';
import '../../features/session/domain/session_models.dart';
import '../../features/storage/domain/storage_service.dart';

import '../services/settings_service.dart';

// Re-export session models to avoid conflicts
export '../../features/session/domain/session_models.dart' show Session, Machine;
export '../../features/session/domain/reducer.dart' show ReducerMessage, ToolInfo, PermissionRequest, TurnClose, ToolCallStatus;

// Storage models
export '../../features/storage/domain/storage_models.dart'
    show SessionStorageModel, MessageStorageModel, SearchKeyword, StorageStats, CleanupResult;

// ========== 全局 Providers ==========

/// 认证状态 Provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = AuthRepository.instance;
  return AuthNotifier(repository);
});

/// 加密状态 Provider
final encryptionStateProvider =
    StateNotifierProvider<EncryptionNotifier, EncryptionState>((ref) {
  return EncryptionNotifier(EncryptionRepository.instance);
});

/// Socket 状态 Provider
final socketStateProvider =
    StateNotifierProvider<SocketNotifier, SocketState>((ref) {
  return SocketNotifier(SocketRepository.instance);
});

/// 会话状态 Provider
final sessionStateProvider =
    StateNotifierProvider<SessionServiceNotifier, SessionServiceState>((ref) {
  return SessionServiceNotifier(SessionRepository.instance);
});

/// 当前用户 Provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.credentials != null
      ? User(
          id: authState.credentials!.machineId,
          name: 'User',
          email: 'user@example.com',
          createdAt: DateTime.now(),
        )
      : null;
});

/// 当前会话 Provider
final currentSessionProvider = StateProvider<Session?>((ref) => null);

/// 是否已认证
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.credentials != null;
});

/// 设置服务 Provider
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final service = SettingsService.instance;
  // 初始化服务
  WidgetsBinding.instance.addPostFrameCallback((_) {
    service.init();
  });
  return service;
});

/// 设置状态 Provider
final settingsStateProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service);
});

/// 存储状态 Provider
final storageStateProvider =
    StateNotifierProvider<StorageNotifier, StorageState>((ref) {
  final service = StorageService.instance;
  return StorageNotifier(service);
});

// ========== 占位组件 - 这些将在后续实现 ==========

/// 404 屏幕
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, Object? error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('未找到页面')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.neutral600),
            const SizedBox(height: 16),
            Text(
              '页面不存在',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 占位屏幕
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 64, color: AppTheme.brandColor),
            const SizedBox(height: 16),
            Text(
              '功能开发中...',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
