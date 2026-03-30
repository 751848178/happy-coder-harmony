import 'dart:convert';

/// 验证工具
///
/// 提供常用的数据验证方法
class Validation {
  /// 验证邮箱
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// 验证 URL
  static bool isValidUrl(String url) {
    return Uri.tryParse(url) != null &&
        (url.startsWith('http://') || url.startsWith('https://'));
  }

  /// 验证机器 ID (UUID 格式)
  static bool isValidMachineId(String id) {
    final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
    return uuidRegex.hasMatch(id);
  }

  /// 验证会话 ID
  static bool isValidSessionId(String id) {
    return id.length >= 8 && id.length <= 64;
  }

  /// 验证 Token 格式
  static bool isValidToken(String token) {
    return token.isNotEmpty && token.length >= 32;
  }

  /// 验证密钥格式 (Base64 编码的密钥)
  static bool isValidKey(String key) {
    try {
      final bytes = base64Decode(key);
      return bytes.length == 32; // 256-bit key
    } catch (e) {
      return false;
    }
  }

  /// 验证 GitHub 用户名
  static bool isValidGitHubUsername(String username) {
    if (username.isEmpty) return false;
    // GitHub 用户名规则：只能包含字母数字和连字符，开头不能为数字或连字符
    final usernameRegex = RegExp(r'^[a-zA-Z0-9]+(?:-[a-zA-Z0-9]+)*$');
    return usernameRegex.hasMatch(username) && username.length <= 39;
  }

  /// 验证文件名
  static bool isValidFileName(String filename) {
    if (filename.isEmpty) return false;
    // 不能包含以下字符：/ \ : * ? " < > |
    final invalidChars = RegExp(r'[\/\\:*?"<>|]');
    return !invalidChars.hasMatch(filename);
  }

  /// 验证端口号
  static bool isValidPort(String port) {
    final portNum = int.tryParse(port);
    if (portNum == null) return false;
    return portNum > 0 && portNum <= 65535;
  }

  /// 验证 IP 地址
  static bool isValidIpAddress(String ip) {
    final ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return ipRegex.hasMatch(ip);
  }

  /// 验证 JSON
  static bool isValidJson(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 验证密钥强度
  static PasswordStrength checkPasswordStrength(String password) {
    int score = 0;

    // 长度检查
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;

    // 复杂性检查
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) score++;

    // 确定强度
    if (score < 3) return PasswordStrength.weak;
    if (score < 5) return PasswordStrength.medium;
    if (score < 7) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }
}

/// 密码强度枚举
enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong,
}

/// 输入验证错误
class ValidationError {
  final String field;
  final String message;

  const ValidationError({
    required this.field,
    required this.message,
  });

  @override
  String toString() => '$field: $message';
}

/// 表单验证结果
class ValidationResult<T> {
  final bool isValid;
  final T? data;
  final List<ValidationError>? errors;

  const ValidationResult({
    required this.isValid,
    this.data,
    this.errors,
  });

  factory ValidationResult.success(T data) {
    return ValidationResult(isValid: true, data: data);
  }

  factory ValidationResult.failure(List<ValidationError> errors) {
    return ValidationResult(isValid: false, errors: errors);
  }
}
