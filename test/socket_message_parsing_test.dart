import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/socketio/domain/socket_service.dart';

void main() {
  test('SocketMessage.fromJson resolves session id from sid fallback', () {
    final message = SocketMessage.fromJson(
      const <String, dynamic>{
        'id': 'msg-1',
        'type': 'server',
        'content': 'hello',
        'sid': 'session-from-sid',
      },
    );

    expect(message.sessionId, 'session-from-sid');
    expect(message.type, SocketMessageType.server);
  });

  test('SocketMessage.fromJson resolves session id from session_id fallback',
      () {
    final message = SocketMessage.fromJson(
      const <String, dynamic>{
        'id': 'msg-2',
        'type': 'user',
        'content': 'hello',
        'session_id': 'session-from-session-id',
      },
    );

    expect(message.sessionId, 'session-from-session-id');
  });

  test('SocketMessage.fromJson parses timestamp from epoch string', () {
    final message = SocketMessage.fromJson(
      const <String, dynamic>{
        'id': 'msg-3',
        'type': 'system',
        'content': 'hello',
        'sessionId': 'session-1',
        'timestamp': '1772962443908',
      },
    );

    expect(message.timestamp, isNotNull);
    expect(
      message.timestamp!.millisecondsSinceEpoch,
      1772962443908,
    );
  });
}
