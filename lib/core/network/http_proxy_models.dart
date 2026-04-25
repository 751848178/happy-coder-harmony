import 'dart:convert';

/// Request payload sent from APP to PC via encrypted RPC.
class HttpRequestProxy {
  final String method;
  final String path;
  final int targetPort;
  final Map<String, String> headers;
  final String? body; // base64-encoded request body

  const HttpRequestProxy({
    required this.method,
    required this.path,
    required this.targetPort,
    this.headers = const {},
    this.body,
  });

  Map<String, dynamic> toJson() => {
        'method': method,
        'path': path,
        'targetPort': targetPort,
        'headers': headers,
        if (body != null) 'body': body,
      };

  factory HttpRequestProxy.fromJson(Map<String, dynamic> json) =>
      HttpRequestProxy(
        method: json['method'] as String,
        path: json['path'] as String,
        targetPort: json['targetPort'] as int,
        headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
        body: json['body'] as String?,
      );
}

/// Response payload returned from PC to APP via encrypted RPC.
class HttpProxyResponse {
  final bool success;
  final int? statusCode;
  final Map<String, String>? headers;
  final String? body; // base64-encoded response body
  final String? error;

  const HttpProxyResponse({
    required this.success,
    this.statusCode,
    this.headers,
    this.body,
    this.error,
  });

  factory HttpProxyResponse.fromJson(Map<String, dynamic> json) =>
      HttpProxyResponse(
        success: json['success'] as bool,
        statusCode: json['statusCode'] as int?,
        headers: json['headers'] != null
            ? Map<String, String>.from(json['headers'] as Map)
            : null,
        body: json['body'] as String?,
        error: json['error'] as String?,
      );

  /// Decode the base64 body to raw bytes.
  List<int>? get bodyBytes => body != null ? base64Decode(body!) : null;
}
