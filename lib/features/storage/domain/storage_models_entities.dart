part of 'storage_models.dart';

class Session {
  const Session({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.active = true,
    this.tag,
    this.path,
    this.metadata,
  });

  final String id;
  final String title;
  final List<String> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool active;
  final String? tag;
  final String? path;
  final Map<String, dynamic>? metadata;
}

class SessionStorageModel {
  const SessionStorageModel({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    required this.lastAccessedAt,
    this.isPinned = false,
    this.isArchived = false,
    this.tag,
    this.metadata,
  });

  final String id;
  final String title;
  final List<String> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastAccessedAt;
  final bool isPinned;
  final bool isArchived;
  final String? tag;
  final Map<String, dynamic>? metadata;

  Session toSessionModel() {
    return Session(
      id: id,
      title: title,
      messages: messages,
      createdAt: createdAt,
      updatedAt: updatedAt,
      active: true,
      tag: tag,
      path: null,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'isPinned': isPinned,
      'isArchived': isArchived,
      if (tag != null) 'tag': tag,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory SessionStorageModel.fromJson(Map<String, dynamic> json) {
    return SessionStorageModel(
      id: json['id'] as String,
      title: json['title'] as String,
      messages: (json['messages'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastAccessedAt: DateTime.parse(json['lastAccessedAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      tag: json['tag'] as String?,
      metadata: _normalizeStringDynamicMap(json['metadata']),
    );
  }
}

class MessageStorageModel {
  const MessageStorageModel({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.role,
    required this.createdAt,
    this.metadata,
  });

  final String id;
  final String sessionId;
  final String content;
  final String role;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'content': content,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory MessageStorageModel.fromJson(Map<String, dynamic> json) {
    return MessageStorageModel(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      content: json['content'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: _normalizeStringDynamicMap(json['metadata']),
    );
  }
}

class SessionMessageArchiveSummary {
  const SessionMessageArchiveSummary({
    this.messageCount = 0,
    this.isComplete = false,
    this.lastRemoteSeq = 0,
  });

  final int messageCount;
  final bool isComplete;
  final int lastRemoteSeq;
}

class SessionArchivedTurnSummary {
  const SessionArchivedTurnSummary({
    required this.id,
    required this.promptMessageId,
    required this.preview,
    required this.createdAt,
    required this.archiveIndex,
  });

  final String id;
  final String promptMessageId;
  final String preview;
  final DateTime createdAt;
  final int archiveIndex;
}

class SearchKeyword {
  const SearchKeyword({
    required this.id,
    required this.keyword,
    required this.createdAt,
  });

  final String id;
  final String keyword;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keyword': keyword,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SearchKeyword.fromJson(Map<String, dynamic> json) {
    return SearchKeyword(
      id: json['id'] as String,
      keyword: json['keyword'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class StorageStats {
  const StorageStats({
    this.totalSessions = 0,
    this.totalMessages = 0,
    this.archivedSessions = 0,
    this.pinnedSessions = 0,
    this.storageSizeBytes = 0,
  });

  final int totalSessions;
  final int totalMessages;
  final int archivedSessions;
  final int pinnedSessions;
  final int storageSizeBytes;
}

class CleanupResult {
  const CleanupResult({
    this.sessionsDeleted = 0,
    this.messagesDeleted = 0,
  });

  final int sessionsDeleted;
  final int messagesDeleted;
}
