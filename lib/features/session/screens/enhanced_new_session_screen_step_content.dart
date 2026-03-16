part of 'enhanced_new_session_screen.dart';

Widget _buildEnhancedStep1Content(_EnhancedNewSessionScreenState state) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle('基本信息'),
        const SizedBox(height: 8),
        const _StepDescription('配置会话的基本信息'),
        const SizedBox(height: 24),
        const _FieldLabel('选择会话类型'),
        const SizedBox(height: 12),
        _TemplateGrid(
          selectedTag: state._selectedTag,
          onSelected: (tag) =>
              state._updateView(() => state._selectedTag = tag),
        ),
        const SizedBox(height: 24),
        const _FieldLabel('会话标题（可选）'),
        const SizedBox(height: 8),
        TextField(
          controller: state._titleController,
          decoration: _enhancedInputDecoration(
            hintText: '输入会话标题',
            prefixIcon: Icons.title,
          ),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('初始提示（可选）'),
        const SizedBox(height: 8),
        TextField(
          controller: state._descriptionController,
          maxLines: 4,
          decoration: _enhancedInputDecoration(
            hintText: '添加初始提示或会话描述',
            prefixIcon: Icons.message,
          ),
        ),
      ],
    ),
  );
}

Widget _buildEnhancedStep2Content(_EnhancedNewSessionScreenState state) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle('环境配置'),
        const SizedBox(height: 8),
        const _StepDescription('选择工作机器和路径'),
        const SizedBox(height: 24),
        const _FieldLabel('选择机器'),
        const SizedBox(height: 8),
        _MachineSelector(
          machines: state._availableMachines,
          selectedId: state._selectedMachineId,
          onSelected: (id) =>
              state._updateView(() => state._selectedMachineId = id),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: state._pickMachine,
            icon: const Icon(Icons.list_alt),
            label: const Text('打开完整选择器'),
          ),
        ),
        const SizedBox(height: 24),
        const _FieldLabel('工作路径'),
        const SizedBox(height: 8),
        TextField(
          controller: state._pathController,
          decoration: _enhancedInputDecoration(
            hintText: '输入或选择工作路径',
            prefixIcon: Icons.folder,
            suffixIcon: IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: state._showPathPicker,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (state._recentPaths.isNotEmpty) ...[
          const _FieldLabel('最近使用的路径'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state._recentPaths
                .map(
                  (path) => _PathChip(
                    path: path,
                    onTap: () => state._pathController.text = path,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    ),
  );
}

Widget _buildEnhancedStep3Content(_EnhancedNewSessionScreenState state) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle('高级配置'),
        const SizedBox(height: 8),
        const _StepDescription('配置AI参数和权限模式'),
        const SizedBox(height: 24),
        const _FieldLabel('选择配置文件'),
        const SizedBox(height: 8),
        _ProfileSelector(
          profiles: state._availableProfiles,
          selectedId: state._selectedProfileId,
          onSelected: (id) =>
              state._updateView(() => state._selectedProfileId = id),
          onEdit: state._editProfile,
        ),
        const SizedBox(height: 24),
        const _FieldLabel('权限模式'),
        const SizedBox(height: 8),
        _PermissionModeSelector(
          selectedMode: state._permissionMode,
          onSelected: (mode) =>
              state._updateView(() => state._permissionMode = mode),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('模型模式'),
        const SizedBox(height: 8),
        _ModelModeSelector(
          selectedMode: state._modelMode,
          onSelected: (mode) =>
              state._updateView(() => state._modelMode = mode),
        ),
      ],
    ),
  );
}

Widget _buildEnhancedBottomActions(_EnhancedNewSessionScreenState state) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      border: Border(top: BorderSide(color: AppTheme.neutral200)),
    ),
    child: SafeArea(
      child: Row(
        children: [
          if (state._currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => state._updateView(() => state._currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('上一步'),
              ),
            ),
          if (state._currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: state._currentStep > 0 ? 1 : 0,
            child: ElevatedButton(
              onPressed: state._currentStep < 2
                  ? state._nextStep
                  : state._createSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(state._currentStep < 2 ? '下一步' : '创建会话'),
            ),
          ),
        ],
      ),
    ),
  );
}
