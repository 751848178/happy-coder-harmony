import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/services/api_service.dart';
import '../domain/kv_models.dart';

/// KV Storage Repository
///
/// 处理键值对存储的所有数据操作
class KVStorageRepository {
  final Dio _dio = ApiService.instance.dio;

  /// 获取单个键值
  Future<KVItem> getKV(String key) async {
    try {
      final response = await _dio.get('/v1/kv/$key');
      return KVItem.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 列出多个键值 (支持前缀过滤)
  Future<List<KVItem>> listKV({
    String? prefix,
    int limit = 100,
    String? cursor,
  }) async {
    try {
      final response = await _dio.get(
        '/v1/kv',
        queryParameters: {
          if (prefix != null) 'prefix': prefix,
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
        },
      );

      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {'items': response.data};

      final items = (responseData['items'] as List<dynamic>?)
              ?.map((item) => KVItem.fromJson(item as Map<String, dynamic>))
              .toList() ??

      return items ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 批量更新键值
  Future<void> batchUpdateKV(KVBatchUpdateRequest request) async {
    try {
      await _dio.post(
        '/v1/kv',
        data: request.toJson(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 设置单个键值
  Future<void> setKV(String key, String value, {int? version}) async {
    await batchUpdateKV(KVBatchUpdateRequest(
      mutations: [
        KVMutation(key: key, value: value, version: version),
      ],
    ));
  }

  /// 删除单个键值
  Future<void> deleteKV(String key) async {
    await batchUpdateKV(KVBatchUpdateRequest(
      mutations: [
        KVMutation(key: key, value: null),
      ],
    ));
  }

  /// 处理错误
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final dioError = error as DioException;
      if (dioError.type == DioExceptionType.connectionTimeout ||
          dioError.type == DioExceptionType.receiveTimeout ||
          dioError.type == DioExceptionType.sendTimeout) {
        return Exception('连接超时，请检查网络连接');
      }
      if (dioError.type == DioExceptionType.connectionError) {
        return Exception('网络连接失败，请检查网络设置');
      }
      if (dioError.type == DioExceptionType.badResponse) {
        final statusCode = dioError.response?.statusCode ?? '未知';
        return Exception('服务器错误($statusCode): ${dioError.message}');
      }
    }
    return Exception('请求失败: $error');
  }
}

/// KV Storage State Provider
///
/// 管理 KV 存储状态和缓存
class KVStorageNotifier extends StateNotifier<KVStorageState> {
  final KVStorageRepository _repository;
  final Map<String, KVItem> _cache = {};

  KVStorageNotifier(this._repository) : super(const KVStorageState.initial());

  /// 刷新 KV 存储
  Future<void> refresh() async {
    state = const KVStorageState.loading();
    try {
      final items = await _repository.listKV();
      // 更新缓存
      for (final item in items) {
        _cache[item.key] = item;
      }
      state = KVStorageState.loaded(items: _cache);
    } catch (e) {
      state = KVStorageState.error(e.toString());
    }
  }

  /// 获取单个键值
  Future<void> getKV(String key) async {
    // 先检查缓存
    if (_cache.containsKey(key)) {
      return;
    }

    try {
      final item = await _repository.getKV(key);
      _cache[key] = item;
      // 通知已加载
      state = KVStorageState.loaded(
        items: {...state.maybeWhen(loaded: (s) => s.items, orElse: () => _cache)},
      );
    } catch (e) {
      state = KVStorageState.error(e.toString());
    }
  }

  /// 设置键值
  Future<void> setKV(String key, String value, {int? version}) async {
    try {
      await _repository.setKV(key, value, version: version);

      // 更新缓存
      _cache[key] = KVItem(
        key: key,
        value: value,
        version: version ?? DateTime.now().millisecondsSinceEpoch,
      );

      state = KVStorageState.loaded(
        items: {...state.maybeWhen(loaded: (s) => s.items, orElse: () => _cache)},
      );
    } catch (e) {
      state = KVStorageState.error(e.toString());
    }
  }

  /// 删除键值
  Future<void> deleteKV(String key) async {
    try {
      await _repository.deleteKV(key);
      _cache.remove(key);

      state = KVStorageState.loaded(
        items: {...state.maybeWhen(loaded: (s) => s.items, orElse: () => _cache)},
      );
    } catch (e) {
      state = KVStorageState.error(e.toString());
    }
  }
}

/// KV Storage State
///
/// KV 存储状态枚举
class KVStorageState {
  final Map<String, KVItem> items;
  final String? error;

  const KVStorageState({
    this.items = const {},
    this.error,
  });

  const KVStorageState.initial() : items = const {}, error = null;

  const KVStorageState.loading() : items = const {}, error = null;

  const KVStorageState.loaded({required this.items, this.error = null});

  const KVStorageState.error(this.error) : items = const {}, error = error;

  bool get isLoading => items.isEmpty && error == null;

  bool get hasError => error != null;

  bool get isLoaded => items.isNotEmpty && error == null;

  T? when<T>({
    T Function() initial,
    required T Function(Map<String, KVItem>, String?) loaded,
    required T Function(String) error,
  }) {
    if (hasError) {
      return error(error!);
    }
    if (isLoaded) {
      return loaded(items, null);
    }
    return initial();
  }

  /// 获取单个键值
  KVItem? get(String key) => items[key];

  /// 检查键是否存在
  bool hasKey(String key) => items.containsKey(key);
}
