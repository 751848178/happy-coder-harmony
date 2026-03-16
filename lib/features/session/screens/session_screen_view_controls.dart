part of 'session_screen.dart';

extension _SessionScreenViewControls on _SessionScreenState {
  Widget _buildSessionControls(
    Session session,
    List<_MessageTurnGroup> turnGroups,
  ) {
    final permissionOption = _resolveCurrentPermissionOption(session);
    final modelOption = _resolveCurrentModelOption(session);
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
            IgnorePointer(
              ignoring: _isRefreshingSessionState,
              child: Opacity(
                opacity: _isRefreshingSessionState ? 0.72 : 1,
                child: _ControlChip(
                  icon: _isRefreshingSessionState
                      ? Icons.sync_rounded
                      : Icons.refresh_rounded,
                  label: _isRefreshingSessionState ? '刷新中' : '刷新',
                  onTap: _refreshSessionState,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ControlChip(
              icon: Icons.security_rounded,
              label: '权限 ${permissionOption.label}',
              onTap: _showPermissionDialog,
            ),
            const SizedBox(width: 8),
            _ControlChip(
              icon: Icons.tune_rounded,
              label: '模型 ${modelOption.label}',
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
