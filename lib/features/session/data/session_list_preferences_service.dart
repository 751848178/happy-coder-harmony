import 'dart:convert';

import '../../../shared/platform/platform_storage.dart';

class SessionListPreferences {
  const SessionListPreferences({
    this.selectedMachineId,
  });

  final String? selectedMachineId;

  bool get isDefault =>
      selectedMachineId == null || selectedMachineId!.trim().isEmpty;

  SessionListPreferences copyWith({
    Object? selectedMachineId = _sessionListPreferencesSentinel,
  }) {
    return SessionListPreferences(
      selectedMachineId:
          identical(selectedMachineId, _sessionListPreferencesSentinel)
              ? this.selectedMachineId
              : _normalizeMachineId(selectedMachineId as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (!isDefault) 'selectedMachineId': selectedMachineId,
    };
  }

  factory SessionListPreferences.fromJson(Map<String, dynamic> json) {
    return SessionListPreferences(
      selectedMachineId: _normalizeMachineId(
        json['selectedMachineId']?.toString(),
      ),
    );
  }
}

class SessionListPreferencesService {
  SessionListPreferencesService._();

  static final SessionListPreferencesService instance =
      SessionListPreferencesService._();

  static const String _storageKey = 'session_list_preferences_v1';

  final PlatformStorage _storage = PlatformStorage.instance;
  SessionListPreferences? _cache;

  Future<SessionListPreferences> load() async {
    if (_cache != null) {
      return _cache!;
    }

    final rawValue = await _storage.read(_storageKey);
    if (rawValue == null || rawValue.trim().isEmpty) {
      _cache = const SessionListPreferences();
      return _cache!;
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is Map<String, dynamic>) {
        _cache = SessionListPreferences.fromJson(decoded);
      } else if (decoded is Map) {
        _cache = SessionListPreferences.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      } else {
        _cache = const SessionListPreferences();
      }
    } catch (_) {
      _cache = const SessionListPreferences();
    }
    return _cache!;
  }

  Future<SessionListPreferences> setSelectedMachineId(String? machineId) async {
    final current = await load();
    final next = current.copyWith(
      selectedMachineId: _normalizeMachineId(machineId),
    );
    _cache = next;
    if (next.isDefault) {
      await _storage.delete(_storageKey);
    } else {
      await _storage.write(key: _storageKey, value: jsonEncode(next.toJson()));
    }
    return next;
  }
}

const Object _sessionListPreferencesSentinel = Object();

String? _normalizeMachineId(String? value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
