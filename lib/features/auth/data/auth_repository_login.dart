part of 'auth_repository.dart';

mixin _AuthRepositoryLoginMixin on _AuthRepositoryBase {
  Future<bool> registerAccount(String publicKey) async {
    try {
      Logger.info('Registering new account with publicKey: $publicKey');
      final response = await dioClient.post(
        '/v1/auth/account/request',
        data: {'publicKey': publicKey},
      );
      Logger.info(
        'Registration response: status=${response.statusCode}, data=${response.data}',
      );
      return response.statusCode == 200;
    } on DioException catch (error) {
      Logger.error(
        'Account registration DioException: type=${error.type}, message=${error.message}, response=${error.response}, statusCode=${error.response?.statusCode}',
      );
      return false;
    } catch (error) {
      Logger.error('Account registration failed: $error');
      return false;
    }
  }

  Future<LoginResponse> loginWithSecretKey(String secretKey) async {
    return _loginWithAuthSecret(secretKey);
  }

  Future<LoginResponse> loginWithSecret(String secret) async {
    return _loginWithAuthSecret(
      secret,
      secretForResponse: secret,
      logLabel: 'secret (Happy Coder format)',
    );
  }

  Future<LoginResponse> _loginWithAuthSecret(
    String authSecret, {
    String? secretForResponse,
    String logLabel = 'secret key',
  }) async {
    try {
      Logger.info('Logging in with $logLabel');
      final crypto = await CryptoService.instance;
      final challengeResult = await crypto.authChallenge(authSecret);
      final response = await dioClient.post(
        '/v1/auth',
        data: {
          'challenge': challengeResult['challenge'],
          'publicKey': challengeResult['publicKey'],
          'signature': challengeResult['signature'],
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Login failed: ${response.statusCode}');
      }
      return _parseLoginResponse(
        response.data as Map<String, dynamic>,
        secret: secretForResponse,
      );
    } on DioException catch (error) {
      Logger.error('Login with $logLabel failed: ${error.message}');
      rethrow;
    }
  }

  LoginResponse _parseLoginResponse(
    Map<String, dynamic> data, {
    String? secret,
  }) {
    final success = data['success'] as bool?;
    if (success != true || data['token'] == null) {
      throw Exception('Authentication failed: $data');
    }

    final encryptionTypeStr = data['encryption_type'] as String?;
    return LoginResponse(
      token: data['token'] as String,
      machineId:
          data['machine_id'] as String? ?? data['machineId'] as String? ?? '',
      encryptionKey: data['encryption_key'] as String?,
      encryptionType: encryptionTypeStr != null
          ? encryptionTypeStr.toEncryptionType()
          : EncryptionType.legacy,
      publicKey: data['public_key'] as String?,
      machineKey: data['machine_key'] as String?,
      secret: secret,
    );
  }
}
