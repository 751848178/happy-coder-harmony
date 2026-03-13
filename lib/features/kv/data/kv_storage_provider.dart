import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/kv_models.dart';
import 'kv_storage_repository.dart';

/// KV Storage State Provider
///
/// 全局 KV 存储状态管理
final kvStorageStateProvider =
    StateNotifierProvider<KVStorageState>((ref) {
  return KVStorageNotifier(KVStorageRepository());
});

/// KV Storage Repository Provider
///
/// 提供 KVStorageRepository 单例
final kvStorageRepositoryProvider = Provider<KVStorageRepository>((ref) {
  return KVStorageRepository();
});
