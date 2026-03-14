import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profiles_repository.dart';
import '../presentation/profiles_notifier.dart';

/// Profiles State Provider
///
/// 全局 AI 配置档案状态管理
final profilesStateProvider =
    StateNotifierProvider<ProfilesNotifier, ProfilesState>((ref) {
  return ProfilesNotifier(ref.watch(profilesRepositoryProvider));
});

/// Profiles Repository Provider
///
/// 提供 ProfilesRepository 单例
final profilesRepositoryProvider = Provider<ProfilesRepository>((ref) {
  return ProfilesRepository();
});
