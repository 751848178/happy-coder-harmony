import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../shared/platform/platform_storage.dart';
import '../../shared/utils/extensions.dart';

class ServerConfigService {
  ServerConfigService._();

  static ServerConfigService? _instance;
  static ServerConfigService get instance =>
      _instance ??= ServerConfigService._();

  static const String defaultServerId = 'default';
  static const String svtonServerId = 'svton';
  static const String customServerId = 'custom';
  static const String defaultServerUrl = String.fromEnvironment(
    'HAPPY_SERVER_URL',
    defaultValue: 'https://api.cluster-fluster.com',
  );
  static const String svtonServerUrl = 'https://hapmony.svton.cn';
  static const List<BuiltInServerOption> builtInServerOptions = [
    BuiltInServerOption(
      id: defaultServerId,
      name: '默认服务器',
      url: defaultServerUrl,
      description: '应用原本使用的默认后端地址',
    ),
    BuiltInServerOption(
      id: svtonServerId,
      name: '开发者提供的国内服务器',
      url: svtonServerUrl,
      description: '我们 APP 开发者提供的国内服务器 https://hapmony.svton.cn',
    ),
  ];

  static const String _keySelectedServerId = 'selected_server_id';
  static const String _keyCustomServerUrl = 'custom_server_url';
  static const String _happyWelcomeText = 'Welcome to Happy Server!';
  static final String _probePublicKey =
      base64Encode(Uint8List.fromList(List<int>.filled(32, 0)));

  final PlatformStorage _storage = PlatformStorage.instance;

  String _selectedServerId = defaultServerId;
  String? _customServerUrl;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    Logger.info('ServerConfigService init start');
    try {
      final storedSelectedServerId = await _storage.read(_keySelectedServerId);
      final storedValue = await _storage.read(_keyCustomServerUrl);
      if (storedValue == null || storedValue.trim().isEmpty) {
        _customServerUrl = null;
      } else {
        _customServerUrl = _normalizeUrl(storedValue.trim());
      }
      _selectedServerId = _normalizeSelectedServerId(
        storedSelectedServerId,
        customServerUrl: _customServerUrl,
      );
      _isInitialized = true;
      Logger.info(
        'ServerConfigService init done: selectedServerId=$_selectedServerId, customServerUrl=${_customServerUrl ?? 'null'}',
      );
    } catch (error) {
      Logger.error('ServerConfigService init failed: $error');
      rethrow;
    }
  }

  String get selectedServerId => _normalizeSelectedServerId(_selectedServerId,
      customServerUrl: _customServerUrl);

  String get serverUrl => switch (selectedServerId) {
        defaultServerId => defaultServerUrl,
        svtonServerId => svtonServerUrl,
        customServerId => customServerUrl ?? defaultServerUrl,
        _ => defaultServerUrl,
      };

  BuiltInServerOption get selectedBuiltInServerOption =>
      builtInServerOptions.firstWhere(
        (option) => option.id == selectedServerId,
        orElse: () => builtInServerOptions.first,
      );

  String get selectedServerName => switch (selectedServerId) {
        defaultServerId => '默认服务器',
        svtonServerId => '开发者提供的国内服务器',
        customServerId => '自定义服务器',
        _ => '默认服务器',
      };

  String? get customServerUrl {
    final value = _customServerUrl?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return _normalizeUrl(value);
  }

  bool get isUsingCustomServer =>
      selectedServerId == customServerId && customServerUrl != null;

  bool get isUsingBuiltInServer => selectedServerId != customServerId;

  ServerConfigSnapshot get snapshot => ServerConfigSnapshot(
        selectedServerId: selectedServerId,
        customServerUrl: customServerUrl,
      );

  Future<void> setBuiltInServer(String serverId) async {
    await init();

    if (!isBuiltInServerId(serverId)) {
      throw ArgumentError('Use setCustomServerUrl() for custom server.');
    }

    final normalized = _normalizeSelectedServerId(serverId);
    await _saveSelectedServerId(normalized);
    Logger.info('ServerConfigService selected built-in server: $normalized');
  }

  Future<void> setCustomServerUrl(String? value) async {
    await init();

    final normalized = value == null || value.trim().isEmpty
        ? null
        : _normalizeUrl(value.trim());

    if (normalized == null) {
      await _storage.delete(_keyCustomServerUrl);
      _customServerUrl = null;
      await _saveSelectedServerId(defaultServerId);
      Logger.info('ServerConfigService cleared custom server URL');
      return;
    }

    await _storage.write(key: _keyCustomServerUrl, value: normalized);
    _customServerUrl = normalized;
    await _saveSelectedServerId(customServerId);
    Logger.info('ServerConfigService saved custom server URL: $normalized');
  }

  Future<void> restoreSnapshot(ServerConfigSnapshot snapshot) async {
    await init();

    final normalizedCustomServerUrl = snapshot.customServerUrl == null ||
            snapshot.customServerUrl!.trim().isEmpty
        ? null
        : _normalizeUrl(snapshot.customServerUrl!.trim());

    if (normalizedCustomServerUrl == null) {
      await _storage.delete(_keyCustomServerUrl);
      _customServerUrl = null;
    } else {
      await _storage.write(
        key: _keyCustomServerUrl,
        value: normalizedCustomServerUrl,
      );
      _customServerUrl = normalizedCustomServerUrl;
    }

    final normalizedSelectedServerId = _normalizeSelectedServerId(
      snapshot.selectedServerId,
      customServerUrl: _customServerUrl,
    );
    await _saveSelectedServerId(normalizedSelectedServerId);
  }

  Future<void> restoreCustomServerUrl(String? value) async {
    await setCustomServerUrl(value);
  }

  static String _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static String? validateServerUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return '服务器地址不能为空';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return '服务器地址格式不正确';
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return '服务器地址必须使用 HTTP 或 HTTPS';
    }

    return null;
  }

  static bool isBuiltInServerId(String value) =>
      value == defaultServerId || value == svtonServerId;

  static String _normalizeSelectedServerId(
    String? value, {
    String? customServerUrl,
  }) {
    if (value == customServerId) {
      return customServerUrl == null || customServerUrl.trim().isEmpty
          ? defaultServerId
          : customServerId;
    }
    if (value == svtonServerId) {
      return svtonServerId;
    }
    return defaultServerId;
  }

  Future<void> _saveSelectedServerId(String serverId) async {
    _selectedServerId = _normalizeSelectedServerId(
      serverId,
      customServerUrl: _customServerUrl,
    );
    await _storage.write(key: _keySelectedServerId, value: _selectedServerId);
  }

  Future<ServerProbeResult> probeServer(String inputUrl) async {
    final normalizedUrl = _normalizeUrl(inputUrl);
    final dio = Dio(
      BaseOptions(
        baseUrl: normalizedUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );

    try {
      final welcomeResponse = await dio.get<String>('/');
      final rootLooksValid = welcomeResponse.statusCode == 200 &&
          (welcomeResponse.data ?? '').contains(_happyWelcomeText);
      if (!rootLooksValid) {
        return const ServerProbeResult(
          ok: false,
          supportsTerminalAuth: false,
          errorMessage: '目标地址不是有效的 Happy Server',
        );
      }

      final statusResponse = await dio.get<String>(
        '/v1/auth/request/status',
        queryParameters: <String, String>{'publicKey': _probePublicKey},
        options: Options(responseType: ResponseType.plain),
      );

      if (statusResponse.statusCode == 200) {
        return const ServerProbeResult(
          ok: true,
          supportsTerminalAuth: true,
        );
      }

      if (statusResponse.statusCode == 404) {
        return const ServerProbeResult(
          ok: true,
          supportsTerminalAuth: false,
          errorMessage: '该服务器可访问，但未启用终端授权接口 /v1/auth/request/status',
        );
      }

      return ServerProbeResult(
        ok: true,
        supportsTerminalAuth: false,
        errorMessage:
            '终端授权接口检查失败（HTTP ${statusResponse.statusCode ?? 'unknown'}）',
      );
    } on DioException catch (error) {
      return ServerProbeResult(
        ok: false,
        supportsTerminalAuth: false,
        errorMessage: error.message ?? '无法连接到服务器',
      );
    } finally {
      dio.close(force: true);
    }
  }
}

class ServerProbeResult {
  const ServerProbeResult({
    required this.ok,
    required this.supportsTerminalAuth,
    this.errorMessage,
  });

  final bool ok;
  final bool supportsTerminalAuth;
  final String? errorMessage;
}

class BuiltInServerOption {
  const BuiltInServerOption({
    required this.id,
    required this.name,
    required this.url,
    required this.description,
  });

  final String id;
  final String name;
  final String url;
  final String description;
}

class ServerConfigSnapshot {
  const ServerConfigSnapshot({
    required this.selectedServerId,
    this.customServerUrl,
  });

  final String selectedServerId;
  final String? customServerUrl;
}
