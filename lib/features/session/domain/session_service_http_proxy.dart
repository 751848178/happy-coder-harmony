part of 'session_service.dart';

extension SessionServiceHttpProxy on SessionServiceNotifier {
  /// Execute an HTTP proxy RPC call to the PC.
  ///
  /// The request is encrypted and sent via the existing Socket.IO RPC channel.
  /// The PC-side handler makes the real HTTP request to localhost and returns
  /// the response (also encrypted).
  Future<HttpProxyResponse> executeHttpProxy({
    required String sessionId,
    required HttpRequestProxy request,
  }) async {
    try {
      final result = await _callSessionRpcDecoded(
        sessionId: sessionId,
        method: 'httpProxy',
        payload: request.toJson(),
      );
      final map = _asStringMap(result);
      if (map == null) {
        return const HttpProxyResponse(
          success: false,
          error: 'Invalid proxy response',
        );
      }
      return HttpProxyResponse.fromJson(map);
    } catch (e) {
      return HttpProxyResponse(success: false, error: e.toString());
    }
  }
}
