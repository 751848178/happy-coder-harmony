part of 'new_session_flow_screen.dart';

Future<void> _createSessionFlowSession(
  _NewSessionFlowScreenState state,
  _MachineOption? machine,
) async {
  if (state._isCreating) {
    return;
  }
  if (machine == null) {
    ScaffoldMessenger.of(state.context).showSnackBar(
      const SnackBar(content: Text('请选择要连接的电脑')),
    );
    return;
  }

  final directory = _effectiveSessionFlowDirectory(state, machine);
  if (directory.isEmpty) {
    ScaffoldMessenger.of(state.context).showSnackBar(
      const SnackBar(content: Text('请选择工作目录')),
    );
    return;
  }

  state._updateView(() {
    state._isCreating = true;
  });
  try {
    final sessionId = await _spawnSessionFlowSessionWithApproval(
      state,
      machine: machine,
      directory: directory,
    );
    if (sessionId == null || sessionId.isEmpty) {
      state._updateView(() {
        state._isCreating = false;
      });
      return;
    }

    final settingsNotifier = state.ref.read(settingsStateProvider.notifier);
    settingsNotifier.setLastUsedAgent(state._selectedAgent);
    settingsNotifier.setLastUsedProfile(state._selectedProfileId);
    settingsNotifier.setLastUsedPermissionMode(state._permissionMode);
    settingsNotifier.setLastUsedModelMode(state._modelMode);

    final prompt = state._promptController.text.trim();
    Object? messageError;
    if (prompt.isNotEmpty) {
      try {
        await state.ref.read(sessionStateProvider.notifier).sendMessage(
          sessionId: sessionId,
          content: prompt,
          metadata: const {'source': 'new-session-flow'},
        );
      } catch (error) {
        messageError = error;
        state.ref
            .read(sessionStateProvider.notifier)
            .updateDraft(sessionId, prompt);
      }
    }

    if (!state.mounted) {
      return;
    }
    state.context.pushReplacement(AppRoutes.sessionDetail(sessionId));
    if (messageError != null) {
      ScaffoldMessenger.of(state.context).showSnackBar(
        SnackBar(content: Text('会话已创建，但首条消息发送失败：$messageError')),
      );
    }
  } catch (error) {
    if (state.mounted) {
      ScaffoldMessenger.of(state.context).showSnackBar(
        SnackBar(content: Text('创建失败: $error')),
      );
    }
  } finally {
    state._updateView(() {
      state._isCreating = false;
    });
  }
}

Future<String?> _spawnSessionFlowSessionWithApproval(
  _NewSessionFlowScreenState state, {
  required _MachineOption machine,
  required String directory,
}) async {
  final profileState = state.ref.read(profileStateProvider);
  final profiles = profileState is ProfileLoaded
      ? profileState.profiles
      : profile_models.BuiltInProfiles.all();
  final selectedProfile =
      _findSessionFlowProfileById(profiles, state._selectedProfileId);
  final environmentVariables = selectedProfile == null
      ? null
      : buildProfileEnvironmentVariables(selectedProfile);

  final notifier = state.ref.read(sessionStateProvider.notifier);
  var result = await notifier.spawnSession(
    machineId: machine.id,
    directory: directory,
    agent: state._selectedAgent,
    approvedNewDirectoryCreation: false,
    environmentVariables:
        environmentVariables == null || environmentVariables.isEmpty
            ? null
            : environmentVariables,
    permissionMode: state._permissionMode,
    modelMode: state._modelMode,
  );

  if (result.requiresDirectoryApproval) {
    final approved = await _confirmSessionFlowDirectoryCreation(
      state,
      result.directoryApprovalPath ?? directory,
    );
    if (!approved) {
      return null;
    }
    result = await notifier.spawnSession(
      machineId: machine.id,
      directory: directory,
      agent: state._selectedAgent,
      approvedNewDirectoryCreation: true,
      environmentVariables:
          environmentVariables == null || environmentVariables.isEmpty
              ? null
              : environmentVariables,
      permissionMode: state._permissionMode,
      modelMode: state._modelMode,
    );
  }

  if (result.isSuccess) {
    return result.sessionId;
  }
  throw Exception(result.errorMessage ?? '创建会话失败');
}

Future<bool> _confirmSessionFlowDirectoryCreation(
  _NewSessionFlowScreenState state,
  String directory,
) async {
  final confirmed = await showDialog<bool>(
    context: state.context,
    builder: (context) => AlertDialog(
      title: const Text('创建目录'),
      content: Text('目录不存在，是否允许在目标机器上创建它？\n\n$directory'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('允许'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

void _closeSessionFlowScreen(_NewSessionFlowScreenState state) {
  if (state.context.canPop()) {
    state.context.pop();
    return;
  }
  state.context.go('${AppRoutes.home}?tab=sessions');
}
