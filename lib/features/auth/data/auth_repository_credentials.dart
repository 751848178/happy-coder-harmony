part of 'auth_repository.dart';

mixin _AuthRepositoryCredentialsMixin on _AuthRepositoryBase {
  Future<bool> isAuthenticated() async {
    final token = await storage.read(AuthRepository._keyToken);
    return token != null && token.isNotEmpty;
  }

  Future<Credentials?> getCredentials() async {
    final token = await storage.read(AuthRepository._keyToken);
    if (token == null || token.isEmpty) {
      return null;
    }

    final encryptionTypeStr =
        await storage.read(AuthRepository._keyEncryptionType);
    return Credentials(
      token: token,
      machineId: await storage.read(AuthRepository._keyMachineId) ?? '',
      encryptionKey: await storage.read(AuthRepository._keyEncryptionKey) ?? '',
      encryptionType: encryptionTypeStr != null
          ? encryptionTypeStr.toEncryptionType()
          : EncryptionType.legacy,
      publicKey: await storage.read(AuthRepository._keyPublicKey),
      machineKey: await storage.read(AuthRepository._keyMachineKey),
      secret: await storage.read(AuthRepository._keySecret),
    );
  }

  Future<void> clearCredentials() async {
    await storage.delete(AuthRepository._keyToken);
    await storage.delete(AuthRepository._keyMachineId);
    await storage.delete(AuthRepository._keyEncryptionKey);
    await storage.delete(AuthRepository._keyEncryptionType);
    await storage.delete(AuthRepository._keyPublicKey);
    await storage.delete(AuthRepository._keyMachineKey);
    await storage.delete(AuthRepository._keySecret);
    await storage.delete(AuthRepository._keyTempSecret);
  }

  Future<void> saveSecretKey(String secretKey) async {
    try {
      await storage.write(key: AuthRepository._keySecret, value: secretKey);
      Logger.info('Secret key saved locally');
    } catch (error) {
      Logger.error('Failed to save secret key: $error');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final credentials = await getCredentials();
      if (credentials == null) {
        await clearCredentials();
        return;
      }

      Logger.info('Logging out');
      try {
        await dioClient.post(
          '/v1/auth/logout',
          options: authorizedOptions(credentials.token),
        );
      } catch (error) {
        Logger.warning('Logout API failed: $error');
      }

      await clearCredentials();
    } catch (error) {
      Logger.error('Logout failed: $error');
      throw Exception('Logout failed: $error');
    }
  }
}
