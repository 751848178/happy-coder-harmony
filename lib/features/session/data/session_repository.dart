import 'dart:async';
import 'dart:convert';

import '../domain/reducer.dart' as domain;
import '../domain/session_models.dart';
import '../../../shared/utils/extensions.dart';

part 'session_repository_messages.dart';
part 'session_repository_messages_merge.dart';
part 'session_repository_models.dart';
part 'session_repository_sessions.dart';

/// 会话数据仓库
///
/// 处理会话的 CRUD 操作和状态管理
class SessionRepository {
  SessionRepository._();

  final Map<String, Session> _sessions = {};
  final Map<String, SessionMessages> _sessionMessages = {};
  final Map<String, Machine> _machines = {};
  final StreamController<SessionStateChange> _stateController =
      StreamController<SessionStateChange>.broadcast();

  static final SessionRepository instance = SessionRepository._();

  Stream<SessionStateChange> get stateChanges => _stateController.stream;
}
