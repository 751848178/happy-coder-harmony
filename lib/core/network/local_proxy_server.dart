import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../features/encryption/domain/crypto_service.dart';
import '../../features/auth/data/token_storage_service.dart';
import '../../features/session/data/session_data_key_store.dart';
import '../../features/socketio/data/socket_repository.dart';
import 'http_proxy_models.dart';

/// A local HTTP server that proxies requests to the connected PC via the
/// existing encrypted RPC channel (Socket.IO → Happy Server → Happy CLI).
///
/// Usage:
///   await LocalProxyServer.instance.start(sessionId: sid, targetPort: 8080);
///   print(LocalProxyServer.instance.proxyUrl); // http://127.0.0.1:xxxxx
///   // ... WebView or any HTTP client can now access proxyUrl
///   await LocalProxyServer.instance.stop();
class LocalProxyServer {
  LocalProxyServer._();

  static final LocalProxyServer instance = LocalProxyServer._();

  static const Duration _rpcTimeout = Duration(seconds: 35);

  HttpServer? _server;
  int? _localPort;
  String? _activeSessionId;
  int _targetPort = 8080;

  bool get isRunning => _server != null;
  int? get localPort => _localPort;
  int get targetPort => _targetPort;
  String? get activeSessionId => _activeSessionId;

  /// The local URL that WebView / HTTP clients should connect to.
  /// Returns empty string if the server is not running.
  String get proxyUrl {
    if (_localPort == null) return '';
    return 'http://127.0.0.1:$_localPort';
  }

  /// Start the local proxy server.
  ///
  /// All incoming HTTP requests will be forwarded to the PC's
  /// `127.0.0.1:[targetPort]` via the RPC channel bound to [sessionId].
  Future<void> start({
    required String sessionId,
    int targetPort = 8080,
  }) async {
    if (_server != null) {
      // Already running — update config if same session, otherwise restart.
      if (_activeSessionId == sessionId && _targetPort == targetPort) {
        return;
      }
      await stop();
    }

    _activeSessionId = sessionId;
    _targetPort = targetPort;

    _server = await HttpServer.bind('127.0.0.1', 0);
    _localPort = _server!.port;
    _server!.listen(_handleRequest);
    debugPrint('[LocalProxy] Started on $proxyUrl → PC :$targetPort');
  }

  /// Stop the proxy server and release the port.
  Future<void> stop() async {
    final server = _server;
    _server = null;
    _localPort = null;
    _activeSessionId = null;
    if (server != null) {
      await server.close(force: true);
      debugPrint('[LocalProxy] Stopped');
    }
  }

  // ---------------------------------------------------------------------------
  // Request handling
  // ---------------------------------------------------------------------------

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      // Always add CORS headers so WebView can load resources freely.
      _addCorsHeaders(request);

      // Handle CORS preflight.
      if (request.method == 'OPTIONS') {
        request.response.statusCode = 204;
        await request.response.close();
        return;
      }

      final sessionId = _activeSessionId;
      if (sessionId == null) {
        _respondError(request, 503, 'Proxy not configured');
        return;
      }

      // 1. Collect request body.
      final bodyBytes = await _collectBody(request);

      // 2. Build proxy request model.
      final path = request.uri.path +
          (request.uri.hasQuery ? '?${request.uri.query}' : '');
      final headers = <String, String>{};
      request.headers.forEach((name, values) {
        headers[name] = values.join(', ');
      });

      // Strip hop-by-hop headers that should not be forwarded.
      headers.remove('host');
      headers.remove('connection');
      headers.remove('transfer-encoding');
      headers.remove('origin');
      headers.remove('referer');

      final proxyRequest = HttpRequestProxy(
        method: request.method,
        path: path,
        targetPort: _targetPort,
        headers: headers,
        body: bodyBytes.isNotEmpty ? base64Encode(bodyBytes) : null,
      );

      // 3. Encrypt and forward via RPC (with timeout).
      final response = await _forwardViaRpc(sessionId, proxyRequest)
          .timeout(_rpcTimeout, onTimeout: () {
        return const HttpProxyResponse(
          success: false,
          statusCode: 504,
          error: 'Gateway timeout',
        );
      });

      // 4. Write response back.
      final httpResponse = request.response;
      httpResponse.statusCode = response.statusCode ?? 502;

      response.headers?.forEach((name, value) {
        // Skip hop-by-hop headers from the upstream response.
        final lower = name.toLowerCase();
        if (lower == 'transfer-encoding' || lower == 'connection') return;
        httpResponse.headers.set(name, value);
      });

      final respBody = response.bodyBytes;
      if (respBody != null) {
        httpResponse.add(respBody);
      }
      await httpResponse.close();
    } catch (e) {
      debugPrint('[LocalProxy] Error handling request: $e');
      try {
        _respondError(request, 502, 'Proxy error: $e');
      } catch (_) {
        // Response already closed — nothing we can do.
      }
    }
  }

  /// Add CORS headers to allow WebView cross-origin requests.
  void _addCorsHeaders(HttpRequest request) {
    final h = request.response.headers;
    h.set('Access-Control-Allow-Origin', '*');
    h.set('Access-Control-Allow-Methods',
        'GET, POST, PUT, DELETE, PATCH, OPTIONS');
    h.set('Access-Control-Allow-Headers', '*');
    h.set('Access-Control-Max-Age', '86400');
  }

  Future<HttpProxyResponse> _forwardViaRpc(
    String sessionId,
    HttpRequestProxy proxyRequest,
  ) async {
    try {
      // Encrypt the payload using the same logic as session_service_rpc.dart.
      final encrypted = await _encryptPayload(sessionId, proxyRequest.toJson());

      // Send via the existing RPC channel.
      final rpcResult = await SocketRepository.instance.sessionRpc(
        sessionId: sessionId,
        method: 'httpProxy',
        encryptedParams: encrypted,
      );

      // Decrypt the result.
      final decrypted = await _decryptResult(sessionId, rpcResult['result']);
      if (decrypted is Map<String, dynamic>) {
        return HttpProxyResponse.fromJson(decrypted);
      }
      return const HttpProxyResponse(success: false, error: 'Invalid response');
    } catch (e) {
      debugPrint('[LocalProxy] RPC forwarding failed: $e');
      return HttpProxyResponse(success: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Encryption helpers (mirrors session_service_rpc.dart logic)
  // ---------------------------------------------------------------------------

  Future<String> _encryptPayload(
    String sessionId,
    Map<String, dynamic> payload,
  ) async {
    final crypto = await CryptoService.instance;
    final sessionKey = SessionDataKeyStore.instance.sessionKeyFor(sessionId);
    if (sessionKey != null) {
      return crypto.encryptHappyCoderAesGcmJson(payload, sessionKey);
    }
    final secretKey = await TokenStorageService.instance.getSecretKey();
    if (secretKey != null && secretKey.isNotEmpty) {
      return crypto.encryptHappyCoderLegacyJson(payload, secretKey);
    }
    throw Exception('Missing encryption key for session $sessionId');
  }

  Future<dynamic> _decryptResult(String sessionId, dynamic payload) async {
    if (payload == null) return null;
    if (payload is! String || payload.trim().isEmpty) return payload;

    final crypto = await CryptoService.instance;
    final sessionKey = SessionDataKeyStore.instance.sessionKeyFor(sessionId);
    if (sessionKey != null) {
      final decrypted =
          await crypto.decryptHappyCoderAesGcmJson(payload, sessionKey);
      if (decrypted != null) return decrypted;
    }

    final secretKey = await TokenStorageService.instance.getSecretKey();
    if (secretKey != null && secretKey.isNotEmpty) {
      final decrypted =
          await crypto.decryptHappyCoderLegacyJson(payload, secretKey);
      if (decrypted != null) return decrypted;
    }

    // Fallback: try plain JSON.
    try {
      return jsonDecode(payload);
    } catch (_) {
      return payload;
    }
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  Future<Uint8List> _collectBody(HttpRequest request) async {
    final builder = BytesBuilder();
    await for (final chunk in request) {
      builder.add(chunk);
    }
    return Uint8List.fromList(builder.toBytes());
  }

  void _respondError(HttpRequest request, int statusCode, String message) {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.text
      ..write(message);
    request.response.close();
  }
}
