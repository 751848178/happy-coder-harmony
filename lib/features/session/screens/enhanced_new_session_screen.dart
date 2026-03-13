import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/providers/app_providers.dart';

/// Enhanced New Session Screen
///
/// 增强版新建会话屏幕，支持机器选择、路径选择、配置文件编辑
class EnhancedNewSessionScreen extends ConsumerStatefulWidget {
  const EnhancedNewSessionScreen({
    super.key,
    this.initialMachineId,
    this.initialPath,
    this.initialProfileId,
  });

  final String? initialMachineId;
  final String? initialPath;
  final String? initialProfileId;

  @override
  ConsumerState<EnhancedNewSessionScreen> createState() => _EnhancedNewSessionScreenState();
}

class _EnhancedNewSessionScreenState extends ConsumerState<EnhancedNewSessionScreen> {
  // Step control
  int _currentStep = 0;

  // Form data
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedTag = 'general';

  // Machine selection
  String? _selectedMachineId;
  final List<Machine> _availableMachines = [];

  // Path selection
  final TextEditingController _pathController = TextEditingController();
  List<String> _recentPaths = [];

  // Profile selection
  String? _selectedProfileId;
  final List<ProfileSummary> _availableProfiles = [];

  // Permission mode
  String _permissionMode = 'auto';

  // Model mode
  String _modelMode = 'auto';

  @override
  void initState() {
    super.initState();
    if (widget.initialPath != null && widget.initialPath!.isNotEmpty) {
      _pathController.text = widget.initialPath!;
    }
    _loadAvailableMachines();
    _loadAvailableProfiles();
    _loadRecentPaths();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableMachines() async {
    // TODO: Load from API
    setState(() {
      _availableMachines.clear();
      _availableMachines.addAll([
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
      _selectedMachineId = widget.initialMachineId ?? _selectedMachineId ?? 'default';
    });
  }

  Future<void> _loadAvailableProfiles() async {
    // TODO: Load from profiles provider
    setState(() {
      _availableProfiles.clear();
      _availableProfiles.addAll([
        const ProfileSummary(
          id: 'default',
          name: '默认配置',
          isDefault: true,
        ),
        const ProfileSummary(
          id: 'claude',
          name: 'Claude配置',
          isDefault: false,
        ),
      ]);
      _selectedProfileId = widget.initialProfileId ?? _selectedProfileId ?? 'default';
    });
  }

  Future<void> _loadRecentPaths() async {
    // TODO: Load from storage
    setState(() {
      _recentPaths = [
        '~/Projects/ai-driven',
        '~/Projects/flutter-app',
        '~/Projects/react-native',
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('新建会话'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress Steps
          _buildSteps(),
          // Form Content
          Expanded(
            child: PageView(
              controller: PageController(initialPage: 0),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1Content(),
                _Step2Content(),
                _Step3Content(),
              ],
            ),
          ),
          // Bottom Actions
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildSteps() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: AppTheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          return Row(
            children: [
              if (index > 0)
                Container(
                  width: 40,
                  height: 2,
                  color: isCompleted ? AppTheme.brandColor : AppTheme.neutral300,
                ),
              _StepIndicator(
                step: index + 1,
                isActive: isCurrent,
                isCompleted: isCompleted,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _Step1Content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle('基本信息'),
          const SizedBox(height: 8),
          const _StepDescription('配置会话的基本信息'),
          const SizedBox(height: 24),

          // Template Selection
          const _FieldLabel('选择会话类型'),
          const SizedBox(height: 12),
          _TemplateGrid(
            selectedTag: _selectedTag,
            onSelected: (tag) => setState(() => _selectedTag = tag),
          ),
          const SizedBox(height: 24),

          // Title Input
          const _FieldLabel('会话标题（可选）'),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: _InputDecoration(
              hintText: '输入会话标题',
              prefixIcon: Icons.title,
            ),
          ),
          const SizedBox(height: 16),

          // Description Input
          const _FieldLabel('初始提示（可选）'),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: _InputDecoration(
              hintText: '添加初始提示或会话描述',
              prefixIcon: Icons.message,
            ),
          ),
        ],
      ),
    );
  }

  Widget _Step2Content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle('环境配置'),
          const SizedBox(height: 8),
          const _StepDescription('选择工作机器和路径'),
          const SizedBox(height: 24),

          // Machine Selection
          const _FieldLabel('选择机器'),
          const SizedBox(height: 8),
          _MachineSelector(
            machines: _availableMachines,
            selectedId: _selectedMachineId,
            onSelected: (id) => setState(() => _selectedMachineId = id),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _pickMachine,
              icon: const Icon(Icons.list_alt),
              label: const Text('打开完整选择器'),
            ),
          ),
          const SizedBox(height: 24),

          // Path Selection
          const _FieldLabel('工作路径'),
          const SizedBox(height: 8),
          TextField(
            controller: _pathController,
            decoration: _InputDecoration(
              hintText: '输入或选择工作路径',
              prefixIcon: Icons.folder,
              suffixIcon: IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: _showPathPicker,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Recent Paths
          if (_recentPaths.isNotEmpty) ...[
            const _FieldLabel('最近使用的路径'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentPaths.map((path) {
                return _PathChip(
                  path: path,
                  onTap: () {
                    _pathController.text = path;
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _Step3Content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle('高级配置'),
          const SizedBox(height: 8),
          const _StepDescription('配置AI参数和权限模式'),
          const SizedBox(height: 24),

          // Profile Selection
          const _FieldLabel('选择配置文件'),
          const SizedBox(height: 8),
          _ProfileSelector(
            profiles: _availableProfiles,
            selectedId: _selectedProfileId,
            onSelected: (id) => setState(() => _selectedProfileId = id),
            onEdit: _editProfile,
          ),
          const SizedBox(height: 24),

          // Permission Mode
          const _FieldLabel('权限模式'),
          const SizedBox(height: 8),
          _PermissionModeSelector(
            selectedMode: _permissionMode,
            onSelected: (mode) => setState(() => _permissionMode = mode),
          ),
          const SizedBox(height: 16),

          // Model Mode
          const _FieldLabel('模型模式'),
          const SizedBox(height: 8),
          _ModelModeSelector(
            selectedMode: _modelMode,
            onSelected: (mode) => setState(() => _modelMode = mode),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.neutral200),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous Button
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('上一步'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),

            // Next/Create Button
            Expanded(
              flex: _currentStep > 0 ? 1 : 0,
              child: ElevatedButton(
                onPressed: _currentStep < 2 ? _nextStep : _createSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(_currentStep < 2 ? '下一步' : '创建会话'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  Future<void> _createSession() async {
    final notifier = ref.read(sessionStateProvider.notifier);
    final title = _titleController.text.trim();
    final prompt = _descriptionController.text.trim();
    final path = _pathController.text.trim();

    final selectedMachine = _availableMachines.cast<Machine?>().firstWhere(
          (machine) => machine?.id == _selectedMachineId,
          orElse: () => null,
        );

    final metadata = <String, dynamic>{
      'permissionMode': _permissionMode,
      'modelMode': _modelMode,
      if (_selectedMachineId != null) 'machineId': _selectedMachineId,
      if (selectedMachine != null) 'host': selectedMachine.name,
      if (_selectedProfileId != null) 'profileId': _selectedProfileId,
      if (prompt.isNotEmpty) 'description': prompt,
    };

    final sessionId = await notifier.createSession(
      title: title.isEmpty ? null : title,
      tag: _selectedTag,
      path: path.isEmpty ? null : path,
      metadata: metadata,
      permissionMode: _permissionMode,
      modelMode: _modelMode,
    );

    if (sessionId == null || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
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

    if (!mounted) {
      return;
    }
    context.go(AppRoutes.sessionDetail(sessionId));
  }

  Future<void> _showPathPicker() async {
    final result = await context.push<String>(
      AppRoutes.newPathPicker(
        machineId: _selectedMachineId,
        path: _pathController.text.trim().isEmpty ? null : _pathController.text.trim(),
      ),
    );
    if (!mounted || result == null || result.isEmpty) {
      return;
    }
    setState(() {
      _pathController.text = result;
      if (!_recentPaths.contains(result)) {
        _recentPaths = [result, ..._recentPaths].take(6).toList();
      }
    });
  }

  Future<void> _editProfile(String profileId) async {
    final result = await context.push<String>(
      AppRoutes.newProfilePicker(profileId: profileId),
    );
    if (!mounted || result == null || result.isEmpty) {
      return;
    }
    setState(() => _selectedProfileId = result);
  }

  Future<void> _pickMachine() async {
    final result = await context.push<String>(
      Uri(
        path: AppRoutes.newPickMachine,
        queryParameters: {
          if (_selectedMachineId != null) 'selectedMachineId': _selectedMachineId!,
        },
      ).toString(),
    );
    if (!mounted || result == null || result.isEmpty) {
      return;
    }
    setState(() => _selectedMachineId = result);
  }
}

/// Step Indicator
class _StepIndicator extends StatelessWidget {
  final int step;
  final bool isActive;
  final bool isCompleted;

  const _StepIndicator({
    required this.step,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive
            ? AppTheme.brandColor
            : AppTheme.neutral300,
        border: Border.all(color: AppTheme.brandColor, width: 2),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                step.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.brandColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

/// Step Title
class _StepTitle extends StatelessWidget {
  final String title;

  const _StepTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

/// Step Description
class _StepDescription extends StatelessWidget {
  final String description;

  const _StepDescription(this.description);

  @override
  Widget build(BuildContext context) {
    return Text(
      description,
      style: TextStyle(
        fontSize: 14,
        color: AppTheme.neutral600,
      ),
    );
  }
}

/// Field Label
class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

/// Input Decoration
InputDecoration _InputDecoration({
  required String hintText,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(prefixIcon, color: AppTheme.neutral500),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppTheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      borderSide: BorderSide(color: AppTheme.neutral300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      borderSide: BorderSide(color: AppTheme.neutral300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      borderSide: BorderSide(color: AppTheme.brandColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
  );
}

/// Template Grid
class _TemplateGrid extends StatelessWidget {
  final String selectedTag;
  final Function(String) onSelected;

  const _TemplateGrid({
    required this.selectedTag,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final templates = [
      _TemplateItem(
        id: 'general',
        name: '通用对话',
        icon: Icons.chat_bubble_outline,
        color: AppTheme.brandColor,
      ),
      _TemplateItem(
        id: 'code',
        name: '代码开发',
        icon: Icons.code,
        color: Colors.blue,
      ),
      _TemplateItem(
        id: 'debug',
        name: '问题调试',
        icon: Icons.bug_report_outlined,
        color: Colors.orange,
      ),
      _TemplateItem(
        id: 'review',
        name: '代码审查',
        icon: Icons.find_in_page,
        color: Colors.green,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: templates.map((template) {
        return _TemplateCard(
          template: template,
          isSelected: selectedTag == template.id,
          onTap: () => onSelected(template.id),
        );
      }).toList(),
    );
  }
}

/// Template Item
class _TemplateItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const _TemplateItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Template Card
class _TemplateCard extends StatelessWidget {
  final _TemplateItem template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? template.color.withOpacity(0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? template.color : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(template.icon, color: template.color, size: 32),
            const SizedBox(height: 8),
            Text(
              template.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? template.color : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Machine Selector
class _MachineSelector extends StatelessWidget {
  final List<Machine> machines;
  final String? selectedId;
  final Function(String?) onSelected;

  const _MachineSelector({
    required this.machines,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (machines.isEmpty) {
      return const _EmptyState(message: '暂无可用机器');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: machines.map((machine) {
        return _MachineCard(
          machine: machine,
          isSelected: selectedId == machine.id,
          onTap: () => onSelected(machine.id),
        );
      }).toList(),
    );
  }
}

/// Machine Card
class _MachineCard extends StatelessWidget {
  final Machine machine;
  final bool isSelected;
  final VoidCallback onTap;

  const _MachineCard({
    required this.machine,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor.withOpacity(0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              machine.status == MachineStatus.online ? Icons.cloud_done : Icons.cloud_off,
              color: machine.status == MachineStatus.online
                  ? AppTheme.successColor
                  : AppTheme.neutral500,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              machine.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.brandColor : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.neutral200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                machine.platform,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.neutral600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Path Chip
class _PathChip extends StatelessWidget {
  final String path;
  final VoidCallback onTap;

  const _PathChip({required this.path, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        path,
        style: const TextStyle(fontSize: 12),
      ),
      avatar: const Icon(Icons.folder, size: 16),
      onPressed: onTap,
      backgroundColor: AppTheme.neutral100,
    );
  }
}

/// Profile Selector
class _ProfileSelector extends StatelessWidget {
  final List<ProfileSummary> profiles;
  final String? selectedId;
  final Function(String?) onSelected;
  final Function(String) onEdit;

  const _ProfileSelector({
    required this.profiles,
    required this.selectedId,
    required this.onSelected,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        children: profiles.map((profile) {
          return _ProfileTile(
            profile: profile,
            isSelected: selectedId == profile.id,
            onSelected: () => onSelected(profile.id),
            onEdit: () => onEdit(profile.id),
          );
        }).toList(),
      ),
    );
  }
}

/// Profile Tile
class _ProfileTile extends StatelessWidget {
  final ProfileSummary profile;
  final bool isSelected;
  final VoidCallback onSelected;
  final VoidCallback onEdit;

  const _ProfileTile({
    required this.profile,
    required this.isSelected,
    required this.onSelected,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.neutral200),
          ),
          color: isSelected ? AppTheme.brandColor.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: profile.id,
              groupValue: isSelected ? profile.id : null,
              onChanged: (_) => onSelected(),
              activeColor: AppTheme.brandColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (profile.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.brandColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '默认',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
              tooltip: '编辑',
            ),
          ],
        ),
      ),
    );
  }
}

/// Permission Mode Selector
class _PermissionModeSelector extends StatelessWidget {
  final String selectedMode;
  final Function(String) onSelected;

  const _PermissionModeSelector({
    required this.selectedMode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final modes = [
      _ModeItem('auto', '自动', Icons.auto_mode),
      _ModeItem('read', '只读', Icons.visibility),
      _ModeItem('edit', '编辑', Icons.edit),
      _ModeItem('full', '完全访问', Icons.admin_panel_settings),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: modes.map((mode) {
        return _ModeCard(
          item: mode,
          isSelected: selectedMode == mode.id,
          onTap: () => onSelected(mode.id),
        );
      }).toList(),
    );
  }
}

/// Model Mode Selector
class _ModelModeSelector extends StatelessWidget {
  final String selectedMode;
  final Function(String) onSelected;

  const _ModelModeSelector({
    required this.selectedMode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final modes = [
      _ModeItem('auto', '自动选择', Icons.auto_awesome),
      _ModeItem('fast', '快速模式', Icons.flash_on),
      _ModeItem('balanced', '平衡模式', Icons.balance),
      _ModeItem('quality', '高质量模式', Icons.high_quality),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: modes.map((mode) {
        return _ModeCard(
          item: mode,
          isSelected: selectedMode == mode.id,
          onTap: () => onSelected(mode.id),
        );
      }).toList(),
    );
  }
}

/// Mode Item
class _ModeItem {
  final String id;
  final String name;
  final IconData icon;

  const _ModeItem(this.id, this.name, this.icon);
}

/// Mode Card
class _ModeCard extends StatelessWidget {
  final _ModeItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor.withOpacity(0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 16, color: isSelected ? AppTheme.brandColor : AppTheme.neutral600),
            const SizedBox(width: 6),
            Text(
              item.name,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppTheme.brandColor : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty State
class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox, size: 40, color: AppTheme.neutral400),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Machine Model
class Machine {
  final String id;
  final String name;
  final String platform;
  final MachineStatus status;

  const Machine({
    required this.id,
    required this.name,
    required this.platform,
    required this.status,
  });
}

enum MachineStatus { online, offline, busy }

/// Profile Summary Model
class ProfileSummary {
  final String id;
  final String name;
  final bool isDefault;

  const ProfileSummary({
    required this.id,
    required this.name,
    this.isDefault = false,
  });
}
