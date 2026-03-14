import 'dart:convert';

import '../../../shared/platform/platform_storage.dart';

class QueuedComposerMessage {
  const QueuedComposerMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  QueuedComposerMessage copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QueuedComposerMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory QueuedComposerMessage.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return QueuedComposerMessage(
      id: json['id']?.toString() ?? 'queued_${now.microsecondsSinceEpoch}',
      content: json['content']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt']) ?? now,
      updatedAt: _parseDateTime(json['updatedAt']) ?? now,
    );
  }
}

class SessionComposerQueueService {
  SessionComposerQueueService._();

  static final SessionComposerQueueService instance =
      SessionComposerQueueService._();

  static const String _storageKey = 'session_composer_queue_v1';

  final PlatformStorage _storage = PlatformStorage.instance;
  Map<String, List<QueuedComposerMessage>>? _cache;

  Future<Map<String, List<QueuedComposerMessage>>> loadAll() async {
    if (_cache != null) {
      return _clone(_cache!);
    }

    final rawValue = await _storage.read(_storageKey);
    if (rawValue == null || rawValue.trim().isEmpty) {
      _cache = <String, List<QueuedComposerMessage>>{};
      return <String, List<QueuedComposerMessage>>{};
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map) {
        _cache = <String, List<QueuedComposerMessage>>{};
        return <String, List<QueuedComposerMessage>>{};
      }

      final next = <String, List<QueuedComposerMessage>>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! List) {
          continue;
        }
        final items = value
            .map((item) => _asStringMap(item))
            .whereType<Map<String, dynamic>>()
            .map(QueuedComposerMessage.fromJson)
            .where((item) => item.content.trim().isNotEmpty)
            .toList();
        if (items.isNotEmpty) {
          next[entry.key.toString()] = items;
        }
      }

      _cache = next;
      return _clone(next);
    } catch (_) {
      _cache = <String, List<QueuedComposerMessage>>{};
      return <String, List<QueuedComposerMessage>>{};
    }
  }

  Future<List<QueuedComposerMessage>> get(String sessionId) async {
    final all = await loadAll();
    return List<QueuedComposerMessage>.from(all[sessionId] ?? const []);
  }

  Future<void> replace(
    String sessionId,
    List<QueuedComposerMessage> messages,
  ) async {
    final normalized = messages
        .where((message) => message.content.trim().isNotEmpty)
        .toList(growable: false);
    final all = await loadAll();
    if (normalized.isEmpty) {
      all.remove(sessionId);
    } else {
      all[sessionId] = normalized;
    }
    _cache = all;
    await _persist(all);
  }

  Future<void> clearSession(String sessionId) async {
    final all = await loadAll();
    if (!all.containsKey(sessionId)) {
      return;
    }
    all.remove(sessionId);
    _cache = all;
    await _persist(all);
  }

  QueuedComposerMessage createDraft(String content, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    return QueuedComposerMessage(
      id: 'queued_${timestamp.microsecondsSinceEpoch}',
      content: content,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  Future<void> _persist(Map<String, List<QueuedComposerMessage>> values) async {
    final serializable = values.map(
      (key, value) => MapEntry(
        key,
        value.map((message) => message.toJson()).toList(growable: false),
      ),
    );
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(serializable),
    );
  }

  Map<String, List<QueuedComposerMessage>> _clone(
    Map<String, List<QueuedComposerMessage>> values,
  ) {
    return values.map(
      (key, value) => MapEntry(
        key,
        List<QueuedComposerMessage>.from(value),
      ),
    );
  }
}

Map<String, dynamic>? _asStringMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
  }
  return null;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    if (value.isEmpty) {
      return null;
    }
    final asInt = int.tryParse(value);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    return DateTime.tryParse(value);
  }
  return null;
}
