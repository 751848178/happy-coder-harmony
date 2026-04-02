part of 'storage_service.dart';

extension StorageQueries on StorageService {
  Future<SessionStorageModel?> getSession(String id) async {
    return _repository.getSession(id);
  }

  Future<List<SessionStorageModel>> getAllSessions() async {
    return _repository.getAllSessions();
  }

  Future<List<SessionStorageModel>> getActiveSessions() async {
    final sessions = await getAllSessions();
    return sessions.where((session) => !session.isArchived).toList();
  }

  Future<List<SessionStorageModel>> getArchivedSessions() async {
    final sessions = await getAllSessions();
    return sessions.where((session) => session.isArchived).toList();
  }

  Future<List<SessionStorageModel>> getPinnedSessions() async {
    final sessions = await getAllSessions();
    return sessions.where((session) => session.isPinned).toList();
  }

  Future<List<SessionStorageModel>> searchSessions(String query) async {
    if (query.trim().isEmpty) {
      return getAllSessions();
    }
    return _repository.searchSessions(query);
  }

  Future<void> saveSearchKeyword(String keyword) async {
    if (keyword.trim().isEmpty) {
      return;
    }
    await _repository.saveSearchKeyword(keyword);
  }

  Future<List<SearchKeyword>> getRecentSearchKeywords({int limit = 10}) async {
    return _repository.getRecentSearchKeywords(limit: limit);
  }

  Future<void> clearSearchKeywords() async {
    await _repository.clearSearchKeywords();
  }

  Future<void> togglePinSession(String id) async {
    await _repository.togglePinSession(id);
  }

  Future<void> toggleArchiveSession(String id) async {
    await _repository.toggleArchiveSession(id);
  }

  Future<void> deleteSession(String id) async {
    await _repository.deleteSession(id);
  }

  Future<CleanupResult> cleanupOldData({
    Duration maxAge = const Duration(days: 30),
  }) async {
    return _repository.cleanupOldData(maxAge: maxAge);
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
  }

  Future<StorageStats> getStats() async {
    return _repository.getStats();
  }

  String formatStorageSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    if (bytes < 1024 * 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    return '$bytes B';
  }
}
