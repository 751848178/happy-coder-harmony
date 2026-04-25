part of 'machine_path_selector.dart';

extension _MachinePathSelectorSections on _MachinePathSelectorState {
  Widget _buildMachineSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.computer, color: AppTheme.brandColor, size: 18),
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
            }),
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
            Icon(Icons.folder, color: AppTheme.brandColor, size: 18),
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
        if (widget.showRecent) _buildRecentPaths(),
        const SizedBox(height: 12),
        _buildPathChips(),
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
            return _PathChip(
              path: path,
              isSelected: _selectedPath == path.path,
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
            return _PathChip(
              path: path,
              isSelected: _selectedPath == path.path,
              onTap: () => _selectPath(path),
            );
          }).toList(),
        ),
      ],
    );
  }
}
