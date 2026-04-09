import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../../shared/utils/extensions.dart';
import '../domain/storage_models.dart';

part 'hive_repository_storage.dart';
part 'hive_repository_message_archive.dart';

class HiveRepository {
  HiveRepository._();

  static final HiveRepository instance = HiveRepository._();
  static const String _boxSessions = 'sessions';
  static const String _boxMessages = 'messages';
  static const String _boxKeywords = 'search_keywords';

  late Box<SessionStorageModel> _sessionsBox;
  late Box<MessageStorageModel> _messagesBox;
  late Box<SearchKeyword> _keywordsBox;

  final _syncController = StreamController<SyncStatus>.broadcast();
  final _statsController = StreamController<StorageStats>.broadcast();

  Stream<SyncStatus> get syncStatusStream => _syncController.stream;
  Stream<StorageStats> get statsStream => _statsController.stream;

  Future<Directory> _getAppDocDir() async {
    if (kIsWeb) {
      return Directory('${Directory.systemTemp.path}/happy_coder');
    }
    if (Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux) {
      return getApplicationDocumentsDirectory();
    }
    return Directory('${Directory.systemTemp.path}/happy_coder');
  }

  Future<void> initialize() async {
    try {
      await _initializeHive();
      await _openBoxes();
      Logger.info('Hive repository initialized');
      _statsController.add(await _computeStats());
    } catch (e) {
      Logger.error('Failed to initialize Hive: $e');
      rethrow;
    }
  }

  Future<StorageStats> _computeStats() async {
    final sizeBytes = await _calculateStorageSize();
    return StorageStats(
      totalSessions: _sessionsBox.length,
      totalMessages: _messagesBox.length,
      archivedSessions: _sessionsBox.values.where((s) => s.isArchived).length,
      pinnedSessions: _sessionsBox.values.where((s) => s.isPinned).length,
      storageSizeBytes: sizeBytes,
    );
  }

  Future<StorageStats> getStats() => _computeStats();

  Future<void> saveSession(SessionStorageModel session) async {
    await _sessionsBox.put(session.id, session);
    _statsController.add(await _computeStats());
  }

  Future<SessionStorageModel?> getSession(String id) async =>
      _sessionsBox.get(id);

  Future<List<SessionStorageModel>> getAllSessions() async {
    return _sessionsBox.values.toList()
      ..sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
  }

  Future<void> updateSessionAccessTime(String id) async {
    final session = await getSession(id);
    if (session != null) {
      await saveSession(_copySession(session, lastAccessedAt: DateTime.now()));
    }
  }

  Future<void> togglePinSession(String id) async {
    final session = await getSession(id);
    if (session != null) {
      await saveSession(_copySession(session, isPinned: !session.isPinned));
    }
  }

  Future<void> toggleArchiveSession(String id) async {
    final session = await getSession(id);
    if (session != null) {
      await saveSession(_copySession(session, isArchived: !session.isArchived));
    }
  }

  Future<void> deleteSession(String id) async {
    final messageKeys = _messagesBox.keys
        .where((key) => _messagesBox.get(key)?.sessionId == id)
        .toList(growable: false);
    if (messageKeys.isNotEmpty) {
      await _messagesBox.deleteAll(messageKeys);
    }
    await _sessionsBox.delete(id);
    _statsController.add(await _computeStats());
  }

  Future<List<SessionStorageModel>> searchSessions(String query) async {
    final lowerQuery = query.toLowerCase();
    return _sessionsBox.values
        .where((s) =>
            s.title.toLowerCase().contains(lowerQuery) ||
            s.messages.any((m) => m.toLowerCase().contains(lowerQuery)))
        .toList()
      ..sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
  }

  Future<void> saveSearchKeyword(String keyword) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _keywordsBox.put(
      id,
      SearchKeyword(id: id, keyword: keyword, createdAt: DateTime.now()),
    );
  }

  Future<List<SearchKeyword>> getRecentSearchKeywords({int limit = 10}) async {
    final keywords = _keywordsBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return keywords.take(limit).toList();
  }

  Future<void> clearSearchKeywords() => _keywordsBox.clear();

  Future<CleanupResult> cleanupOldData({
    Duration maxAge = const Duration(days: 30),
  }) async {
    final cutoff = DateTime.now().subtract(maxAge);
    final sessionsDeleted = await _deleteExpiredSessions(cutoff);
    final messagesDeleted = await _deleteExpiredMessages(cutoff);
    _statsController.add(await _computeStats());
    return CleanupResult(
      sessionsDeleted: sessionsDeleted,
      messagesDeleted: messagesDeleted,
    );
  }

  Future<void> clearAll() async {
    await _sessionsBox.clear();
    await _messagesBox.clear();
    await _keywordsBox.clear();
    _statsController.add(const StorageStats());
  }

  void dispose() {
    _syncController.close();
    _statsController.close();
  }
}

enum SyncStatus { idle, syncing, completed, error }
