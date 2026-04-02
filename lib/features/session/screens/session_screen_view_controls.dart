part of 'session_screen.dart';

extension _SessionScreenViewControls on _SessionScreenState {
  Widget _buildSessionControls(
    Session session,
    List<_MessageTurnGroup> turnGroups,
  ) {
    final modeMetadata = _watchModeMetadataForSession(session);
    final permissionOption = _resolveCurrentPermissionOption(
      session,
      modeMetadata: modeMetadata,
    );
    final modelOption = _resolveCurrentModelOption(
      session,
      modeMetadata: modeMetadata,
    );
    final permissionLabel = permissionOption?.label ??
        _currentExplicitPermissionKey(session) ??
        '未设置';
    final modelLabel = modelOption?.label ??
        _displayModelKeyLabel(_currentExplicitModelKey(session));
    final isActive = session.active || session.presence?.isOnline == true;
    final statusText = isActive ? '已连接' : '离线';

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.successColor
                          : AppTheme.neutral500,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isActive
                          ? AppTheme.successColor
                          : AppTheme.neutral600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ControlChip(
              icon: Icons.security_rounded,
              label: '权限 $permissionLabel',
              onTap: _showPermissionDialog,
            ),
            const SizedBox(width: 8),
            _ControlChip(
              icon: Icons.tune_rounded,
              label: '模型 $modelLabel',
              onTap: () => _showModelDialog(session),
            ),
            if (turnGroups.isNotEmpty) ...[
              const SizedBox(width: 8),
              _ControlChip(
                icon: _collapseAllTurns
                    ? Icons.unfold_more_rounded
                    : Icons.unfold_less_rounded,
                label: _collapseAllTurns ? '展开轮次' : '折叠轮次',
                onTap: () => _toggleAllTurns(turnGroups),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
