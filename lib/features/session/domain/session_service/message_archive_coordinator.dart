part of 'session_service.dart';

class _SessionServiceMessageArchiveCoordinator {
  static const int archiveSyncPageSize = 40;
  static const int archiveSyncParseConcurrency = 8;

  const _SessionServiceMessageArchiveCoordinator(this._notifier);

  final SessionServiceNotifier _notifier;
}
