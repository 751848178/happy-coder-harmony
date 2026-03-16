part of 'enhanced_new_session_screen.dart';

Future<void> _loadEnhancedAvailableMachines(
  _EnhancedNewSessionScreenState state,
) async {
  state._updateView(() {
    state._availableMachines
      ..clear()
      ..addAll([
        const Machine(
          id: 'default',
          name: '默认机器',
          platform: 'macOS',
          status: MachineStatus.online,
        ),
        const Machine(
          id: 'local-1',
          name: '本地开发环境',
          platform: 'Linux',
          status: MachineStatus.online,
        ),
      ]);
    state._selectedMachineId =
        state.widget.initialMachineId ?? state._selectedMachineId ?? 'default';
  });
}

Future<void> _loadEnhancedAvailableProfiles(
  _EnhancedNewSessionScreenState state,
) async {
  state._updateView(() {
    state._availableProfiles
      ..clear()
      ..addAll([
        const ProfileSummary(id: 'default', name: '默认配置', isDefault: true),
        const ProfileSummary(id: 'claude', name: 'Claude配置'),
      ]);
    state._selectedProfileId =
        state.widget.initialProfileId ?? state._selectedProfileId ?? 'default';
  });
}

Future<void> _loadEnhancedRecentPaths(
    _EnhancedNewSessionScreenState state) async {
  state._updateView(() {
    state._recentPaths = [
      '~/Projects/ai-driven',
      '~/Projects/flutter-app',
      '~/Projects/react-native',
    ];
  });
}

void _advanceEnhancedStep(_EnhancedNewSessionScreenState state) {
  if (state._currentStep < 2) {
    state._updateView(() {
      state._currentStep++;
    });
  }
}

Future<void> _createEnhancedSession(
    _EnhancedNewSessionScreenState state) async {
  final notifier = state.ref.read(sessionStateProvider.notifier);
  final title = state._titleController.text.trim();
  final prompt = state._descriptionController.text.trim();
  final path = state._pathController.text.trim();
  final selectedMachine = state._availableMachines.cast<Machine?>().firstWhere(
        (machine) => machine?.id == state._selectedMachineId,
        orElse: () => null,
      );
  final metadata = <String, dynamic>{
    'permissionMode': state._permissionMode,
    'modelMode': state._modelMode,
    if (state._selectedMachineId != null) 'machineId': state._selectedMachineId,
    if (selectedMachine != null) 'host': selectedMachine.name,
    if (state._selectedProfileId != null) 'profileId': state._selectedProfileId,
    if (prompt.isNotEmpty) 'description': prompt,
  };

  final sessionId = await notifier.createSession(
    title: title.isEmpty ? null : title,
    tag: state._selectedTag,
    path: path.isEmpty ? null : path,
    metadata: metadata,
    permissionMode: state._permissionMode,
    modelMode: state._modelMode,
  );
  if (sessionId == null || !state.mounted) {
    ScaffoldMessenger.of(state.context).showSnackBar(
      const SnackBar(content: Text('创建会话失败')),
    );
    return;
  }
  if (prompt.isNotEmpty) {
    await notifier.sendMessage(
      sessionId: sessionId,
      content: prompt,
      metadata: const {'source': 'enhanced-session-wizard'},
    );
  }
  if (state.mounted) {
    state.context.go(AppRoutes.sessionDetail(sessionId));
  }
}

Future<void> _showEnhancedPathPicker(
  _EnhancedNewSessionScreenState state,
) async {
  final result = await state.context.push<String>(
    AppRoutes.newPathPicker(
      machineId: state._selectedMachineId,
      path: state._pathController.text.trim().isEmpty
          ? null
          : state._pathController.text.trim(),
    ),
  );
  if (!state.mounted || result == null || result.isEmpty) {
    return;
  }
  state._updateView(() {
    state._pathController.text = result;
    if (!state._recentPaths.contains(result)) {
      state._recentPaths = [result, ...state._recentPaths].take(6).toList();
    }
  });
}

Future<void> _editEnhancedProfile(
  _EnhancedNewSessionScreenState state,
  String profileId,
) async {
  final result = await state.context.push<String>(
    AppRoutes.newProfilePicker(profileId: profileId),
  );
  if (!state.mounted || result == null || result.isEmpty) {
    return;
  }
  state._updateView(() {
    state._selectedProfileId = result;
  });
}

Future<void> _pickEnhancedMachine(_EnhancedNewSessionScreenState state) async {
  final result = await state.context.push<String>(
    Uri(
      path: AppRoutes.newPickMachine,
      queryParameters: {
        if (state._selectedMachineId != null)
          'selectedMachineId': state._selectedMachineId!,
      },
    ).toString(),
  );
  if (!state.mounted || result == null || result.isEmpty) {
    return;
  }
  state._updateView(() {
    state._selectedMachineId = result;
  });
}
