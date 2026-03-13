import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/services/settings_service.dart' show SettingsState;
import '../../../core/theme/app_theme.dart';
import '../../profile/domain/profile_models.dart' as profile_models;
import '../../profile/domain/profile_state.dart';
import '../../profile/screens/profile_list_screen.dart';
import '../domain/session_creation_options.dart';
import '../domain/session_service.dart';

class NewSessionFlowScreen extends ConsumerStatefulWidget {
  const NewSessionFlowScreen({
    super.key,
    this.initialMachineId,
    this.initialPath,
    this.initialProfileId,
    this.initialAgent,
    this.initialPermissionMode,
    this.initialModelMode,
  });

  final String? initialMachineId;
  final String? initialPath;
  final String? initialProfileId;
  final String? initialAgent;
  final String? initialPermissionMode;
  final String? initialModelMode;

  @override
  ConsumerState<NewSessionFlowScreen> createState() =>
      _NewSessionFlowScreenState();
}

class _NewSessionFlowScreenState extends ConsumerState<NewSessionFlowScreen> {
  static const double _maxContentWidth = 720;

  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();

  String? _selectedMachineId;
  String? _selectedProfileId;
  String _selectedAgent = 'claude';
  String _permissionMode = defaultPermissionModeForAgent('claude');
  String _modelMode = defaultModelModeForAgent('claude');
  bool _isCreating = false;
  bool _seededInitialState = false;

  @override
  void initState() {
    super.initState();
    _selectedMachineId = widget.initialMachineId;
    _selectedProfileId = widget.initialProfileId;
    if (widget.initialPath != null && widget.initialPath!.trim().isNotEmpty) {
      _pathController.text = widget.initialPath!.trim();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionStateProvider.notifier).loadSessions();
      ref.read(profileStateProvider.notifier).loadProfiles();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionStateProvider);
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final profileState = ref.watch(profileStateProvider);
    final settings = ref.watch(settingsStateProvider);
    final mediaQuery = MediaQuery.of(context);
    final horizontalPadding = mediaQuery.size.width > 700 ? 16.0 : 8.0;

    final profiles = profileState is ProfileLoaded
        ? profileState.profiles
        : profile_models.BuiltInProfiles.all();
    final machines = _collectMachineOptions(sessionNotifier);

    if (!_seededInitialState) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _seededInitialState) {
          return;
        }
        _seedInitialState(
          settings: settings,
          profiles: profiles,
          machines: machines,
          sessions: sessionNotifier.sessions,
        );
      });
    }

    final effectiveMachineId =
        _selectedMachineId ?? (machines.isNotEmpty ? machines.first.id : null);
    final selectedMachine = machines
        .where((item) => item.id == effectiveMachineId)
        .cast<_MachineOption?>()
        .firstWhere((item) => item != null, orElse: () => null);
    final compatibleProfiles = profiles
        .where((profile) => profile.isCompatibleWith(_selectedAgent))
        .toList();
    final selectedProfile = _resolveSelectedProfile(
      profiles: compatibleProfiles,
      preferredId: _selectedProfileId,
    );
    final permissionOptions = permissionOptionsForAgent(_selectedAgent);
    final modelOptions = modelOptionsForAgent(_selectedAgent);
    final selectedPermission = permissionOptions.firstWhere(
      (option) => option.key == _permissionMode,
      orElse: () => permissionOptions.first,
    );
    final selectedModel = modelOptions.firstWhere(
      (option) => option.key == _modelMode,
      orElse: () => modelOptions.first,
    );
    final effectiveDirectory = _effectiveDirectory(selectedMachine);
    final canCreate = !_isCreating &&
        selectedMachine != null &&
        effectiveDirectory.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('新建会话'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _closeScreen,
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _maxContentWidth),
                      child: _buildScreenBody(selectedMachine: selectedMachine),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  8,
                  horizontalPadding,
                  12,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: _maxContentWidth),
                    child: _buildComposerPanel(
                      selectedMachine: selectedMachine,
                      selectedProfile: selectedProfile,
                      selectedPermission: selectedPermission,
                      selectedModel: selectedModel,
                      canCreate: canCreate,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreenBody({
    required _MachineOption? selectedMachine,
  }) {
    final notices = <Widget>[];

    if (selectedMachine == null) {
      notices.add(
        _NoticeCard(
          icon: Icons.desktop_windows_outlined,
          title: '先选择一台电脑',
          message: '电脑、目录、模板和 Agent 都在底部输入面板里切换。',
        ),
      );
    } else if (!selectedMachine.isOnline) {
      notices.add(
        _NoticeCard(
          icon: Icons.portable_wifi_off_outlined,
          title: '当前电脑离线',
          message: '可以继续配置会话，但服务端恢复在线前不会开始执行。',
          toneColor: AppTheme.warningColor,
        ),
      );
    }

    if (notices.isEmpty) {
      return const SizedBox.expand();
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      itemBuilder: (context, index) => notices[index],
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: notices.length,
    );
  }

  Widget _buildComposerPanel({
    required _MachineOption? selectedMachine,
    required profile_models.AIProfile? selectedProfile,
    required SessionModeOption selectedPermission,
    required SessionModeOption selectedModel,
    required bool canCreate,
  }) {
    final directory = _effectiveDirectory(selectedMachine);
    final connectionColor = selectedMachine == null
        ? AppTheme.neutral500
        : selectedMachine.isOnline
            ? AppTheme.successColor
            : AppTheme.errorColor;
    final connectionText = selectedMachine == null
        ? '未选择电脑'
        : (selectedMachine.isOnline ? '在线' : '离线');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _StatusDot(color: connectionColor),
                    const SizedBox(width: 6),
                    Text(
                      connectionText,
                      style: TextStyle(
                        fontSize: 11,
                        color: connectionColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    selectedPermission.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: _modeTint(_selectedAgent, _permissionMode),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedModel.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.neutral600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.neutral100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ContextButton(
                icon: selectedMachine == null || selectedMachine.isOnline
                    ? Icons.desktop_windows_outlined
                    : Icons.desktop_access_disabled_outlined,
                label: selectedMachine?.title ?? '选择电脑',
                onTap: _pickMachine,
              ),
              if (directory.isNotEmpty || selectedMachine != null)
                const SizedBox(height: 4),
              _ContextButton(
                icon: Icons.folder_outlined,
                label: directory.isEmpty ? '选择工作目录' : directory,
                onTap: _pickPath,
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.neutral100,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _promptController,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: '你想做什么？',
                  filled: false,
                  contentPadding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.neutral500,
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _IconActionButton(
                            icon: Icons.settings_outlined,
                            tooltip: '权限和模型',
                            onTap: _showSettingsSheet,
                          ),
                          const SizedBox(width: 8),
                          _ActionPill(
                            icon: Icons.person_outline_rounded,
                            label: selectedProfile?.name ?? '选择模板',
                            onTap: _pickProfile,
                            onLongPress: selectedProfile == null
                                ? null
                                : () {
                                    setState(() => _selectedProfileId = null);
                                  },
                          ),
                          const SizedBox(width: 8),
                          _ActionPill(
                            icon: _selectedAgent == 'codex'
                                ? Icons.memory_rounded
                                : Icons.psychology_alt_outlined,
                            label: sessionAgentLabel(_selectedAgent),
                            onTap: _cycleAgent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SendButton(
                    enabled: canCreate,
                    loading: _isCreating,
                    onTap: canCreate
                        ? () => _createSession(selectedMachine)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _seedInitialState({
    required SettingsState settings,
    required List<profile_models.AIProfile> profiles,
    required List<_MachineOption> machines,
    required List<Session> sessions,
  }) {
    final requestedProfileId =
        widget.initialProfileId ?? settings.lastUsedProfile;
    final requestedProfile = _findProfileById(profiles, requestedProfileId);
    final explicitAgent =
        widget.initialAgent != null && widget.initialAgent!.trim().isNotEmpty
            ? normalizeSessionAgent(widget.initialAgent!)
            : null;
    final initialAgent = explicitAgent ??
        (requestedProfile != null
            ? resolvePreferredAgentForProfile(
                requestedProfile,
                fallback: settings.lastUsedAgent,
              )
            : normalizeSessionAgent(settings.lastUsedAgent));
    final compatibleProfile = _resolveSelectedProfile(
      profiles: profiles
          .where((profile) => profile.isCompatibleWith(initialAgent))
          .toList(),
      preferredId: requestedProfile?.id,
    );
    final initialPermission = resolveModeSelection(
      preferred: widget.initialPermissionMode ??
          settings.lastUsedPermissionMode ??
          compatibleProfile?.defaultPermissionMode?.value,
      options: permissionOptionsForAgent(initialAgent),
      fallback: defaultPermissionModeForAgent(initialAgent),
    );
    final initialModel = resolveModeSelection(
      preferred: widget.initialModelMode ??
          settings.lastUsedModelMode ??
          compatibleProfile?.defaultModelMode,
      options: modelOptionsForAgent(initialAgent),
      fallback: defaultModelModeForAgent(initialAgent),
    );
    final initialMachineId =
        _selectedMachineId ?? (machines.isNotEmpty ? machines.first.id : null);

    setState(() {
      _selectedAgent = initialAgent;
      _permissionMode = initialPermission;
      _modelMode = initialModel;
      _selectedProfileId = compatibleProfile?.id;
      _selectedMachineId = initialMachineId;
      if (_pathController.text.trim().isEmpty && initialMachineId != null) {
        _pathController.text =
            _defaultPathForMachine(initialMachineId, sessions, machines) ?? '';
      }
      _seededInitialState = true;
    });
  }

  List<_MachineOption> _collectMachineOptions(SessionServiceNotifier notifier) {
    final options = <_MachineOption>[];
    final seenIds = <String>{};

    for (final machine in notifier.machines) {
      if (!seenIds.add(machine.id)) {
        continue;
      }
      options.add(
        _MachineOption(
          id: machine.id,
          title: machine.name,
          subtitle: [
            if ((machine.metadata?['host']?.toString() ?? '').isNotEmpty)
              machine.metadata!['host'].toString(),
            if ((machine.platform ?? '').isNotEmpty) machine.platform!,
            machine.active ? '在线' : '离线',
          ].join(' • '),
          host: machine.metadata?['host']?.toString() ?? machine.name,
          homeDir: machine.metadata?['homeDir']?.toString(),
          isOnline: machine.active,
        ),
      );
    }

    for (final session in notifier.sessions) {
      final machineId = session.metadata?['machineId']?.toString();
      if (machineId == null || machineId.isEmpty || !seenIds.add(machineId)) {
        continue;
      }
      options.add(
        _MachineOption(
          id: machineId,
          title: session.metadata?['host']?.toString() ?? machineId,
          subtitle: [
            if ((session.path ?? '').isNotEmpty) _compactPath(session.path!),
            session.active ? '在线' : '离线',
          ].join(' • '),
          host: session.metadata?['host']?.toString() ?? machineId,
          homeDir: session.metadata?['homeDir']?.toString(),
          isOnline: session.active,
        ),
      );
    }

    return options;
  }

  String? _defaultPathForMachine(
    String machineId,
    List<Session> sessions,
    List<_MachineOption> machines,
  ) {
    return _mostRecentPathForMachine(machineId, sessions) ??
        machines
            .where((item) => item.id == machineId)
            .cast<_MachineOption?>()
            .firstWhere((item) => item != null, orElse: () => null)
            ?.homeDir;
  }

  String _effectiveDirectory(_MachineOption? machine) {
    final manual = _pathController.text.trim();
    if (manual.isNotEmpty) {
      return manual;
    }
    return machine?.homeDir?.trim() ?? '';
  }

  String? _mostRecentPathForMachine(String machineId, List<Session> sessions) {
    final items = sessions
        .where((session) =>
            session.metadata?['machineId']?.toString() == machineId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final session in items) {
      final path = session.path ?? session.metadata?['path']?.toString() ?? '';
      if (path.isNotEmpty) {
        return path;
      }
    }
    return null;
  }

  profile_models.AIProfile? _resolveSelectedProfile({
    required List<profile_models.AIProfile> profiles,
    required String? preferredId,
  }) {
    return _findProfileById(profiles, preferredId);
  }

  void _selectAgent(String agent) {
    final normalized = normalizeSessionAgent(agent);
    if (_selectedAgent == normalized) {
      return;
    }

    final profileState = ref.read(profileStateProvider);
    final profiles = profileState is ProfileLoaded
        ? profileState.profiles
        : profile_models.BuiltInProfiles.all();
    final currentProfile = _findProfileById(profiles, _selectedProfileId);
    final nextProfile =
        currentProfile != null && currentProfile.isCompatibleWith(normalized)
            ? currentProfile
            : null;

    setState(() {
      _selectedAgent = normalized;
      _selectedProfileId = nextProfile?.id;
      _permissionMode = resolveModeSelection(
        preferred: nextProfile?.defaultPermissionMode?.value ?? _permissionMode,
        options: permissionOptionsForAgent(normalized),
        fallback: defaultPermissionModeForAgent(normalized),
      );
      _modelMode = resolveModeSelection(
        preferred: nextProfile?.defaultModelMode ?? _modelMode,
        options: modelOptionsForAgent(normalized),
        fallback: defaultModelModeForAgent(normalized),
      );
    });
  }

  profile_models.AIProfile? _findProfileById(
    List<profile_models.AIProfile> profiles,
    String? profileId,
  ) {
    if (profileId == null || profileId.isEmpty) {
      return null;
    }
    return profiles
        .where((profile) => profile.id == profileId)
        .cast<profile_models.AIProfile?>()
        .firstWhere((profile) => profile != null, orElse: () => null);
  }

  void _cycleAgent() {
    final currentIndex = supportedSessionAgents.indexOf(_selectedAgent);
    final nextIndex = currentIndex < 0
        ? 0
        : (currentIndex + 1) % supportedSessionAgents.length;
    _selectAgent(supportedSessionAgents[nextIndex]);
  }

  Future<void> _pickMachine() async {
    final result = await context.push<String>(
      Uri(
        path: AppRoutes.newPickMachine,
        queryParameters: {
          if (_selectedMachineId != null)
            'selectedMachineId': _selectedMachineId!,
        },
      ).toString(),
    );
    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    final sessions = ref.read(sessionStateProvider.notifier).sessions;
    final machines =
        _collectMachineOptions(ref.read(sessionStateProvider.notifier));
    final nextPath = _defaultPathForMachine(result, sessions, machines);
    setState(() {
      _selectedMachineId = result;
      _pathController.text = nextPath ?? '';
    });
  }

  Future<void> _pickPath() async {
    final result = await context.push<String>(
      AppRoutes.newPathPicker(
        machineId: _selectedMachineId,
        path: _pathController.text.trim().isEmpty
            ? null
            : _pathController.text.trim(),
      ),
    );
    if (!mounted || result == null || result.isEmpty) {
      return;
    }
    setState(() => _pathController.text = result);
  }

  Future<void> _pickProfile() async {
    final result = await context.push<String>(
      AppRoutes.newProfilePicker(
        profileId: _selectedProfileId,
        agent: _selectedAgent,
      ),
    );
    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    final state = ref.read(profileStateProvider);
    final profiles = state is ProfileLoaded
        ? state.profiles
        : profile_models.BuiltInProfiles.all();
    final profile = _findProfileById(profiles, result);
    if (profile == null) {
      return;
    }

    final nextAgent = resolvePreferredAgentForProfile(
      profile,
      fallback: _selectedAgent,
    );
    setState(() {
      _selectedAgent = nextAgent;
      _selectedProfileId = profile.id;
      _permissionMode = resolveModeSelection(
        preferred: profile.defaultPermissionMode?.value,
        options: permissionOptionsForAgent(nextAgent),
        fallback: defaultPermissionModeForAgent(nextAgent),
      );
      _modelMode = resolveModeSelection(
        preferred: profile.defaultModelMode,
        options: modelOptionsForAgent(nextAgent),
        fallback: defaultModelModeForAgent(nextAgent),
      );
    });
  }

  Future<void> _showSettingsSheet() async {
    final permissionOptions = permissionOptionsForAgent(_selectedAgent);
    final modelOptions = modelOptionsForAgent(_selectedAgent);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        var localPermission = _permissionMode;
        var localModel = _modelMode;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final mediaHeight = MediaQuery.sizeOf(context).height;
            final sheetHeight = (160.0 +
                    (permissionOptions.length * 58.0) +
                    (modelOptions.length * 58.0))
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
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.neutral300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '会话设置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: [
                            _SheetSection(
                              title: '权限模式',
                              children: permissionOptions.map((option) {
                                return _SheetOptionTile(
                                  title: option.label,
                                  subtitle: option.description,
                                  selected: localPermission == option.key,
                                  onTap: () {
                                    setState(
                                        () => _permissionMode = option.key);
                                    setModalState(
                                        () => localPermission = option.key);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            _SheetSection(
                              title: '模型',
                              children: modelOptions.map((option) {
                                return _SheetOptionTile(
                                  title: option.label,
                                  subtitle: option.description,
                                  selected: localModel == option.key,
                                  onTap: () {
                                    setState(() => _modelMode = option.key);
                                    setModalState(
                                        () => localModel = option.key);
                                  },
                                );
                              }).toList(),
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

  Future<void> _createSession(_MachineOption? machine) async {
    if (_isCreating) {
      return;
    }
    if (machine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择要连接的电脑')),
      );
      return;
    }

    final directory = _effectiveDirectory(machine);
    if (directory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择工作目录')),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final sessionId = await _spawnSessionWithOptionalApproval(
        machine: machine,
        directory: directory,
      );
      if (sessionId == null || sessionId.isEmpty) {
        setState(() => _isCreating = false);
        return;
      }

      final settingsNotifier = ref.read(settingsStateProvider.notifier);
      settingsNotifier.setLastUsedAgent(_selectedAgent);
      settingsNotifier.setLastUsedProfile(_selectedProfileId);
      settingsNotifier.setLastUsedPermissionMode(_permissionMode);
      settingsNotifier.setLastUsedModelMode(_modelMode);

      final prompt = _promptController.text.trim();
      Object? messageError;
      if (prompt.isNotEmpty) {
        try {
          await ref.read(sessionStateProvider.notifier).sendMessage(
            sessionId: sessionId,
            content: prompt,
            metadata: const {'source': 'new-session-flow'},
          );
        } catch (error) {
          messageError = error;
          ref
              .read(sessionStateProvider.notifier)
              .updateDraft(sessionId, prompt);
        }
      }

      if (!mounted) {
        return;
      }
      context.pushReplacement(AppRoutes.sessionDetail(sessionId));
      if (messageError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('会话已创建，但首条消息发送失败：$messageError'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<String?> _spawnSessionWithOptionalApproval({
    required _MachineOption machine,
    required String directory,
  }) async {
    final profileState = ref.read(profileStateProvider);
    final profiles = profileState is ProfileLoaded
        ? profileState.profiles
        : profile_models.BuiltInProfiles.all();
    final selectedProfile = _findProfileById(profiles, _selectedProfileId);
    final environmentVariables = selectedProfile == null
        ? null
        : buildProfileEnvironmentVariables(selectedProfile);

    final notifier = ref.read(sessionStateProvider.notifier);
    var result = await notifier.spawnSession(
      machineId: machine.id,
      directory: directory,
      agent: _selectedAgent,
      approvedNewDirectoryCreation: false,
      environmentVariables:
          environmentVariables == null || environmentVariables.isEmpty
              ? null
              : environmentVariables,
      permissionMode: _permissionMode,
      modelMode: _modelMode,
    );

    if (result.requiresDirectoryApproval) {
      final approved = await _confirmDirectoryCreation(
        result.directoryApprovalPath ?? directory,
      );
      if (!approved) {
        return null;
      }

      result = await notifier.spawnSession(
        machineId: machine.id,
        directory: directory,
        agent: _selectedAgent,
        approvedNewDirectoryCreation: true,
        environmentVariables:
            environmentVariables == null || environmentVariables.isEmpty
                ? null
                : environmentVariables,
        permissionMode: _permissionMode,
        modelMode: _modelMode,
      );
    }

    if (result.isSuccess) {
      return result.sessionId;
    }
    throw Exception(result.errorMessage ?? '创建会话失败');
  }

  Future<bool> _confirmDirectoryCreation(String directory) async {
    final confirmed = await showDialog<bool>(
      context: context,
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

  void _closeScreen() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('${AppRoutes.home}?tab=sessions');
  }

  String _compactPath(String path) {
    final normalized = path.trim();
    if (normalized.length <= 36) {
      return normalized;
    }
    return '...${normalized.substring(normalized.length - 33)}';
  }

  Color _modeTint(String agent, String modeKey) {
    if (agent == 'codex') {
      switch (modeKey) {
        case 'read-only':
          return AppTheme.infoColor;
        case 'safe-yolo':
          return AppTheme.successColor;
        case 'yolo':
          return AppTheme.warningColor;
      }
    }
    switch (modeKey) {
      case 'acceptEdits':
        return AppTheme.successColor;
      case 'plan':
        return AppTheme.infoColor;
      case 'bypassPermissions':
        return AppTheme.warningColor;
      default:
        return AppTheme.neutral600;
    }
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.message,
    this.toneColor = AppTheme.brandColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color toneColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: toneColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: toneColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutral600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ContextButton extends StatelessWidget {
  const _ContextButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.neutral600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.settings_outlined,
            size: 18,
            color: AppTheme.brandColor,
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 210),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.brandColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.brandColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final background = enabled ? AppTheme.brandColor : AppTheme.neutral300;
    return InkWell(
      onTap: enabled && !loading ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.arrow_upward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  const _SheetSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SheetOptionTile extends StatelessWidget {
  const _SheetOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppTheme.brandColor : AppTheme.neutral400,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.brandColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          selected ? AppTheme.brandColor : AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MachineOption {
  const _MachineOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.host,
    required this.isOnline,
    this.homeDir,
  });

  final String id;
  final String title;
  final String subtitle;
  final String host;
  final bool isOnline;
  final String? homeDir;
}
