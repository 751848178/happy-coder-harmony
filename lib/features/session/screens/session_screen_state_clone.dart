part of 'session_screen.dart';

extension _SessionScreenStateClone on _SessionScreenState {
  void _openCloneSession(Session? session) {
    if (session == null) {
      return;
    }
    final metadata = session.metadata ?? const <String, dynamic>{};
    final uri = AppRoutes.newClonedSession(
      machineId: metadata['machineId']?.toString(),
      path: session.path ?? metadata['path']?.toString(),
      agent: metadata['flavor']?.toString(),
      permissionMode: metadata['currentOperatingModeCode']?.toString() ??
          session.permissionMode,
      modelMode: metadata['currentModelCode']?.toString() ?? session.modelMode,
    );
    context.push(uri);
  }
}
