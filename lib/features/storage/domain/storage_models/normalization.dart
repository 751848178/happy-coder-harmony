part of 'storage_models.dart';

Map<String, dynamic>? _normalizeStringDynamicMap(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Map<String, dynamic>) {
    return value.map((key, nestedValue) {
      return MapEntry(key, _normalizeStorageValue(nestedValue));
    });
  }
  if (value is Map) {
    return value.map((key, nestedValue) {
      return MapEntry(key.toString(), _normalizeStorageValue(nestedValue));
    });
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
