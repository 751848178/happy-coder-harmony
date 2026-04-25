part of 'auth_notifier.dart';

Future<void> _completeSecretLogin(
  AuthNotifier notifier,
  LoginResponse response, {
  required String secret,
}) async {
  await notifier._authRepository.saveSecretKey(secret);
  await _saveCredentials(notifier, response);
  notifier._updateState(AuthState.authenticated(
    credentials: _credentialsFromLoginResponse(response, secret: secret),
  ));
}

Future<void> _completeAuthorizedAccountAuth(
  AuthNotifier notifier,
  AccountAuthStatusResponse response, {
  required String successLog,
}) async {
  _stopAccountPolling(notifier);
  await _saveCredentials(notifier, _loginResponseFromAccountAuth(response));
  final savedCredentials = await _restoreStoredAuthenticatedCredentials(
    notifier,
  );
  notifier._updateState(AuthState.authenticated(
    credentials: savedCredentials ?? _credentialsFromAccountAuth(response),
  ));
  Logger.info(successLog);
}

Future<void> _saveCredentials(
  AuthNotifier notifier,
  LoginResponse credentials,
) async {
  await notifier._storage.saveToken(credentials.token);
  await notifier._storage.saveMachineId(credentials.machineId);
  if (credentials.encryptionKey != null) {
    await notifier._storage.saveEncryptionKey(credentials.encryptionKey!);
  }
  await notifier._storage.saveEncryptionType(credentials.encryptionType);
  if (credentials.publicKey != null) {
    await notifier._storage.savePublicKey(credentials.publicKey!);
  }
  if (credentials.machineKey != null) {
    await notifier._storage.saveMachineKey(credentials.machineKey!);
  }
  Logger.info('Credentials saved successfully');
}

Future<Credentials?> _restoreStoredAuthenticatedCredentials(
  AuthNotifier notifier,
) async {
  final savedCredentials = await notifier._authRepository.getCredentials();
  if (savedCredentials != null) {
    notifier._updateState(
      AuthState.authenticated(credentials: savedCredentials),
    );
  }
  return savedCredentials;
}

Credentials _credentialsFromLoginResponse(
  LoginResponse response, {
  required String secret,
}) {
  return Credentials(
    token: response.token,
    machineId: response.machineId,
    encryptionKey: response.encryptionKey ?? '',
    encryptionType: response.encryptionType,
    publicKey: response.publicKey ?? '',
    machineKey: response.machineKey ?? '',
    secret: secret,
  );
}

Credentials _credentialsFromAccountAuth(AccountAuthStatusResponse response) {
  return Credentials(
    token: response.token!,
    machineId: response.machineId ?? '',
    encryptionKey: response.encryptionKey ?? '',
    encryptionType:
        response.encryptionType?.toEncryptionType() ?? EncryptionType.legacy,
    publicKey: response.publicKey ?? '',
    machineKey: '',
    secret: '',
  );
}

LoginResponse _loginResponseFromAccountAuth(
    AccountAuthStatusResponse response) {
  return LoginResponse(
    token: response.token!,
    machineId: response.machineId ?? '',
    encryptionKey: response.encryptionKey,
    encryptionType:
        response.encryptionType?.toEncryptionType() ?? EncryptionType.legacy,
    publicKey: response.publicKey,
    machineKey: null,
  );
}
