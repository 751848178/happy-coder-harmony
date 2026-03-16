part of 'socket_repository.dart';

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

Map<String, dynamic>? _decodeMaybeJsonMap(dynamic value) {
  final asMap = _asStringMap(value);
  if (asMap != null) {
    return asMap;
  }
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      return _asStringMap(decoded);
    } catch (_) {
      return null;
    }
  }
  return null;
}
