part of 'settings_service.dart';

extension SettingsServiceStorage on SettingsService {
  Future<void> init() async {
    if (_cache != null) {
      return;
    }
    final raw = await _storage.read(SettingsService._storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _cache = <String, dynamic>{};
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _cache = decoded;
      } else if (decoded is Map) {
        _cache = decoded.map((key, value) => MapEntry(key.toString(), value));
      } else {
        _cache = <String, dynamic>{};
      }
    } catch (_) {
      _cache = <String, dynamic>{};
    }
  }

  Map<String, dynamic> get _values => _cache ?? const <String, dynamic>{};

  bool _getBool(String key, bool fallback) {
    final value = _values[key];
    if (value is bool) {
      return value;
    }
    if (value == 'true') {
      return true;
    }
    if (value == 'false') {
      return false;
    }
    return fallback;
  }

  String _getString(String key, String fallback) {
    final value = _values[key];
    return value is String && value.isNotEmpty ? value : fallback;
  }

  String? _getNullableString(String key) {
    final value = _values[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  int _getInt(String key, int fallback) {
    final value = _values[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return value is String ? int.tryParse(value) ?? fallback : fallback;
  }

  double _getDouble(String key, double fallback) {
    final value = _values[key];
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return value is String ? double.tryParse(value) ?? fallback : fallback;
  }

  Future<void> _persist() async {
    await init();
    await _storage.write(
      key: SettingsService._storageKey,
      value: jsonEncode(_cache ?? const <String, dynamic>{}),
    );
  }

  Future<void> _setBool(String key, bool value) async {
    await init();
    _cache![key] = value;
    await _persist();
  }

  Future<void> _setString(String key, String value) async {
    await init();
    _cache![key] = value;
    await _persist();
  }

  Future<void> _setNullableString(String key, String? value) async {
    await init();
    if (value == null || value.isEmpty) {
      _cache!.remove(key);
    } else {
      _cache![key] = value;
    }
    await _persist();
  }

  Future<void> _setInt(String key, int value) async {
    await init();
    _cache![key] = value;
    await _persist();
  }

  Future<void> _setDouble(String key, double value) async {
    await init();
    _cache![key] = value;
    await _persist();
  }
}
