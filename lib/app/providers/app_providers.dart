import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/auth_models.dart';
import '../../shared/models/auth_state.dart';

import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/data/auth_repository.dart';

import '../../features/encryption/domain/encryption_service.dart';
import '../../features/encryption/data/encryption_repository.dart';
import '../../features/socketio/domain/socket_service.dart';
import '../../features/socketio/data/socket_repository.dart';
import '../../features/session/domain/session_service.dart';
import '../../features/session/data/session_repository.dart';
import '../../features/session/domain/session_models.dart';
import '../../features/storage/domain/storage_service.dart';

import '../services/settings_service.dart';

/// ============================================================================
/// 全局 Provider 配置文件
/// ============================================================================
/// 
/// 这个文件定义了应用中所有的全局状态 Provider
/// 
/// 【什么是 Provider？】
/// Provider 是 Riverpod 状态管理框架的核心概念，可以理解为：
/// - 一个全局的"数据容器"或"服务容器"
/// - 可以在应用的任何地方访问
/// - 当数据变化时，会自动通知所有监听的 Widget 重建
/// 
/// 【Provider 的类型】
/// 1. Provider - 只读的数据提供者（不会变化）
/// 2. StateProvider - 简单的可变状态（类似 useState）
/// 3. StateNotifierProvider - 复杂的状态管理（类似 Redux）
/// 4. FutureProvider - 异步数据提供者
/// 5. StreamProvider - 流式数据提供者
/// 
/// 【学习要点】
/// - ref.watch() - 监听 Provider，数据变化时重建 Widget
/// - ref.read() - 读取 Provider 的当前值，不监听变化
/// - ref.listen() - 监听 Provider 变化，执行副作用（如导航、弹窗）
/// ============================================================================

// Re-export session models to avoid conflicts
// 重新导出会话模型，避免在其他文件中重复导入
export '../../features/session/domain/session_models.dart'
    show Session, Machine;
export '../../features/session/domain/reducer.dart'
    show ReducerMessage, ToolInfo, PermissionRequest, TurnClose, ToolCallStatus;
export '../../features/session/domain/session_service.dart';

// Storage models
// 存储模型
export '../../features/storage/domain/storage_models.dart'
    show
        SessionStorageModel,
        MessageStorageModel,
        SearchKeyword,
        StorageStats,
        CleanupResult;

// ============================================================================
// 核心业务 Providers
// ============================================================================

/// 认证状态 Provider
/// 
/// 管理用户的登录状态、凭证信息等
/// 
/// 【使用示例】
/// ```dart
/// // 在 Widget 中监听认证状态
/// final authState = ref.watch(authStateProvider);
/// if (authState.credentials != null) {
///   // 用户已登录
/// }
/// 
/// // 执行登录操作
/// ref.read(authStateProvider.notifier).login(username, password);
/// ```
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = AuthRepository.instance;
  return AuthNotifier(repository);
});

/// 加密状态 Provider
/// 
/// 管理端到端加密的密钥、加密盒子等
final encryptionStateProvider =
    StateNotifierProvider<EncryptionNotifier, EncryptionState>((ref) {
  return EncryptionNotifier(EncryptionRepository.instance);
});

/// Socket 连接状态 Provider
/// 
/// 管理与服务器的 WebSocket 连接，用于实时通信
/// 
/// 【功能】
/// - 建立/断开 WebSocket 连接
/// - 接收服务器推送的消息
/// - 发送实时消息到服务器
final socketStateProvider =
    StateNotifierProvider<SocketNotifier, SocketState>((ref) {
  return SocketNotifier(SocketRepository.instance);
});

/// 会话状态 Provider（核心）
/// 
/// 这是应用最重要的 Provider 之一，管理所有会话相关的状态：
/// - 会话列表（所有对话）
/// - 会话消息（每个对话的消息历史）
/// - 机器列表（可用的开发环境）
/// 
/// 【数据流】
/// 1. 从本地缓存加载会话数据
/// 2. 从服务器同步最新数据
/// 3. 通过 WebSocket 接收实时更新
/// 4. 将变更保存到本地缓存
/// 
/// 【使用示例】
/// ```dart
/// // 获取所有会话
/// final sessionState = ref.watch(sessionStateProvider);
/// sessionState.whenOrNull(
///   ready: (sessions, messages, machines) {
///     // 显示会话列表
///   },
/// );
/// 
/// // 发送消息
/// ref.read(sessionStateProvider.notifier).sendMessage(
///   sessionId: 'xxx',
///   content: 'Hello',
/// );
/// ```
final sessionStateProvider =
    StateNotifierProvider<SessionServiceNotifier, SessionServiceState>((ref) {
  return SessionServiceNotifier(SessionRepository.instance);
});

// ============================================================================
// 派生 Providers（从其他 Provider 计算得出）
// ============================================================================

/// 当前用户 Provider
/// 
/// 从认证状态中提取当前登录的用户信息
/// 
/// 【特点】
/// - 这是一个派生 Provider，依赖于 authStateProvider
/// - 当 authStateProvider 变化时，这个 Provider 会自动重新计算
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
/// 
/// 存储用户当前正在查看的会话
/// 
/// 【使用场景】
/// - 在会话详情页设置当前会话
/// - 在其他页面获取当前会话信息
/// 
/// 【注意】
/// StateProvider 适合存储简单的状态，如当前选中项、开关状态等
final currentSessionProvider = StateProvider<Session?>((ref) => null);

/// 当前处于前台的会话详情页 ID
/// 
/// 【作用】
/// 当用户打开会话详情页时，记录该会话的 ID
/// 这样可以避免在后台进行不必要的数据同步和刷新
/// 
/// 【优化原理】
/// - 列表页在详情页打开时，不再刷新该会话的预览信息
/// - 避免在用户查看详情时，后台的状态变化导致界面抖动
final activeSessionDetailIdProvider = StateProvider<String?>((ref) => null);

/// 是否已认证 Provider
/// 
/// 简单的布尔值，表示用户是否已登录
/// 
/// 【使用场景】
/// - 路由守卫（未登录跳转到登录页）
/// - 条件渲染（显示/隐藏某些功能）
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.credentials != null;
});

// ============================================================================
// 应用配置 Providers
// ============================================================================

/// 设置服务 Provider
/// 
/// 管理应用的各种设置（主题、语言、显示选项等）
/// 
/// 【初始化时机】
/// 使用 addPostFrameCallback 确保在第一帧渲染后初始化
/// 避免在构建过程中执行耗时操作
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final service = SettingsService.instance;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    service.init();
  });
  return service;
});

/// 设置状态 Provider
/// 
/// 提供响应式的设置状态，当设置变化时自动通知 UI 更新
final settingsStateProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service);
});

/// 存储状态 Provider
/// 
/// 管理本地数据库的状态（缓存大小、清理操作等）
final storageStateProvider =
    StateNotifierProvider<StorageNotifier, StorageState>((ref) {
  final service = StorageService.instance;
  return StorageNotifier(service);
});

// ============================================================================
// UI 组件（占位）
// ============================================================================

/// 404 页面
/// 
/// 当用户访问不存在的路由时显示
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
