part of 'new_session_flow_screen.dart';

Widget _buildSessionFlowComposerHeader(
  _NewSessionFlowScreenState state, {
  required SessionModeOption selectedPermission,
  required SessionModeOption selectedModel,
  required Color connectionColor,
  required String connectionText,
}) {
  return Padding(
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
                color: _sessionFlowModeTint(
                    state._selectedAgent, state._permissionMode),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              selectedModel.label,
              style: const TextStyle(fontSize: 11, color: AppTheme.neutral600),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildSessionFlowContextCard(
  _NewSessionFlowScreenState state, {
  required _MachineOption? selectedMachine,
  required String directory,
}) {
  return Container(
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
          onTap: state._pickMachine,
        ),
        if (directory.isNotEmpty || selectedMachine != null)
          const SizedBox(height: 4),
        _ContextButton(
          icon: Icons.folder_outlined,
          label: directory.isEmpty ? '选择工作目录' : directory,
          onTap: state._pickPath,
        ),
      ],
    ),
  );
}

Widget _buildSessionFlowPromptCard(
  _NewSessionFlowScreenState state, {
  required profile_models.AIProfile? selectedProfile,
  required bool canCreate,
  required _MachineOption? selectedMachine,
}) {
  return Container(
    decoration: BoxDecoration(
      color: AppTheme.neutral100,
      borderRadius: BorderRadius.circular(20),
    ),
    padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: state._promptController,
          minLines: 1,
          maxLines: 5,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText: '你想做什么？',
            filled: false,
            contentPadding: EdgeInsets.fromLTRB(8, 10, 8, 10),
            border: InputBorder.none,
            hintStyle: TextStyle(fontSize: 15, color: AppTheme.neutral500),
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
                      onTap: state._showSettingsSheet,
                    ),
                    const SizedBox(width: 8),
                    _ActionPill(
                      icon: Icons.person_outline_rounded,
                      label: selectedProfile?.name ?? '选择模板',
                      onTap: state._pickProfile,
                      onLongPress: selectedProfile == null
                          ? null
                          : () => state._updateView(
                              () => state._selectedProfileId = null),
                    ),
                    const SizedBox(width: 8),
                    _ActionPill(
                      icon: state._selectedAgent == 'codex'
                          ? Icons.memory_rounded
                          : Icons.psychology_alt_outlined,
                      label: sessionAgentLabel(state._selectedAgent),
                      onTap: state._cycleAgent,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(
              enabled: canCreate,
              loading: state._isCreating,
              onTap: canCreate
                  ? () => state._createSession(selectedMachine)
                  : null,
            ),
          ],
        ),
      ],
    ),
  );
}
