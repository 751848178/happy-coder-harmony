part of 'auth_repository.dart';

mixin _AuthRepositoryAccountStatusMixin on _AuthRepositoryBase {
  Future<AccountAuthStatusResponse?> pollAccountAuthStatus() async {
    try {
      final secretKey = await storage.read(AuthRepository._keyTempSecret);
      if (secretKey == null) {
        return null;
      }

      final crypto = await CryptoService.instance;
      final publicKey = await crypto.getPublicKey(secretKey);
      Logger.info('Polling account auth status for: $publicKey');
      final response = await dioClient.post(
        '/v1/auth/account/request',
        data: {'publicKey': publicKey},
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final status = accountAuthStatusFromState(data['state'] as String?);
      final supportsV2 = data['supportsV2'] as bool? ?? false;
      if (status != AccountAuthStatus.authorized) {
        return AccountAuthStatusResponse(
          status: status,
          supportsV2: supportsV2,
        );
      }

      final encryptedResponse = data['response'] as String?;
      if (encryptedResponse == null) {
        return AccountAuthStatusResponse(
          status: status,
          supportsV2: supportsV2,
        );
      }

      final decrypted = await _decryptBox(encryptedResponse, secretKey);
      if (decrypted == null) {
        return AccountAuthStatusResponse(
          status: status,
          supportsV2: supportsV2,
        );
      }

      try {
        final decryptedData = jsonDecode(decrypted) as Map<String, dynamic>;
        await storage.delete(AuthRepository._keyTempSecret);
        final token = decryptedData['token'] as String?;
        final tokenPreview = token == null || token.isEmpty
            ? ''
            : token.substring(0, token.length < 16 ? token.length : 16);
        Logger.info(
          'Decrypted auth response, token: $tokenPreview...',
        );
        return AccountAuthStatusResponse(
          status: status,
          supportsV2: supportsV2,
          token: token,
          machineId: decryptedData['machine_id'] as String?,
          encryptionKey: decryptedData['encryption_key'] as String?,
          encryptionType: decryptedData['encryption_type'] as String?,
          publicKey: decryptedData['public_key'] as String?,
        );
      } catch (error) {
        Logger.error('Failed to parse decrypted data: $error');
        return AccountAuthStatusResponse(
          status: status,
          supportsV2: supportsV2,
        );
      }
    } on DioException catch (error) {
      Logger.error('Poll account auth status failed: ${error.message}');
      return null;
    }
  }

  Future<TerminalAuthStatusResponse?> getAccountAuthStatus(
    String publicKey,
  ) async {
    try {
      Logger.info('Checking account auth status for: $publicKey');
      final response = await dioClient.get(
        '/v1/auth/account/request',
        queryParameters: {'publicKey': publicKey},
      );
      if (response.statusCode != 200) {
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      return TerminalAuthStatusResponse(
        status: terminalAuthStatusFromState(data['state'] as String?),
        supportsV2: data['supportsV2'] as bool? ?? false,
      );
    } on DioException catch (error) {
      Logger.error('Get account auth status failed: ${error.message}');
      return null;
    }
  }

  Future<String?> _decryptBox(
    String encryptedBase64,
    String secretKeyBase64,
  ) async {
    try {
      final crypto = await CryptoService.instance;
      final decrypted = await crypto.cryptoBoxOpenEasy(
        encryptedBase64,
        secretKeyBase64,
      );
      if (decrypted != null) {
        Logger.info('Successfully decrypted account auth response');
        return decrypted;
      }
      Logger.warning('Decryption returned null');
      return encryptedBase64;
    } catch (error) {
      Logger.error('Decryption failed: $error');
      return null;
    }
  }
}
