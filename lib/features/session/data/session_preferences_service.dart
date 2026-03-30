import 'dart:convert';

import '../../../shared/platform/platform_storage.dart';

class SessionPreferences {
  const SessionPreferences({
    this.alias,
    this.permissionMode,
    this.modelMode,
  });

  final String? alias;
  final String? permissionMode;
  final String? modelMode;

  static const Object _sentinel = Object();

  bool get isEmpty =>
      !_hasValue(alias) && !_hasValue(permissionMode) && !_hasValue(modelMode);

  SessionPreferences copyWith({
    Object? alias = _sentinel,
    Object? permissionMode = _sentinel,
    Object? modelMode = _sentinel,
  }) {
    return SessionPreferences(
      alias: identical(alias, _sentinel)
          ? this.alias
          : _normalize(alias as String?),
      permissionMode: identical(permissionMode, _sentinel)
          ? this.permissionMode
          : _normalize(permissionMode as String?),
      modelMode: identical(modelMode, _sentinel)
          ? this.modelMode
          : _normalize(modelMode as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (_hasValue(alias)) 'alias': alias,
      if (_hasValue(permissionMode)) 'permissionMode': permissionMode,
      if (_hasValue(modelMode)) 'modelMode': modelMode,
    };
  }

  factory SessionPreferences.fromJson(Map<String, dynamic> json) {
    return SessionPreferences(
      alias: _normalize(json['alias'] as String?),
      permissionMode: _normalize(json['permissionMode'] as String?),
      modelMode: _normalize(json['modelMode'] as String?),
    );
  }

  static String? _normalize(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool _hasValue(String? value) =>
      value != null && value.trim().isNotEmpty;
}

class SessionPreferencesService {
  SessionPreferencesService._();

  static final SessionPreferencesService instance =
      SessionPreferencesService._();

  static const String _storageKey = 'session_preferences_v1';

  final PlatformStorage _storage = PlatformStorage.instance;
  Map<String, SessionPreferences>? _cache;

  Future<Map<String, SessionPreferences>> loadAll() async {
    if (_cache != null) {
      return Map<String, SessionPreferences>.from(_cache!);
    }

    final rawValue = await _storage.read(_storageKey);
    if (rawValue == null || rawValue.trim().isEmpty) {
      _cache = <String, SessionPreferences>{};
      return <String, SessionPreferences>{};
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map) {
        _cache = <String, SessionPreferences>{};
        return <String, SessionPreferences>{};
      }

      final next = <String, SessionPreferences>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          next[entry.key.toString()] = SessionPreferences.fromJson(value);
        } else if (value is Map) {
          next[entry.key.toString()] = SessionPreferences.fromJson(
            value.map(
              (key, mapValue) => MapEntry(key.toString(), mapValue),
            ),
          );
        }
      }
      _cache = next;
      return Map<String, SessionPreferences>.from(next);
    } catch (_) {
      _cache = <String, SessionPreferences>{};
      return <String, SessionPreferences>{};
    }
  }

  Future<SessionPreferences> get(String sessionId) async {
    final all = await loadAll();
    return all[sessionId] ?? const SessionPreferences();
  }

  Future<void> update({
    required String sessionId,
    Object? alias = SessionPreferences._sentinel,
    Object? permissionMode = SessionPreferences._sentinel,
    Object? modelMode = SessionPreferences._sentinel,
  }) async {
    final current = await get(sessionId);
    final next = current.copyWith(
      alias: alias,
      permissionMode: permissionMode,
      modelMode: modelMode,
    );

    final all = await loadAll();
    if (next.isEmpty) {
      all.remove(sessionId);
    } else {
      all[sessionId] = next;
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

  Future<void> _persist(Map<String, SessionPreferences> values) async {
    final serializable = values.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(serializable),
    );
  }
}
