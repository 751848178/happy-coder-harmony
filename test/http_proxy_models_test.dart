import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_coder_flutter/core/network/http_proxy_models.dart';

void main() {
  group('HttpRequestProxy', () {
    test('toJson includes all fields', () {
      const request = HttpRequestProxy(
        method: 'POST',
        path: '/api/data?key=value',
        targetPort: 3000,
        headers: {'content-type': 'application/json'},
        body: 'SGVsbG8=',
      );

      final json = request.toJson();

      expect(json['method'], 'POST');
      expect(json['path'], '/api/data?key=value');
      expect(json['targetPort'], 3000);
      expect(json['headers'], {'content-type': 'application/json'});
      expect(json['body'], 'SGVsbG8=');
    });

    test('toJson omits body when null', () {
      const request = HttpRequestProxy(
        method: 'GET',
        path: '/',
        targetPort: 8080,
      );

      final json = request.toJson();

      expect(json.containsKey('body'), isFalse);
    });

    test('fromJson round-trips correctly', () {
      const original = HttpRequestProxy(
        method: 'PUT',
        path: '/update',
        targetPort: 5173,
        headers: {'accept': 'text/html'},
        body: 'dGVzdA==',
      );

      final json = original.toJson();
      final restored = HttpRequestProxy.fromJson(json);

      expect(restored.method, original.method);
      expect(restored.path, original.path);
      expect(restored.targetPort, original.targetPort);
      expect(restored.headers, original.headers);
      expect(restored.body, original.body);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'method': 'GET',
        'path': '/',
        'targetPort': 8080,
      };

      final request = HttpRequestProxy.fromJson(json);

      expect(request.headers, isEmpty);
      expect(request.body, isNull);
    });
  });

  group('HttpProxyResponse', () {
    test('fromJson parses success response', () {
      final json = {
        'success': true,
        'statusCode': 200,
        'headers': {'content-type': 'text/html'},
        'body': base64Encode(utf8.encode('<html>Hello</html>')),
      };

      final response = HttpProxyResponse.fromJson(json);

      expect(response.success, isTrue);
      expect(response.statusCode, 200);
      expect(response.headers, {'content-type': 'text/html'});
      expect(response.body, isNotNull);
    });

    test('fromJson parses error response', () {
      final json = {
        'success': false,
        'error': 'Connection refused',
      };

      final response = HttpProxyResponse.fromJson(json);

      expect(response.success, isFalse);
      expect(response.error, 'Connection refused');
      expect(response.statusCode, isNull);
      expect(response.headers, isNull);
      expect(response.body, isNull);
    });

    test('bodyBytes decodes base64 correctly', () {
      final content = utf8.encode('Hello, World!');
      final json = {
        'success': true,
        'statusCode': 200,
        'body': base64Encode(content),
      };

      final response = HttpProxyResponse.fromJson(json);

      expect(response.bodyBytes, equals(content));
    });

    test('bodyBytes returns null when body is null', () {
      const response = HttpProxyResponse(success: true);

      expect(response.bodyBytes, isNull);
    });
  });
}
