part of 'auth_repository.dart';

mixin _AuthRepositoryTerminalMixin on _AuthRepositoryBase {
  Future<bool> approveTerminalAuth({
    required String publicKey,
    required String response,
  }) async {
    try {
      Logger.info('Approving terminal auth for: $publicKey');
      final apiResponse = await postAuthorized(
        '/v1/auth/response',
        data: {
          'publicKey': publicKey,
          'response': response,
        },
        retryReason: 'terminal auth approval',
      );
      return apiResponse.statusCode == 200;
    } on DioException catch (error) {
      Logger.error(
        'Approve terminal auth failed: status=${error.response?.statusCode}, data=${error.response?.data}, message=${error.message}',
      );
      return false;
    }
  }

  Future<TerminalAuthStatusResponse?> getTerminalAuthStatus(
    String publicKey,
  ) async {
    try {
      Logger.info('Checking terminal auth status for: $publicKey');
      final response = await dioClient.get(
        '/v1/auth/request/status',
        queryParameters: {'publicKey': publicKey},
      );
      if (response.statusCode != 200) {
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      return TerminalAuthStatusResponse(
        status: terminalAuthStatusFromState(data['status'] as String?),
        supportsV2: data['supportsV2'] as bool? ?? false,
      );
    } on DioException catch (error) {
      Logger.error('Get terminal auth status failed: ${error.message}');
      return null;
    }
  }
}
