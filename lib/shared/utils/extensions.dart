import 'dart:math';
import 'package:flutter/foundation.dart';

/// 日志工具类
class Logger {
  static const bool _isDebugMode = kDebugMode;

  /// 输出调试信息
  static void debug(String message) {
    if (_isDebugMode) {
      print('[DEBUG] $message');
    }
  }

  /// 输出信息
  static void info(String message) {
    if (_isDebugMode) {
      print('[INFO] $message');
    }
  }

  /// 输出警告
  static void warning(String message) {
    if (_isDebugMode) {
      print('[WARNING] $message');
    }
  }

  /// 输出错误
  static void error(String message) {
    if (_isDebugMode) {
      print('[ERROR] $message');
    }
  }
}

/// String 扩展
extension StringExtension on String {
  /// 生成唯一 ID
  static String generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'msg_$timestamp\_$random';
  }
}

