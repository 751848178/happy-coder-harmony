import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_files_repository.dart';

/// Session Files State Provider
///
/// 全局会话文件状态管理
final sessionFilesStateProvider =
    StateNotifierProvider<SessionFilesNotifier, SessionFilesState>((ref) {
  return SessionFilesNotifier(SessionFilesRepository());
});

/// Session Files Repository Provider
///
/// 提供 SessionFilesRepository 单例
final sessionFilesRepositoryProvider = Provider<SessionFilesRepository>((ref) {
  return SessionFilesRepository();
});
