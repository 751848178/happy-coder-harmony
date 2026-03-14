import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Machine info model
class MachineInfo {
  final String id;
  final String name;
  final String host;
  final String? iconPath;
  final bool isLocal;
  final bool isOnline;
  final String? sshKey;

  const MachineInfo({
    required this.id,
    required this.name,
    required this.host,
    this.iconPath,
    this.isLocal = false,
    this.isOnline = true,
    this.sshKey,
  });

  MachineInfo copyWith({
    String? id,
    String? name,
    String? host,
    String? iconPath,
    bool? isLocal,
    bool? isOnline,
    String? sshKey,
  }) {
    return MachineInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      iconPath: iconPath ?? this.iconPath,
      isLocal: isLocal ?? this.isLocal,
      isOnline: isOnline ?? this.isOnline,
      sshKey: sshKey ?? this.sshKey,
    );
  }
}

/// Path info model
class PathInfo {
  final String path;
  final String label;
  final IconData icon;
  final bool isFavorite;
  final int? recentIndex;

  const PathInfo({
    required this.path,
    required this.label,
    required this.icon,
    this.isFavorite = false,
    this.recentIndex,
  });

  String get displayName => label.isEmpty ? path : label;
}

/// Built-in machines
class BuiltInMachines {
  static const all = [
    MachineInfo(
      id: 'local',
      name: '本地机器',
      host: 'localhost',
      isLocal: true,
      isOnline: true,
    ),
  ];

  static MachineInfo? byId(String id) {
    for (final machine in all) {
      if (machine.id == id) return machine;
    }
    return null;
  }
}

/// Built-in paths
class BuiltInPaths {
  static const all = [
    PathInfo(
      path: '/',
      label: '根目录',
      icon: Icons.home,
    ),
    PathInfo(
      path: '/home',
      label: '用户目录',
      icon: Icons.person,
    ),
    PathInfo(
      path: '/tmp',
      label: '临时目录',
      icon: Icons.folder,
    ),
    PathInfo(
      path: '/var/log',
      label: '日志目录',
      icon: Icons.description,
    ),
    PathInfo(
      path: '/etc',
      label: '配置目录',
      icon: Icons.settings,
    ),
  ];

  static const recentPaths = [
    PathInfo(
      path: '/home/user/project',
      label: 'project',
      icon: Icons.code,
      recentIndex: 0,
    ),
    PathInfo(
      path: '/home/user/work',
      label: 'work',
      icon: Icons.work,
      recentIndex: 1,
    ),
    PathInfo(
      path: '/home/user/documents',
      label: 'documents',
      icon: Icons.folder_open,
      recentIndex: 2,
    ),
    PathInfo(
      path: '/home/user/downloads',
      label: 'downloads',
      icon: Icons.download,
      recentIndex: 3,
    ),
  ];
}

/// Machine and Path Selector Widget
///
/// Allows users to select a machine and path for sessions
class MachinePathSelector extends StatefulWidget {
  const MachinePathSelector({
    super.key,
    this.initialMachineId,
    this.initialPath,
    this.onMachineChanged,
    this.onPathChanged,
    this.onSelectionConfirmed,
    this.showRecent = true,
    this.showPathInput = true,
  });

  final String? initialMachineId;
  final String? initialPath;
  final Function(MachineInfo)? onMachineChanged;
  final Function(String)? onPathChanged;
  final VoidCallback? onSelectionConfirmed;
  final bool showRecent;
  final bool showPathInput;

  @override
  State<MachinePathSelector> createState() => _MachinePathSelectorState();
}

class _MachinePathSelectorState extends State<MachinePathSelector> {
  MachineInfo? _selectedMachine;
  String? _selectedPath;
  final _pathController = TextEditingController();
  bool _showAllPaths = false;

  @override
  void initState() {
    super.initState();
    _selectedMachine = widget.initialMachineId != null
        ? BuiltInMachines.byId(widget.initialMachineId!)
        : BuiltInMachines.all.first;
    _selectedPath = widget.initialPath;
    if (widget.initialPath != null) {
      _pathController.text = widget.initialPath!;
    }
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  void _selectMachine(MachineInfo machine) {
    setState(() => _selectedMachine = machine);
    widget.onMachineChanged?.call(machine);
  }

  void _selectPath(PathInfo path) {
    setState(() {
      _selectedPath = path.path;
      _pathController.text = path.path;
    });
    widget.onPathChanged?.call(path.path);
  }

  void _onPathInputChanged(String value) {
    setState(() => _selectedPath = value.isEmpty ? null : value);
    widget.onPathChanged?.call(value.isEmpty ? '/' : value);
  }

  void _showAddMachineDialog() {
    final nameController = TextEditingController();
    final hostController = TextEditingController();
    final sshKeyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加远程机器'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hostController,
                decoration: const InputDecoration(
                  labelText: '主机地址',
                  border: OutlineInputBorder(),
                  hintText: 'user@host 或 host:port',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sshKeyController,
                decoration: const InputDecoration(
                  labelText: 'SSH 密钥（可选）',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  hostController.text.trim().isEmpty) {
                return;
              }
              // In a real app, this would save the machine
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Machine selector
          _buildMachineSelector(),

          const SizedBox(height: 20),

          // Path selector
          _buildPathSelector(),

          if (widget.onSelectionConfirmed != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedMachine != null && _selectedPath != null
                    ? widget.onSelectionConfirmed
                    : null,
                icon: const Icon(Icons.check),
                label: const Text('确认选择'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMachineSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.computer,
              color: AppTheme.brandColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              '选择机器',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ...BuiltInMachines.all.map((machine) {
              final isSelected = _selectedMachine?.id == machine.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _MachineChip(
                  machine: machine,
                  isSelected: isSelected,
                  onTap: () => _selectMachine(machine),
                ),
              );
            }).toList(),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: _showAddMachineDialog,
              icon: const Icon(Icons.add),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.neutral600,
              ),
            ),
          ],
        ),
        // Machine status
        if (_selectedMachine != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedMachine!.isLocal
                  ? AppTheme.successColor.withValues(alpha: 0.1)
                  : AppTheme.infoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedMachine!.isLocal
                    ? AppTheme.successColor.withValues(alpha: 0.3)
                    : AppTheme.infoColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedMachine!.isLocal ? Icons.check_circle : Icons.lan,
                  size: 16,
                  color: _selectedMachine!.isLocal
                      ? AppTheme.successColor
                      : AppTheme.infoColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedMachine!.isLocal
                      ? '本地机器'
                      : '远程机器: ${_selectedMachine!.host}',
                  style: TextStyle(
                    fontSize: 13,
                    color: _selectedMachine!.isLocal
                        ? AppTheme.successColor
                        : AppTheme.infoColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPathSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.folder,
              color: AppTheme.brandColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              '选择路径',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Recent paths
        if (widget.showRecent) _buildRecentPaths(),

        const SizedBox(height: 12),

        // Path chips
        _buildPathChips(),

        // Custom path input
        if (widget.showPathInput) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _pathController,
            decoration: const InputDecoration(
              labelText: '或输入自定义路径',
              border: OutlineInputBorder(),
              hintText: '/path/to/directory',
              prefixIcon: Icon(Icons.edit),
            ),
            onChanged: _onPathInputChanged,
          ),
        ],
      ],
    );
  }

  Widget _buildRecentPaths() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '最近使用',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.neutral500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BuiltInPaths.recentPaths.map((path) {
            final isSelected = _selectedPath == path.path;
            return _PathChip(
              path: path,
              isSelected: isSelected,
              onTap: () => _selectPath(path),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPathChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '常用路径',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.neutral500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BuiltInPaths.all.map((path) {
            final isSelected = _selectedPath == path.path;
            return _PathChip(
              path: path,
              isSelected: isSelected,
              onTap: () => _selectPath(path),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Machine chip widget
class _MachineChip extends StatelessWidget {
  const _MachineChip({
    required this.machine,
    required this.isSelected,
    required this.onTap,
  });

  final MachineInfo machine;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor : AppTheme.neutral100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : AppTheme.neutral300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              machine.isLocal ? Icons.computer : Icons.cloud,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.neutral600,
            ),
            const SizedBox(width: 6),
            Text(
              machine.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Path chip widget
class _PathChip extends StatelessWidget {
  const _PathChip({
    required this.path,
    required this.isSelected,
    required this.onTap,
  });

  final PathInfo path;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandColor.withValues(alpha: 0.15)
              : AppTheme.neutral100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : AppTheme.neutral300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              path.icon,
              size: 14,
              color: isSelected ? AppTheme.brandColor : AppTheme.neutral600,
            ),
            const SizedBox(width: 6),
            Text(
              path.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.brandColor : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick machine selector (for toolbar)
class QuickMachineSelector extends StatelessWidget {
  const QuickMachineSelector({
    super.key,
    required this.selectedMachine,
    required this.onMachineChanged,
    this.compact = false,
  });

  final MachineInfo? selectedMachine;
  final ValueChanged<MachineInfo?> onMachineChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<MachineInfo?>(
      value: selectedMachine,
      decoration: InputDecoration(
        labelText: '机器',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: compact,
      ),
      items: [
        ...BuiltInMachines.all,
        const MachineInfo(
          id: 'add',
          name: '添加...',
          host: '',
        ),
      ].map((machine) {
        return DropdownMenuItem<MachineInfo?>(
          value: machine.id == 'add' ? null : machine,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                machine.isLocal ? Icons.computer : Icons.cloud,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(machine.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (machine) {
        if (machine != null && machine.id != 'add') {
          onMachineChanged(machine);
        }
      },
    );
  }
}

/// Quick path selector (for toolbar)
class QuickPathSelector extends StatelessWidget {
  const QuickPathSelector({
    super.key,
    required this.path,
    required this.onPathChanged,
    this.compact = false,
  });

  final String path;
  final ValueChanged<String> onPathChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: path)
        ..selection = TextSelection.collapsed(offset: 0),
      decoration: InputDecoration(
        labelText: '路径',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: compact,
        prefixIcon: const Icon(Icons.folder, size: 18),
      ),
      onChanged: onPathChanged,
    );
  }
}
