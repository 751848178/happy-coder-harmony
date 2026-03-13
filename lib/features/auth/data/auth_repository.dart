import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/utils/extensions.dart';
import '../../../../shared/models/auth_models.dart'
    show
        Credentials,
        EncryptionType,
        SessionMessage,
        Artifact,
        KVPair,
        Friend,
        ConnectToken,
        User;
import '../../session/domain/session_models.dart';
import '../../encryption/domain/crypto_service.dart';
import '../../../shared/platform/platform_storage.dart';
import '../../../harmony/harmony_bridge.dart';

/// Extension for String to convert to EncryptionType
extension _EncryptionTypeStringExtension on String {
  EncryptionType toEncryptionType() {
    return EncryptionType.values.firstWhere(
      (e) => e.name == this,
      orElse: () => EncryptionType.legacy,
    );
  }
}

/// 认证数据仓库
///
/// 负责与后端 API 通信和凭证存储
class AuthRepository {
  AuthRepository._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.serverUrl,
    connectTimeout: Duration(milliseconds: AppConfig.socketTimeout),
    receiveTimeout: Duration(milliseconds: AppConfig.socketTimeout),
    headers: {
      'Content-Type': 'application/json',
      'User-Agent': AppConfig.userAgent,
    },
  ));

  final _storage = PlatformStorage.instance;

  /// 本地存储键
  static const String _keyToken = 'auth_token';
  static const String _keyMachineId = 'machine_id';
  static const String _keyEncryptionKey = 'encryption_key';
  static const String _keyEncryptionType = 'encryption_type';
  static const String _keyPublicKey = 'public_key';
  static const String _keyMachineKey = 'machine_key';
  static const String _keySecret = 'secret'; // Happy Coder 格式的 secret
  static const String _keyTempSecret = 'temp_secret_key'; // 用于轮询认证的临时密钥

  // ========== 公开方法 ==========

  /// 初始化仓库
  static AuthRepository get instance => AuthRepository._();

  /// 检查是否已认证
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(_keyToken);
    return token != null && token!.isNotEmpty;
  }

  /// 获取存储的凭证
  Future<Credentials?> getCredentials() async {
    final token = await _storage.read(_keyToken);
    if (token == null || token!.isEmpty) return null;

    final encryptionTypeStr = await _storage.read(_keyEncryptionType);
    final secret = await _storage.read(_keySecret);

    return Credentials(
      token: token!,
      machineId: await _storage.read(_keyMachineId) ?? '',
      encryptionKey: await _storage.read(_keyEncryptionKey) ?? '',
      encryptionType: encryptionTypeStr != null
          ? encryptionTypeStr.toEncryptionType()
          : EncryptionType.legacy,
      publicKey: await _storage.read(_keyPublicKey),
      machineKey: await _storage.read(_keyMachineKey),
      secret: secret, // Happy Coder 格式使用 secret 字段
    );
  }

  /// 清除认证凭证
  Future<void> clearCredentials() async {
    await _storage.delete(_keyToken);
    await _storage.delete(_keyMachineId);
    await _storage.delete(_keyEncryptionKey);
    await _storage.delete(_keyEncryptionType);
    await _storage.delete(_keyPublicKey);
    await _storage.delete(_keyMachineKey);
    await _storage.delete(_keySecret);
    await _storage.delete(_keyTempSecret);
  }

  // ========== API 方法 ==========

  /// 注册新账户（创建账户）
  ///
  /// [publicKey] Base64 编码的公钥
  /// 返回是否注册成功
  Future<bool> registerAccount(String publicKey) async {
    try {
      Logger.info('Registering new account with publicKey: $publicKey');

      final response = await _dio.post(
        '/v1/auth/account/request',
        data: {
          'publicKey': publicKey,
        },
      );

      Logger.info('Registration response: status=${response.statusCode}, data=${response.data}');

      if (response.statusCode == 200) {
        Logger.info('Account registered successfully');
        return true;
      } else {
        Logger.error('Account registration failed: status=${response.statusCode}, data=${response.data}');
        return false;
      }
    } on DioException catch (e) {
      Logger.error('Account registration DioException: type=${e.type}, message=${e.message}, response=${e.response}, statusCode=${e.response?.statusCode}');
      return false;
    } catch (e) {
      Logger.error('Account registration failed: $e');
      return false;
    }
  }

  /// 保存 secret key 到本地存储
  ///
  /// [secretKey] Base64 编码的私钥
  Future<void> saveSecretKey(String secretKey) async {
    try {
      await _storage.write(key: _keySecret, value: secretKey);
      Logger.info('Secret key saved locally');
    } catch (e) {
      Logger.error('Failed to save secret key: $e');
      rethrow;
    }
  }

  /// 使用 secret key 登录（扫描终端二维码）
  ///
  /// [secretKey] Base64 编码的私钥
  Future<LoginResponse> loginWithSecretKey(String secretKey) async {
    try {
      Logger.info('Logging in with secret key');

      // 使用 CryptoService 生成认证挑战和签名
      final crypto = await CryptoService.instance;
      final challengeResult = await crypto.authChallenge(secretKey);

      final response = await _dio.post(
        '/v1/auth',
        data: {
          'challenge': challengeResult['challenge'],
          'publicKey': challengeResult['publicKey'],
          'signature': challengeResult['signature'],
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final success = data['success'] as bool?;
        if (success == true && data['token'] != null) {
          final encryptionTypeStr = data['encryption_type'] as String?;
          return LoginResponse(
            token: data['token'] as String,
            machineId: data['machine_id'] as String? ??
                  data['machineId'] as String? ??
                  '',
            encryptionKey: data['encryption_key'] as String?,
            encryptionType: encryptionTypeStr != null
                ? encryptionTypeStr.toEncryptionType()
                : EncryptionType.legacy,
            publicKey: data['public_key'] as String?,
            machineKey: data['machine_key'] as String?,
          );
        } else {
          throw Exception('Authentication failed: ${response.data}');
        }
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      Logger.error('Login with secret key failed: ${e.message}');
      rethrow;
    }
  }

  /// 使用 secret 直接登录（Happy Coder 格式）
  ///
  /// [secret] Base64 编码的私钥
  /// 这个方法用于直接从 happy:// 链接获取 secret 后登录
  Future<LoginResponse> loginWithSecret(String secret) async {
    try {
      Logger.info('Logging in with secret (Happy Coder format)');

      // 使用 CryptoService 生成认证挑战和签名
      final crypto = await CryptoService.instance;
      final challengeResult = await crypto.authChallenge(secret);

      final response = await _dio.post(
        '/v1/auth',
        data: {
          'challenge': challengeResult['challenge'],
          'publicKey': challengeResult['publicKey'],
          'signature': challengeResult['signature'],
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final success = data['success'] as bool?;
        if (success == true && data['token'] != null) {
          final encryptionTypeStr = data['encryption_type'] as String?;

          return LoginResponse(
            token: data['token'] as String,
            machineId: data['machine_id'] as String? ??
                  data['machineId'] as String? ??
                  '',
            encryptionKey: data['encryption_key'] as String?,
            encryptionType: encryptionTypeStr != null
                ? encryptionTypeStr.toEncryptionType()
                : EncryptionType.legacy,
            publicKey: data['public_key'] as String?,
            machineKey: data['machine_key'] as String?,
            secret: secret, // 存储原始 secret 用于 Happy Coder 格式
          );
        } else {
          throw Exception('Authentication failed: ${response.data}');
        }
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      Logger.error('Login with secret failed: ${e.message}');
      rethrow;
    }
  }

  /// 批准账户认证请求（Happy Coder 风格）
  ///
  /// 当扫描终端生成的 happy:// 链接时，用此方法批准
  /// [publicKey] 终端的公钥
  /// [response] 加密的响应数据
  /// [credentials] 当前用户的凭证
  Future<bool> approveAccountAuth({
    required String publicKey,
    required String response,
    required Credentials credentials,
  }) async {
    try {
      Logger.info('Approving account auth for: $publicKey');

      final apiResponse = await _dio.post(
        '/v1/auth/account/response',
        options: Options(
          headers: {
            ..._dio.options.headers,
            'Authorization': 'Bearer ${credentials.token}',
          },
        ),
        data: {
          'publicKey': publicKey,
          'response': response,
        },
      );

      if (apiResponse.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to approve: ${apiResponse.statusCode}');
      }
    } on DioException catch (e) {
      Logger.error('Approve account auth failed: ${e.message}');
      return false;
    }
  }

  /// 生成 QR 码登录请求（用于扫描终端登录）
  ///
  /// Happy Coder 使用 happy:///account?base64url= 格式
  Future<QRCodeResponse> generateQRCodeForTerminal() async {
    try {
      Logger.info('Generating QR code for terminal login');

      // 生成密钥对用于认证
      final crypto = await CryptoService.instance;
      final keyPairResult = await crypto.generateKeyPair();

      final publicKey = keyPairResult['publicKey'];
      final secretKey = keyPairResult['secretKey'];

      // 保存私钥用于后续认证
      await _storage.write(
        key: _keyTempSecret,
        value: secretKey ?? '',
      );

      final response = await _dio.post(
        '/v1/auth/account/request',
        data: {
          'publicKey': publicKey,
        },
      );

      if (response.statusCode == 200) {
        // 构建 QR 码数据：happy:///account?base64url=<base64url(publicKey)>
        final encoded = CryptoService.base64UrlEncode(publicKey ?? '');
        final base64urlPublic = encoded;
        final qrData = 'happy:///account?base64url=$base64urlPublic';

        return QRCodeResponse(
          qrId: publicKey?.substring(0, 16) ?? '',
          qrData: qrData,
          secretKey: secretKey,
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        );
      } else {
        throw Exception('Failed to generate QR code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      Logger.error('QR code generation failed: ${e.message}');
      rethrow;
    }
  }

  /// 轮询账户认证状态（Happy Coder 风格）
  ///
  /// Happy Coder 使用 /v1/auth/account/request 端点
  Future<AccountAuthStatusResponse?> pollAccountAuthStatus() async {
    try {
      final secretKey = await _storage.read(_keyTempSecret);
      if (secretKey == null) {
        return null;
      }

      // 从 secretKey 派生公钥
      final crypto = await CryptoService.instance;
      final publicKey = await crypto.getPublicKey(secretKey);

      Logger.info('Polling account auth status for: $publicKey');

      final response = await _dio.post(
        '/v1/auth/account/request',
        data: {'publicKey': publicKey},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final state = data['state'] as String?;
        final supportsV2 = data['supportsV2'] as bool? ?? false;

        AccountAuthStatus resultStatus;
        switch (state) {
          case 'not_found':
            resultStatus = AccountAuthStatus.notFound;
            break;
          case 'pending':
            resultStatus = AccountAuthStatus.pending;
            break;
          case 'authorized':
            resultStatus = AccountAuthStatus.authorized;
            break;
          default:
            resultStatus = AccountAuthStatus.notFound;
        }

        if (resultStatus == AccountAuthStatus.authorized) {
          // 解密响应并获取 token
          final encryptedResponse = data['response'] as String?;
          if (encryptedResponse != null) {
            // 使用 libsodium 风格的解密
            final decrypted = await _decryptBox(encryptedResponse, secretKey);
            if (decrypted != null) {
              try {
                // 解析解密后的数据（JSON 格式）
                final decryptedData = jsonDecode(decrypted) as Map<String, dynamic>;
                final token = decryptedData['token'] as String?;
                final machineId = decryptedData['machine_id'] as String?;
                final encryptionKey = decryptedData['encryption_key'] as String?;
                final encryptionType = decryptedData['encryption_type'] as String?;
                final publicKeyResp = decryptedData['public_key'] as String?;

                Logger.info('Decrypted auth response, token: ${token?.substring(0, 16)}...');

                // 清除临时密钥
                await _storage.delete(_keyTempSecret);

                return AccountAuthStatusResponse(
                  status: resultStatus,
                  supportsV2: supportsV2,
                  token: token,
                  machineId: machineId,
                  encryptionKey: encryptionKey,
                  encryptionType: encryptionType,
                  publicKey: publicKeyResp,
                );
              } catch (e) {
                Logger.error('Failed to parse decrypted data: $e');
              }
            }
          }
        }

        return AccountAuthStatusResponse(
          status: resultStatus,
          supportsV2: supportsV2,
        );
      } else {
        return null;
      }
    } on DioException catch (e) {
      Logger.error('Poll account auth status failed: ${e.message}');
      return null;
    }
  }

  /// 解密 Box 格式的数据（libsodium 风格）
  Future<String?> _decryptBox(String encryptedBase64, String secretKeyBase64) async {
    try {
      final crypto = await CryptoService.instance;

      // 使用 CryptoService 解密
      final decrypted = await crypto.cryptoBoxOpenEasy(encryptedBase64, secretKeyBase64);

      if (decrypted != null) {
        Logger.info('Successfully decrypted account auth response');
        return decrypted;
      }

      Logger.warning('Decryption returned null');
      return encryptedBase64; // 回退
    } catch (e) {
      Logger.error('Decryption failed: $e');
      return null;
    }
  }

  /// 获取账户认证状态（用于检查是否有待批准的请求）
  ///
  /// Happy Coder 使用 /v1/auth/account/request 端点
  Future<TerminalAuthStatusResponse?> getAccountAuthStatus(String publicKey) async {
    try {
      Logger.info('Checking account auth status for: $publicKey');

      final response = await _dio.get(
        '/v1/auth/account/request',
        queryParameters: {
          'publicKey': publicKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final state = data['state'] as String?;
        final supportsV2 = data['supportsV2'] as bool? ?? false;

        TerminalAuthStatus resultStatus;
        switch (state) {
          case 'not_found':
            resultStatus = TerminalAuthStatus.notFound;
            break;
          case 'pending':
            resultStatus = TerminalAuthStatus.pending;
            break;
          case 'authorized':
            resultStatus = TerminalAuthStatus.authorized;
            break;
          default:
            resultStatus = TerminalAuthStatus.notFound;
        }

        return TerminalAuthStatusResponse(
          status: resultStatus,
          supportsV2: supportsV2,
        );
      } else {
        return null;
      }
    } on DioException catch (e) {
      Logger.error('Get account auth status failed: ${e.message}');
      return null;
    }
  }

  /// Base64 解码
  Uint8List _base64Decode(String input) {
    // 将 URL-safe base64 转换为标准 base64
    String standard = input
        .replaceAll('-', '+')
        .replaceAll('_', '/');

    // 补齐 padding
    while (standard.length % 4 != 0) {
      standard += '=';
    }

    return base64Decode(standard);
  }

  /// Base64 URL 编码（URL-safe base64）
  String _base64UrlEncode(String input) {
    final bytes = _base64Decode(input);
    return bytes
        .map((b) => b == 43 ? '-' : b == 61 ? '_' : b)
        .join('')
        .replaceAll(RegExp(r'=+$'), '');
  }

  /// 登出
  Future<void> logout() async {
    try {
      final credentials = await getCredentials();
      if (credentials == null) {
        await clearCredentials();
        return;
      }

      Logger.info('Logging out');

      // 通知服务器登出
      try {
        await _dio.post(
          '/v1/auth/logout',
          options: Options(
            headers: {
              ..._dio.options.headers,
              'Authorization': 'Bearer ${credentials.token}',
            },
          ),
        );
      } catch (e) {
        // 忽略登出失败，直接清除本地数据
        Logger.warning('Logout API failed: $e');
      }

      await clearCredentials();
    } catch (e) {
      Logger.error('Logout failed: $e');
      throw Exception('Logout failed: $e');
    }
  }

  // ========== 以下为保留的旧 API 方法，用于兼容性 ==========

  /// 批准终端认证请求（旧格式，保留兼容性）
  Future<bool> approveTerminalAuth({
    required String publicKey,
    required String response,
  }) async {
    try {
      Logger.info('Approving terminal auth for: $publicKey');

      final credentials = await getCredentials();
      if (credentials == null) {
        throw Exception('Not authenticated');
      }

      final apiResponse = await _dio.post(
        '/v1/auth/response',
        options: Options(
          headers: {
            ..._dio.options.headers,
            'Authorization': 'Bearer ${credentials.token}',
          },
        ),
        data: {
          'publicKey': publicKey,
          'response': response,
        },
      );

      if (apiResponse.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to approve: ${apiResponse.statusCode}');
      }
    } on DioException catch (e) {
      Logger.error('Approve terminal auth failed: ${e.message}');
      return false;
    }
  }

  /// 检查终端认证请求状态（旧格式）
  Future<TerminalAuthStatusResponse?> getTerminalAuthStatus(String publicKey) async {
    try {
      Logger.info('Checking terminal auth status for: $publicKey');

      final response = await _dio.get(
        '/v1/auth/request/status',
        queryParameters: {
          'publicKey': publicKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final status = data['status'] as String?;

        TerminalAuthStatus resultStatus;
        switch (status) {
          case 'not_found':
            resultStatus = TerminalAuthStatus.notFound;
            break;
          case 'pending':
            resultStatus = TerminalAuthStatus.pending;
            break;
          case 'authorized':
            resultStatus = TerminalAuthStatus.authorized;
            break;
          default:
            resultStatus = TerminalAuthStatus.notFound;
        }

        return TerminalAuthStatusResponse(
          status: resultStatus,
          supportsV2: data['supportsV2'] as bool? ?? false,
        );
      } else {
        return null;
      }
    } on DioException catch (e) {
      Logger.error('Get terminal auth status failed: ${e.message}');
      return null;
    }
  }
}

// ========== 数据模型 ==========

/// 账户认证状态响应（Happy Coder 格式）
class AccountAuthStatusResponse {
  const AccountAuthStatusResponse({
    required this.status,
    this.supportsV2 = false,
    this.token,
    this.machineId,
    this.encryptionKey,
    this.encryptionType,
    this.publicKey,
  });

  final AccountAuthStatus status;
  final bool supportsV2;
  final String? token; // 当状态为 authorized 时包含 token
  final String? machineId; // 从解密响应中获取
  final String? encryptionKey; // 从解密响应中获取
  final String? encryptionType; // 从解密响应中获取
  final String? publicKey; // 从解密响应中获取

  /// 检查是否成功认证
  bool get isAuthorized => status == AccountAuthStatus.authorized && token != null;
}

/// 账户认证状态枚举
enum AccountAuthStatus {
  notFound,
  pending,
  authorized,
}

/// QR 码响应
class QRCodeResponse {
  const QRCodeResponse({
    required this.qrId,
    required this.qrData,
    required this.expiresAt,
    this.secretKey,
  });

  final String qrId;
  final String qrData;
  final DateTime expiresAt;
  final String? secretKey; // 私钥，用于后续认证
}

/// 登录响应
class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.machineId,
    this.encryptionKey,
    required this.encryptionType,
    this.publicKey,
    this.machineKey,
    this.secret, // Happy Coder 格式使用 secret 字段
  });

  final String token;
  final String machineId;
  final String? encryptionKey;
  final EncryptionType encryptionType;
  final String? publicKey;
  final String? machineKey;
  final String? secret; // Happy Coder 格式使用 secret 字段
}

/// 终端认证状态响应
class TerminalAuthStatusResponse {
  const TerminalAuthStatusResponse({
    required this.status,
    required this.supportsV2,
  });

  final TerminalAuthStatus status;
  final bool supportsV2;
}

/// 终端认证状态枚举
enum TerminalAuthStatus {
  notFound,
  pending,
  authorized,
}
