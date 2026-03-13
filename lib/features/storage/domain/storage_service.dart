import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/extensions.dart';
import '../../session/domain/session_models.dart' as session_models;
import '../data/hive_repository.dart';
import 'storage_models.dart';

/// 存储状态
class StorageState {
  final bool isLoading;
  final List<SessionStorageModel> sessions;
  final List<SessionStorageModel>? searchResults;
  final StorageStats? stats;
  final CleanupResult? cleanupResult;
  final String? errorMessage;

  const StorageState({
    this.isLoading = false,
    this.sessions = const [],
    this.searchResults,
    this.stats,
    this.cleanupResult,
    this.errorMessage,
  });

  StorageState copyWith({
    bool? isLoading,
    List<SessionStorageModel>? sessions,
    List<SessionStorageModel>? searchResults,
    StorageStats? stats,
    CleanupResult? cleanupResult,
    String? errorMessage,
  }) {
    return StorageState(
      isLoading: isLoading ?? this.isLoading,
      sessions: sessions ?? this.sessions,
      searchResults: searchResults ?? this.searchResults,
      stats: stats ?? this.stats,
      cleanupResult: cleanupResult ?? this.cleanupResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get hasError => errorMessage != null;
  bool get hasSessions => sessions.isNotEmpty;
  bool get hasSearchResults =>
      searchResults != null && searchResults!.isNotEmpty;
  int get sessionCount => sessions.length;
}

/// 存储状态 Notifier
class StorageNotifier extends StateNotifier<StorageState> {
  StorageNotifier(this._service) : super(const StorageState()) {
    initialize();
  }

  final StorageService _service;

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.initialize();
      final stats = await _service.getStats();
      state = state.copyWith(isLoading: false, stats: stats);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true);
    try {
      final sessions = await _service.getAllSessions();
      final stats = await _service.getStats();
      state =
          state.copyWith(isLoading: false, sessions: sessions, stats: stats);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> searchSessions(String query) async {
    try {
      final results = await _service.searchSessions(query);
      if (query.trim().isNotEmpty) {
        await _service.saveSearchKeyword(query);
      }
      state = state.copyWith(searchResults: results);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> togglePinSession(String id) async {
    try {
      await _service.togglePinSession(id);
      final sessions = await _service.getPinnedSessions();
      final stats = await _service.getStats();
      state = state.copyWith(sessions: sessions, stats: stats);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> toggleArchiveSession(String id) async {
    try {
      await _service.toggleArchiveSession(id);
      final sessions = await _service.getAllSessions();
      final stats = await _service.getStats();
      state = state.copyWith(sessions: sessions, stats: stats);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      await _service.deleteSession(id);
      final sessions = await _service.getAllSessions();
      final stats = await _service.getStats();
      state = state.copyWith(sessions: sessions, stats: stats);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> cleanupOldData() async {
    try {
      final result = await _service.cleanupOldData();
      final stats = await _service.getStats();
      state = state.copyWith(stats: stats, cleanupResult: result);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> clearAll() async {
    try {
      await _service.clearAll();
      state = const StorageState();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

/// 存储服务
///
/// 提供本地数据存储的高级接口
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  late HiveRepository _repository;

  /// 初始化服务
  Future<void> initialize() async {
    _repository = HiveRepository.instance;
    await _repository.initialize();
    Logger.info('Storage service initialized');
  }

  /// 同步在线数据到本地
  Future<void> syncFromOnline(List<Session> onlineSessions) async {
    for (final session in onlineSessions) {
      final existing = await _repository.getSession(session.id);

      if (existing == null) {
        // 新会话，创建本地存储
        final storageModel = SessionStorageModel(
          id: session.id,
          title: session.title,
          messages: session.messages.map((m) => m.toString()).toList(),
          createdAt: session.createdAt,
          updatedAt: session.updatedAt,
          lastAccessedAt: DateTime.now(),
          isPinned: false,
          isArchived: false,
          tag: session.tag,
          metadata: session.metadata,
        );
        await _repository.saveSession(storageModel);
      } else {
        // 更新现有会话
        await _repository.updateSessionAccessTime(session.id);
      }
    }
  }

  /// 缓存远端会话摘要，供启动时快速恢复列表
  Future<void> cacheRemoteSessions(
    List<session_models.Session> onlineSessions,
  ) async {
    for (final session in onlineSessions) {
      final existing = await _repository.getSession(session.id);
      final metadata = session.metadata == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(session.metadata!);
      if ((session.path ?? '').isNotEmpty) {
        metadata['path'] = session.path;
      }

      final storageModel = SessionStorageModel(
        id: session.id,
        title: session.title,
        messages: existing?.messages ?? const [],
        createdAt: session.createdAt,
        updatedAt: session.updatedAt,
        lastAccessedAt: existing?.lastAccessedAt ?? session.updatedAt,
        isPinned: existing?.isPinned ?? false,
        isArchived: existing?.isArchived ?? !session.active,
        tag: session.tag,
        metadata: metadata.isEmpty ? null : metadata,
      );
      await _repository.saveSession(storageModel);
    }
  }

  /// 获取所有会话
  Future<List<SessionStorageModel>> getAllSessions() async {
    return await _repository.getAllSessions();
  }

  /// 获取活跃会话
  Future<List<SessionStorageModel>> getActiveSessions() async {
    final sessions = await getAllSessions();
    return sessions.where((s) => !s.isArchived).toList();
  }

  /// 获取归档会话
  Future<List<SessionStorageModel>> getArchivedSessions() async {
    final sessions = await getAllSessions();
    return sessions.where((s) => s.isArchived).toList();
  }

  /// 获取置顶会话
  Future<List<SessionStorageModel>> getPinnedSessions() async {
    final sessions = await getAllSessions();
    return sessions.where((s) => s.isPinned).toList();
  }

  /// 搜索会话
  Future<List<SessionStorageModel>> searchSessions(String query) async {
    if (query.trim().isEmpty) {
      return await getAllSessions();
    }
    return await _repository.searchSessions(query);
  }

  /// 保存搜索关键词
  Future<void> saveSearchKeyword(String keyword) async {
    if (keyword.trim().isEmpty) return;
    await _repository.saveSearchKeyword(keyword);
  }

  /// 获取最近搜索关键词
  Future<List<SearchKeyword>> getRecentSearchKeywords({int limit = 10}) async {
    return await _repository.getRecentSearchKeywords(limit: limit);
  }

  /// 清除搜索关键词
  Future<void> clearSearchKeywords() async {
    await _repository.clearSearchKeywords();
  }

  /// 切换会话置顶
  Future<void> togglePinSession(String id) async {
    await _repository.togglePinSession(id);
  }

  /// 切换会话归档
  Future<void> toggleArchiveSession(String id) async {
    await _repository.toggleArchiveSession(id);
  }

  /// 删除会话
  Future<void> deleteSession(String id) async {
    await _repository.deleteSession(id);
  }

  /// 清理过期数据
  Future<CleanupResult> cleanupOldData(
      {Duration maxAge = const Duration(days: 30)}) async {
    return await _repository.cleanupOldData(maxAge: maxAge);
  }

  /// 清空所有数据
  Future<void> clearAll() async {
    await _repository.clearAll();
  }

  /// 获取存储统计
  Future<StorageStats> getStats() async {
    return await _repository.getStats();
  }

  /// 格式化存储大小
  String formatStorageSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (bytes < 1024 * 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    return '$bytes B';
  }
}
