part of 'session_service.dart';

extension SessionServiceMachineLoaders on SessionServiceNotifier {
  Future<void> loadMachines({
    bool force = false,
    bool allowFailure = false,
  }) =>
      _catalogCoordinator.loadMachines(
        force: force,
        allowFailure: allowFailure,
      );
}
