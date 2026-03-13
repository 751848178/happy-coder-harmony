import 'package:hive/hive.dart';

Map<String, dynamic>? _normalizeStringDynamicMap(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Map<String, dynamic>) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key,
        _normalizeStorageValue(nestedValue),
      ),
    );
  }
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key.toString(),
        _normalizeStorageValue(nestedValue),
      ),
    );
  }
  return null;
}

dynamic _normalizeStorageValue(dynamic value) {
  if (value is Map) {
    return _normalizeStringDynamicMap(value);
  }
  if (value is List) {
    return value.map(_normalizeStorageValue).toList();
  }
  return value;
}

/// 本地存储模型
///

/// Session 类占位符
/// 实际的 Session 类定义在 session_models.dart 中
/// 这里我们只做简单的类型引用，实际使用时需要导入正确的模型
class Session {
  final String id;
  final String title;
  final List<String> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool active;
  final String? tag;
  final String? path;
  final Map<String, dynamic>? metadata;

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
}

/// 会话存储模型
class SessionStorageModel {
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

  /// 转换为 Session 模型
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

/// 消息存储模型
class MessageStorageModel {
  final String id;
  final String sessionId;
  final String content;
  final String role; // 'user' or 'assistant'
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const MessageStorageModel({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.role,
    required this.createdAt,
    this.metadata,
  });

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

/// 搜索关键词模型
class SearchKeyword {
  final String id;
  final String keyword;
  final DateTime createdAt;

  const SearchKeyword({
    required this.id,
    required this.keyword,
    required this.createdAt,
  });

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

/// 存储统计模型
class StorageStats {
  final int totalSessions;
  final int totalMessages;
  final int archivedSessions;
  final int pinnedSessions;
  final int storageSizeBytes;

  const StorageStats({
    this.totalSessions = 0,
    this.totalMessages = 0,
    this.archivedSessions = 0,
    this.pinnedSessions = 0,
    this.storageSizeBytes = 0,
  });
}

/// 清理结果
class CleanupResult {
  final int sessionsDeleted;
  final int messagesDeleted;

  const CleanupResult({
    this.sessionsDeleted = 0,
    this.messagesDeleted = 0,
  });
}

// Hive TypeAdapters

/// SessionStorageModel Hive TypeAdapter
class SessionStorageModelAdapter extends TypeAdapter<SessionStorageModel> {
  @override
  final int typeId = 100;

  @override
  SessionStorageModel read(BinaryReader reader) {
    return SessionStorageModel(
      id: reader.readString(),
      title: reader.readString(),
      messages: reader.readStringList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      lastAccessedAt: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      isPinned: reader.readBool(),
      isArchived: reader.readBool(),
      tag: reader.read() as String?,
      metadata: _normalizeStringDynamicMap(reader.read()),
    );
  }

  @override
  void write(BinaryWriter writer, SessionStorageModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeStringList(obj.messages);
    writer.write(obj.createdAt.millisecondsSinceEpoch);
    writer.write(obj.updatedAt.millisecondsSinceEpoch);
    writer.write(obj.lastAccessedAt.millisecondsSinceEpoch);
    writer.writeBool(obj.isPinned);
    writer.writeBool(obj.isArchived);
    writer.write(obj.tag);
    writer.write(obj.metadata);
  }
}

/// MessageStorageModel Hive TypeAdapter
class MessageStorageModelAdapter extends TypeAdapter<MessageStorageModel> {
  @override
  final int typeId = 101;

  @override
  MessageStorageModel read(BinaryReader reader) {
    return MessageStorageModel(
      id: reader.readString(),
      sessionId: reader.readString(),
      content: reader.readString(),
      role: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      metadata: _normalizeStringDynamicMap(reader.read()),
    );
  }

  @override
  void write(BinaryWriter writer, MessageStorageModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.sessionId);
    writer.writeString(obj.content);
    writer.writeString(obj.role);
    writer.write(obj.createdAt.millisecondsSinceEpoch);
    writer.write(obj.metadata);
  }
}

/// SearchKeyword Hive TypeAdapter
class SearchKeywordAdapter extends TypeAdapter<SearchKeyword> {
  @override
  final int typeId = 102;

  @override
  SearchKeyword read(BinaryReader reader) {
    return SearchKeyword(
      id: reader.readString(),
      keyword: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.read()),
    );
  }

  @override
  void write(BinaryWriter writer, SearchKeyword obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.keyword);
    writer.write(obj.createdAt.millisecondsSinceEpoch);
  }
}
