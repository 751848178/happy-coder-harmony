import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../domain/socket_service.dart';
import '../../session/data/session_composer_queue_service.dart';
import '../../session/data/session_preferences_service.dart';
import '../../session/data/session_repository.dart';
import '../../session/data/session_ui_state_service.dart';
import '../../session/domain/session_activity_state.dart';
import '../../session/domain/session_models.dart';
import '../../auth/data/token_storage_service.dart';
import '../../encryption/domain/crypto_service.dart';
import '../../storage/domain/storage_service.dart';
import '../../../shared/utils/extensions.dart';
import '../../../core/config/app_config.dart';
import '../../../harmony/harmony_bridge.dart';

part 'socket_repository_connection.dart';
part 'socket_repository_connection_support.dart';
part 'socket_repository_helpers.dart';
part 'socket_repository_machine_rpc.dart';
part 'socket_repository_rpc_cache.dart';
part 'socket_repository_rpc.dart';
part 'socket_repository_updates.dart';

class ToolCallRequest {
  final String id;
  final String sessionId;
  final String toolName;
  final String? toolDescription;
  final Map<String, dynamic>? parameters;

  const ToolCallRequest({
    required this.id,
    required this.sessionId,
    required this.toolName,
    this.toolDescription,
    this.parameters,
  });
}

class SocketRepository {
  SocketRepository._();

  static final SocketRepository instance = SocketRepository._();

  io.Socket? _socket;
  Completer<void>? _connectionCompleter;
  String? _token;

  final SessionRepository _sessionRepository = SessionRepository.instance;
  final TokenStorageService _tokenStorage = TokenStorageService.instance;
  final StreamController<SocketMessage> _messageController =
      StreamController<SocketMessage>.broadcast();
  final StreamController<SocketEvent> _eventController =
      StreamController<SocketEvent>.broadcast();
  final StreamController<ToolCallRequest> _toolCallRequestController =
      StreamController<ToolCallRequest>.broadcast();
  final Set<String> _deduplicationSet = {};
  final Map<String, DateTime> _lastEphemeralSessionApplyAt = {};

  Timer? _deduplicationTimer;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  static const int _maxReconnectAttempts = 10;

  Stream<SocketMessage> get messageStream => _messageController.stream;

  Stream<SocketEvent> get eventStream => _eventController.stream;

  Stream<ToolCallRequest> get toolCallRequestStream =>
      _toolCallRequestController.stream;

  SocketConnectionState get connectionState {
    if (_socket == null) return SocketConnectionState.disconnected;
    return _socket!.connected
        ? SocketConnectionState.connected
        : SocketConnectionState.disconnected;
  }

  String? get socketId => _socket?.id;
}
