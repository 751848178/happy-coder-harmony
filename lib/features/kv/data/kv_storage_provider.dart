import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'kv_storage_repository.dart';
import '../presentation/kv_storage_notifier.dart';

/// KV Storage State Provider
///
/// 全局 KV 存储状态管理
final kvStorageStateProvider =
    StateNotifierProvider<KVStorageNotifier, KVStorageState>((ref) {
  return KVStorageNotifier(ref.watch(kvStorageRepositoryProvider));
});

/// KV Storage Repository Provider
///
/// 提供 KVStorageRepository 单例
final kvStorageRepositoryProvider = Provider<KVStorageRepository>((ref) {
  return KVStorageRepository();
});
