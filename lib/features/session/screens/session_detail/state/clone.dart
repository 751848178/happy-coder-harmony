part of '../session_detail.dart';

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
      permissionMode: session.permissionMode ??
          metadata['currentOperatingModeCode']?.toString(),
      modelMode: session.modelMode ?? metadata['currentModelCode']?.toString(),
    );
    context.push(uri);
  }
}
