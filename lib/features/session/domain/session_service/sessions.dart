part of 'session_service.dart';

extension SessionServiceSessionLoaders on SessionServiceNotifier {
  static const Duration _sessionListAutoSyncMinAge =
      _SessionServiceCatalogCoordinator.sessionListAutoSyncMinAge;

  Future<void> loadSessions({bool force = false}) =>
      _catalogCoordinator.loadSessions(force: force);

  Future<void> syncSessionsIfStale({
    Duration minAge = _sessionListAutoSyncMinAge,
  }) =>
      _catalogCoordinator.syncSessionsIfStale(minAge: minAge);
}
