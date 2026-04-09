import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/domain/reducer.dart' show ReducerMessage;
import '../../../shared/utils/extensions.dart';
import '../../session/domain/session_local_snapshot.dart';
import '../../session/domain/session_models.dart' as session_models;
import 'storage_models.dart';
import '../data/hive_repository.dart';

part 'storage_notifier.dart';
part 'storage_queries.dart';
part 'storage_session_message_archive.dart';
part 'storage_session_sync.dart';
part 'storage_state.dart';

/// 存储服务
///
/// 提供本地数据存储的高级接口
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();
  static const String _localSessionSnapshotKey = '__happyLocalSessionState';

  late HiveRepository _repository;

  /// 初始化服务
  Future<void> initialize() async {
    _repository = HiveRepository.instance;
    await _repository.initialize();
    Logger.info('Storage service initialized');
  }
}
