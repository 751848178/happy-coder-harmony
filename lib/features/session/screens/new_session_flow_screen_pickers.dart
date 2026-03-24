part of 'new_session_flow_screen.dart';

Future<void> _pickSessionFlowMachine(_NewSessionFlowScreenState state) async {
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

  final sessions = state.ref.read(sessionStateProvider.notifier).sessions;
  final machines = _collectSessionFlowMachineOptions(
    state,
    state.ref.read(sessionStateProvider.notifier),
  );
  final nextPath =
      _defaultSessionFlowPathForMachine(result, sessions, machines);
  state._updateView(() {
    state._selectedMachineId = result;
    state._pathController.text = nextPath ?? '';
  });
}

Future<void> _pickSessionFlowPath(_NewSessionFlowScreenState state) async {
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
  });
}

Future<void> _showSessionFlowSettingsSheet(
  _NewSessionFlowScreenState state,
) async {
  final permissionOptions = permissionOptionsForAgent(state._selectedAgent);

  await showModalBottomSheet<void>(
    context: state.context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      var localPermission = state._permissionMode;
      return StatefulBuilder(
        builder: (context, setModalState) {
          final mediaHeight = MediaQuery.sizeOf(context).height;
          final sheetHeight = (148.0 + (permissionOptions.length * 58.0))
              .clamp(320.0, mediaHeight * 0.78)
              .toDouble();
          return SafeArea(
            top: false,
            child: SizedBox(
              height: sheetHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSessionFlowSheetHandle(),
                    const SizedBox(height: 16),
                    const Text(
                      '会话设置',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: [
                          _SheetSection(
                            title: '权限模式',
                            children: permissionOptions
                                .map(
                                  (option) => _SheetOptionTile(
                                    title: option.label,
                                    subtitle: option.description,
                                    selected: localPermission == option.key,
                                    onTap: () {
                                      state._updateView(
                                        () =>
                                            state._permissionMode = option.key,
                                      );
                                      setModalState(
                                          () => localPermission = option.key);
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
