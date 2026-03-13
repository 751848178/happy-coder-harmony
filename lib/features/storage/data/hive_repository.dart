import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../../shared/utils/extensions.dart';
import '../domain/storage_models.dart';

/// Hive 存储仓库
///
/// 处理会话和消息的本地存储
class HiveRepository {
  HiveRepository._();

  static final HiveRepository instance = HiveRepository._();

  late Box<SessionStorageModel> _sessionsBox;
  late Box<MessageStorageModel> _messagesBox;
  late Box<SearchKeyword> _keywordsBox;

  // Box 名称
  static const String _boxSessions = 'sessions';
  static const String _boxMessages = 'messages';
  static const String _boxKeywords = 'search_keywords';

  /// 状态流
  final _syncController = StreamController<SyncStatus>.broadcast();
  final _statsController = StreamController<StorageStats>.broadcast();

  Stream<SyncStatus> get syncStatusStream => _syncController.stream;
  Stream<StorageStats> get statsStream => _statsController.stream;

  /// 获取应用文档目录
  Future<Directory> _getAppDocDir() async {
    if (kIsWeb) {
      // Web 平台：使用临时目录
      final tempDir = Directory.systemTemp;
      return Directory('${tempDir.path}/happy_coder');
    } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return await getApplicationDocumentsDirectory();
    } else {
      // HarmonyOS 和其他平台：使用临时目录
      final tempDir = Directory.systemTemp;
      return Directory('${tempDir.path}/happy_coder');
    }
  }

  /// 初始化仓库
  Future<void> initialize() async {
    try {
      // 初始化 Hive
      if (kIsWeb) {
        await Hive.initFlutter();
      } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        await Hive.initFlutter();
      } else {
        // HarmonyOS：使用自定义路径初始化
        final dir = await _getAppDocDir();
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        Hive.init(dir.path); // Hive.init()是同步方法，不用await
      }

      // 注册适配器
      if (!Hive.isAdapterRegistered(SessionStorageModelAdapter().typeId)) {
        Hive.registerAdapter(SessionStorageModelAdapter());
      }
      if (!Hive.isAdapterRegistered(MessageStorageModelAdapter().typeId)) {
        Hive.registerAdapter(MessageStorageModelAdapter());
      }
      if (!Hive.isAdapterRegistered(SearchKeywordAdapter().typeId)) {
        Hive.registerAdapter(SearchKeywordAdapter());
      }

      // 打开 Box
      _sessionsBox = await Hive.openBox<SessionStorageModel>(_boxSessions);
      _messagesBox = await Hive.openBox<MessageStorageModel>(_boxMessages);
      _keywordsBox = await Hive.openBox<SearchKeyword>(_boxKeywords);

      Logger.info('Hive repository initialized');
      _statsController.add(await _computeStats());
    } catch (e) {
      Logger.error('Failed to initialize Hive: $e');
      rethrow;
    }
  }

  /// 计算存储统计
  Future<StorageStats> _computeStats() async {
    final sessionsCount = _sessionsBox.length;
    final messagesCount = _messagesBox.length;
    final archivedCount = _sessionsBox.values.where((s) => s.isArchived).length;
    final pinnedCount = _sessionsBox.values.where((s) => s.isPinned).length;

    // 估算存储大小
    final sizeBytes = await _calculateStorageSize();

    return StorageStats(
      totalSessions: sessionsCount,
      totalMessages: messagesCount,
      archivedSessions: archivedCount,
      pinnedSessions: pinnedCount,
      storageSizeBytes: sizeBytes,
    );
  }

  /// 获取存储统计
  Future<StorageStats> getStats() async {
    return await _computeStats();
  }

  /// 计算存储大小
  Future<int> _calculateStorageSize() async {
    try {
      final appDocDir = await _getAppDocDir();
      Directory storageDir = Directory('${appDocDir.path}/happy_coder');

      if (!await storageDir.exists()) {
        return 0;
      }

      int totalSize = 0;

      await for (final entity in storageDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        } else if (entity is Directory) {
          totalSize += await _calculateDirSize(entity);
        }
      }

      return totalSize;
    } catch (e) {
      Logger.error('Failed to calculate storage size: $e');
      return 0;
    }
  }

  /// 计算目录大小
  Future<int> _calculateDirSize(Directory dir) async {
    int totalSize = 0;

    try {
      await for (final entity in dir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        } else if (entity is Directory) {
          totalSize += await _calculateDirSize(entity);
        }
      }
    } catch (e) {
      Logger.error('Failed to calculate dir size: $e');
    }

    return totalSize;
  }

  /// 保存会话
  Future<void> saveSession(SessionStorageModel session) async {
    await _sessionsBox.put(session.id, session);
    _statsController.add(await _computeStats());
  }

  /// 获取会话
  Future<SessionStorageModel?> getSession(String id) async {
    return _sessionsBox.get(id);
  }

  /// 获取所有会话
  Future<List<SessionStorageModel>> getAllSessions() async {
    return _sessionsBox.values.toList()
      ..sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
  }

  /// 更新会话访问时间
  Future<void> updateSessionAccessTime(String id) async {
    final session = await getSession(id);
    if (session != null) {
      final updated = SessionStorageModel(
        id: session.id,
        title: session.title,
        messages: session.messages,
        createdAt: session.createdAt,
        updatedAt: session.updatedAt,
        lastAccessedAt: DateTime.now(),
        isPinned: session.isPinned,
        isArchived: session.isArchived,
        tag: session.tag,
        metadata: session.metadata,
      );
      await saveSession(updated);
    }
  }

  /// 切换会话置顶
  Future<void> togglePinSession(String id) async {
    final session = await getSession(id);
    if (session != null) {
      final updated = SessionStorageModel(
        id: session.id,
        title: session.title,
        messages: session.messages,
        createdAt: session.createdAt,
        updatedAt: session.updatedAt,
        lastAccessedAt: session.lastAccessedAt,
        isPinned: !session.isPinned,
        isArchived: session.isArchived,
        tag: session.tag,
        metadata: session.metadata,
      );
      await saveSession(updated);
    }
  }

  /// 切换会话归档
  Future<void> toggleArchiveSession(String id) async {
    final session = await getSession(id);
    if (session != null) {
      final updated = SessionStorageModel(
        id: session.id,
        title: session.title,
        messages: session.messages,
        createdAt: session.createdAt,
        updatedAt: session.updatedAt,
        lastAccessedAt: session.lastAccessedAt,
        isPinned: session.isPinned,
        isArchived: !session.isArchived,
        tag: session.tag,
        metadata: session.metadata,
      );
      await saveSession(updated);
    }
  }

  /// 删除会话
  Future<void> deleteSession(String id) async {
    await _sessionsBox.delete(id);
    _statsController.add(await _computeStats());
  }

  /// 搜索会话
  Future<List<SessionStorageModel>> searchSessions(String query) async {
    final lowerQuery = query.toLowerCase();
    return _sessionsBox.values
        .where((s) =>
            s.title.toLowerCase().contains(lowerQuery) ||
            s.messages.any((m) => m.toLowerCase().contains(lowerQuery)))
        .toList()
      ..sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
  }

  /// 保存搜索关键词
  Future<void> saveSearchKeyword(String keyword) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final searchKeyword = SearchKeyword(
      id: id,
      keyword: keyword,
      createdAt: DateTime.now(),
    );
    await _keywordsBox.put(id, searchKeyword);
  }

  /// 获取最近搜索关键词
  Future<List<SearchKeyword>> getRecentSearchKeywords({int limit = 10}) async {
    final keywords = _keywordsBox.values.toList();
    keywords.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return keywords.take(limit).toList();
  }

  /// 清除搜索关键词
  Future<void> clearSearchKeywords() async {
    await _keywordsBox.clear();
  }

  /// 清理过期数据
  Future<CleanupResult> cleanupOldData({Duration maxAge = const Duration(days: 30)}) async {
    final cutoff = DateTime.now().subtract(maxAge);

    int sessionsDeleted = 0;
    int messagesDeleted = 0;

    // 清理过期会话
    for (final key in _sessionsBox.keys) {
      final session = _sessionsBox.get(key);
      if (session != null && session.lastAccessedAt.isBefore(cutoff) && !session.isPinned) {
        await _sessionsBox.delete(key);
        sessionsDeleted++;
      }
    }

    // 清理过期消息
    for (final key in _messagesBox.keys) {
      final message = _messagesBox.get(key);
      if (message != null && message.createdAt.isBefore(cutoff)) {
        await _messagesBox.delete(key);
        messagesDeleted++;
      }
    }

    _statsController.add(await _computeStats());

    return CleanupResult(
      sessionsDeleted: sessionsDeleted,
      messagesDeleted: messagesDeleted,
    );
  }

  /// 清空所有数据
  Future<void> clearAll() async {
    await _sessionsBox.clear();
    await _messagesBox.clear();
    await _keywordsBox.clear();
    _statsController.add(const StorageStats());
  }

  /// 释放资源
  void dispose() {
    _syncController.close();
    _statsController.close();
  }
}

/// 同步状态
enum SyncStatus {
  idle,
  syncing,
  completed,
  error,
}
