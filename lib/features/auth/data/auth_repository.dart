import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/platform/platform_storage.dart';
import '../../../shared/utils/extensions.dart';
import '../../../../shared/models/auth_models.dart'
    show Credentials, EncryptionType;
import '../../encryption/domain/crypto_service.dart';

part 'auth_repository_account_auth.dart';
part 'auth_repository_account_status.dart';
part 'auth_repository_credentials.dart';
part 'auth_repository_login.dart';
part 'auth_repository_models.dart';
part 'auth_repository_terminal.dart';

extension _EncryptionTypeStringExtension on String {
  EncryptionType toEncryptionType() {
    return EncryptionType.values.firstWhere(
      (type) => type.name == this,
      orElse: () => EncryptionType.legacy,
    );
  }
}

abstract class _AuthRepositoryBase {
  Dio get dioClient;
  PlatformStorage get storage;
  Options authorizedOptions(String token);
  Future<Credentials?> getCredentials();
  Future<Response<dynamic>> postAuthorized(
    String path, {
    required Map<String, dynamic> data,
    String? token,
    String? retryReason,
  });
}

/// 认证数据仓库
///
/// 负责与后端 API 通信和凭证存储
class AuthRepository extends _AuthRepositoryBase
    with
        _AuthRepositoryCredentialsMixin,
        _AuthRepositoryLoginMixin,
        _AuthRepositoryAccountAuthMixin,
        _AuthRepositoryAccountStatusMixin,
        _AuthRepositoryTerminalMixin {
  AuthRepository._();

  static final AuthRepository _instance = AuthRepository._();

  static AuthRepository get instance => _instance;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.serverUrl,
      connectTimeout: Duration(milliseconds: AppConfig.socketTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.socketTimeout),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': AppConfig.userAgent,
      },
    ),
  );

  final PlatformStorage _storage = PlatformStorage.instance;

  static const String _keyToken = 'auth_token';
  static const String _keyMachineId = 'machine_id';
  static const String _keyEncryptionKey = 'encryption_key';
  static const String _keyEncryptionType = 'encryption_type';
  static const String _keyPublicKey = 'public_key';
  static const String _keyMachineKey = 'machine_key';
  static const String _keySecret = 'secret';
  static const String _keyTempSecret = 'temp_secret_key';

  @override
  Dio get dioClient {
    _dio.options.baseUrl = AppConfig.serverUrl;
    return _dio;
  }

  @override
  PlatformStorage get storage => _storage;

  @override
  Options authorizedOptions(String token) {
    return Options(
      headers: {
        ..._dio.options.headers,
        'Authorization': 'Bearer $token',
      },
    );
  }

  @override
  Future<Response<dynamic>> postAuthorized(
    String path, {
    required Map<String, dynamic> data,
    String? token,
    String? retryReason,
  }) async {
    final resolvedToken = token ?? (await getCredentials())?.token;
    if (resolvedToken == null || resolvedToken.isEmpty) {
      throw Exception('Not authenticated');
    }

    try {
      return await dioClient.post(
        path,
        options: authorizedOptions(resolvedToken),
        data: data,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) {
        rethrow;
      }

      final reason = retryReason == null || retryReason.isEmpty
          ? path
          : '$path ($retryReason)';
      Logger.warning(
        'Authorized request received 401 for $reason; refreshing token from saved secret and retrying once',
      );

      final refreshedCredentials =
          await _refreshCredentialsFromSavedSecret(reason: reason);
      if (refreshedCredentials == null) {
        rethrow;
      }

      return dioClient.post(
        path,
        options: authorizedOptions(refreshedCredentials.token),
        data: data,
      );
    }
  }

  Future<Credentials?> _refreshCredentialsFromSavedSecret({
    required String reason,
  }) async {
    final secret = await storage.read(_keySecret);
    if (secret == null || secret.isEmpty) {
      Logger.warning(
        'Cannot refresh token for $reason: no saved secret available',
      );
      return null;
    }

    try {
      final response = await loginWithSecret(secret);
      await _persistLoginResponse(response, secret: secret);
      Logger.info('Auth token refreshed successfully for $reason');
      return Credentials(
        token: response.token,
        machineId: response.machineId,
        encryptionKey: response.encryptionKey ?? '',
        encryptionType: response.encryptionType,
        publicKey: response.publicKey ?? '',
        machineKey: response.machineKey ?? '',
        secret: secret,
      );
    } catch (error) {
      Logger.error('Token refresh failed for $reason: $error');
      return null;
    }
  }

  Future<void> _persistLoginResponse(
    LoginResponse response, {
    required String secret,
  }) async {
    await storage.write(key: _keyToken, value: response.token);
    await storage.write(key: _keyMachineId, value: response.machineId);
    await storage.write(
      key: _keyEncryptionType,
      value: response.encryptionType.name,
    );
    await storage.write(key: _keySecret, value: secret);

    if (response.encryptionKey != null) {
      await storage.write(
        key: _keyEncryptionKey,
        value: response.encryptionKey!,
      );
    }
    if (response.publicKey != null) {
      await storage.write(
        key: _keyPublicKey,
        value: response.publicKey!,
      );
    }
    if (response.machineKey != null) {
      await storage.write(
        key: _keyMachineKey,
        value: response.machineKey!,
      );
    }
  }
}
