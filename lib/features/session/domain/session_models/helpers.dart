part of 'session_models.dart';

List<dynamic> _asDynamicList(dynamic value) {
  if (value is List<dynamic>) {
    return value;
  }
  if (value is List) {
    return value.toList();
  }
  return const <dynamic>[];
}

List<Todo>? _parseTodos(dynamic value) {
  final todos = <Todo>[];
  for (final rawTodo in _asDynamicList(value)) {
    final todoMap = _asStringMap(rawTodo);
    if (todoMap == null) {
      continue;
    }
    try {
      todos.add(
        Todo(
          id: _firstNonEmptyString([todoMap['id']]) ?? '',
          title: _firstNonEmptyString([todoMap['title']]) ?? '',
          description: _firstNonEmptyString([todoMap['description']]),
          completed: _parseBool(todoMap['completed']) ?? false,
          createdAt:
              _parseDateTime(todoMap['createdAt'] ?? todoMap['created_at']),
          completedAt:
              _parseDateTime(todoMap['completedAt'] ?? todoMap['completed_at']),
          tags: _asDynamicList(todoMap['tags'])
              .map((tag) => tag.toString())
              .where((tag) => tag.isNotEmpty)
              .toList(),
        ),
      );
    } catch (_) {
      continue;
    }
  }
  return todos.isEmpty ? null : todos;
}

bool? _parseBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return null;
}

int? _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String && value.isNotEmpty) {
    return int.tryParse(value);
  }
  return null;
}

String? _firstNonEmptyString(List<dynamic> candidates) {
  for (final candidate in candidates) {
    if (candidate == null) {
      continue;
    }
    final value = candidate.toString().trim();
    if (value.isNotEmpty && value != 'null') {
      return value;
    }
  }
  return null;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    if (value.isEmpty) return null;
    final asInt = int.tryParse(value);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    return DateTime.tryParse(value);
  }
  return null;
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
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (key, mapValue) => MapEntry(key.toString(), mapValue),
        );
      }
    } catch (_) {
      return null;
    }
  }
  return null;
}
