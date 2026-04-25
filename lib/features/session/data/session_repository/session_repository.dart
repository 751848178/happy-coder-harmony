import 'dart:async';

import 'package:collection/collection.dart';

import '../../domain/reducer.dart' as domain;
import '../../domain/session_local_snapshot.dart';
import '../../domain/session_models.dart';
import '../../domain/session_list_preview_helpers.dart';
import '../../domain/session_recency.dart';
import '../../../../shared/utils/extensions.dart';

part 'messages.dart';
part 'message_state.dart';
part 'message_windows.dart';
part 'messages_merge.dart';
part 'models.dart';
part 'state_change.dart';
part 'sessions.dart';

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

const DeepCollectionEquality _sessionRepositoryDeepEquality =
    DeepCollectionEquality();
