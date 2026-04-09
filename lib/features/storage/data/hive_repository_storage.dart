part of 'hive_repository.dart';

extension _HiveRepositoryStorage on HiveRepository {
  Future<void> _initializeHive() async {
    if (kIsWeb ||
        Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux) {
      await Hive.initFlutter();
      return;
    }
    final dir = await _getAppDocDir();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    Hive.init(dir.path);
  }

  Future<void> _openBoxes() async {
    if (!Hive.isAdapterRegistered(SessionStorageModelAdapter().typeId)) {
      Hive.registerAdapter(SessionStorageModelAdapter());
    }
    if (!Hive.isAdapterRegistered(MessageStorageModelAdapter().typeId)) {
      Hive.registerAdapter(MessageStorageModelAdapter());
    }
    if (!Hive.isAdapterRegistered(SearchKeywordAdapter().typeId)) {
      Hive.registerAdapter(SearchKeywordAdapter());
    }
    _sessionsBox = await Hive.openBox<SessionStorageModel>(
      HiveRepository._boxSessions,
    );
    _messagesBox = await Hive.openBox<MessageStorageModel>(
      HiveRepository._boxMessages,
    );
    _keywordsBox = await Hive.openBox<SearchKeyword>(
      HiveRepository._boxKeywords,
    );
  }

  Future<int> _calculateStorageSize() async {
    try {
      final appDocDir = await _getAppDocDir();
      final storageDir = Directory('${appDocDir.path}/happy_coder');
      if (!await storageDir.exists()) {
        return 0;
      }
      var totalSize = 0;
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

  Future<int> _calculateDirSize(Directory dir) async {
    var totalSize = 0;
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

  SessionStorageModel _copySession(
    SessionStorageModel session, {
    DateTime? lastAccessedAt,
    bool? isPinned,
    bool? isArchived,
    Map<String, dynamic>? metadata,
  }) {
    return SessionStorageModel(
      id: session.id,
      title: session.title,
      messages: session.messages,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
      lastAccessedAt: lastAccessedAt ?? session.lastAccessedAt,
      isPinned: isPinned ?? session.isPinned,
      isArchived: isArchived ?? session.isArchived,
      tag: session.tag,
      metadata: metadata ?? session.metadata,
    );
  }

  Future<int> _deleteExpiredSessions(DateTime cutoff) async {
    var sessionsDeleted = 0;
    for (final key in _sessionsBox.keys) {
      final session = _sessionsBox.get(key);
      if (session != null &&
          session.lastAccessedAt.isBefore(cutoff) &&
          !session.isPinned) {
        await _sessionsBox.delete(key);
        sessionsDeleted++;
      }
    }
    return sessionsDeleted;
  }

  Future<int> _deleteExpiredMessages(DateTime cutoff) async {
    var messagesDeleted = 0;
    for (final key in _messagesBox.keys) {
      final message = _messagesBox.get(key);
      if (message != null && message.createdAt.isBefore(cutoff)) {
        await _messagesBox.delete(key);
        messagesDeleted++;
      }
    }
    return messagesDeleted;
  }
}
