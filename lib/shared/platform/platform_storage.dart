import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Platform-aware secure storage service
///
/// Uses Hive for all platforms including HarmonyOS.
/// This avoids issues with flutter_secure_storage and shared_preferences on HarmonyOS.
class PlatformStorage {
  PlatformStorage._();

  static PlatformStorage? _instance;
  Box? _box;
  bool _isInitialized = false;

  static PlatformStorage get instance {
    _instance ??= PlatformStorage._();
    return _instance!;
  }

  static const String _boxName = 'platform_storage';

  /// Initialize the storage
  Future<void> _init() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        await Hive.initFlutter();
      } else {
        await _initializeHiveForIo();
      }

      _box = Hive.isBoxOpen(_boxName)
          ? Hive.box(_boxName)
          : await Hive.openBox(_boxName);
      _isInitialized = true;
      print('[PlatformStorage] Initialized successfully');
    } catch (e) {
      print('[PlatformStorage] Initialization error: $e');
      rethrow;
    }
  }

  Future<void> _initializeHiveForIo() async {
    if (Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux) {
      try {
        await Hive.initFlutter();
        return;
      } catch (_) {
        // In widget tests and unsupported desktop harnesses path_provider may
        // not be registered. Fall back to a writable temp directory so the app
        // can still bootstrap.
      }
    }

    final dir = Directory('${Directory.systemTemp.path}/happy_coder_platform');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    Hive.init(dir.path);
  }

  /// Get the box, initializing if needed
  Future<Box> _getBox() async {
    if (!_isInitialized || _box == null) {
      await _init();
    }
    return _box!;
  }

  /// Read a value
  Future<String?> read(String key) async {
    try {
      final box = await _getBox();
      final value = box.get(key) as String?;
      return value;
    } catch (e) {
      print('[PlatformStorage] Error reading key "$key": $e');
      return null;
    }
  }

  /// Write a value
  Future<void> write({required String key, required String value}) async {
    try {
      final box = await _getBox();
      await box.put(key, value);
    } catch (e) {
      print('[PlatformStorage] Error writing key "$key": $e');
      rethrow;
    }
  }

  /// Delete a value
  Future<void> delete(String key) async {
    try {
      final box = await _getBox();
      await box.delete(key);
    } catch (e) {
      print('[PlatformStorage] Error deleting key "$key": $e');
    }
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    try {
      final box = await _getBox();
      return box.containsKey(key);
    } catch (e) {
      print('[PlatformStorage] Error checking key "$key": $e');
      return false;
    }
  }

  /// Clear all values
  Future<void> clearAll() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      print('[PlatformStorage] Error clearing all: $e');
    }
  }

  /// Get all keys
  Future<Map<String, String>> readAll() async {
    try {
      final box = await _getBox();
      final keys = box.keys;
      final Map<String, String> result = {};
      for (final key in keys) {
        if (key is String) {
          final value = box.get(key) as String? ?? '';
          result[key] = value;
        }
      }
      return result;
    } catch (e) {
      print('[PlatformStorage] Error reading all: $e');
      return {};
    }
  }
}
