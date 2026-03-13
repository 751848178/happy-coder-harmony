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

  static const String _keyCustomServerUrl = 'custom_server_url';
  static const String _happyWelcomeText = 'Welcome to Happy Server!';
  static final String _probePublicKey =
      base64Encode(Uint8List.fromList(List<int>.filled(32, 0)));

  final PlatformStorage _storage = PlatformStorage.instance;

  String? _customServerUrl;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    Logger.info('ServerConfigService init start');
    try {
      final storedValue = await _storage.read(_keyCustomServerUrl);
      if (storedValue == null || storedValue.trim().isEmpty) {
        _customServerUrl = null;
      } else {
        _customServerUrl = _normalizeUrl(storedValue.trim());
      }
      _isInitialized = true;
      Logger.info(
        'ServerConfigService init done: customServerUrl=${_customServerUrl ?? 'null'}',
      );
    } catch (error) {
      Logger.error('ServerConfigService init failed: $error');
      rethrow;
    }
  }

  String? get customServerUrl {
    final value = _customServerUrl?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return _normalizeUrl(value);
  }

  bool get isUsingCustomServer => customServerUrl != null;

  Future<void> setCustomServerUrl(String? value) async {
    await init();

    final normalized = value == null || value.trim().isEmpty
        ? null
        : _normalizeUrl(value.trim());

    if (normalized == null) {
      await _storage.delete(_keyCustomServerUrl);
      _customServerUrl = null;
      Logger.info('ServerConfigService cleared custom server URL');
      return;
    }

    await _storage.write(key: _keyCustomServerUrl, value: normalized);
    _customServerUrl = normalized;
    Logger.info('ServerConfigService saved custom server URL: $normalized');
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
