part of 'auth_repository.dart';

mixin _AuthRepositoryAccountAuthMixin on _AuthRepositoryBase {
  Future<bool> approveAccountAuth({
    required String publicKey,
    required String response,
    required Credentials credentials,
  }) async {
    try {
      Logger.info('Approving account auth for: $publicKey');
      final apiResponse = await dioClient.post(
        '/v1/auth/account/response',
        options: authorizedOptions(credentials.token),
        data: {
          'publicKey': publicKey,
          'response': response,
        },
      );
      return apiResponse.statusCode == 200;
    } on DioException catch (error) {
      Logger.error('Approve account auth failed: ${error.message}');
      return false;
    }
  }

  Future<QRCodeResponse> generateQRCodeForTerminal() async {
    try {
      Logger.info('Generating QR code for terminal login');
      final crypto = await CryptoService.instance;
      final keyPairResult = await crypto.generateKeyPair();
      final publicKey = keyPairResult['publicKey'];
      final secretKey = keyPairResult['secretKey'];

      await storage.write(
        key: AuthRepository._keyTempSecret,
        value: secretKey ?? '',
      );
      final response = await dioClient.post(
        '/v1/auth/account/request',
        data: {'publicKey': publicKey},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to generate QR code: ${response.statusCode}');
      }

      final encoded = CryptoService.base64UrlEncode(publicKey ?? '');
      return QRCodeResponse(
        qrId: publicKey?.substring(0, 16) ?? '',
        qrData: 'happy:///account?base64url=$encoded',
        secretKey: secretKey,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
    } on DioException catch (error) {
      Logger.error('QR code generation failed: ${error.message}');
      rethrow;
    }
  }
}
