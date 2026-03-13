import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../data/auth_repository.dart'
    show AuthRepository, LoginResponse, AccountAuthStatus, TerminalAuthStatus;
import '../data/token_storage_service.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/models/auth_models.dart';
import '../../../shared/models/auth_state.dart';
import '../../encryption/domain/crypto_service.dart';

/// 认证 Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authRepository) : super(AuthState.initial);

  final AuthRepository _authRepository;
  final TokenStorageService _storage = TokenStorageService.instance;

  Timer? _accountPollingTimer;
  DateTime? _qrExpiresAt;

  /// 使用 secret key 登录（扫描终端二维码）
  Future<void> loginWithSecretKey(String secretKey) async {
    state = AuthState.loading;

    try {
      final response = await _authRepository.loginWithSecretKey(secretKey);
      await _authRepository.saveSecretKey(secretKey);
      await _saveCredentials(response);

      state = AuthState.authenticated(
          credentials: Credentials(
        token: response.token,
        machineId: response.machineId,
        encryptionKey: response.encryptionKey ?? '',
        encryptionType: response.encryptionType,
        publicKey: response.publicKey ?? '',
        machineKey: response.machineKey ?? '',
        secret: secretKey, // 存储原始 secret
      ));

      Logger.info('Login with secret key successful');
    } catch (e) {
      state = AuthState.error('Failed to login: $e');
      Logger.error('Login with secret key error: $e');
    }
  }

  /// 使用 Happy Coder 格式的 secret 登录（happy:// 链接）
  ///
  /// [secret] Base64 编码的私钥（Happy Coder 格式）
  Future<void> loginWithHappySecret(String secret) async {
    state = AuthState.loading;

    try {
      final response = await _authRepository.loginWithSecret(secret);
      await _authRepository.saveSecretKey(secret);
      await _saveCredentials(response);

      state = AuthState.authenticated(
          credentials: Credentials(
        token: response.token,
        machineId: response.machineId,
        encryptionKey: response.encryptionKey ?? '',
        encryptionType: response.encryptionType,
        publicKey: response.publicKey ?? '',
        machineKey: response.machineKey ?? '',
        secret: secret, // 存储原始 secret
      ));

      Logger.info('Login with Happy Coder secret successful');
    } catch (e) {
      state = AuthState.error('Failed to login: $e');
      Logger.error('Login with Happy Coder secret error: $e');
    }
  }

  /// 直接输入链接登录
  ///
  /// [linkUrl] 链接，支持多种格式：
  /// - happy://<base64_secret> (Happy Coder 格式）
  /// - happy:///account?base64url=<base64url(publicKey)> (Happy Coder 移动端扫描）
  /// - handy://<base64_secret_key> (CLI 生成，向后兼容）
  /// - https://happy.link/<base64_secret_key> (HarmonyOS 原生扫描）
  Future<void> loginWithLink(String linkUrl) async {
    state = AuthState.loading;

    try {
      if (linkUrl.startsWith('happy:///account?')) {
        await _startAccountAuth(linkUrl);
        return;
      }

      final secretKey = _parseLinkForSecretKey(linkUrl);
      if (secretKey == null) {
        throw Exception('Invalid link format');
      }

      final response = await _authRepository.loginWithSecretKey(secretKey);
      await _authRepository.saveSecretKey(secretKey);
      await _saveCredentials(response);

      state = AuthState.authenticated(
          credentials: Credentials(
        token: response.token,
        machineId: response.machineId,
        encryptionKey: response.encryptionKey ?? '',
        encryptionType: response.encryptionType,
        publicKey: response.publicKey ?? '',
        machineKey: response.machineKey ?? '',
        secret: secretKey,
      ));

      Logger.info('Login with link successful: $linkUrl');
    } catch (e) {
      state = AuthState.error('Failed to login: $e');
      Logger.error('Login with link error: $e');
    }
  }

  /// 解析链接提取 secret key
  ///
  /// 支持：
  /// - happy://<base64_secret> (Happy Coder 格式）
  /// - happy://terminal?<base64_secret> (终端链接格式)
  /// - happy://?secret=<base64_secret> (标准查询参数)
  /// - happy:///account?base64url=<base64url(publicKey)> (Happy Coder 移动端扫描）
  /// - handy://<base64_secret_key> (CLI 生成，向后兼容）
  /// - https://happy.link/<base64_secret_key> (HarmonyOS 原生扫描）
  String? _parseLinkForSecretKey(String linkUrl) {
    try {
      Logger.info('Parsing link: $linkUrl');

      // 解析 happy://<base64_secret> (Happy Coder 格式）
      if (linkUrl.startsWith('happy://')) {
        final uri = Uri.tryParse(linkUrl);
        if (uri != null) {
          // Prefer query parameter (e.g. happy://?secret=XXX)
          if (uri.query.isNotEmpty) {
            final secretParam = uri.queryParameters['secret'] ??
                uri.queryParameters['key'] ??
                uri.queryParameters['token'];
            if (secretParam != null && secretParam.isNotEmpty) {
              Logger.info('Secret from query param: ${secretParam.length}');
              return _normalizeBase64(secretParam);
            }

            // Format: happy://terminal?ISled... (no key=value)
            if (uri.queryParameters.length == 1) {
              final entry = uri.queryParameters.entries.first;
              if (entry.value.isEmpty && entry.key.isNotEmpty) {
                Logger.info('Secret from query key: ${entry.key.length}');
                return _normalizeBase64(entry.key);
              }
            }

            Logger.info('Secret from raw query: ${uri.query.length}');
            return _normalizeBase64(uri.query);
          }

          // Format: happy://<secret> where secret is host
          if (uri.host.isNotEmpty &&
              uri.host != 'terminal' &&
              uri.host != 'account') {
            Logger.info('Secret from host: ${uri.host.length}');
            return _normalizeBase64(uri.host);
          }

          // Format: happy:///SECRET
          var path = uri.path;
          if (path.startsWith('/')) {
            path = path.substring(1);
          }
          if (path.isNotEmpty) {
            Logger.info('Secret from path: ${path.length}');
            return _normalizeBase64(path);
          }
        }

        final value = linkUrl.substring(8);
        Logger.info('Value from happy:// link: ${value.length}');
        return _normalizeBase64(value);
      }

      // 解析 https://happy.link/xxxxx (HarmonyOS 原生扫描的格式）
      if (linkUrl.startsWith('https://happy.link/')) {
        final value = linkUrl.substring(19); // https://happy.link/ 后面的部分
        Logger.info('Value from happy.link: ${value.length}');
        return _normalizeBase64(value);
      }

      // 解析 handy://<base64_secret_key> (backward compatibility)
      if (linkUrl.startsWith('handy://')) {
        final encodedSecret = linkUrl.substring(8);
        Logger.info(
            'Encoded secret from handy:// link: ${encodedSecret.length}');
        final normalized = _normalizeBase64(encodedSecret);
        final decoded = utf8.decode(base64Decode(normalized));
        Logger.info('Decoded secret key length: ${decoded.length}');
        return _normalizeBase64(decoded);
      }

      // 解析 happy:///account?base64url=<base64url(publicKey)>
      // 这个格式用于移动端扫描，需要启动轮询流程
      if (linkUrl.startsWith('happy:///account?')) {
        // 这个格式不直接返回 secret，由 _startAccountAuth 处理
        return null; // 返回 null 表示需要特殊处理
      }

      Logger.error('Invalid link format: $linkUrl');
      return null;
    } catch (e) {
      Logger.error('Parse link error: $e');
      return null;
    }
  }

  String _normalizeBase64(String input) {
    var standard = input.trim().replaceAll('-', '+').replaceAll('_', '/');
    while (standard.length % 4 != 0) {
      standard += '=';
    }
    return standard;
  }

  /// Base64 URL to standard Base64 (with padding)
  String _base64Decode(String input) {
    var standard = input.trim().replaceAll('-', '+').replaceAll('_', '/');
    while (standard.length % 4 != 0) {
      standard += '=';
    }
    return standard;
  }

  /// 启动账户认证轮询流程（Happy Coder 格式）
  ///
  /// 当扫描 happy:///account? 链接时启动
  Future<void> _startAccountAuth(String linkUrl) async {
    try {
      // 提取 base64url 参数
      final uri = Uri.parse(linkUrl);
      final base64url = uri.queryParameters['base64url'];
      if (base64url == null) {
        throw Exception('Missing base64url parameter');
      }

      // Base64 URL 解码获取公钥
      final publicKey = _base64Decode(base64url);
      Logger.info('Public key from link: $publicKey');

      // 存储公钥用于轮询
      await _storage.write(key: 'temp_public_key', value: publicKey);

      // 开始轮询认证状态
      _startAccountPolling(publicKey);

      // 更新状态为等待授权
      state = AuthState.accountAuthPolling(
        publicKey: publicKey,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );

      Logger.info('Account auth polling started');
    } catch (e) {
      state = AuthState.error('Failed to start account auth: $e');
      Logger.error('Start account auth error: $e');
    }
  }

  /// 开始账户认证轮询
  void _startAccountPolling(String publicKey) {
    _stopAccountPolling();

    _accountPollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) => _pollAccountAuth(publicKey),
    );

    Logger.info('Account auth polling started');
  }

  /// 停止账户认证轮询
  void _stopAccountPolling() {
    _accountPollingTimer?.cancel();
    _accountPollingTimer = null;

    if (_qrExpiresAt != null) {
      final duration = DateTime.now().difference(_qrExpiresAt!);
      Logger.info('Account auth polling stopped after ${duration.inSeconds}s');
    }

    // 清除临时数据
    _storage.delete('temp_public_key');
  }

  /// 轮询账户认证状态
  Future<void> _pollAccountAuth(String publicKey) async {
    try {
      // 检查是否过期
      if (_qrExpiresAt != null && DateTime.now().isAfter(_qrExpiresAt!)) {
        _stopAccountPolling();
        state = AuthState.error('Account auth request expired');
        return;
      }

      // 轮询认证状态
      final response = await _authRepository.pollAccountAuthStatus();

      if (response != null) {
        if (response.isAuthorized) {
          _stopAccountPolling();

          // 使用从解密响应中获取的完整凭证
          await _saveCredentials(LoginResponse(
            token: response.token!,
            machineId: response.machineId ?? '',
            encryptionKey: response.encryptionKey,
            encryptionType: response.encryptionType != null
                ? response.encryptionType!.toEncryptionType()
                : EncryptionType.legacy,
            publicKey: response.publicKey,
            machineKey: null,
          ));

          // 获取保存的凭证（包含 secret）
          final savedCredentials = await _authRepository.getCredentials();

          state = AuthState.authenticated(
              credentials: savedCredentials ??
                  Credentials(
                    token: response.token!,
                    machineId: response.machineId ?? '',
                    encryptionKey: response.encryptionKey ?? '',
                    encryptionType: response.encryptionType != null
                        ? response.encryptionType!.toEncryptionType()
                        : EncryptionType.legacy,
                    publicKey: response.publicKey ?? '',
                    machineKey: '',
                    secret: '', // 链接登录时 secret 由其他设备生成
                  ));

          Logger.info('Account auth successful: linked device authorized');
        } else if (response.status == AccountAuthStatus.notFound) {
          _stopAccountPolling();
          state = AuthState.error('Account auth request not found');
        }
        // pending 状态继续等待
      }
    } catch (e) {
      Logger.error('Poll account auth error: $e');
      // 继续轮询，不中断
    }
  }

  /// 保存凭证
  Future<void> _saveCredentials(LoginResponse credentials) async {
    await _storage.saveToken(credentials.token);
    await _storage.saveMachineId(credentials.machineId);
    if (credentials.encryptionKey != null) {
      await _storage.saveEncryptionKey(credentials.encryptionKey!);
    }
    final encryptionType = credentials.encryptionType;
    await _storage.saveEncryptionType(encryptionType);
    if (credentials.publicKey != null) {
      await _storage.savePublicKey(credentials.publicKey!);
    }
    if (credentials.machineKey != null) {
      await _storage.saveMachineKey(credentials.machineKey!);
    }
    Logger.info('Credentials saved successfully');
  }

  /// 生成 QR 码（用于终端扫描登录）
  Future<void> generateQRCodeForTerminal() async {
    state = AuthState.loading;

    try {
      final response = await _authRepository.generateQRCodeForTerminal();
      _qrExpiresAt = response.expiresAt;

      state = AuthState.qrCode(
        qrId: response.qrId,
        qrData: response.qrData,
        expiresAt: response.expiresAt,
      );

      Logger.info('QR code generated: ${response.qrId}');
    } catch (e) {
      state = AuthState.error('Failed to generate QR code: $e');
      _stopAccountPolling();
      Logger.error('Generate QR code error: $e');
    }
  }

  /// 创建账户后开始轮询授权
  Future<void> startAccountAuthPolling({
    required String secretKey,
    required DateTime expiresAt,
  }) async {
    try {
      final crypto = await CryptoService.instance;
      final publicKey = await crypto.getPublicKey(secretKey);
      _qrExpiresAt = expiresAt;
      _startAccountPolling(publicKey);
      state = AuthState.accountAuthPolling(
        publicKey: publicKey,
        expiresAt: expiresAt,
      );
      Logger.info('Account auth polling started for create account');
    } catch (e) {
      Logger.error('Start account auth polling failed: $e');
      state = AuthState.error('Failed to start account auth: $e');
    }
  }

  /// 取消账户认证轮询
  Future<void> cancelAccountAuth() async {
    state = AuthState.loading;

    try {
      _stopAccountPolling();
      await _storage.delete('temp_public_key');
      await _storage.delete('temp_secret');

      state = AuthState.initial;

      Logger.info('Account auth cancelled');
    } catch (e) {
      state = AuthState.error('Failed to cancel: $e');
      Logger.error('Cancel account auth error: $e');
    }
  }

  /// 连接终端（happy://terminal?{publicKey}）
  ///
  /// 返回 true 表示已成功连接或已授权
  Future<bool> connectTerminal(String authUrl) async {
    final credentials =
        state.credentials ?? await _authRepository.getCredentials();
    if (credentials == null ||
        credentials.secret == null ||
        credentials.secret!.isEmpty) {
      throw Exception('未找到凭证，请先登录');
    }

    final publicKeyBytes = _parseTerminalPublicKey(authUrl);
    if (publicKeyBytes == null) {
      throw Exception('终端链接格式不正确');
    }

    final publicKeyBase64 = base64Encode(publicKeyBytes);

    // 构造响应
    final crypto = await CryptoService.instance;
    final secretBytes = CryptoService.decodeBase64Flexible(credentials.secret!);
    final responseV1 =
        await crypto.encryptBoxBundle(secretBytes, publicKeyBytes);
    final contentPublicKey =
        await crypto.deriveHappyCoderContentPublicKey(credentials.secret!);
    final v2Payload = Uint8List(1 + contentPublicKey.length);
    v2Payload[0] = 0;
    v2Payload.setAll(1, contentPublicKey);
    final responseV2 = await crypto.encryptBoxBundle(v2Payload, publicKeyBytes);

    final status = await _authRepository.getTerminalAuthStatus(publicKeyBase64);
    if (status == null) {
      throw Exception(
        '无法获取终端认证状态，请确认手机与 PC CLI 使用同一个 Happy Server：${AppConfig.serverUrl}',
      );
    }

    if (status.status == TerminalAuthStatus.authorized) {
      return true;
    }

    if (status.status == TerminalAuthStatus.notFound) {
      return true;
    }

    final responseBytes = status.supportsV2 ? responseV2 : responseV1;
    final responseBase64 = base64Encode(responseBytes);

    final success = await _authRepository.approveTerminalAuth(
      publicKey: publicKeyBase64,
      response: responseBase64,
    );

    if (!success) {
      throw Exception('终端连接失败');
    }

    return true;
  }

  Uint8List? _parseTerminalPublicKey(String authUrl) {
    final cleaned = authUrl.trim();
    if (cleaned.isEmpty) return null;

    String? value;
    if (cleaned.startsWith('happy://terminal?')) {
      final uri = Uri.tryParse(cleaned);
      if (uri != null && uri.query.isNotEmpty) {
        final param = uri.queryParameters['publicKey'] ??
            uri.queryParameters['key'] ??
            uri.queryParameters['token'];
        if (param != null && param.isNotEmpty) {
          value = param;
        } else if (uri.queryParameters.length == 1) {
          final entry = uri.queryParameters.entries.first;
          if (entry.value.isEmpty && entry.key.isNotEmpty) {
            value = entry.key;
          }
        } else {
          value = uri.query;
        }
      } else {
        value = cleaned.substring('happy://terminal?'.length);
      }
    } else {
      // 允许直接输入 base64url 公钥
      value = cleaned;
    }

    if (value == null || value.isEmpty) return null;
    return _decodeBase64Flexible(value);
  }

  Uint8List _decodeBase64Flexible(String input) {
    var standard = input.trim().replaceAll('-', '+').replaceAll('_', '/');
    while (standard.length % 4 != 0) {
      standard += '=';
    }
    return base64Decode(standard);
  }

  /// 链接账户批准（扫描新设备 QR 码时）
  ///
  /// [authUrl] 认证链接，格式为 happy:///account?base64url=<publicKey>
  /// 或者直接传递公钥的 base64url 编码
  Future<bool> linkAccount(String authUrlOrKey) async {
    state = AuthState.loading;

    try {
      final credentials = await _authRepository.getCredentials();
      if (credentials == null ||
          credentials.secret == null ||
          credentials.secret!.isEmpty) {
        state = AuthState.error('No credentials available');
        return false;
      }

      String publicKeyBase64Url;

      // 解析链接获取公钥，或直接使用传入的 base64url 公钥
      if (authUrlOrKey.startsWith('happy:///account?')) {
        // 解析 happy:///account?base64url=<publicKey> 格式
        final uri = Uri.tryParse(authUrlOrKey);
        if (uri != null && uri.queryParameters.containsKey('base64url')) {
          publicKeyBase64Url = uri.queryParameters['base64url']!;
        } else {
          // 尝试从字符串中提取参数
          final paramStart = authUrlOrKey.indexOf('base64url=');
          if (paramStart > 0) {
            publicKeyBase64Url = authUrlOrKey.substring(paramStart + 10);
          } else {
            throw Exception('Could not parse base64url parameter from URL');
          }
        }
      } else {
        // 直接使用传入的公钥 base64url
        publicKeyBase64Url = authUrlOrKey;
      }

      Logger.info(
          'Linking account with public key (base64url): $publicKeyBase64Url');

      // Base64 URL 解码获取 Curve25519 公钥
      final crypto = await CryptoService.instance;
      final publicKeyBase64 = CryptoService.base64UrlDecode(publicKeyBase64Url);

      Logger.info('Linking account with public key (base64): $publicKeyBase64');

      // 使用 libsodium 加密当前设备的 secret 作为响应
      // 需要传入: message, publicKey (Curve25519), secretKey
      final encryptedResponse = await crypto.cryptoBoxForLink(
        credentials.secret!,
        publicKeyBase64,
        credentials.secret!,
      );

      if (encryptedResponse == null) {
        state = AuthState.error('Encryption failed - sodium not available');
        return false;
      }

      // 发送批准请求到服务器
      final success = await _authRepository.approveAccountAuth(
        publicKey: publicKeyBase64,
        response: encryptedResponse,
        credentials: credentials,
      );

      if (success) {
        state = AuthState.authenticated(credentials: credentials);
        Logger.info('Account linked successfully');
      } else {
        state = AuthState.error('Failed to link account');
      }

      return success;
    } catch (e) {
      state = AuthState.error('Failed to link account: $e');
      Logger.error('Link account error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    state = AuthState.loading;

    try {
      await _authRepository.logout();
      _stopAccountPolling();

      state = AuthState.initial;

      Logger.info('User logged out');
    } catch (e) {
      state = AuthState.error('Failed to logout: $e');
      Logger.error('Logout error: $e');
    }
  }

  // TODO: Implement backup keys functionality
  // Future<void> backupKeys(String password) async {
  //   final strength = Validation.checkPasswordStrength(password);
  //   if (strength == PasswordStrength.weak) {
  //     state = AuthState.error('Password too weak');
  //     return;
  //   }
  //
  //   state = AuthState.loading;
  //
  //   try {
  //     final response = await _authRepository.backupKeys(password);
  //     state = AuthState.backupSuccess(
  //       backupId: response.backupId,
  //       encryptedData: response.encryptedData,
  //     );
  //
  //     Logger.info('Keys backed up successfully: ${response.backupId}');
  //   } catch (e) {
  //     state = AuthState.error('Failed to backup keys: $e');
  //     Logger.error('Backup keys error: $e');
  //   }
  // }

  // TODO: Implement restore keys functionality
  // Future<void> restoreKeys(String backupId, String password) async {
  //   state = AuthState.loading;
  //
  //   try {
  //     final response = await _authRepository.restoreKeys(backupId, password);
  //     final credentials = Credentials(
  //       token: response.token,
  //       machineId: response.machineId,
  //       encryptionKey: response.encryptionKey ?? '',
  //       encryptionType: response.encryptionType,
  //       publicKey: response.publicKey ?? '',
  //       machineKey: response.machineKey ?? '',
  //       secret: null, // 恢复时 secret 可能为 null
  //     );
  //
  //     state = AuthState.authenticated(credentials: credentials);
  //
  //     Logger.info('Keys restored successfully');
  //   } catch (e) {
  //     state = AuthState.error('Failed to restore keys: $e');
  //     Logger.error('Restore keys error: $e');
  //   }
  // }

  Future<void> checkAuthStatus() async {
    final isAuthenticated = await _authRepository.isAuthenticated();

    if (isAuthenticated) {
      final credentials = await _authRepository.getCredentials();
      if (credentials != null) {
        state = AuthState.authenticated(credentials: credentials);
      } else {
        state = AuthState.initial;
      }
    } else {
      state = AuthState.initial;
    }
  }

  /// 单次轮询状态检查（用于 QR 码屏幕）
  ///
  /// 返回状态字符串或 null
  Future<String?> pollStatusOnce() async {
    try {
      final response = await _authRepository.pollAccountAuthStatus();

      if (response != null) {
        if (response.isAuthorized) {
          _stopAccountPolling();

          // 使用从解密响应中获取的完整凭证
          await _saveCredentials(LoginResponse(
            token: response.token!,
            machineId: response.machineId ?? '',
            encryptionKey: response.encryptionKey,
            encryptionType: response.encryptionType != null
                ? response.encryptionType!.toEncryptionType()
                : EncryptionType.legacy,
            publicKey: response.publicKey,
            machineKey: null,
          ));

          // 获取保存的凭证
          final savedCredentials = await _authRepository.getCredentials();

          state = AuthState.authenticated(
              credentials: savedCredentials ??
                  Credentials(
                    token: response.token!,
                    machineId: response.machineId ?? '',
                    encryptionKey: response.encryptionKey ?? '',
                    encryptionType: response.encryptionType != null
                        ? response.encryptionType!.toEncryptionType()
                        : EncryptionType.legacy,
                    publicKey: response.publicKey ?? '',
                    machineKey: '',
                    secret: '',
                  ));

          Logger.info('Account auth successful via QR scan');
          return 'authorized';
        } else if (response.status == AccountAuthStatus.notFound) {
          _stopAccountPolling();
          Logger.warning('Account auth request not found');
          return 'rejected';
        }
      }

      return null;
    } catch (e) {
      Logger.error('Poll status once error: $e');
      return null;
    }
  }
}
