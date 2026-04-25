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
    _syncSessionFlowModeSelections(state);
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
  final permissionOptions = _sessionFlowPermissionOptions(
    state,
  );
  final modelOptions = _sessionFlowModelOptions(
    state,
  );
  final modelLoadStatus = state.ref.read(sessionStateProvider).whenOrNull<int>(
            loading: () => 0,
            initial: () => 0,
            error: (_) => 1,
            ready: (_, __, ___) => 2,
          ) ??
      0;

  await showModalBottomSheet<void>(
    context: state.context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      var localPermission = state._permissionMode;
      var localModel = state._modelMode;
      return StatefulBuilder(
        builder: (context, setModalState) {
          final mediaHeight = MediaQuery.sizeOf(context).height;
          final modelTileCount = modelOptions.isEmpty ? 1 : modelOptions.length;
          final sheetHeight = (236.0 +
                  (permissionOptions.length * 58.0) +
                  (modelTileCount * 58.0))
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
                          const SizedBox(height: 12),
                          _SheetSection(
                            title: '模型',
                            children: _buildModelSectionChildren(
                              modelOptions: modelOptions,
                              modelLoadStatus: modelLoadStatus,
                              hasMachine: state._selectedMachineId != null,
                              localModel: localModel,
                              onModelSelected: (key) {
                                state._updateView(
                                  () => state._modelMode = key,
                                );
                                setModalState(() => localModel = key);
                              },
                            ),
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

List<Widget> _buildModelSectionChildren({
  required List<SessionModeOption> modelOptions,
  required int modelLoadStatus,
  required bool hasMachine,
  required String localModel,
  required void Function(String key) onModelSelected,
}) {
  if (modelLoadStatus == 0) {
    return const [
      _SheetInfoTile(title: '加载中...', subtitle: '正在从电脑获取可用模型'),
    ];
  }
  if (modelLoadStatus == 1) {
    return const [
      _SheetInfoTile(title: '加载失败', subtitle: '无法获取可用模型，请检查网络连接'),
    ];
  }
  if (!hasMachine) {
    return const [
      _SheetInfoTile(title: '未选择电脑', subtitle: '请先选择一台电脑以获取可用模型'),
    ];
  }
  if (modelOptions.isEmpty) {
    return const [
      _SheetInfoTile(title: '暂无可用模型', subtitle: '当前电脑未提供可选模型'),
    ];
  }
  return modelOptions
      .map(
        (option) => _SheetOptionTile(
          title: option.label,
          subtitle: option.description,
          selected: localModel == option.key,
          onTap: () => onModelSelected(option.key),
        ),
      )
      .toList();
}
