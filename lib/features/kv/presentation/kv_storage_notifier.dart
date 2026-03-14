import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kv_storage_repository.dart';
import '../domain/kv_models.dart';

class KVStorageState {
  const KVStorageState({
    this.items = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  const KVStorageState.initial()
      : items = const {},
        isLoading = false,
        errorMessage = null;

  final Map<String, KVItem> items;
  final bool isLoading;
  final String? errorMessage;

  static const Object _unset = Object();

  KVStorageState copyWith({
    Map<String, KVItem>? items,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return KVStorageState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  bool get hasError => errorMessage != null;

  KVItem? getItem(String key) => items[key];

  bool hasKey(String key) => items.containsKey(key);
}

class KVStorageNotifier extends StateNotifier<KVStorageState> {
  KVStorageNotifier(this._repository) : super(const KVStorageState.initial());

  final KVStorageRepository _repository;
  final Map<String, KVItem> _cache = {};

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.listKV();
      _cache
        ..clear()
        ..addEntries(items.map((item) => MapEntry(item.key, item)));
      _emitLoadedState();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> getKV(String key) async {
    if (_cache.containsKey(key)) {
      _emitLoadedState();
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final item = await _repository.getKV(key);
      _cache[item.key] = item;
      _emitLoadedState();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> setKV(String key, String value, {int? version}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.setKV(key, value, version: version);
      _cache[key] = KVItem(
        key: key,
        value: value,
        version: version ?? DateTime.now().millisecondsSinceEpoch,
      );
      _emitLoadedState();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> deleteKV(String key) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteKV(key);
      _cache.remove(key);
      _emitLoadedState();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  void _emitLoadedState() {
    state = KVStorageState(
      items: Map<String, KVItem>.unmodifiable(_cache),
    );
  }
}
